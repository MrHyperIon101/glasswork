import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/repository/label_repository.dart';
import 'package:glasswork/data/repository/project_repository.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';

import 'device.dart';
import 'fake_server.dart';

/// The repositories, end to end across two devices.
///
/// The engine tests prove that queued changes travel. These prove the repositories queue
/// the right ones: that a cascade arrives on the other device whole, and that rows unique
/// per key stay unique when two devices create them offline.
void main() {
  const day = 86400000;
  var nowMs = 0;

  late FakeServer server;
  late Device laptop;
  late Device phone;

  setUp(() {
    nowMs = 1757203200000; // 2026-09-06
    server = FakeServer(
      now: () => DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
    );
    laptop = Device('laptop', server, now: () => nowMs);
    phone = Device('phone', server, now: () => nowMs);
  });

  tearDown(() async {
    await laptop.close();
    await phone.close();
  });

  /// A project with a field and a task, made on the laptop and synced to the phone.
  Future<({String workspaceId, String projectId, String taskId, String fieldId})>
  shared() async {
    final workspace = await WorkspaceRepository(laptop.writer).ensureSeeded();
    final projects = ProjectRepository(laptop.writer);
    final project = await projects.createProject(
      workspaceId: workspace.id,
      name: 'Sem V',
      fields: const [FieldDefSpec(name: 'Stage', type: FieldType.text)],
    );
    final section = (await projects.watchSections(project.id).first).first;
    final field = (await projects.watchFields(project.id).first).single;
    final task = await TaskRepository(laptop.writer).create(
      listId: section.id,
      workspaceId: workspace.id,
      title: 'DBMS lab',
    );

    await laptop.sync();
    await phone.sync();
    return (
      workspaceId: workspace.id,
      projectId: project.id,
      taskId: task.id,
      fieldId: field.id,
    );
  }

  test('a project deleted on one device is gone from the other, tasks and all', () async {
    final s = await shared();
    final onPhone = ProjectRepository(phone.writer);
    expect(
      (await onPhone.watchProjects(s.workspaceId).first).map((p) => p.name),
      ['Personal', 'Sem V'],
    );

    nowMs += day;
    await ProjectRepository(laptop.writer).deleteProject(s.projectId);
    await laptop.sync();
    await phone.sync();

    expect(
      (await onPhone.watchProjects(s.workspaceId).first).map((p) => p.name),
      ['Personal'],
    );
    expect(await onPhone.watchSections(s.projectId).first, isEmpty);
    expect(await onPhone.watchFields(s.projectId).first, isEmpty);
    expect(await TaskRepository(phone.writer).watchAll(s.workspaceId).first, isEmpty);
  });

  test('undo on one device brings the project back on the other', () async {
    final s = await shared();
    final onLaptop = ProjectRepository(laptop.writer);

    nowMs += day;
    await onLaptop.deleteProject(s.projectId);
    await laptop.sync();
    await phone.sync();

    nowMs += 3000;
    await onLaptop.restoreProject(s.projectId);
    await laptop.sync();
    await phone.sync();

    expect(
      (await TaskRepository(phone.writer).watchAll(s.workspaceId).first).map(
        (t) => t.title,
      ),
      ['DBMS lab'],
    );
    expect(
      await ProjectRepository(phone.writer).watchSections(s.projectId).first,
      hasLength(3),
    );
  });

  test('a label both devices attach while offline is still one attachment', () async {
    final s = await shared();
    final label = await LabelRepository(
      laptop.writer,
    ).ensure(workspaceId: s.workspaceId, name: 'uni');
    await laptop.sync();
    await phone.sync();

    for (final device in [laptop, phone]) {
      nowMs += day;
      await LabelRepository(device.writer).attach(
        workspaceId: s.workspaceId,
        taskId: s.taskId,
        labelId: label.id,
      );
    }

    await laptop.sync();
    await phone.sync();
    await laptop.sync();

    for (final device in [laptop, phone]) {
      expect(
        await device.db.select(device.db.taskLabels).get(),
        hasLength(1),
        reason: device.name,
      );
      expect(
        await LabelRepository(device.writer).watchAssignments(s.workspaceId).first,
        {
          s.taskId: {label.id},
        },
        reason: device.name,
      );
    }
  });

  test('a field both devices set while offline keeps the later value, in one row', () async {
    final s = await shared();

    for (final (device, value) in [
      (laptop, 'Draft (Monday, laptop)'),
      (phone, 'Review (Tuesday, phone)'),
    ]) {
      nowMs += day;
      await ProjectRepository(device.writer).setFieldValue(
        workspaceId: s.workspaceId,
        taskId: s.taskId,
        fieldId: s.fieldId,
        value: value,
      );
    }

    await laptop.sync();
    await phone.sync();
    await laptop.sync();

    for (final device in [laptop, phone]) {
      final rows = await device.db.select(device.db.fieldValues).get();
      expect(rows, hasLength(1), reason: device.name);
      expect(rows.single.value, 'Review (Tuesday, phone)', reason: device.name);
    }
  });
}
