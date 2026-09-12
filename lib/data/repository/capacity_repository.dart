import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../capacity/ledger.dart';
import '../../capacity/recurrence.dart';
import '../db/database.dart';
import '../db/tables.dart';

/// The capacity profile and the timetable behind it.
class CapacityRepository {
  CapacityRepository(this._db, {required this.clientId});

  final AppDatabase _db;
  final String clientId;

  static const _uuid = Uuid();

  /// The profile, created with defaults on first read.
  Future<CapacityProfile> ensureProfile(String workspaceId) async {
    final existing =
        await (_db.select(_db.capacityProfiles)
              ..where((p) => p.workspaceId.equals(workspaceId)))
            .getSingleOrNull();
    if (existing != null) return existing;

    return _db
        .into(_db.capacityProfiles)
        .insertReturning(
          CapacityProfilesCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            clientId: Value(clientId),
          ),
        );
  }

  Stream<CapacityProfile?> watchProfile(String workspaceId) =>
      (_db.select(_db.capacityProfiles)
            ..where((p) => p.workspaceId.equals(workspaceId)))
          .watchSingleOrNull();

  Future<void> updateProfile(
    String id, {
    int? sleepTargetMin,
    int? sleepStartMin,
    int? mealsMin,
    int? bufferMin,
    double? focusFactor,
    int? minGapMin,
  }) async {
    await (_db.update(_db.capacityProfiles)..where((p) => p.id.equals(id))).write(
      CapacityProfilesCompanion(
        sleepTargetMin: Value.absentIfNull(sleepTargetMin),
        sleepStartMin: Value.absentIfNull(sleepStartMin),
        mealsMin: Value.absentIfNull(mealsMin),
        bufferMin: Value.absentIfNull(bufferMin),
        focusFactor: Value.absentIfNull(focusFactor),
        minGapMin: Value.absentIfNull(minGapMin),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<Commitment>> watchCommitments(String workspaceId) =>
      (_db.select(_db.commitments)
            ..where(
              (c) => c.workspaceId.equals(workspaceId) & c.deletedAt.isNull(),
            )
            ..orderBy([(c) => OrderingTerm(expression: c.startMin)]))
          .watch();

  Future<Commitment> addCommitment({
    required String workspaceId,
    required String title,
    required Set<int> weekdays,
    required int startMin,
    required int durationMin,
    CommitmentKind kind = CommitmentKind.classes,
    String? location,
    DateTime? until,
  }) {
    return _db
        .into(_db.commitments)
        .insertReturning(
          CommitmentsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            title: title,
            rrule: Recurrence.weekly(weekdays, until: until),
            startMin: startMin,
            durationMin: durationMin,
            kind: Value(kind),
            location: Value(location),
            clientId: Value(clientId),
          ),
        );
  }

  Future<void> deleteCommitment(String id) async {
    await (_db.update(_db.commitments)..where((c) => c.id.equals(id))).write(
      CommitmentsCompanion(
        deletedAt: Value(DateTime.now()),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restoreCommitment(String id) async {
    await (_db.update(_db.commitments)..where((c) => c.id.equals(id))).write(
      CommitmentsCompanion(
        deletedAt: const Value(null),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

/// Translates stored rows into the pure types the ledger works with.
///
/// Kept as free functions rather than methods on the Drift rows so the capacity engine
/// stays completely independent of the database — that is what lets it be tested with
/// hand-built inputs and no I/O.
abstract final class CapacityMapping {
  static CapacitySettings settings(CapacityProfile? profile) {
    if (profile == null) return const CapacitySettings();
    return CapacitySettings(
      sleepTargetMin: profile.sleepTargetMin,
      sleepStartMin: profile.sleepStartMin,
      mealsMin: profile.mealsMin,
      bufferMin: profile.bufferMin,
      focusFactor: profile.focusFactor,
      minGapMin: profile.minGapMin,
    );
  }

  /// Commitments whose recurrence the engine understands.
  ///
  /// A rule it cannot read is skipped and reported rather than guessed at — the ledger
  /// would rather be visibly missing a block than silently wrong about the day.
  static (List<FixedBlock>, List<String>) blocks(List<Commitment> rows) {
    final blocks = <FixedBlock>[];
    final rejected = <String>[];

    for (final row in rows) {
      try {
        blocks.add(
          FixedBlock(
            title: row.title,
            startMin: row.startMin,
            durationMin: row.durationMin,
            recurrence: Recurrence.parse(row.rrule),
          ),
        );
      } on RecurrenceError catch (e) {
        rejected.add('${row.title}: ${e.message}');
      }
    }

    return (blocks, rejected);
  }
}
