import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../db/tables.dart';
import '../order_key.dart';

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

/// Projects, their sections, their custom fields and their saved views.
///
/// "Section" is what a list is called in the UI — the same row is a section in list view
/// and a column in board view, which is why there is one table rather than two.
class ProjectRepository {
  ProjectRepository(this._db, {required this.clientId});

  final AppDatabase _db;
  final String clientId;

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
  }) async {
    final last = await _lastProjectKey(workspaceId);
    final boardId = _uuid.v4();

    return _db.transaction(() async {
      final project = await _db
          .into(_db.boards)
          .insertReturning(
            BoardsCompanion.insert(
              id: boardId,
              workspaceId: workspaceId,
              name: name,
              purpose: Value(purpose),
              icon: Value(icon),
              colour: Value(colour),
              orderKey: last == null ? OrderKey.first : OrderKey.after(last),
              viewDefault: const Value(BoardView.board),
              clientId: Value(clientId),
            ),
          );

      var key = OrderKey.first;
      for (final (i, section) in sections.indexed) {
        await _db.into(_db.lists).insert(
          ListsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: boardId,
            name: section,
            orderKey: key,
            // The last section is treated as the done column by convention.
            isDoneColumn: Value(i == sections.length - 1),
            clientId: Value(clientId),
          ),
        );
        key = OrderKey.after(key);
      }

      var fieldKey = OrderKey.first;
      for (final field in fields) {
        await _db.into(_db.fieldDefs).insert(
          FieldDefsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: boardId,
            name: field.name,
            type: field.type,
            optionsJson: Value(FieldOption.encode(field.options)),
            orderKey: fieldKey,
            showInline: Value(field.showInline),
            clientId: Value(clientId),
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
  }) => _writeBoard(
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
  Future<void> archiveProject(String id) =>
      _writeBoard(id, const BoardsCompanion(archived: Value(true)));

  Future<void> unarchiveProject(String id) =>
      _writeBoard(id, const BoardsCompanion(archived: Value(false)));

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

    return _db
        .into(_db.lists)
        .insertReturning(
          ListsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: boardId,
            name: name,
            orderKey: last == null
                ? OrderKey.first
                : OrderKey.after(last.orderKey),
            clientId: Value(clientId),
          ),
        );
  }

  Future<void> renameSection(String id, String name) async {
    await (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(
      ListsCompanion(
        name: Value(name),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setSectionWipLimit(String id, int? limit) async {
    await (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(
      ListsCompanion(
        wipLimit: Value(limit),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Why deleting a section is not just a tombstone.
  ///
  /// Tasks point at a section. Removing one without moving its tasks leaves them
  /// pointing at a row nothing renders — they vanish from every view while still
  /// counting in totals, which is the worst kind of bug: invisible, and it makes the
  /// numbers lie.
  ///
  /// Returns false when this is the only section left, since its tasks would have
  /// nowhere to go.
  Future<bool> deleteSection(String id) async {
    final section =
        await (_db.select(_db.lists)..where((l) => l.id.equals(id)))
            .getSingleOrNull();
    if (section == null) return false;

    final siblings =
        await (_db.select(_db.lists)..where(
              (l) =>
                  l.boardId.equals(section.boardId) &
                  l.deletedAt.isNull() &
                  l.id.equals(id).not(),
            ))
            .get();
    if (siblings.isEmpty) return false;

    final now = DateTime.now();
    await _db.transaction(() async {
      // Tasks move rather than disappear.
      await (_db.update(_db.tasks)..where((t) => t.listId.equals(id))).write(
        TasksCompanion(
          listId: Value(siblings.first.id),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
      );
      await (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(
        ListsCompanion(
          deletedAt: Value(now),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
      );
    });
    return true;
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
  Future<void> deleteProject(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      final sections =
          await (_db.select(_db.lists)..where((l) => l.boardId.equals(id)))
              .get();
      final sectionIds = sections.map((s) => s.id).toList();

      if (sectionIds.isNotEmpty) {
        await (_db.update(_db.tasks)..where((t) => t.listId.isIn(sectionIds)))
            .write(
              TasksCompanion(
                deletedAt: Value(now),
                clientId: Value(clientId),
                updatedAt: Value(now),
              ),
            );
      }

      await (_db.update(_db.lists)..where((l) => l.boardId.equals(id))).write(
        ListsCompanion(
          deletedAt: Value(now),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
      );
      await (_db.update(_db.fieldDefs)..where((f) => f.boardId.equals(id)))
          .write(
            FieldDefsCompanion(
              deletedAt: Value(now),
              clientId: Value(clientId),
              updatedAt: Value(now),
            ),
          );
      await (_db.update(_db.boards)..where((b) => b.id.equals(id))).write(
        BoardsCompanion(
          deletedAt: Value(now),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> restoreProject(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      final sections =
          await (_db.select(_db.lists)..where((l) => l.boardId.equals(id)))
              .get();
      final sectionIds = sections.map((s) => s.id).toList();

      if (sectionIds.isNotEmpty) {
        await (_db.update(_db.tasks)..where((t) => t.listId.isIn(sectionIds)))
            .write(
              TasksCompanion(
                deletedAt: const Value(null),
                clientId: Value(clientId),
                updatedAt: Value(now),
              ),
            );
      }
      await (_db.update(_db.lists)..where((l) => l.boardId.equals(id))).write(
        ListsCompanion(
          deletedAt: const Value(null),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
      );
      await (_db.update(_db.fieldDefs)..where((f) => f.boardId.equals(id)))
          .write(
            FieldDefsCompanion(
              deletedAt: const Value(null),
              clientId: Value(clientId),
              updatedAt: Value(now),
            ),
          );
      await (_db.update(_db.boards)..where((b) => b.id.equals(id))).write(
        BoardsCompanion(
          deletedAt: const Value(null),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
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

    return _db
        .into(_db.fieldDefs)
        .insertReturning(
          FieldDefsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: boardId,
            name: name,
            type: type,
            optionsJson: Value(FieldOption.encode(options)),
            orderKey: last == null
                ? OrderKey.first
                : OrderKey.after(last.orderKey),
            showInline: Value(showInline),
            clientId: Value(clientId),
          ),
        );
  }

  Future<void> restoreField(String id) async {
    await (_db.update(_db.fieldDefs)..where((f) => f.id.equals(id))).write(
      FieldDefsCompanion(
        deletedAt: const Value(null),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restoreSection(String id) async {
    await (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(
      ListsCompanion(
        deletedAt: const Value(null),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteField(String id) async {
    await (_db.update(_db.fieldDefs)..where((f) => f.id.equals(id))).write(
      FieldDefsCompanion(
        deletedAt: Value(DateTime.now()),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

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

  /// Upsert by (task, field) — there is only ever one value per pair.
  Future<void> setFieldValue({
    required String workspaceId,
    required String taskId,
    required String fieldId,
    required String? value,
  }) async {
    final existing =
        await (_db.select(_db.fieldValues)..where(
              (v) => v.taskId.equals(taskId) & v.fieldId.equals(fieldId),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.fieldValues).insert(
        FieldValuesCompanion.insert(
          id: _uuid.v4(),
          workspaceId: workspaceId,
          taskId: taskId,
          fieldId: fieldId,
          value: Value(value),
          clientId: Value(clientId),
        ),
      );
      return;
    }

    await (_db.update(_db.fieldValues)..where((v) => v.id.equals(existing.id)))
        .write(
          FieldValuesCompanion(
            value: Value(value),
            deletedAt: const Value(null),
            clientId: Value(clientId),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  // --- internals ---

  Future<void> _writeBoard(String id, BoardsCompanion patch) async {
    await (_db.update(_db.boards)..where((b) => b.id.equals(id))).write(
      patch.copyWith(
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
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
