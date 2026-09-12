import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;
  late WorkspaceRepository workspaces;
  late String workspaceId;
  late String listId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    workspaces = WorkspaceRepository(db);
    final ws = await workspaces.ensureSeeded();
    workspaceId = ws.id;
    listId = (await workspaces.watchLists(workspaceId).first).first.id;
    tasks = TaskRepository(db, clientId: await workspaces.clientId());
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

  test('clientId is stable across calls', () async {
    final a = await workspaces.clientId();
    final b = await workspaces.clientId();
    expect(a, b);
    expect(a, isNotEmpty);
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
    expect(row!.clientId, await workspaces.clientId());
    expect(row.title, 'renamed');
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
