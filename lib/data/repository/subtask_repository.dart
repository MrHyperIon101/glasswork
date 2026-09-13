import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../order_key.dart';

/// Steps within a task.
///
/// Same contract as [TaskRepository]: nothing here awaits the network, every write goes
/// through [SyncWriter], and deletion is a tombstone.
class SubtaskRepository {
  SubtaskRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  Stream<List<Subtask>> watchFor(String taskId) {
    final q = _db.select(_db.subtasks)
      ..where((s) => s.taskId.equals(taskId) & s.deletedAt.isNull())
      ..orderBy([
        (s) => OrderingTerm(expression: s.orderKey),
        (s) => OrderingTerm(expression: s.clientId),
      ]);
    return q.watch();
  }

  Future<Subtask> create({
    required String taskId,
    required String workspaceId,
    required String title,
  }) async {
    final last =
        await (_db.select(_db.subtasks)
              ..where((s) => s.taskId.equals(taskId) & s.deletedAt.isNull())
              ..orderBy([
                (s) => OrderingTerm(
                  expression: s.orderKey,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return _writer.insert(
      _db.subtasks,
      SubtasksCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        taskId: taskId,
        title: title,
        orderKey: last == null ? OrderKey.first : OrderKey.after(last.orderKey),
      ),
    );
  }

  Future<void> setDone(String id, {required bool done}) =>
      _write(id, SubtasksCompanion(done: Value(done)));

  Future<void> rename(String id, String title) =>
      _write(id, SubtasksCompanion(title: Value(title)));

  Future<void> softDelete(String id) =>
      _write(id, SubtasksCompanion(deletedAt: Value(DateTime.now())));

  Future<void> restore(String id) =>
      _write(id, const SubtasksCompanion(deletedAt: Value(null)));

  Future<void> _write(String id, SubtasksCompanion patch) =>
      _writer.update(_db.subtasks, id, patch);
}
