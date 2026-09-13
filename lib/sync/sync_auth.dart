import 'dart:async';
import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../data/db/database.dart';

/// Who is signed in for sync.
class SyncAccount {
  const SyncAccount({required this.userId, this.email});

  final String userId;
  final String? email;
}

/// Email and password sign-in, and keeping that sign-in across launches.
///
/// The session is kept in the local database as a local-only setting, beside the device's
/// own id. It never syncs.
///
/// Launching offline must not sign anyone out. Only a server that actively refuses the
/// stored sign-in — a revoked or already-used refresh token — makes this forget it.
class SyncAuth {
  SyncAuth(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  /// Where the session is stored, in the local settings.
  static const sessionKey = 'auth_session';

  /// The shortest password the project accepts.
  ///
  /// The project enforces this (`minimum_password_length` in supabase/config.toml); the app
  /// only says so up front. test/sync/auth_config_test.dart checks that the two agree.
  static const minimumPasswordLength = 8;

  StreamSubscription<AuthState>? _changes;

  GoTrueClient get _auth => _client.auth;

  /// The signed-in account, while a session is loaded.
  SyncAccount? get account => switch (_auth.currentUser) {
    final user? => SyncAccount(userId: user.id, email: user.email),
    null => null,
  };

  /// Starts keeping the session stored as it refreshes, and loads the stored one.
  ///
  /// Returns the account when there is a usable session. Throws
  /// [AuthRetryableFetchException] when checking needs the network and it is not there;
  /// the session stays stored for the next try.
  Future<SyncAccount?> start() async {
    _changes ??= _auth.onAuthStateChange.listen(
      _store,
      // Failures reach callers of ensureSession directly. A background refresh that
      // fails is retried by the client on its own.
      onError: (Object _) {},
    );
    return ensureSession();
  }

  /// A usable session, refreshing or recovering the stored one if it needs it.
  Future<SyncAccount?> ensureSession() async {
    final current = _auth.currentSession;
    if (current != null && !current.isExpired) return account;

    final stored = await _stored();
    if (current == null && stored == null) return null;

    try {
      if (current != null) {
        await _auth.refreshSession();
      } else {
        await _auth.recoverSession(stored!);
      }
    } on AuthRetryableFetchException {
      rethrow;
    } on AuthException {
      // Refused rather than unreachable: this sign-in is over.
      await _setStored(null);
      return null;
    }
    return account;
  }

  /// The account in the stored session, read without the network.
  ///
  /// For saying who is signed in while offline, before the session can be refreshed into
  /// use.
  Future<SyncAccount?> storedAccount() async {
    final stored = await _stored();
    if (stored == null) return null;
    try {
      final user = (jsonDecode(stored) as Map<String, dynamic>)['user'];
      if (user is! Map || user['id'] is! String) return null;
      return SyncAccount(
        userId: user['id'] as String,
        email: user['email'] as String?,
      );
    } on FormatException {
      return null;
    }
  }

  /// Signs in to an existing account.
  Future<SyncAccount> signIn({
    required String email,
    required String password,
  }) async => _signedIn(
    await _auth.signInWithPassword(email: email, password: password),
  );

  /// Creates an account and signs in to it.
  ///
  /// The project asks for no email confirmation — the only confirmation its built-in email
  /// can send is a link, and nothing here opens one — so a new account arrives signed in.
  /// Should that setting ever change, this says so rather than leaving someone waiting.
  Future<SyncAccount> createAccount({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signUp(email: email, password: password);
    if (response.session == null) {
      throw const AuthException(
        'Confirm your email address, then sign in.',
        code: 'email_not_confirmed',
      );
    }
    return _signedIn(response);
  }

  /// Ends the sign-in on this device. Nothing local is touched.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException {
      // The server could not be told. The session still ends here, which is what matters.
    }
    await _setStored(null);
  }

  Future<void> dispose() async => _changes?.cancel();

  Future<SyncAccount> _signedIn(AuthResponse response) async {
    final user = response.user;
    if (user == null) {
      throw const AuthException('Signed in, but no account came back.');
    }
    if (response.session case final session?) {
      await _setStored(jsonEncode(session.toJson()));
    }
    return SyncAccount(userId: user.id, email: user.email);
  }

  Future<void> _store(AuthState state) async {
    if (state.event == AuthChangeEvent.signedOut) {
      await _setStored(null);
      return;
    }
    if (state.session case final session?) {
      await _setStored(jsonEncode(session.toJson()));
    }
  }

  Future<String?> _stored() async {
    final row =
        await (_db.select(_db.localSettings)
              ..where((s) => s.key.equals(sessionKey)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> _setStored(String? session) async {
    if (session == null) {
      await (_db.delete(_db.localSettings)
            ..where((s) => s.key.equals(sessionKey)))
          .go();
      return;
    }
    await _db
        .into(_db.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(key: sessionKey, value: session),
        );
  }
}
