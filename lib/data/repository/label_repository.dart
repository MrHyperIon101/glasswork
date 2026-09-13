import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../natural_id.dart';

/// Labels, and which tasks carry them.
///
/// Labels are workspace-wide on purpose, unlike custom fields: `#urgent` means the same
/// thing in every project, and a label you have to recreate per project stops getting
/// used. Fields describe a project's vocabulary; labels cut across it.
class LabelRepository {
  LabelRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  Stream<List<Label>> watchAll(String workspaceId) =>
      (_db.select(_db.labels)
            ..where(
              (l) => l.workspaceId.equals(workspaceId) & l.deletedAt.isNull(),
            )
            ..orderBy([(l) => OrderingTerm(expression: l.name)]))
          .watch();

  /// task id -> label ids.
  Stream<Map<String, Set<String>>> watchAssignments(String workspaceId) {
    final q = _db.select(_db.taskLabels)
      ..where(
        (tl) => tl.workspaceId.equals(workspaceId) & tl.deletedAt.isNull(),
      );

    return q.watch().map((rows) {
      final out = <String, Set<String>>{};
      for (final row in rows) {
        (out[row.taskId] ??= {}).add(row.labelId);
      }
      return out;
    });
  }

  /// Finds a label by name or creates it. Used by quick-add, where typing `#uni` should
  /// not require the label to exist already.
  Future<Label> ensure({
    required String workspaceId,
    required String name,
    int? colour,
  }) async {
    final existing =
        await (_db.select(_db.labels)
              ..where(
                (l) =>
                    l.workspaceId.equals(workspaceId) &
                    l.name.lower().equals(name.toLowerCase()) &
                    l.deletedAt.isNull(),
              )
              // Two devices can each create `#uni` offline, and after sync both exist.
              // Oldest first, so every device settles on the same one instead of throwing.
              ..orderBy([
                (l) => OrderingTerm(expression: l.createdAt),
                (l) => OrderingTerm(expression: l.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing;

    return _writer.insert(
      _db.labels,
      LabelsCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        name: name,
        colour: Value(colour ?? _autoColour(name)),
      ),
    );
  }

  Future<void> attach({
    required String workspaceId,
    required String taskId,
    required String labelId,
  }) {
    return _db.transaction(() async {
      final pair =
          await (_db.select(_db.taskLabels)
                ..where((tl) => _pair(tl, taskId, labelId)))
              .get();

      if (pair.isEmpty) {
        await _writer.insert(
          _db.taskLabels,
          TaskLabelsCompanion.insert(
            // Derived from the pair, so two devices attaching offline make one row.
            id: NaturalId.taskLabel(taskId, labelId),
            workspaceId: workspaceId,
            taskId: taskId,
            labelId: labelId,
          ),
        );
        return;
      }
      if (pair.any((tl) => tl.deletedAt == null)) return;

      // Re-attaching something previously removed clears the tombstone rather than
      // inserting a duplicate pair.
      await _writer.updateWhere(
        _db.taskLabels,
        (tl) => _pair(tl, taskId, labelId),
        const TaskLabelsCompanion(deletedAt: Value(null)),
      );
    });
  }

  Future<void> detach({required String taskId, required String labelId}) =>
      _writer.updateWhere(
        _db.taskLabels,
        (tl) => _pair(tl, taskId, labelId) & tl.deletedAt.isNull(),
        TaskLabelsCompanion(deletedAt: Value(DateTime.now())),
      );

  Future<void> rename(String id, String name) =>
      _writer.update(_db.labels, id, LabelsCompanion(name: Value(name)));

  Future<void> restore(String id) => _writer.update(
    _db.labels,
    id,
    const LabelsCompanion(deletedAt: Value(null)),
  );

  Future<void> delete(String id) => _writer.update(
    _db.labels,
    id,
    LabelsCompanion(deletedAt: Value(DateTime.now())),
  );

  static Expression<bool> _pair(
    $TaskLabelsTable tl,
    String taskId,
    String labelId,
  ) => tl.taskId.equals(taskId) & tl.labelId.equals(labelId);

  /// A stable colour derived from the name, so a label created by quick-add still looks
  /// deliberate without asking you to pick one mid-capture.
  static int _autoColour(String name) {
    const palette = [
      0xFF0A84FF,
      0xFFBF5AF2,
      0xFF30D158,
      0xFFFF9F0A,
      0xFFFF453A,
      0xFFFFD60A,
      0xFF64D2FF,
    ];
    var hash = 0;
    for (final unit in name.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }
}
