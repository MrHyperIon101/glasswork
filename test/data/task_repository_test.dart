import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late SyncWriter writer;
  late TaskRepository tasks;
  late WorkspaceRepository workspaces;
  late String workspaceId;
  late String listId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    writer = SyncWriter(db, clientId: await WorkspaceRepository.ensureClientId(db));
    workspaces = WorkspaceRepository(writer);
    final ws = await workspaces.ensureSeeded();
    workspaceId = ws.id;
    listId = (await workspaces.watchLists(workspaceId).first).first.id;
    tasks = TaskRepository(writer);
  });

  tearDown(() => db.close());

  Future<Task> add(String title) =>
      tasks.create(listId: listId, workspaceId: workspaceId, title: title);

  test('seeding is idempotent', () async {
    final again = await workspaces.ensureSeeded();
    expect(again.id, workspaceId);
    expect(await db.select(db.workspaces).get(), hasLength(1));
    // One project seeded with three sections — calling ensureSeeded again must not
    // duplicate any of them.
    expect(await db.select(db.boards).get(), hasLength(1));
    expect(await db.select(db.lists).get(), hasLength(3));
  });

  test('seeding queues everything it creates for sync', () async {
    final entries = await db.select(db.outbox).get();
    expect(
      entries.map((e) => e.targetTable),
      unorderedEquals(['workspaces', 'boards', 'lists', 'lists', 'lists']),
    );
  });

  test('with two workspaces, opens the oldest rather than throwing', () async {
    // Once sync runs, a device can hold its own workspace and one pulled from another.
    await writer.insert(
      db.workspaces,
      WorkspacesCompanion.insert(
        id: 'from-the-laptop',
        name: 'Personal',
        createdAt: Value(DateTime(2026, 1, 1)),
      ),
    );

    expect((await workspaces.ensureSeeded()).id, 'from-the-laptop');
  });

  test('the client id is created once and then never changes', () async {
    final again = await WorkspaceRepository.ensureClientId(db);
    expect(again, writer.clientId);
    expect(again, isNotEmpty);
  });

  test('created tasks keep insertion order', () async {
    await add('first');
    await add('second');
    await add('third');

    final list = await tasks.watchList(listId).first;
    expect(list.map((t) => t.title), ['first', 'second', 'third']);
  });

  test('delete is a tombstone and restore brings it back', () async {
    final t = await add('delete me');

    await tasks.softDelete(t.id);
    expect(await tasks.watchList(listId).first, isEmpty);
    expect(await db.select(db.tasks).get(), hasLength(1));

    await tasks.restore(t.id);
    final back = await tasks.watchList(listId).first;
    expect(back.single.title, 'delete me');
  });

  test('completing sets completedAt, uncompleting clears it', () async {
    final t = await add('do the thing');

    await tasks.setDone(t.id, done: true);
    var row = await tasks.watchTask(t.id).first;
    expect(row!.status, TaskStatus.done);
    expect(row.completedAt, isNotNull);

    await tasks.setDone(t.id, done: false);
    row = await tasks.watchTask(t.id).first;
    expect(row!.status, TaskStatus.open);
    expect(row.completedAt, isNull);
  });

  test('moving a task rewrites exactly one row', () async {
    final a = await add('a');
    final b = await add('b');
    final c = await add('c');

    final keysBefore = {
      for (final t in await tasks.watchList(listId).first) t.id: t.orderKey,
    };

    // Drag c to the top.
    await tasks.moveBetween(c.id, afterId: null, beforeId: a.id);

    final after = await tasks.watchList(listId).first;
    expect(after.map((t) => t.title), ['c', 'a', 'b']);

    final changed = after
        .where((t) => keysBefore[t.id] != t.orderKey)
        .map((t) => t.id)
        .toList();
    expect(changed, [c.id], reason: 'only the moved row may change');
    expect(b.id, isNotNull);
  });

  test('moving between two neighbours lands between them', () async {
    final a = await add('a');
    final b = await add('b');
    final c = await add('c');

    await tasks.moveBetween(a.id, afterId: b.id, beforeId: c.id);

    final after = await tasks.watchList(listId).first;
    expect(after.map((t) => t.title), ['b', 'a', 'c']);
  });

  test('every write stamps the client id', () async {
    final t = await add('stamped');
    await tasks.rename(t.id, 'renamed');

    final row = await tasks.watchTask(t.id).first;
    expect(row!.clientId, writer.clientId);
    expect(row.title, 'renamed');
  });

  test('every write is queued for sync', () async {
    final t = await add('queued');
    await db.delete(db.outbox).go();

    await tasks.rename(t.id, 'renamed');
    await tasks.setPriority(t.id, 2);

    final entry = (await db.select(db.outbox).get()).single;
    expect(entry.rowId, t.id);
    expect(SyncWriter.decodeFieldNames(entry.changedFields), {'title', 'priority'});
  });

  test('search matches title and notes, case-insensitively', () async {
    final a = await add('Submit DBMS lab');
    await add('Unrelated');
    await tasks.setNotes(a.id, 'remember the ER diagram');

    expect(
      (await tasks.search('dbms').first).map((t) => t.title),
      ['Submit DBMS lab'],
    );
    expect(
      (await tasks.search('ER DIAGRAM').first).map((t) => t.title),
      ['Submit DBMS lab'],
    );
    expect(await tasks.search('nothing here').first, isEmpty);
  });

  test('search excludes tombstoned tasks', () async {
    final t = await add('findable');
    expect(await tasks.search('findable').first, hasLength(1));

    await tasks.softDelete(t.id);
    expect(await tasks.search('findable').first, isEmpty);
  });
}
