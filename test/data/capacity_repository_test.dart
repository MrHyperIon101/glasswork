import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/natural_id.dart';
import 'package:glasswork/data/repository/capacity_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late SyncWriter writer;
  late CapacityRepository capacity;
  late String workspaceId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    writer = SyncWriter(db, clientId: 'device-a');
    workspaceId = (await WorkspaceRepository(writer).ensureSeeded()).id;
    capacity = CapacityRepository(writer);
  });

  tearDown(() => db.close());

  Future<Commitment> block(String id) =>
      (db.select(db.commitments)..where((c) => c.id.equals(id))).getSingle();

  Future<Commitment> addBlock(String scheduleId, String title) =>
      capacity.addCommitment(
        workspaceId: workspaceId,
        scheduleId: scheduleId,
        title: title,
        weekdays: {1, 3},
        startMin: 9 * 60,
        durationMin: 60,
      );

  group('the profile', () {
    test('is created once, under an id derived from the workspace', () async {
      final a = await capacity.ensureProfile(workspaceId);
      final b = await capacity.ensureProfile(workspaceId);

      expect(b.id, a.id);
      expect(a.id, NaturalId.capacityProfile(workspaceId));
      expect(await db.select(db.capacityProfiles).get(), hasLength(1));
    });

    test('still reads as one when another device made its own before syncing', () async {
      final mine = await capacity.ensureProfile(workspaceId);
      await writer.insert(
        db.capacityProfiles,
        CapacityProfilesCompanion.insert(
          id: 'from-the-phone',
          workspaceId: workspaceId,
          createdAt: Value(DateTime.now().add(const Duration(days: 1))),
        ),
      );

      expect((await capacity.watchProfile(workspaceId).first)!.id, mine.id);
    });
  });

  group('timetable sets', () {
    test('the fallback adopts blocks made before sets existed, and the adoption syncs', () async {
      await writer.insert(
        db.commitments,
        CommitmentsCompanion.insert(
          id: 'loose',
          workspaceId: workspaceId,
          title: 'DBMS',
          rrule: 'FREQ=WEEKLY;BYDAY=MO',
          startMin: 9 * 60,
          durationMin: 60,
        ),
      );
      await db.delete(db.outbox).go();

      final fallback = await capacity.ensureFallbackSchedule(workspaceId);

      expect(fallback.id, NaturalId.fallbackSchedule(workspaceId));
      expect((await block('loose')).scheduleId, fallback.id);
      final entry = (await db.select(db.outbox).get()).firstWhere(
        (e) => e.rowId == 'loose',
      );
      expect(SyncWriter.decodeFieldNames(entry.changedFields), {'schedule_id'});
    });

    test('deleting a set takes its blocks; undo restores them, not one deleted before', () async {
      final sem = await capacity.addSchedule(workspaceId: workspaceId, name: 'Sem V');
      final kept = await addBlock(sem.id, 'DBMS');
      final gone = await addBlock(sem.id, 'Dropped elective');
      await writer.update(
        db.commitments,
        gone.id,
        CommitmentsCompanion(deletedAt: Value(DateTime(2026, 9, 6))),
      );

      expect(await capacity.deleteSchedule(sem.id), isTrue);
      expect((await block(kept.id)).deletedAt, isNotNull);

      await capacity.restoreSchedule(sem.id);

      expect((await block(kept.id)).deletedAt, isNull);
      expect(
        (await block(gone.id)).deletedAt,
        isNotNull,
        reason: 'deleted on its own, earlier',
      );
    });

    test('the fallback set cannot be deleted', () async {
      final fallback = await capacity.ensureFallbackSchedule(workspaceId);

      expect(await capacity.deleteSchedule(fallback.id), isFalse);
      expect(
        (await capacity.watchSchedules(workspaceId).first).map((s) => s.id),
        contains(fallback.id),
      );
    });
  });
}
