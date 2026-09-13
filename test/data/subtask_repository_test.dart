import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/repository/subtask_repository.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late SubtaskRepository steps;
  late Task task;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final writer = SyncWriter(
      db,
      clientId: await WorkspaceRepository.ensureClientId(db),
    );
    final workspaces = WorkspaceRepository(writer);
    final ws = await workspaces.ensureSeeded();
    final listId = (await workspaces.watchLists(ws.id).first).first.id;

    steps = SubtaskRepository(writer);
    task = await TaskRepository(
      writer,
    ).create(listId: listId, workspaceId: ws.id, title: 'Parent');
  });

  tearDown(() => db.close());

  Future<Subtask> add(String title) =>
      steps.create(taskId: task.id, workspaceId: task.workspaceId, title: title);

  test('steps keep insertion order', () async {
    await add('one');
    await add('two');
    await add('three');

    final all = await steps.watchFor(task.id).first;
    expect(all.map((s) => s.title), ['one', 'two', 'three']);
  });

  test('completing a step is reversible', () async {
    final s = await add('do it');

    await steps.setDone(s.id, done: true);
    expect((await steps.watchFor(task.id).first).single.done, isTrue);

    await steps.setDone(s.id, done: false);
    expect((await steps.watchFor(task.id).first).single.done, isFalse);
  });

  test('deleting a step is a tombstone and restore brings it back', () async {
    final s = await add('temporary');

    await steps.softDelete(s.id);
    expect(await steps.watchFor(task.id).first, isEmpty);
    expect(await db.select(db.subtasks).get(), hasLength(1));

    await steps.restore(s.id);
    expect(await steps.watchFor(task.id).first, hasLength(1));
  });

  test('steps belong to their task only', () async {
    await add('mine');
    expect(await steps.watchFor('some-other-task').first, isEmpty);
  });

  test('every write stamps the client id', () async {
    final s = await add('stamped');
    await steps.rename(s.id, 'renamed');

    final row = (await steps.watchFor(task.id).first).single;
    expect(row.title, 'renamed');
    expect(row.clientId, isNotNull);
  });
}
