import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../db/tables.dart';
import '../order_key.dart';

/// Reads and writes tasks.
///
/// Every method here touches only the local database and returns promptly. Nothing in
/// this class may ever await the network — when sync arrives in phase 4 it observes the
/// outbox, it does not sit in the write path.
class TaskRepository {
  TaskRepository(this._db, {required this.clientId});

  final AppDatabase _db;

  /// Stable per-device identity. Tiebreaks equal order keys, and becomes the HLC's node
  /// id in phase 4.
  final String clientId;

  static const _uuid = Uuid();

  // --- reads ---

  /// Live tasks in a list, in order. Tombstones excluded.
  ///
  /// Ordered by `(orderKey, clientId)` — the tiebreak matters because two offline
  /// devices can generate the same key between the same neighbours.
  Stream<List<Task>> watchList(String listId) {
    final q = _db.select(_db.tasks)
      ..where((t) => t.listId.equals(listId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.orderKey),
        (t) => OrderingTerm(expression: t.clientId),
      ]);
    return q.watch();
  }

  /// Every live task in the workspace, across all lists. Feeds the smart views and the
  /// Today dashboard.
  Stream<List<Task>> watchAll(String workspaceId) {
    final q = _db.select(_db.tasks)
      ..where((t) => t.workspaceId.equals(workspaceId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.orderKey),
        (t) => OrderingTerm(expression: t.clientId),
      ]);
    return q.watch();
  }

  Stream<Task?> watchTask(String id) {
    final q = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    return q.watchSingleOrNull();
  }

  /// Case-insensitive substring match over title and notes.
  Stream<List<Task>> search(String query) {
    final term = '%${query.trim().toLowerCase()}%';
    final q = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            (t.title.lower().like(term) | t.notesMd.lower().like(term)),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.orderKey),
        (t) => OrderingTerm(expression: t.clientId),
      ]);
    return q.watch();
  }

  // --- writes ---

  /// Appends a task to the end of [listId].
  Future<Task> create({
    required String listId,
    required String workspaceId,
    required String title,
    DateTime? dueAt,
    String? dueDate,
    int priority = 0,
    int? estimateMin,
  }) async {
    final last = await _lastKeyIn(listId);
    final row = TasksCompanion.insert(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      listId: listId,
      title: title,
      orderKey: last == null ? OrderKey.first : OrderKey.after(last),
      clientId: Value(clientId),
      dueAt: Value(dueAt),
      dueDate: Value(dueDate),
      priority: Value(priority),
      estimateMin: Value(estimateMin),
    );
    return _db.into(_db.tasks).insertReturning(row);
  }

  Future<void> rename(String id, String title) => _write(
    id,
    TasksCompanion(title: Value(title)),
  );

  Future<void> setPriority(String id, int priority) => _write(
    id,
    TasksCompanion(priority: Value(priority)),
  );

  Future<void> setDue(String id, {DateTime? dueAt, String? dueDate}) => _write(
    id,
    TasksCompanion(dueAt: Value(dueAt), dueDate: Value(dueDate)),
  );

  Future<void> setNotes(String id, String? notesMd) => _write(
    id,
    TasksCompanion(notesMd: Value(notesMd)),
  );

  Future<void> setEstimate(String id, int? minutes) => _write(
    id,
    TasksCompanion(estimateMin: Value(minutes)),
  );

  /// Completing and uncompleting are the same operation in both directions, so undo is
  /// just calling it again with the opposite value.
  Future<void> setDone(String id, {required bool done}) => _write(
    id,
    TasksCompanion(
      status: Value(done ? TaskStatus.done : TaskStatus.open),
      completedAt: Value(done ? DateTime.now() : null),
    ),
  );

  /// Soft delete. The row stays so the tombstone can sync; [restore] is the undo.
  Future<void> softDelete(String id) => _write(
    id,
    TasksCompanion(deletedAt: Value(DateTime.now())),
  );

  Future<void> restore(String id) => _write(
    id,
    const TasksCompanion(deletedAt: Value(null)),
  );

  /// Moves [id] to sit between two neighbours. Pass null for either end.
  ///
  /// Writes exactly one row — that is the entire point of fractional indexing.
  Future<void> moveBetween(String id, {String? afterId, String? beforeId}) async {
    final lower = afterId == null ? null : (await _taskById(afterId))?.orderKey;
    final upper = beforeId == null ? null : (await _taskById(beforeId))?.orderKey;
    await _write(id, TasksCompanion(orderKey: Value(OrderKey.between(lower, upper))));
  }

  /// Moves a task into another section, optionally between two neighbours there.
  ///
  /// Still one row: the section change and the new order key are the same write. A board
  /// drag across columns is not a delete-and-recreate, which matters because recreating
  /// would lose the task's identity, its steps and its history.
  Future<void> moveToSection(
    String id,
    String sectionId, {
    String? afterId,
    String? beforeId,
  }) async {
    final lower = afterId == null ? null : (await _taskById(afterId))?.orderKey;
    final upper = beforeId == null ? null : (await _taskById(beforeId))?.orderKey;

    // Dropping onto an empty column, or below everything in it.
    final String key;
    if (lower == null && upper == null) {
      final last = await _lastKeyIn(sectionId);
      key = last == null ? OrderKey.first : OrderKey.after(last);
    } else {
      key = OrderKey.between(lower, upper);
    }

    await _write(
      id,
      TasksCompanion(listId: Value(sectionId), orderKey: Value(key)),
    );
  }

  // --- internals ---

  /// Every write stamps [clientId] and bumps [updatedAt], so no caller can forget.
  Future<void> _write(String id, TasksCompanion patch) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      patch.copyWith(
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Task?> _taskById(String id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String?> _lastKeyIn(String listId) async {
    final q = _db.select(_db.tasks)
      ..where((t) => t.listId.equals(listId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.orderKey, mode: OrderingMode.desc),
      ])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row?.orderKey;
  }
}
