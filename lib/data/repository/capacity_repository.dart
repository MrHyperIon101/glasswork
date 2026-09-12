import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../capacity/ledger.dart';
import '../../capacity/recurrence.dart';
import '../../capacity/timetable.dart';
import '../db/database.dart';
import '../db/tables.dart';
import '../order_key.dart';

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

  /// 'YYYY-MM-DD'. Text rather than a timestamp: a semester starts on a date, not at
  /// an instant in some timezone.
  static String? _isoOf(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  // --- timetable sets ---

  Stream<List<TimetableSet>> watchSchedules(String workspaceId) =>
      (_db.select(_db.schedules)
            ..where(
              (s) => s.workspaceId.equals(workspaceId) & s.deletedAt.isNull(),
            )
            ..orderBy([
              (s) => OrderingTerm(expression: s.startsOn),
              (s) => OrderingTerm(expression: s.orderKey),
            ]))
          .watch();

  /// The set every loose commitment belongs to.
  ///
  /// Created once, on demand, so a workspace that predates timetable sets keeps working
  /// and its existing blocks stay in force.
  Future<TimetableSet> ensureFallbackSchedule(String workspaceId) async {
    final existing =
        await (_db.select(_db.schedules)..where(
              (s) =>
                  s.workspaceId.equals(workspaceId) &
                  s.isFallback.equals(true) &
                  s.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (existing != null) return existing;

    final created = await _db
        .into(_db.schedules)
        .insertReturning(
          SchedulesCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            name: 'Everyday',
            isFallback: const Value(true),
            orderKey: OrderKey.first,
            clientId: Value(clientId),
          ),
        );

    // Adopt any blocks created before sets existed.
    await (_db.update(_db.commitments)..where(
          (c) => c.workspaceId.equals(workspaceId) & c.scheduleId.isNull(),
        ))
        .write(CommitmentsCompanion(scheduleId: Value(created.id)));

    return created;
  }

  Future<TimetableSet> addSchedule({
    required String workspaceId,
    required String name,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    final last =
        await (_db.select(_db.schedules)
              ..where((s) => s.workspaceId.equals(workspaceId))
              ..orderBy([
                (s) => OrderingTerm(
                  expression: s.orderKey,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return _db
        .into(_db.schedules)
        .insertReturning(
          SchedulesCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            name: name,
            startsOn: Value(_isoOf(startsOn)),
            endsOn: Value(_isoOf(endsOn)),
            orderKey: last == null
                ? OrderKey.first
                : OrderKey.after(last.orderKey),
            clientId: Value(clientId),
          ),
        );
  }

  Future<void> updateSchedule(
    String id, {
    String? name,
    DateTime? startsOn,
    DateTime? endsOn,
    bool clearDates = false,
  }) async {
    await (_db.update(_db.schedules)..where((s) => s.id.equals(id))).write(
      SchedulesCompanion(
        name: Value.absentIfNull(name),
        startsOn: clearDates
            ? const Value(null)
            : Value.absentIfNull(_isoOf(startsOn)),
        endsOn: clearDates
            ? const Value(null)
            : Value.absentIfNull(_isoOf(endsOn)),
        clientId: Value(clientId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Copies a set and all its blocks under a new name and dates.
  ///
  /// This is the whole time-saver: next semester usually rhymes with this one, so you
  /// duplicate and adjust rather than retyping fourteen classes.
  Future<TimetableSet> duplicateSchedule({
    required String workspaceId,
    required String sourceId,
    required String name,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    return _db.transaction(() async {
      final created = await addSchedule(
        workspaceId: workspaceId,
        name: name,
        startsOn: startsOn,
        endsOn: endsOn,
      );

      final source =
          await (_db.select(_db.commitments)..where(
                (c) => c.scheduleId.equals(sourceId) & c.deletedAt.isNull(),
              ))
              .get();

      for (final block in source) {
        await _db.into(_db.commitments).insert(
          CommitmentsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            scheduleId: Value(created.id),
            title: block.title,
            rrule: block.rrule,
            startMin: block.startMin,
            durationMin: block.durationMin,
            kind: Value(block.kind),
            location: Value(block.location),
            clientId: Value(clientId),
          ),
        );
      }

      return created;
    });
  }

  Future<void> deleteSchedule(String id) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      await (_db.update(_db.schedules)..where((s) => s.id.equals(id))).write(
        SchedulesCompanion(
          deletedAt: Value(now),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
      );
      // Its blocks go with it; leaving them orphaned would silently move them to the
      // fallback and start subtracting classes that no longer happen.
      await (_db.update(_db.commitments)..where((c) => c.scheduleId.equals(id)))
          .write(
            CommitmentsCompanion(
              deletedAt: Value(now),
              clientId: Value(clientId),
              updatedAt: Value(now),
            ),
          );
    });
  }

  Future<void> restoreSchedule(String id) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      await (_db.update(_db.schedules)..where((s) => s.id.equals(id))).write(
        SchedulesCompanion(
          deletedAt: const Value(null),
          clientId: Value(clientId),
          updatedAt: Value(now),
        ),
      );
      await (_db.update(_db.commitments)..where((c) => c.scheduleId.equals(id)))
          .write(
            CommitmentsCompanion(
              deletedAt: const Value(null),
              clientId: Value(clientId),
              updatedAt: Value(now),
            ),
          );
    });
  }

  // --- commitments ---

  Stream<List<Commitment>> watchCommitments(String workspaceId) =>
      (_db.select(_db.commitments)
            ..where(
              (c) => c.workspaceId.equals(workspaceId) & c.deletedAt.isNull(),
            )
            ..orderBy([(c) => OrderingTerm(expression: c.startMin)]))
          .watch();

  Future<Commitment> addCommitment({
    required String workspaceId,
    required String scheduleId,
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
            scheduleId: Value(scheduleId),
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
  /// Builds the day-resolving timetable from stored sets and their blocks.
  static Timetable timetable(
    List<TimetableSet> sets,
    List<Commitment> commitments,
  ) {
    final windows = <ScheduleWindow>[];
    for (final set in sets) {
      final own = commitments.where((c) => c.scheduleId == set.id).toList();
      final (blocks, _) = blocksOf(own);
      windows.add(
        ScheduleWindow(
          id: set.id,
          name: set.name,
          blocks: blocks,
          startsOn: _parseIso(set.startsOn),
          endsOn: _parseIso(set.endsOn),
          isFallback: set.isFallback,
        ),
      );
    }
    return Timetable(windows);
  }

  static DateTime? _parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

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
  static (List<FixedBlock>, List<String>) blocksOf(List<Commitment> rows) {
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

