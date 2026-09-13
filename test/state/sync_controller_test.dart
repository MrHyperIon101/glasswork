import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

import '../sync/session_fixture.dart';

/// The controller wired the way the app wires it, over an in-memory database and HTTP
/// that answers the way Supabase does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late List<http.Request> requests;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    requests = [];
  });

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  ProviderContainer launch(http.Response Function(http.Request request) answer) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
        supabaseClientProvider.overrideWith((ref) {
          final client = SupabaseClient(
            'https://project.supabase.co',
            'sb_publishable_test',
            authOptions: const AuthClientOptions(
              authFlowType: AuthFlowType.implicit,
            ),
            httpClient: MockClient((request) async {
              requests.add(request);
              final response = answer(request);
              return http.Response.bytes(
                response.bodyBytes,
                response.statusCode,
                headers: response.headers,
                request: request,
              );
            }),
          );
          ref.onDispose(client.dispose);
          return client;
        }),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    // Kept alive the way the app shell keeps it.
    container.listen(syncProvider, (_, _) {});
    return container;
  }

  Future<SyncState> until(
    ProviderContainer container,
    bool Function(SyncState state) reached,
  ) async {
    for (var i = 0; i < 200; i++) {
      final state = container.read(syncProvider);
      if (reached(state)) return state;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    fail('still ${container.read(syncProvider)} after 5 seconds');
  }

  /// Answers as a project with an empty account, and a working sign-in.
  http.Response emptyAccount(http.Request request, Map<String, Object?> session) =>
      switch (request.url.path) {
        '/auth/v1/token' => json(session),
        '/auth/v1/logout' => http.Response('', 204),
        '/rest/v1/rpc/pull_rows' => json(const <Object?>[]),
        '/rest/v1/rpc/merge_rows' => http.Response('', 204),
        _ => http.Response('not expected: ${request.url}', 500),
      };

  Future<ProviderContainer> signedIn(Map<String, Object?> session) async {
    final container = launch((request) => emptyAccount(request, session));
    await until(container, (s) => s is SyncSignedOut);
    await container.read(syncProvider.notifier).signIn(email, 'correct horse');
    return container;
  }

  test('with nothing stored, launch settles on signed out and asks the network nothing', () async {
    final container = launch((_) => http.Response('not expected', 500));

    expect(await until(container, (s) => s is! SyncStarting), isA<SyncSignedOut>());
    expect(requests, isEmpty);
  });

  test('signing in to an empty account claims it, then syncs as that account', () async {
    final session = sessionJson(expiresIn: const Duration(hours: 1));
    final container = await signedIn(session);

    final on =
        await until(container, (s) => s is SyncOn && s.lastSynced != null) as SyncOn;
    expect(on.account.email, email);
    expect(on.problem, isNull);

    final pushes = requests
        .where((r) => r.url.path == '/rest/v1/rpc/merge_rows')
        .toList();
    expect(pushes, isNotEmpty, reason: "this device's work went up");
    expect(
      {
        for (final push in pushes)
          for (final change in jsonDecode(push.body)['changes'] as List)
            change['table'],
      },
      containsAll(['workspaces', 'boards', 'lists']),
    );
    expect(
      pushes.first.headers['authorization'],
      'Bearer ${session['access_token']}',
      reason: 'as the signed-in account, not anonymously',
    );
  });

  test('signing out stops syncing and leaves everything on the device', () async {
    final container = await signedIn(
      sessionJson(expiresIn: const Duration(hours: 1)),
    );
    await until(container, (s) => s is SyncOn && s.lastSynced != null);
    final sync = container.read(syncProvider.notifier);

    await sync.signOut();

    expect(container.read(syncProvider), isA<SyncSignedOut>());
    expect(await db.select(db.workspaces).get(), hasLength(1));
    final sentBefore = requests.length;
    await sync.syncNow();
    expect(requests, hasLength(sentBefore), reason: 'signed out, nothing is sent');
  });
}
