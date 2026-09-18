import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase/supabase.dart';

import '../sync/account_link.dart';
import '../sync/backend_config.dart';
import '../images/image_store.dart';
import '../sync/change_feed.dart';
import '../sync/image_sync.dart';
import '../sync/supabase_transport.dart';
import '../sync/sync_auth.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_transport.dart';
import '../sync/synced_tables.dart';
import 'providers.dart';
import 'sync_summary.dart';

// --- state ------------------------------------------------------------------------------

/// Where sync stands. The sidebar summarises it; the sync sheet acts on it.
sealed class SyncState {
  const SyncState();
}

/// Loading the stored sign-in, at launch.
final class SyncStarting extends SyncState {
  const SyncStarting();
}

/// This build has no project to sync with. Everything else works; nothing leaves the device.
final class SyncUnconfigured extends SyncState {
  const SyncUnconfigured();
}

/// Not signed in. Everything works; nothing leaves this device.
final class SyncSignedOut extends SyncState {
  const SyncSignedOut({this.notice});

  /// Why sync stopped, when it stopped without being asked to.
  final String? notice;
}

/// Signed in, and getting this device ready to sync with the account.
final class SyncLinking extends SyncState {
  const SyncLinking({required this.account, this.error});

  final SyncAccount account;

  /// Why getting ready stopped, if it did. Trying again starts over safely.
  final String? error;
}

/// Signed in. The account has another device's work, and this device has its own.
final class SyncChoosing extends SyncState {
  const SyncChoosing({required this.account, required this.plan, this.error});

  final SyncAccount account;
  final AdoptAccount plan;

  /// Why carrying out the last choice failed, if it did. Nothing was changed.
  final String? error;
}

/// Signed in, but this device already syncs with a different account.
final class SyncLinkedElsewhere extends SyncState {
  const SyncLinkedElsewhere({required this.account});

  final SyncAccount account;
}

/// What stopped the last sync.
enum SyncProblem {
  /// No connection. Changes wait here, and go when there is one.
  offline,

  /// This device's date or time is wrong.
  deviceClock,

  /// Another device's clock is wrong enough that its changes were refused.
  otherDeviceClock,

  /// Anything else. Retried on its own.
  failed,
}

/// Signed in and syncing.
final class SyncOn extends SyncState {
  const SyncOn({
    required this.account,
    this.syncing = false,
    this.lastSynced,
    this.problem,
    this.detail,
    this.pending = 0,
  });

  final SyncAccount account;
  final bool syncing;
  final DateTime? lastSynced;
  final SyncProblem? problem;

  /// The error behind [problem], for anyone who wants the specifics.
  final String? detail;

  /// Changes made here that have not reached the server yet.
  final int pending;

  SyncOn copyWith({
    bool? syncing,
    DateTime? lastSynced,
    int? pending,
    SyncProblem? problem,
    String? detail,
    bool clearProblem = false,
  }) => SyncOn(
    account: account,
    syncing: syncing ?? this.syncing,
    lastSynced: lastSynced ?? this.lastSynced,
    pending: pending ?? this.pending,
    problem: clearProblem ? null : problem ?? this.problem,
    detail: clearProblem ? null : detail ?? this.detail,
  );
}

// --- providers --------------------------------------------------------------------------

/// Whether this build was given a project to sync with.
///
/// A provider rather than the constant itself, so a test that supplies its own client is a
/// build with a project, whatever the constants say.
final backendConfiguredProvider = Provider<bool>((ref) => BackendConfig.configured);

/// The Supabase client. One for the app's lifetime, because it holds the session.
///
/// Only ever read where [backendConfiguredProvider] says there is a project to talk to.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = SupabaseClient(
    BackendConfig.url,
    BackendConfig.publishableKey,
    // Password sign-in has no redirect to protect, so none of the storage PKCE asks for.
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  ref.onDispose(client.dispose);
  return client;
});

final syncAuthProvider = Provider<SyncAuth>((ref) {
  final auth = SyncAuth(
    ref.watch(supabaseClientProvider),
    ref.watch(databaseProvider),
  );
  ref.onDispose(auth.dispose);
  return auth;
});

/// Word of other devices' changes, so they arrive at once. Silent under test, where there is
/// no server to listen to.
final changeFeedProvider = Provider<ChangeFeed>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) return const NoChangeFeed();
  return SupabaseChangeFeed(ref.watch(supabaseClientProvider));
});

/// Where note images' bytes are sent and fetched.
final imageBlobsProvider = Provider<ImageBlobs>(
  (ref) => SupabaseImageBlobs(ref.watch(supabaseClientProvider)),
);

final syncProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

/// Whether the sync sheet is open.
class SyncSheetOpen extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

final syncSheetOpenProvider = NotifierProvider<SyncSheetOpen, bool>(
  SyncSheetOpen.new,
);

// --- controller -------------------------------------------------------------------------

/// Signing in, linking this device to the account, and syncing in the background.
///
/// Nothing else in the app waits on anything here. Edits go to the local database and
/// return; this notices them, sends them a moment later, and pulls in what other devices
/// did.
class SyncController extends Notifier<SyncState> {
  late SyncAuth _auth;
  late ChangeFeed _feed;
  AppScope? _scope;
  SyncEngine? _engine;
  AccountLink? _link;
  ImageSync? _images;
  Future<void>? _imagesRunning;
  Timer? _imagesAgain;

  Timer? _every;
  Timer? _afterEdit;
  Timer? _afterRemote;
  Timer? _retry;
  StreamSubscription<int>? _pending;
  AppLifecycleListener? _lifecycle;

  Future<void>? _running;
  bool _runAgain = false;
  int _failures = 0;

  /// How long after an edit it is sent: once typing pauses, so a title typed is one push.
  static const editDelay = Duration(milliseconds: 800);

  /// How long after word of another device's change this one pulls. One push of many rows
  /// is many messages, and this makes them one pull.
  static const remoteDelay = Duration(milliseconds: 250);

  /// How often other devices' changes are fetched while nothing is telling this device
  /// about them.
  static const interval = Duration(seconds: 30);

  /// The same, while the change feed is connected and changes arrive as they happen. Only a
  /// safety net for a message that went missing.
  static const liveInterval = Duration(minutes: 5);

  /// How long checking the sign-in may take before it counts as offline.
  ///
  /// With no network, the auth client keeps retrying a refresh for about ten seconds, and
  /// "Checking…" shown that long reads as stuck.
  static const authTimeout = Duration(seconds: 4);

  /// Waits between failed attempts: growing, then holding at the last.
  static const retryDelays = [
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  @override
  SyncState build() {
    ref.onDispose(_stop);
    // A build given no project keeps everything on this device, and says so rather than
    // offering a sign-in that could not work.
    if (!ref.watch(backendConfiguredProvider)) return const SyncUnconfigured();
    _auth = ref.watch(syncAuthProvider);
    _feed = ref.watch(changeFeedProvider);

    final scope = ref.watch(appScopeProvider).value;
    if (scope == null) return const SyncStarting();

    final transport = SupabaseTransport(ref.watch(supabaseClientProvider));
    final engine = SyncEngine(
      db: scope.db,
      writer: scope.writer,
      transport: transport,
      tables: scope.db.syncedTables,
    );
    _scope = scope;
    _engine = engine;
    _images = ImageSync(
      db: scope.db,
      store: ref.watch(imageStoreProvider),
      blobs: ref.watch(imageBlobsProvider),
    );
    _link = AccountLink(
      db: scope.db,
      writer: scope.writer,
      engine: engine,
      transport: transport,
      backupPath: _backupPath,
    );

    unawaited(_start());
    return const SyncStarting();
  }

  // --- signing in ---

  /// Signs in to an existing account. Throws what went wrong, for the sheet to say.
  Future<void> signIn(String email, String password) async {
    final account = await _auth.signIn(email: email, password: password);
    if (ref.mounted) await _connect(account);
  }

  /// Creates an account and signs in to it. Throws what went wrong, for the sheet to say.
  Future<void> createAccount(String email, String password) async {
    final account = await _auth.createAccount(email: email, password: password);
    if (ref.mounted) await _connect(account);
  }

  /// Starts getting ready to sync again, after it stopped.
  Future<void> retry() async {
    final current = state;
    if (current is SyncLinking) await _connect(current.account);
  }

  /// Carries out the choice of what becomes of this device's work.
  Future<void> choose(LinkChoice choice) async {
    final current = state;
    if (current is! SyncChoosing) return;

    state = SyncLinking(account: current.account);
    try {
      await _link!.adopt(current.account.userId, current.plan, choice);
    } on Exception catch (e) {
      // The choice still stands: nothing of this device's was changed.
      if (ref.mounted) {
        state = SyncChoosing(
          account: current.account,
          plan: current.plan,
          error: describeSyncError(e),
        );
      }
      return;
    }
    if (ref.mounted) _reopen();
  }

  /// Signs out. Everything stays on this device.
  Future<void> signOut() async {
    _stop();
    await _auth.signOut();
    if (ref.mounted) state = const SyncSignedOut();
  }

  // --- syncing ---

  /// Syncs now, or straight after the sync already running. Never two at once.
  Future<void> syncNow() {
    if (state is! SyncOn) return Future.value();
    if (_running case final running?) {
      _runAgain = true;
      return running;
    }
    final run = _runUntilSettled();
    _running = run;
    return run.whenComplete(() => _running = null);
  }

  Future<void> _runUntilSettled() async {
    do {
      _runAgain = false;
      await _syncOnce();
    } while (_runAgain && ref.mounted && state is SyncOn);
  }

  Future<void> _syncOnce() async {
    final engine = _engine;
    final before = state;
    if (engine == null || before is! SyncOn) return;
    state = before.copyWith(syncing: true);

    SyncReport report;
    try {
      if (await _auth.ensureSession().timeout(authTimeout) == null) {
        if (ref.mounted) await _endedByServer();
        return;
      }
      report = await engine.syncOnce();
    } on AuthRetryableFetchException catch (e) {
      report = SyncReport(error: SyncOfflineException(e.message));
    } on TimeoutException {
      report = const SyncReport(
        error: SyncOfflineException('the sign-in could not be refreshed in time'),
      );
    }

    if (!ref.mounted) return;
    final current = state;
    if (current is! SyncOn) return;

    if (report.signedOut) {
      await _endedByServer();
      return;
    }
    if (report.ok) {
      _failures = 0;
      _retry?.cancel();
      state = current.copyWith(
        syncing: false,
        lastSynced: DateTime.now(),
        clearProblem: true,
      );
      // With the rows through, the image files they name follow.
      unawaited(_syncImages());
      return;
    }

    state = current.copyWith(
      syncing: false,
      problem: _problemOf(report),
      detail: '${report.error}',
    );
    final delay = retryDelays[math.min(_failures, retryDelays.length - 1)];
    _failures++;
    _retry?.cancel();
    _retry = Timer(delay, () => unawaited(syncNow()));
  }

  static SyncProblem _problemOf(SyncReport report) {
    if (report.deviceClockAhead) return SyncProblem.deviceClock;
    if (report.clockDrift) return SyncProblem.otherDeviceClock;
    if (report.error is SyncOfflineException) return SyncProblem.offline;
    return SyncProblem.failed;
  }

  // --- internals ---

  Future<void> _start() async {
    SyncAccount? account;
    var offline = false;
    try {
      account = await _auth.start().timeout(authTimeout);
    } on TimeoutException {
      offline = true;
    } on AuthRetryableFetchException {
      offline = true;
    }
    if (!ref.mounted) return;

    if (offline) {
      // A sign-in is stored but cannot be checked. If this device was already syncing, it
      // still is; it just has to wait for a connection.
      final stored = await _auth.storedAccount();
      if (!ref.mounted) return;
      if (stored != null && await _link!.linkedAccount() == stored.userId) {
        if (ref.mounted) _turnOn(stored, problem: SyncProblem.offline);
        return;
      }
    }
    if (!ref.mounted) return;

    if (account == null) {
      state = const SyncSignedOut();
      return;
    }
    await _connect(account);
  }

  /// Takes a signed-in account to syncing, or to the choice that has to come first.
  Future<void> _connect(SyncAccount account) async {
    final link = _link!;
    final linked = await link.linkedAccount();
    if (!ref.mounted) return;
    if (linked == account.userId) {
      _turnOn(account);
      return;
    }
    if (linked != null) {
      state = SyncLinkedElsewhere(account: account);
      return;
    }

    state = SyncLinking(account: account);
    try {
      final plan = await link.plan(account.userId);
      if (!ref.mounted) return;

      switch (plan) {
        case LinkedElsewhere():
          state = SyncLinkedElsewhere(account: account);
        case AlreadyLinked():
          await link.confirm(account.userId);
          if (ref.mounted) _turnOn(account);
        case ClaimAccount():
          await link.claim(account.userId);
          if (ref.mounted) _turnOn(account);
        case final AdoptAccount adopt when !adopt.needsChoice:
          // Only the starter project here: nothing to ask about, and nothing to lose.
          await link.adopt(account.userId, adopt, LinkChoice.replace);
          if (ref.mounted) _reopen();
        case final AdoptAccount adopt:
          state = SyncChoosing(account: account, plan: adopt);
      }
    } on Exception catch (e) {
      if (ref.mounted) {
        state = SyncLinking(account: account, error: describeSyncError(e));
      }
    }
  }

  void _turnOn(SyncAccount account, {SyncProblem? problem}) {
    state = SyncOn(account: account, problem: problem);

    final db = _scope!.db;
    _pending ??= db
        .customSelect('SELECT COUNT(*) AS n FROM outbox', readsFrom: {db.outbox})
        .watchSingle()
        .map((row) => row.read<int>('n'))
        .listen(_onPending);
    _every ??= Timer.periodic(interval, (_) => unawaited(syncNow()));
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(syncNow()));
    _feed.start(
      clientId: _scope!.writer.clientId,
      onChange: _onRemoteChange,
      onLive: _onLive,
    );

    unawaited(syncNow());
  }

  /// Another device changed something: pull it in, once the burst of messages is over.
  void _onRemoteChange() {
    if (state is! SyncOn) return;
    _afterRemote?.cancel();
    _afterRemote = Timer(remoteDelay, () => unawaited(syncNow()));
  }

  /// The change feed connected or dropped. Connected, changes arrive as they happen and the
  /// interval is only a safety net; dropped, the interval is how they arrive.
  void _onLive(bool live) {
    if (state is! SyncOn) return;
    _every?.cancel();
    _every = Timer.periodic(
      live ? liveInterval : interval,
      (_) => unawaited(syncNow()),
    );
    // Whatever changed while it was disconnected was never announced.
    if (live) unawaited(syncNow());
  }

  void _onPending(int pending) {
    final current = state;
    if (current is! SyncOn) return;
    if (current.pending != pending) state = current.copyWith(pending: pending);

    if (pending > 0) {
      _afterEdit?.cancel();
      _afterEdit = Timer(editDelay, () => unawaited(syncNow()));
    }
  }

  /// Reopens the app's data on the workspace linking just switched to.
  ///
  /// Everything built on that data is rebuilt, this controller included, which then finds
  /// the device linked and starts syncing.
  void _reopen() => ref.invalidate(appScopeProvider);

  Future<void> _endedByServer() async {
    _stop();
    await _auth.signOut();
    if (ref.mounted) {
      state = const SyncSignedOut(
        notice: 'You were signed out. Sign in again to keep syncing.',
      );
    }
  }

  /// How long to wait for another device to send an image whose row arrived first.
  static const imageWait = Duration(seconds: 20);

  /// Sends and fetches image files, a batch at a time until none are left, never two passes
  /// at once. A failure is left for the next sync to try again.
  Future<void> _syncImages() {
    if (_imagesRunning case final running?) return running;
    Future<void> run() async {
      final images = _images;
      if (images == null) return;
      try {
        ImageSyncReport report;
        do {
          report = await images.run();
        } while (report.more && ref.mounted && state is SyncOn);
        if (report.waiting > 0 && ref.mounted && state is SyncOn) {
          _imagesAgain?.cancel();
          _imagesAgain = Timer(imageWait, () => unawaited(_syncImages()));
        }
      } on Exception catch (e) {
        debugPrint('Images did not sync: $e');
      }
    }

    final running = run();
    _imagesRunning = running;
    return running.whenComplete(() => _imagesRunning = null);
  }

  void _stop() {
    _imagesAgain?.cancel();
    _imagesAgain = null;
    _every?.cancel();
    _every = null;
    _afterEdit?.cancel();
    _afterEdit = null;
    _afterRemote?.cancel();
    _afterRemote = null;
    unawaited(_feed.stop());
    _retry?.cancel();
    _retry = null;
    unawaited(_pending?.cancel());
    _pending = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  static Future<String> _backupPath() async {
    final directory = await getApplicationSupportDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    return '${directory.path}${Platform.pathSeparator}before-sync-$stamp.sqlite';
  }
}
