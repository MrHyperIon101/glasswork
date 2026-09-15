import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// The local database. This is the source of truth — not the server.
///
/// Every UI read and write goes here and returns immediately. Sync (phase 4) reconciles
/// in the background via [Outbox]; no UI path ever awaits the network.
@DriftDatabase(
  tables: [
    Workspaces,
    Boards,
    Lists,
    Tasks,
    Subtasks,
    Labels,
    TaskLabels,
    Notes,
    Outbox,
    LocalSettings,
    CapacityProfiles,
    Commitments,
    FieldDefs,
    FieldValues,
    ProjectViews,
    Schedules,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'glasswork', native: _native));

  /// drift's default is `getApplicationDocumentsDirectory()`, which on Linux drops a
  /// .sqlite file straight into the user's Documents folder. Application support is where
  /// this belongs.
  static final _native = DriftNativeOptions(
    databaseDirectory: getApplicationSupportDirectory,
  );

  /// Bump this for **every** schema change, and add the matching step below.
  ///
  /// Forgetting to is silent: drift compares this against the file's `user_version`, sees
  /// no change, runs no migration, and the app then queries a table that was never
  /// created. Nothing fails at build time — it fails at launch, on the machine that
  /// already had a database.
  @override
  int get schemaVersion => 5;

  /// The weekday names the per-day sleep columns are named with, Monday first.
  static const sleepDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: the capacity engine.
      if (from < 2) {
        await m.createTable(capacityProfiles);
        await m.createTable(commitments);
      }

      // v3: projects with custom fields and saved views.
      if (from < 3) {
        await m.addColumn(boards, boards.purpose);
        await m.addColumn(boards, boards.archived);
        await m.createTable(fieldDefs);
        await m.createTable(fieldValues);
        await m.createTable(projectViews);
      }

      // v4: timetables become named, date-ranged sets.
      if (from < 4) {
        await m.createTable(schedules);
        await m.addColumn(commitments, commitments.scheduleId);
      }

      // v5: sleep set per day, and reminders.
      if (from < 5) {
        final p = capacityProfiles;
        for (final column in [
          p.wakeMonMin, p.bedtimeMonMin, p.wakeTueMin, p.bedtimeTueMin, //
          p.wakeWedMin, p.bedtimeWedMin, p.wakeThuMin, p.bedtimeThuMin, //
          p.wakeFriMin, p.bedtimeFriMin, p.wakeSatMin, p.bedtimeSatMin, //
          p.wakeSunMin, p.bedtimeSunMin,
        ]) {
          await m.addColumn(capacityProfiles, column);
        }
        // Every day starts where the single bedtime and sleep target already put it, so no
        // figure moves on upgrade. No field clocks are stamped: every device derives the
        // same values from the same two columns, as the server migration does, and the
        // first real edit anywhere wins.
        await customStatement(
          'UPDATE capacity_profiles SET ${[
            for (final day in sleepDays) ...[
              'wake_${day}_min = (sleep_start_min + sleep_target_min) % 1440',
              'bedtime_${day}_min = sleep_start_min',
            ],
          ].join(', ')}',
        );

        await m.addColumn(tasks, tasks.remindAt);
      }
    },
    beforeOpen: (details) async {
      // Drift disables foreign keys by default; the schema relies on them.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
