import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../db/tables.dart';
import '../natural_id.dart';
import '../order_key.dart';
import '../project_filter.dart';

/// One choice in a select field.
class FieldOption {
  const FieldOption({required this.label, this.colour});

  final String label;

  /// ARGB int, or null to fall back to the neutral tint.
  final int? colour;

  Map<String, Object?> toJson() => {'label': label, 'colour': colour};

  static List<FieldOption> decode(String json) {
    final raw = jsonDecode(json);
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map && e['label'] is String)
          FieldOption(label: e['label'] as String, colour: e['colour'] as int?),
    ];
  }

  static String encode(List<FieldOption> options) =>
      jsonEncode([for (final o in options) o.toJson()]);
}

/// What deleting a section did, so undo can reverse all of it.
class SectionDeletion {
  const SectionDeletion({
    required this.sectionId,
    required this.movedTo,
    required this.taskIds,
  });

  final String sectionId;

  /// The section its tasks were moved into.
  final String movedTo;

  final List<String> taskIds;
}

/// Projects, their sections, their custom fields and their saved views.
///
/// "Section" is what a list is called in the UI — the same row is a section in list view
/// and a column in board view, which is why there is one table rather than two.
class ProjectRepository {
  ProjectRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  // --- projects ---

  Stream<List<Board>> watchProjects(String workspaceId) =>
      (_db.select(_db.boards)
            ..where(
              (b) =>
                  b.workspaceId.equals(workspaceId) &
                  b.deletedAt.isNull() &
                  b.archived.equals(false),
            )
            ..orderBy([
              (b) => OrderingTerm(expression: b.orderKey),
              (b) => OrderingTerm(expression: b.clientId),
            ]))
          .watch();

  Stream<Board?> watchProject(String id) =>
      (_db.select(_db.boards)..where((b) => b.id.equals(id)))
          .watchSingleOrNull();

  /// Creates a project with its sections in one transaction, so a half-built project
  /// can never appear in the sidebar.
  Future<Board> createProject({
    required String workspaceId,
    required String name,
    String? purpose,
    String? icon,
    int? colour,
    List<String> sections = const ['To do', 'In progress', 'Done'],
    List<FieldDefSpec> fields = const [],
  }) {
    return _db.transaction(() async {
      final last = await _lastProjectKey(workspaceId);
      final project = await _writer.insert(
        _db.boards,
        BoardsCompanion.insert(
          id: _uuid.v4(),
          workspaceId: workspaceId,
          name: name,
          purpose: Value(purpose),
          icon: Value(icon),
          colour: Value(colour),
          orderKey: last == null ? OrderKey.first : OrderKey.after(last),
          viewDefault: const Value(BoardView.board),
        ),
      );

      var key = OrderKey.first;
      for (final (i, section) in sections.indexed) {
        await _writer.insert(
          _db.lists,
          ListsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: project.id,
            name: section,
            orderKey: key,
            // The last section is treated as the done column by convention.
            isDoneColumn: Value(i == sections.length - 1),
          ),
        );
        key = OrderKey.after(key);
      }

      var fieldKey = OrderKey.first;
      for (final field in fields) {
        await _writer.insert(
          _db.fieldDefs,
          FieldDefsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: project.id,
            name: field.name,
            type: field.type,
            optionsJson: Value(FieldOption.encode(field.options)),
            orderKey: fieldKey,
            showInline: Value(field.showInline),
          ),
        );
        fieldKey = OrderKey.after(fieldKey);
      }

      return project;
    });
  }

  Future<void> updateProject(
    String id, {
    String? name,
    String? purpose,
    String? icon,
    int? colour,
    BoardView? viewDefault,
  }) => _writer.update(
    _db.boards,
    id,
    BoardsCompanion(
      name: Value.absentIfNull(name),
      purpose: Value.absentIfNull(purpose),
      icon: Value.absentIfNull(icon),
      colour: Value.absentIfNull(colour),
      viewDefault: Value.absentIfNull(viewDefault),
    ),
  );

  /// Archiving rather than deleting: a finished project is history worth keeping, and
  /// its tasks are the only record of what the term actually involved.
  Future<void> archiveProject(String id) => _writer.update(
    _db.boards,
    id,
    const BoardsCompanion(archived: Value(true)),
  );

  Future<void> unarchiveProject(String id) => _writer.update(
    _db.boards,
    id,
    const BoardsCompanion(archived: Value(false)),
  );

  // --- sections ---

  Stream<List<BoardList>> watchSections(String boardId) =>
      (_db.select(_db.lists)
            ..where((l) => l.boardId.equals(boardId) & l.deletedAt.isNull())
            ..orderBy([
              (l) => OrderingTerm(expression: l.orderKey),
              (l) => OrderingTerm(expression: l.clientId),
            ]))
          .watch();

  Future<BoardList> addSection({
    required String workspaceId,
    required String boardId,
    required String name,
  }) async {
    final last =
        await (_db.select(_db.lists)
              ..where((l) => l.boardId.equals(boardId) & l.deletedAt.isNull())
              ..orderBy([
                (l) => OrderingTerm(
                  expression: l.orderKey,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return _writer.insert(
      _db.lists,
      ListsCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        boardId: boardId,
        name: name,
        orderKey: last == null ? OrderKey.first : OrderKey.after(last.orderKey),
      ),
    );
  }

  Future<void> renameSection(String id, String name) =>
      _writer.update(_db.lists, id, ListsCompanion(name: Value(name)));

  Future<void> setSectionWipLimit(String id, int? limit) =>
      _writer.update(_db.lists, id, ListsCompanion(wipLimit: Value(limit)));

  /// Deletes a section, moving its tasks into the first section that remains.
  ///
  /// Why not just a tombstone: tasks point at a section. Removing one without moving its
  /// tasks leaves them pointing at a row nothing renders — they vanish from every view
  /// while still counting in totals, which is the worst kind of bug: invisible, and it
  /// makes the numbers lie.
  ///
  /// Returns what it did, for undo — or null when this is the only section left, since
  /// its tasks would have nowhere to go.
  Future<SectionDeletion?> deleteSection(String id) {
    return _db.transaction(() async {
      final section =
          await (_db.select(_db.lists)..where((l) => l.id.equals(id)))
              .getSingleOrNull();
      if (section == null) return null;

      // First as the section list shows it, which is what the confirmation promises.
      final remaining =
          await (_db.select(_db.lists)
                ..where(
                  (l) =>
                      l.boardId.equals(section.boardId) &
                      l.deletedAt.isNull() &
                      l.id.equals(id).not(),
                )
                ..orderBy([
                  (l) => OrderingTerm(expression: l.orderKey),
                  (l) => OrderingTerm(expression: l.clientId),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (remaining == null) return null;

      // Tasks move rather than disappear — deleted ones too, so restoring one later puts
      // it somewhere it can be seen.
      final moved = await _writer.updateWhere(
        _db.tasks,
        (t) => t.listId.equals(id),
        TasksCompanion(listId: Value(remaining.id)),
      );
      await _writer.update(
        _db.lists,
        id,
        ListsCompanion(deletedAt: Value(DateTime.now())),
      );

      return SectionDeletion(
        sectionId: id,
        movedTo: remaining.id,
        taskIds: moved,
      );
    });
  }

  /// Undoes [deleteSection]: brings the section back, and its tasks with it.
  ///
  /// Only tasks still where the delete put them go back. One dragged somewhere else in the
  /// meantime was placed deliberately, and undo does not overrule that.
  Future<void> restoreSection(SectionDeletion deletion) {
    return _db.transaction(() async {
      await _writer.update(
        _db.lists,
        deletion.sectionId,
        const ListsCompanion(deletedAt: Value(null)),
      );
      if (deletion.taskIds.isEmpty) return;

      await _writer.updateWhere(
        _db.tasks,
        (t) => t.id.isIn(deletion.taskIds) & t.listId.equals(deletion.movedTo),
        TasksCompanion(listId: Value(deletion.sectionId)),
      );
    });
  }

  /// How many tasks a section holds, for the confirmation copy.
  Future<int> taskCountIn(String sectionId) async {
    final rows =
        await (_db.select(_db.tasks)..where(
              (t) => t.listId.equals(sectionId) & t.deletedAt.isNull(),
            ))
            .get();
    return rows.length;
  }

  /// Soft-deletes a project along with its sections, fields and tasks.
  ///
  /// Everything is tombstoned rather than removed, so [restoreProject] can put the
  /// whole thing back and sync has something to replicate.
  ///
  /// Only live rows, all under one deletion time. That time is how restore tells what went
  /// with the project from what had already been deleted on its own — so a task deleted
  /// last week stays deleted when the project comes back.
  Future<void> deleteProject(String id) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final sectionIds = await _sectionIdsOf(id);

      if (sectionIds.isNotEmpty) {
        await _writer.updateWhere(
          _db.tasks,
          (t) => t.listId.isIn(sectionIds) & t.deletedAt.isNull(),
          TasksCompanion(deletedAt: Value(now)),
        );
      }
      await _writer.updateWhere(
        _db.lists,
        (l) => l.boardId.equals(id) & l.deletedAt.isNull(),
        ListsCompanion(deletedAt: Value(now)),
      );
      await _writer.updateWhere(
        _db.fieldDefs,
        (f) => f.boardId.equals(id) & f.deletedAt.isNull(),
        FieldDefsCompanion(deletedAt: Value(now)),
      );
      await _writer.update(
        _db.boards,
        id,
        BoardsCompanion(deletedAt: Value(now)),
      );
    });
  }

  /// Undoes [deleteProject]: restores the project and everything carrying its deletion
  /// time.
  Future<void> restoreProject(String id) {
    return _db.transaction(() async {
      final project =
          await (_db.select(_db.boards)..where((b) => b.id.equals(id)))
              .getSingleOrNull();
      final deletedAt = project?.deletedAt;
      if (deletedAt == null) return;

      final sectionIds = await _sectionIdsOf(id);
      if (sectionIds.isNotEmpty) {
        await _writer.updateWhere(
          _db.tasks,
          (t) => t.listId.isIn(sectionIds) & t.deletedAt.equals(deletedAt),
          const TasksCompanion(deletedAt: Value(null)),
        );
      }
      await _writer.updateWhere(
        _db.lists,
        (l) => l.boardId.equals(id) & l.deletedAt.equals(deletedAt),
        const ListsCompanion(deletedAt: Value(null)),
      );
      await _writer.updateWhere(
        _db.fieldDefs,
        (f) => f.boardId.equals(id) & f.deletedAt.equals(deletedAt),
        const FieldDefsCompanion(deletedAt: Value(null)),
      );
      await _writer.update(
        _db.boards,
        id,
        const BoardsCompanion(deletedAt: Value(null)),
      );
    });
  }

  /// How many live tasks a project holds, for the confirmation copy.
  Future<int> projectTaskCount(String projectId) async {
    final sections =
        await (_db.select(_db.lists)..where(
              (l) => l.boardId.equals(projectId) & l.deletedAt.isNull(),
            ))
            .get();
    if (sections.isEmpty) return 0;

    final rows =
        await (_db.select(_db.tasks)..where(
              (t) =>
                  t.listId.isIn(sections.map((s) => s.id).toList()) &
                  t.deletedAt.isNull(),
            ))
            .get();
    return rows.length;
  }

  // --- saved views ---

  Stream<List<ProjectView>> watchViews(String boardId) =>
      (_db.select(_db.projectViews)
            ..where((v) => v.boardId.equals(boardId) & v.deletedAt.isNull())
            ..orderBy([(v) => OrderingTerm(expression: v.orderKey)]))
          .watch();

  /// Saves the current way of looking at a project under a name.
  Future<ProjectView> addView({
    required String workspaceId,
    required String boardId,
    required String name,
    required ViewKind kind,
    required ProjectFilter filter,
  }) async {
    final last =
        await (_db.select(_db.projectViews)
              ..where((v) => v.boardId.equals(boardId) & v.deletedAt.isNull())
              ..orderBy([
                (v) => OrderingTerm(
                  expression: v.orderKey,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return _writer.insert(
      _db.projectViews,
      ProjectViewsCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        boardId: boardId,
        name: name,
        kind: kind,
        filterJson: Value(filter.encode()),
        orderKey: last == null ? OrderKey.first : OrderKey.after(last.orderKey),
      ),
    );
  }

  Future<void> updateView(
    String id, {
    String? name,
    ViewKind? kind,
    ProjectFilter? filter,
  }) => _writer.update(
    _db.projectViews,
    id,
    ProjectViewsCompanion(
      name: Value.absentIfNull(name),
      kind: Value.absentIfNull(kind),
      filterJson: filter == null ? const Value.absent() : Value(filter.encode()),
    ),
  );

  Future<void> deleteView(String id) => _writer.update(
    _db.projectViews,
    id,
    ProjectViewsCompanion(deletedAt: Value(DateTime.now())),
  );

  Future<void> restoreView(String id) => _writer.update(
    _db.projectViews,
    id,
    const ProjectViewsCompanion(deletedAt: Value(null)),
  );

  // --- custom fields ---

  Stream<List<FieldDef>> watchFields(String boardId) =>
      (_db.select(_db.fieldDefs)
            ..where((f) => f.boardId.equals(boardId) & f.deletedAt.isNull())
            ..orderBy([(f) => OrderingTerm(expression: f.orderKey)]))
          .watch();

  Future<FieldDef> addField({
    required String workspaceId,
    required String boardId,
    required String name,
    required FieldType type,
    List<FieldOption> options = const [],
    bool showInline = true,
  }) async {
    final last =
        await (_db.select(_db.fieldDefs)
              ..where((f) => f.boardId.equals(boardId) & f.deletedAt.isNull())
              ..orderBy([
                (f) => OrderingTerm(
                  expression: f.orderKey,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return _writer.insert(
      _db.fieldDefs,
      FieldDefsCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        boardId: boardId,
        name: name,
        type: type,
        optionsJson: Value(FieldOption.encode(options)),
        orderKey: last == null ? OrderKey.first : OrderKey.after(last.orderKey),
        showInline: Value(showInline),
      ),
    );
  }

  Future<void> restoreField(String id) => _writer.update(
    _db.fieldDefs,
    id,
    const FieldDefsCompanion(deletedAt: Value(null)),
  );

  Future<void> deleteField(String id) => _writer.update(
    _db.fieldDefs,
    id,
    FieldDefsCompanion(deletedAt: Value(DateTime.now())),
  );

  /// Every field value for a project's tasks, keyed by task then field.
  Stream<Map<String, Map<String, String?>>> watchFieldValues(String boardId) {
    final query = _db.select(_db.fieldValues).join([
      innerJoin(
        _db.fieldDefs,
        _db.fieldDefs.id.equalsExp(_db.fieldValues.fieldId),
      ),
    ])..where(_db.fieldDefs.boardId.equals(boardId) & _db.fieldValues.deletedAt.isNull());

    return query.watch().map((rows) {
      final out = <String, Map<String, String?>>{};
      for (final row in rows) {
        final value = row.readTable(_db.fieldValues);
        (out[value.taskId] ??= {})[value.fieldId] = value.value;
      }
      return out;
    });
  }

  /// One value per task and field.
  ///
  /// The row's id derives from the pair, so two devices setting the same field offline
  /// write the same row, and the merge keeps whichever value was set later.
  Future<void> setFieldValue({
    required String workspaceId,
    required String taskId,
    required String fieldId,
    required String? value,
  }) {
    return _db.transaction(() async {
      final updated = await _writer.updateWhere(
        _db.fieldValues,
        (v) => v.taskId.equals(taskId) & v.fieldId.equals(fieldId),
        FieldValuesCompanion(
          value: Value(value),
          deletedAt: const Value(null),
        ),
      );
      if (updated.isNotEmpty) return;

      await _writer.insert(
        _db.fieldValues,
        FieldValuesCompanion.insert(
          id: NaturalId.fieldValue(taskId, fieldId),
          workspaceId: workspaceId,
          taskId: taskId,
          fieldId: fieldId,
          value: Value(value),
        ),
      );
    });
  }

  // --- internals ---

  /// Every section a project has had, deleted ones included.
  Future<List<String>> _sectionIdsOf(String projectId) async {
    final sections =
        await (_db.select(_db.lists)
              ..where((l) => l.boardId.equals(projectId)))
            .get();
    return [for (final s in sections) s.id];
  }

  Future<String?> _lastProjectKey(String workspaceId) async {
    final row =
        await (_db.select(_db.boards)
              ..where((b) => b.workspaceId.equals(workspaceId))
              ..orderBy([
                (b) => OrderingTerm(
                  expression: b.orderKey,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.orderKey;
  }
}

/// A field to create alongside a new project. Used by the role templates.
class FieldDefSpec {
  const FieldDefSpec({
    required this.name,
    required this.type,
    this.options = const [],
    this.showInline = true,
  });

  final String name;
  final FieldType type;
  final List<FieldOption> options;
  final bool showInline;
}
