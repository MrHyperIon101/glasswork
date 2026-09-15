import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../capacity/ledger.dart';
import '../../capacity/recurrence.dart';
import '../../capacity/timetable.dart';
import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../db/tables.dart';
import '../natural_id.dart';
import '../order_key.dart';

/// The capacity profile and the timetable behind it.
class CapacityRepository {
  CapacityRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  /// The profile, created with defaults on first read.
  Future<CapacityProfile> ensureProfile(String workspaceId) {
    return _db.transaction(() async {
      final existing = await _profileOf(workspaceId).getSingleOrNull();
      if (existing != null) return existing;

      return _writer.insert(
        _db.capacityProfiles,
        CapacityProfilesCompanion.insert(
          // Derived, so two devices creating it offline create the same row.
          id: NaturalId.capacityProfile(workspaceId),
          workspaceId: workspaceId,
        ),
      );
    });
  }

  Stream<CapacityProfile?> watchProfile(String workspaceId) =>
      _profileOf(workspaceId).watchSingleOrNull();

  /// The workspace's profile, oldest first.
  ///
  /// There is one per workspace — by construction from now on, since the id derives from
  /// the workspace. Two made on separate devices before that would both sync, and asking
  /// for "the only one" would then throw.
  SimpleSelectStatement<$CapacityProfilesTable, CapacityProfile> _profileOf(
    String workspaceId,
  ) => _db.select(_db.capacityProfiles)
    ..where((p) => p.workspaceId.equals(workspaceId))
    ..orderBy([
      (p) => OrderingTerm(expression: p.createdAt),
      (p) => OrderingTerm(expression: p.id),
    ])
    ..limit(1);

  Future<void> updateProfile(
    String id, {
    int? sleepTargetMin,
    int? sleepStartMin,
    int? mealsMin,
    int? bufferMin,
    double? focusFactor,
    int? minGapMin,
  }) => _writer.update(
    _db.capacityProfiles,
    id,
    CapacityProfilesCompanion(
      sleepTargetMin: Value.absentIfNull(sleepTargetMin),
      sleepStartMin: Value.absentIfNull(sleepStartMin),
      mealsMin: Value.absentIfNull(mealsMin),
      bufferMin: Value.absentIfNull(bufferMin),
      focusFactor: Value.absentIfNull(focusFactor),
      minGapMin: Value.absentIfNull(minGapMin),
    ),
  );

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
  Future<TimetableSet> ensureFallbackSchedule(String workspaceId) {
    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.schedules)
                ..where(
                  (s) =>
                      s.workspaceId.equals(workspaceId) &
                      s.isFallback.equals(true) &
                      s.deletedAt.isNull(),
                )
                // Oldest first, for the same reason as the profile.
                ..orderBy([
                  (s) => OrderingTerm(expression: s.createdAt),
                  (s) => OrderingTerm(expression: s.id),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return existing;

      final created = await _writer.insert(
        _db.schedules,
        SchedulesCompanion.insert(
          // Derived, like the profile. It can never be tombstoned — deleteSchedule refuses
          // the fallback — so this cannot collide with a deleted one.
          id: NaturalId.fallbackSchedule(workspaceId),
          workspaceId: workspaceId,
          name: 'Everyday',
          isFallback: const Value(true),
          orderKey: OrderKey.first,
        ),
      );

      // Adopt any blocks created before sets existed.
      await _writer.updateWhere(
        _db.commitments,
        (c) => c.workspaceId.equals(workspaceId) & c.scheduleId.isNull(),
        CommitmentsCompanion(scheduleId: Value(created.id)),
      );

      return created;
    });
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

    return _writer.insert(
      _db.schedules,
      SchedulesCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        name: name,
        startsOn: Value(_isoOf(startsOn)),
        endsOn: Value(_isoOf(endsOn)),
        orderKey: last == null ? OrderKey.first : OrderKey.after(last.orderKey),
      ),
    );
  }

  Future<void> updateSchedule(
    String id, {
    String? name,
    DateTime? startsOn,
    DateTime? endsOn,
    bool clearDates = false,
  }) => _writer.update(
    _db.schedules,
    id,
    SchedulesCompanion(
      name: Value.absentIfNull(name),
      startsOn: clearDates
          ? const Value(null)
          : Value.absentIfNull(_isoOf(startsOn)),
      endsOn: clearDates ? const Value(null) : Value.absentIfNull(_isoOf(endsOn)),
    ),
  );

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
  }) {
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
        await _writer.insert(
          _db.commitments,
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
          ),
        );
      }

      return created;
    });
  }

  /// Deletes a set and its blocks. Returns false for the fallback set, which cannot be
  /// deleted: it is where every block outside a dated set lives.
  ///
  /// Only live blocks, all under one deletion time, which is how [restoreSchedule] tells
  /// the blocks that went with the set from ones already deleted on their own.
  Future<bool> deleteSchedule(String id) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final deleted = await _writer.updateWhere(
        _db.schedules,
        (s) =>
            s.id.equals(id) & s.isFallback.equals(false) & s.deletedAt.isNull(),
        SchedulesCompanion(deletedAt: Value(now)),
      );
      if (deleted.isEmpty) return false;

      // Its blocks go with it; leaving them orphaned would silently move them to the
      // fallback and start subtracting classes that no longer happen.
      await _writer.updateWhere(
        _db.commitments,
        (c) => c.scheduleId.equals(id) & c.deletedAt.isNull(),
        CommitmentsCompanion(deletedAt: Value(now)),
      );
      return true;
    });
  }

  /// Undoes [deleteSchedule]: restores the set and the blocks carrying its deletion time.
  Future<void> restoreSchedule(String id) {
    return _db.transaction(() async {
      final schedule =
          await (_db.select(_db.schedules)..where((s) => s.id.equals(id)))
              .getSingleOrNull();
      final deletedAt = schedule?.deletedAt;
      if (deletedAt == null) return;

      await _writer.updateWhere(
        _db.commitments,
        (c) => c.scheduleId.equals(id) & c.deletedAt.equals(deletedAt),
        const CommitmentsCompanion(deletedAt: Value(null)),
      );
      await _writer.update(
        _db.schedules,
        id,
        const SchedulesCompanion(deletedAt: Value(null)),
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
  }) => _writer.insert(
    _db.commitments,
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
    ),
  );

  /// Changes a block. Only what is passed is written, so this does not undo another
  /// device's change to a field it never touched.
  ///
  /// New [weekdays] keep the rule's end date, which the editor does not show.
  Future<void> updateCommitment(
    String id, {
    String? title,
    Set<int>? weekdays,
    int? startMin,
    int? durationMin,
  }) async {
    String? rrule;
    if (weekdays != null) {
      final current = await (_db.select(
        _db.commitments,
      )..where((c) => c.id.equals(id))).getSingleOrNull();
      DateTime? until;
      try {
        until = current == null ? null : Recurrence.parse(current.rrule).until;
      } on RecurrenceError {
        // A rule the engine could not read has no end date worth keeping.
      }
      rrule = Recurrence.weekly(weekdays, until: until);
    }

    await _writer.update(
      _db.commitments,
      id,
      CommitmentsCompanion(
        title: Value.absentIfNull(title),
        rrule: Value.absentIfNull(rrule),
        startMin: Value.absentIfNull(startMin),
        durationMin: Value.absentIfNull(durationMin),
      ),
    );
  }

  Future<void> deleteCommitment(String id) => _writer.update(
    _db.commitments,
    id,
    CommitmentsCompanion(deletedAt: Value(DateTime.now())),
  );

  Future<void> restoreCommitment(String id) => _writer.update(
    _db.commitments,
    id,
    const CommitmentsCompanion(deletedAt: Value(null)),
  );
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
