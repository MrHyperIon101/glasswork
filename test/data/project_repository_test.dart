import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/natural_id.dart';
import 'package:glasswork/data/order_key.dart';
import 'package:glasswork/data/repository/project_repository.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late SyncWriter writer;
  late ProjectRepository projects;
  late TaskRepository tasks;
  late String workspaceId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    writer = SyncWriter(db, clientId: 'device-a');
    workspaceId = (await WorkspaceRepository(writer).ensureSeeded()).id;
    projects = ProjectRepository(writer);
    tasks = TaskRepository(writer);
  });

  tearDown(() => db.close());

  Future<Board> newProject({
    List<String> sections = const ['To do', 'In progress', 'Done'],
  }) => projects.createProject(
    workspaceId: workspaceId,
    name: 'Sem V',
    sections: sections,
    fields: const [FieldDefSpec(name: 'Stage', type: FieldType.select)],
  );

  Future<List<BoardList>> sectionsOf(Board project) =>
      projects.watchSections(project.id).first;

  Future<Task> addTask(BoardList section, String title) =>
      tasks.create(listId: section.id, workspaceId: workspaceId, title: title);

  Future<Task> reload(Task task) async => (await tasks.watchTask(task.id).first)!;

  /// Row id -> the fields queued for it.
  Future<Map<String, Set<String>>> queued() async => {
    for (final e in await db.select(db.outbox).get())
      e.rowId: SyncWriter.decodeFieldNames(e.changedFields),
  };

  group('deleting a project', () {
    test('queues every row it tombstones, and nothing else', () async {
      final project = await newProject();
      final sections = await sectionsOf(project);
      final field = (await projects.watchFields(project.id).first).single;
      final task = await addTask(sections.first, 'DBMS lab');
      await db.delete(db.outbox).go();

      await projects.deleteProject(project.id);

      final expected = [
        project.id,
        ...sections.map((s) => s.id),
        field.id,
        task.id,
      ];
      final dirty = await queued();
      expect(dirty.keys, unorderedEquals(expected));
      for (final id in expected) {
        expect(dirty[id], {'deleted_at'}, reason: id);
      }
    });

    test('undo brings back what went with it, and nothing deleted before', () async {
      final project = await newProject();
      final section = (await sectionsOf(project)).first;
      final kept = await addTask(section, 'DBMS lab');
      final gone = await addTask(section, 'Deleted last week');
      await writer.update(
        db.tasks,
        gone.id,
        TasksCompanion(deletedAt: Value(DateTime(2026, 9, 6))),
      );

      await projects.deleteProject(project.id);
      await projects.restoreProject(project.id);

      expect((await reload(kept)).deletedAt, isNull);
      expect(
        (await reload(gone)).deletedAt,
        isNotNull,
        reason: 'deleted on its own, earlier',
      );
      expect(await sectionsOf(project), hasLength(3));
      expect(await projects.watchFields(project.id).first, hasLength(1));
    });
  });

  group('deleting a section', () {
    test('moves its tasks to the first remaining section, as the confirmation says', () async {
      final project = await newProject();
      final first = (await sectionsOf(project)).first;
      // Made after the others but ordered before them, so first by position and first
      // by creation disagree.
      final front = await writer.insert(
        db.lists,
        ListsCompanion.insert(
          id: 'front',
          workspaceId: workspaceId,
          boardId: project.id,
          name: 'Front',
          orderKey: OrderKey.between(null, first.orderKey),
        ),
      );
      final task = await addTask(first, 'DBMS lab');
      await db.delete(db.outbox).go();

      final deletion = await projects.deleteSection(first.id);

      expect(deletion!.movedTo, front.id);
      expect((await reload(task)).listId, front.id);
      expect((await queued())[task.id], {'list_id'}, reason: 'the move syncs');
    });

    test('undo moves its tasks back', () async {
      final project = await newProject();
      final [first, second, _] = await sectionsOf(project);
      final task = await addTask(second, 'DBMS lab');

      final deletion = await projects.deleteSection(second.id);
      expect((await reload(task)).listId, first.id);

      await projects.restoreSection(deletion!);

      expect((await reload(task)).listId, second.id);
      expect(await sectionsOf(project), hasLength(3));
    });

    test('undo leaves a task that was moved again in the meantime where it is', () async {
      final project = await newProject();
      final [first, second, third] = await sectionsOf(project);
      final task = await addTask(second, 'DBMS lab');

      final deletion = await projects.deleteSection(second.id);
      expect(deletion!.movedTo, first.id);
      await tasks.moveToSection(task.id, third.id);

      await projects.restoreSection(deletion);

      expect((await reload(task)).listId, third.id);
    });

    test('the only section cannot be deleted, since its tasks would have nowhere to go', () async {
      final project = await newProject(sections: const ['Only']);
      final only = (await sectionsOf(project)).single;

      expect(await projects.deleteSection(only.id), isNull);
      expect(await sectionsOf(project), hasLength(1));
    });
  });

  test('a field holds one value per task, under an id derived from the pair', () async {
    final project = await newProject();
    final field = (await projects.watchFields(project.id).first).single;
    final task = await addTask((await sectionsOf(project)).first, 'DBMS lab');

    for (final value in ['Draft', 'Review']) {
      await projects.setFieldValue(
        workspaceId: workspaceId,
        taskId: task.id,
        fieldId: field.id,
        value: value,
      );
    }

    final rows = await db.select(db.fieldValues).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, NaturalId.fieldValue(task.id, field.id));
    expect(rows.single.value, 'Review');
  });
}
