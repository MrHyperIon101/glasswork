import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/sync/supabase_transport.dart';
import 'package:glasswork/sync/sync_engine.dart';
import 'package:glasswork/sync/sync_transport.dart';
import 'package:glasswork/sync/sync_writer.dart';
import 'package:glasswork/sync/synced_tables.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

/// The transport against the HTTP the Supabase client really sends and receives.
///
/// The rows answered here are the server's own: test/sync/fixtures/pull_rows.json was
/// captured from pull_rows on the project, inside a transaction that rolled back.
void main() {
  final fixture =
      jsonDecode(File('test/sync/fixtures/pull_rows.json').readAsStringSync())
          as Map<String, dynamic>;

  late List<http.Request> requests;

  SupabaseTransport transportAnswering(
    FutureOr<http.Response> Function(http.Request request) answer,
  ) {
    requests = [];
    final client = SupabaseClient(
      'https://project.supabase.co',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await answer(request);
        // A real client's response carries the request it answers, and postgrest reads it.
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    return SupabaseTransport(client);
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  const change = RowChange(
    table: 'tasks',
    id: 'aaaaaaaa-0000-4000-8000-0000000000f4',
    values: {'title': 'DBMS lab', 'due_at': '2026-09-20T18:30:00.000Z'},
    versions: {
      'title': '001757755800000:00000:laptop',
      'due_at': '001757755800000:00000:laptop',
    },
    clientId: 'laptop',
  );

  Future<Object?> failureOf(Future<Object?> call) =>
      call.then<Object?>((_) => null, onError: (Object error) => error);

  group('push', () {
    test('calls merge_rows with each change in the shape the server reads', () async {
      final transport = transportAnswering((_) => http.Response('', 204));

      await transport.push(const [change]);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/rpc/merge_rows');
      expect(jsonDecode(request.body), {
        'changes': [
          {
            'table': 'tasks',
            'id': 'aaaaaaaa-0000-4000-8000-0000000000f4',
            'values': {'title': 'DBMS lab', 'due_at': '2026-09-20T18:30:00.000Z'},
            'versions': {
              'title': '001757755800000:00000:laptop',
              'due_at': '001757755800000:00000:laptop',
            },
            'client_id': 'laptop',
          },
        ],
      });
    });

    test('splits a large push into calls the server accepts', () async {
      final transport = transportAnswering((_) => http.Response('', 204));

      await transport.push([
        for (var i = 0; i < SupabaseTransport.pushBatch * 2 + 1; i++)
          RowChange(
            table: 'tasks',
            id: '$i',
            values: const {},
            versions: const {},
            clientId: 'laptop',
          ),
      ]);

      expect(
        [for (final r in requests) (jsonDecode(r.body)['changes'] as List).length],
        [SupabaseTransport.pushBatch, SupabaseTransport.pushBatch, 1],
      );
    });
  });

  group('pull', () {
    test("sends the cursor, and decodes the server's rows", () async {
      final transport = transportAnswering((_) => json(fixture['tasks']));

      final page = await transport.pull(
        'tasks',
        since: DateTime.utc(2026, 9, 13),
        after: PullCursor(
          DateTime.utc(2026, 9, 13, 13, 0, 0, 0, 123),
          'aaaaaaaa-0000-4000-8000-000000000001',
        ),
        limit: 2,
      );

      expect(requests.single.url.path, '/rest/v1/rpc/pull_rows');
      expect(jsonDecode(requests.single.body), {
        'target': 'tasks',
        'since': '2026-09-13T00:00:00.000Z',
        'after_updated_at': '2026-09-13T13:00:00.000123Z',
        'after_id': 'aaaaaaaa-0000-4000-8000-000000000001',
        'max_rows': 2,
      });

      final row = page.rows.single;
      expect(row.id, 'aaaaaaaa-0000-4000-8000-0000000000f4');
      expect(row.updatedAt, DateTime.utc(2026, 9, 13, 13, 29, 12, 482, 507));
      expect(row.clientId, 'laptop');
      expect(row.versions['title'], '001757755800000:00000:laptop');
      expect(row.values['title'], 'DBMS lab');
      expect(row.values.keys, isNot(contains('field_versions')));
      expect(page.hasMore, isFalse, reason: 'one row is less than a full page');
    });

    test('a full page says there may be more', () async {
      final transport = transportAnswering((_) => json(fixture['tasks']));

      final page = await transport.pull('tasks', limit: 1);

      expect(page.hasMore, isTrue);
    });
  });

  test("the engine applies the server's rows with every type intact", () async {
    final transport = transportAnswering((request) {
      final target = jsonDecode(request.body)['target'] as String;
      return json(fixture[target] ?? const <Object?>[]);
    });
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // The task's section, as it would already be here from an earlier pull.
    const workspace = 'aaaaaaaa-0000-4000-8000-0000000000f1';
    await db.into(db.boards).insert(
      BoardsCompanion.insert(
        id: 'b',
        workspaceId: workspace,
        name: 'Sem V',
        orderKey: 'a0',
      ),
    );
    await db.into(db.lists).insert(
      ListsCompanion.insert(
        id: 'aaaaaaaa-0000-4000-8000-0000000000f3',
        workspaceId: workspace,
        boardId: 'b',
        name: 'To do',
        orderKey: 'a0',
      ),
    );

    final engine = SyncEngine(
      db: db,
      writer: SyncWriter(db, clientId: 'phone'),
      transport: transport,
      tables: db.syncedTables,
    );
    expect(await engine.pull(), 2, reason: 'the workspace and the task');

    final task = await db.select(db.tasks).getSingle();
    expect(task.title, 'DBMS lab');
    expect(task.dueAt!.toUtc(), DateTime.utc(2026, 9, 20, 18, 30));
    expect(task.createdAt.toUtc(), DateTime.utc(2026, 9, 13, 9, 30));
    expect(task.estimateMin, 90);
    expect(task.priority, 2);
    expect(task.dueDate, isNull);
    expect(task.clientId, 'laptop');
    expect(
      SyncWriter.decodeVersions(task.fieldVersions)['title'],
      '001757755800000:00000:laptop',
    );
    expect((await db.select(db.workspaces).getSingle()).name, 'Personal');
  });

  group('refusals', () {
    test("a clock ahead of the server's is reported as this device's clock", () async {
      final transport = transportAnswering(
        (_) => json({
          'code': 'GW001',
          'message': 'clock ahead of server time: 009999999999999:00000:broken',
          'details': null,
          'hint': null,
        }, 400),
      );

      expect(
        await failureOf(transport.push(const [change])),
        isA<DeviceClockAheadException>(),
      );
    });

    test('an unreachable server is an ordinary failure, to retry later', () async {
      final client = SupabaseClient(
        'https://project.supabase.co',
        'sb_publishable_test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (_) async => throw http.ClientException('Network is unreachable'),
        ),
      );
      addTearDown(client.dispose);

      final error = await failureOf(
        SupabaseTransport(client).pull('tasks', limit: 1),
      );

      expect(error, isA<SyncOfflineException>());
    });

    test('a token the server cannot accept means signed out', () async {
      final transport = transportAnswering(
        (_) => json({
          'code': 'PGRST301',
          'message': 'JWSError JWSInvalidSignature',
          'details': null,
          'hint': null,
        }, 401),
      );

      expect(
        await failureOf(transport.pull('tasks', limit: 1)),
        isA<SyncSignedOutException>(),
      );
    });

    test('writing into a workspace the account is not in is not mistaken for signed out', () async {
      final transport = transportAnswering(
        (_) => json({
          'code': '42501',
          'message': 'not a member of workspace aaaaaaaa-0000-4000-8000-000000000001',
          'details': null,
          'hint': null,
        }, 403),
      );

      final error = await failureOf(transport.push(const [change]));

      expect(error, isA<SyncTransportException>());
      expect(error, isNot(isA<SyncSignedOutException>()));
    });
  });
}
