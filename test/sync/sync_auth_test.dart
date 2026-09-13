import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/sync/sync_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

import 'session_fixture.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  SyncAuth authAnswering(
    FutureOr<http.Response> Function(http.Request request) answer, {
    List<http.Request>? sent,
  }) {
    final client = SupabaseClient(
      'https://project.supabase.co',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
      httpClient: MockClient((request) async {
        sent?.add(request);
        return answer(request);
      }),
    );
    final auth = SyncAuth(client, db);
    addTearDown(() async {
      await auth.dispose();
      await client.dispose();
    });
    return auth;
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<String?> stored() async =>
      (await (db.select(db.localSettings)
                ..where((s) => s.key.equals(SyncAuth.sessionKey)))
              .getSingleOrNull())
          ?.value;

  Future<void> store(Map<String, Object?> session) => db
      .into(db.localSettings)
      .insert(
        LocalSettingsCompanion.insert(
          key: SyncAuth.sessionKey,
          value: jsonEncode(session),
        ),
      );

  test('signs in with an email and password, and the next launch needs no network', () async {
    final sent = <http.Request>[];
    final auth = authAnswering(
      (request) => request.url.path == '/auth/v1/token'
          ? json(sessionJson(expiresIn: const Duration(hours: 1)))
          : http.Response('not expected: ${request.url}', 500),
      sent: sent,
    );
    expect(await auth.start(), isNull, reason: 'nothing stored yet');

    final account = await auth.signIn(email: email, password: 'correct horse');

    expect(account.userId, userId);
    final request = sent.single;
    expect(request.url.queryParameters['grant_type'], 'password');
    expect(
      jsonDecode(request.body),
      allOf(containsPair('email', email), containsPair('password', 'correct horse')),
    );

    // The next launch, with every request failing: an unexpired session needs none.
    final relaunched = authAnswering(
      (_) async => throw http.ClientException('Network is unreachable'),
    );
    expect((await relaunched.start())?.userId, userId);
  });

  test('creating an account signs straight in to it', () async {
    final auth = authAnswering(
      (request) => request.url.path == '/auth/v1/signup'
          ? json(sessionJson(expiresIn: const Duration(hours: 1)))
          : http.Response('not expected: ${request.url}', 500),
    );
    await auth.start();

    final account = await auth.createAccount(email: email, password: 'correct horse');

    expect(account.email, email);
    expect(await stored(), isNotNull);
  });

  test('an account that still needs confirming is reported rather than left waiting', () async {
    // What the server answers when email confirmation is on: an account, but no session.
    final auth = authAnswering(
      (_) => json({
        'id': userId,
        'aud': 'authenticated',
        'email': email,
        'confirmation_sent_at': '2026-09-13T09:30:00Z',
        'app_metadata': {'provider': 'email'},
        'user_metadata': <String, Object?>{},
        'created_at': '2026-09-13T09:30:00Z',
      }),
    );
    await auth.start();

    await expectLater(
      auth.createAccount(email: email, password: 'correct horse'),
      throwsA(
        isA<AuthException>().having((e) => e.code, 'code', 'email_not_confirmed'),
      ),
    );
  });

  test('launching offline keeps an expired session for when the network is back', () async {
    await store(sessionJson(expiresIn: const Duration(minutes: -5)));
    final auth = authAnswering(
      (_) async => throw http.ClientException('Network is unreachable'),
    );

    await expectLater(auth.start(), throwsA(isA<AuthRetryableFetchException>()));
    expect(await stored(), isNotNull);
    expect(
      (await auth.storedAccount())?.email,
      email,
      reason: 'who is signed in can still be shown',
    );
  });

  test('a stored session the server refuses is forgotten', () async {
    await store(sessionJson(expiresIn: const Duration(minutes: -5)));
    final auth = authAnswering(
      (_) => json({
        'code': 400,
        'error_code': 'refresh_token_not_found',
        'msg': 'Invalid Refresh Token: Refresh Token Not Found',
      }, 400),
    );

    expect(await auth.start(), isNull);
    expect(await stored(), isNull);
  });

  test('signing out forgets the session even when the server cannot be told', () async {
    await store(sessionJson(expiresIn: const Duration(hours: 1)));
    final auth = authAnswering(
      (_) async => throw http.ClientException('Network is unreachable'),
    );
    expect((await auth.start())?.userId, userId);

    await auth.signOut();

    expect(await stored(), isNull);
    expect(auth.account, isNull);
  });
}
