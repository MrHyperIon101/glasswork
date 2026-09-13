import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/natural_id.dart';
import 'package:glasswork/data/repository/label_repository.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late SyncWriter writer;
  late LabelRepository labels;
  late String workspaceId;
  late Task task;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    writer = SyncWriter(db, clientId: 'device-a');
    final workspaces = WorkspaceRepository(writer);
    workspaceId = (await workspaces.ensureSeeded()).id;
    final listId = (await workspaces.watchLists(workspaceId).first).first.id;
    task = await TaskRepository(
      writer,
    ).create(listId: listId, workspaceId: workspaceId, title: 'DBMS lab');
    labels = LabelRepository(writer);
  });

  tearDown(() => db.close());

  Future<List<TaskLabel>> pairs() => db.select(db.taskLabels).get();

  Future<void> attach(Label label) => labels.attach(
    workspaceId: workspaceId,
    taskId: task.id,
    labelId: label.id,
  );

  test('attaching twice keeps one row, under an id derived from the pair', () async {
    final uni = await labels.ensure(workspaceId: workspaceId, name: 'uni');

    await attach(uni);
    await attach(uni);

    expect(await pairs(), hasLength(1));
    expect((await pairs()).single.id, NaturalId.taskLabel(task.id, uni.id));
  });

  test('detaching and attaching again reuses the same row', () async {
    final uni = await labels.ensure(workspaceId: workspaceId, name: 'uni');
    await attach(uni);

    await labels.detach(taskId: task.id, labelId: uni.id);
    expect((await labels.watchAssignments(workspaceId).first)[task.id], isNull);

    await attach(uni);
    expect(await pairs(), hasLength(1));
    expect((await labels.watchAssignments(workspaceId).first)[task.id], {uni.id});
  });

  test('finding a label by name tolerates the duplicate two offline devices make', () async {
    // Each device created #uni before either had synced, so both rows now exist on both.
    for (final (id, created) in [
      ('newer', DateTime(2026, 9, 2)),
      ('older', DateTime(2026, 9, 1)),
    ]) {
      await writer.insert(
        db.labels,
        LabelsCompanion.insert(
          id: id,
          workspaceId: workspaceId,
          name: 'uni',
          createdAt: Value(created),
        ),
      );
    }

    final found = await labels.ensure(workspaceId: workspaceId, name: 'UNI');

    expect(found.id, 'older', reason: 'the same choice on every device');
    expect(await db.select(db.labels).get(), hasLength(2), reason: 'found, not created');
  });
}
