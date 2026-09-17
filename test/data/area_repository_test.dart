import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/repository/area_repository.dart';
import 'package:glasswork/data/repository/project_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late AreaRepository areas;
  late ProjectRepository projects;
  late String workspaceId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final writer = SyncWriter(db, clientId: 'laptop');
    workspaceId = (await WorkspaceRepository(writer).ensureSeeded()).id;
    areas = AreaRepository(writer);
    projects = ProjectRepository(writer);
  });
  tearDown(() => db.close());

  Future<Set<String>> queuedFields(String id) async => {
    for (final entry in await (db.select(db.outbox)..where((o) => o.rowId.equals(id))).get())
      ...SyncWriter.decodeFieldNames(entry.changedFields),
  };

  test('areas list in the order they were made, and each syncs', () async {
    final uni = await areas.create(workspaceId: workspaceId, name: 'University');
    final work = await areas.create(workspaceId: workspaceId, name: 'Work');

    expect([for (final a in await areas.watchAll(workspaceId).first) a.name], [
      'University',
      'Work',
    ]);
    expect(uni.orderKey.compareTo(work.orderKey), lessThan(0));
    expect(await queuedFields(uni.id), containsAll(['name', 'order_key', 'workspace_id']));
  });

  test('a project moved into an area, and out again, writes only which area', () async {
    final uni = await areas.create(workspaceId: workspaceId, name: 'University');
    final dbms = await projects.createProject(workspaceId: workspaceId, name: 'DBMS');
    await db.delete(db.outbox).go();

    await areas.moveProject(dbms.id, uni.id);
    var row = await (db.select(db.boards)..where((b) => b.id.equals(dbms.id))).getSingle();
    expect(row.areaId, uni.id);
    expect(await queuedFields(dbms.id), {'area_id'});

    await areas.moveProject(dbms.id, null);
    row = await (db.select(db.boards)..where((b) => b.id.equals(dbms.id))).getSingle();
    expect(row.areaId, isNull);
  });

  test('a project can be made in an area', () async {
    final uni = await areas.create(workspaceId: workspaceId, name: 'University');
    final dbms = await projects.createProject(
      workspaceId: workspaceId,
      name: 'DBMS',
      areaId: uni.id,
    );
    expect(dbms.areaId, uni.id);
  });

  test('a deleted area is a tombstone, gone from the list until restored, projects untouched', () async {
    final uni = await areas.create(workspaceId: workspaceId, name: 'University');
    final dbms = await projects.createProject(
      workspaceId: workspaceId,
      name: 'DBMS',
      areaId: uni.id,
    );

    await areas.softDelete(uni.id);
    expect(await areas.watchAll(workspaceId).first, isEmpty);
    final tombstone = await (db.select(db.areas)..where((a) => a.id.equals(uni.id))).getSingle();
    expect(tombstone.deletedAt, isNotNull);
    final project = await (db.select(db.boards)..where((b) => b.id.equals(dbms.id))).getSingle();
    expect(project.areaId, uni.id, reason: 'undoing the delete puts it back where it was');

    await areas.restore(uni.id);
    expect([for (final a in await areas.watchAll(workspaceId).first) a.id], [uni.id]);
  });

  test('renaming writes the name alone', () async {
    final uni = await areas.create(workspaceId: workspaceId, name: 'Uni');
    await db.delete(db.outbox).go();
    await areas.rename(uni.id, 'University');
    expect((await areas.watchAll(workspaceId).first).single.name, 'University');
    expect(await queuedFields(uni.id), {'name'});
  });
}
