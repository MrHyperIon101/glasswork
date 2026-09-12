import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Minimal workspace -> board -> list chain, since Tasks has real foreign keys.
  Future<String> seedList() async {
    await db
        .into(db.workspaces)
        .insert(WorkspacesCompanion.insert(id: 'ws', name: 'Personal'));
    await db.into(db.boards).insert(
      BoardsCompanion.insert(
        id: 'b1',
        workspaceId: 'ws',
        name: 'Sem V',
        orderKey: 'a0',
      ),
    );
    await db.into(db.lists).insert(
      ListsCompanion.insert(
        id: 'l1',
        workspaceId: 'ws',
        boardId: 'b1',
        name: 'Inbox',
        orderKey: 'a0',
      ),
    );
    return 'l1';
  }

  test('writes and reads a task carrying the full sync tail', () async {
    final listId = await seedList();

    await db.into(db.tasks).insert(
      TasksCompanion.insert(
        id: 't1',
        workspaceId: 'ws',
        listId: listId,
        title: 'Submit DBMS lab',
        orderKey: 'a0',
        clientId: const Value('device-a'),
        fieldVersions: const Value('{"title":"1757000000000:0:device-a"}'),
        estimateMin: const Value(240),
      ),
    );

    final task = await db.select(db.tasks).getSingle();

    expect(task.title, 'Submit DBMS lab');
    expect(task.status, TaskStatus.open);
    expect(task.estimateMin, 240);
    expect(task.clientId, 'device-a');
    expect(task.fieldVersions, contains('device-a'));
    expect(task.deletedAt, isNull);
    // Defaults must land without the caller supplying them.
    expect(task.createdAt, isNotNull);
    expect(task.slipCount, 0);
  });

  test('deleting is a tombstone, not a removal', () async {
    final listId = await seedList();
    await db.into(db.tasks).insert(
      TasksCompanion.insert(
        id: 't1',
        workspaceId: 'ws',
        listId: listId,
        title: 'Gone',
        orderKey: 'a0',
      ),
    );

    final now = DateTime.now();
    await (db.update(db.tasks)..where((t) => t.id.equals('t1'))).write(
      TasksCompanion(deletedAt: Value(now)),
    );

    final all = await db.select(db.tasks).get();
    expect(all, hasLength(1), reason: 'row must survive deletion');
    expect(all.single.deletedAt, isNotNull);

    final live = await (db.select(
      db.tasks,
    )..where((t) => t.deletedAt.isNull())).get();
    expect(live, isEmpty, reason: 'live queries must exclude tombstones');
  });

  test('ordering is by (orderKey, clientId) so equal keys stay deterministic', () async {
    final listId = await seedList();

    // Two offline devices can genuinely generate the same key between the same
    // neighbours. Without the clientId tiebreak the order would be arbitrary.
    for (final (id, key, client) in [
      ('t3', 'a1', 'device-a'),
      ('t1', 'a0', 'device-b'),
      ('t2', 'a1', 'device-a'),
      ('t4', 'a1', 'device-b'),
    ]) {
      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: id,
          workspaceId: 'ws',
          listId: listId,
          title: id,
          orderKey: key,
          clientId: Value(client),
        ),
      );
    }

    final ordered =
        await (db.select(db.tasks)..orderBy([
              (t) => OrderingTerm(expression: t.orderKey),
              (t) => OrderingTerm(expression: t.clientId),
              (t) => OrderingTerm(expression: t.id),
            ]))
            .get();

    expect(ordered.map((t) => t.id), ['t1', 't2', 't3', 't4']);
  });

  test('foreign keys are enforced', () async {
    await expectLater(
      db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: 'orphan',
          workspaceId: 'ws',
          listId: 'does-not-exist',
          title: 'Orphan',
          orderKey: 'a0',
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
