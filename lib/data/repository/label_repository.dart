import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Labels, and which tasks carry them.
///
/// Labels are workspace-wide on purpose, unlike custom fields: `#urgent` means the same
/// thing in every project, and a label you have to recreate per project stops getting
/// used. Fields describe a project's vocabulary; labels cut across it.
class LabelRepository {
  LabelRepository(this._db, {required this.clientId});

  final AppDatabase _db;
  final String clientId;

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
        await (_db.select(_db.labels)..where(
              (l) =>
                  l.workspaceId.equals(workspaceId) &
                  l.name.lower().equals(name.toLowerCase()) &
                  l.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (existing != null) return existing;

    return _db
        .into(_db.labels)
        .insertReturning(
          LabelsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            name: name,
            colour: Value(colour ?? _autoColour(name)),
            clientId: Value(clientId),
          ),
        );
  }

  Future<void> attach({
    required String workspaceId,
    required String taskId,
    required String labelId,
  }) async {
    final existing =
        await (_db.select(_db.taskLabels)..where(
              (tl) => tl.taskId.equals(taskId) & tl.labelId.equals(labelId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      // Re-attaching something previously removed clears the tombstone rather than
      // inserting a duplicate pair.
      await (_db.update(_db.taskLabels)
            ..where((tl) => tl.id.equals(existing.id)))
          .write(
            TaskLabelsCompanion(
              deletedAt: const Value(null),
              clientId: Value(clientId),
              updatedAt: Value(DateTime.now()),
            ),
          );
      return;
    }

    await _db.into(_db.taskLabels).insert(
      TaskLabelsCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        taskId: taskId,
        labelId: labelId,
        clientId: Value(clientId),
      ),
    );
  }

  Future<void> detach({
    required String taskId,
    required String labelId,
  }) async {
    await (_db.update(_db.taskLabels)..where(
          (tl) => tl.taskId.equals(taskId) & tl.labelId.equals(labelId),
        ))
        .write(
          TaskLabelsCompanion(
            deletedAt: Value(DateTime.now()),
            clientId: Value(clientId),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> rename(String id, String name) async {
    await (_db.update(_db.labels)..where((l) => l.id.equals(id))).write(
      LabelsCompanion(
        name: Value(name),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_db.update(_db.labels)..where((l) => l.id.equals(id))).write(
      LabelsCompanion(
        deletedAt: Value(DateTime.now()),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

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
