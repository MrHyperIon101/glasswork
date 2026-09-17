import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../order_key.dart';

/// Areas: groups of projects, named by the person.
///
/// The same contract as every repository: nothing here awaits the network, every write goes
/// through [SyncWriter], and deleting is a tombstone that can be undone. Deleting an area
/// leaves its projects where they are; with their area gone they list with the projects in
/// no area, and come back under it if the delete is undone.
class AreaRepository {
  AreaRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  /// Live areas, in their order.
  Stream<List<Area>> watchAll(String workspaceId) =>
      (_db.select(_db.areas)
            ..where((a) => a.workspaceId.equals(workspaceId) & a.deletedAt.isNull())
            ..orderBy([
              (a) => OrderingTerm(expression: a.orderKey),
              (a) => OrderingTerm(expression: a.clientId),
            ]))
          .watch();

  /// A new area, after the others.
  Future<Area> create({required String workspaceId, required String name}) =>
      _db.transaction(() async {
        final last =
            await (_db.select(_db.areas)
                  ..where((a) => a.workspaceId.equals(workspaceId))
                  ..orderBy([(a) => OrderingTerm.desc(a.orderKey)])
                  ..limit(1))
                .getSingleOrNull();
        return _writer.insert(
          _db.areas,
          AreasCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            name: name,
            orderKey: last == null ? OrderKey.first : OrderKey.after(last.orderKey),
          ),
        );
      });

  Future<void> rename(String id, String name) =>
      _writer.update(_db.areas, id, AreasCompanion(name: Value(name)));

  Future<void> softDelete(String id) =>
      _writer.update(_db.areas, id, AreasCompanion(deletedAt: Value(DateTime.now())));

  Future<void> restore(String id) =>
      _writer.update(_db.areas, id, const AreasCompanion(deletedAt: Value(null)));

  /// Lists [projectId] under [areaId], or with the projects in no area for null.
  Future<void> moveProject(String projectId, String? areaId) =>
      _writer.update(_db.boards, projectId, BoardsCompanion(areaId: Value(areaId)));
}
