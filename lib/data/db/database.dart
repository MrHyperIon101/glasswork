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
  int get schemaVersion => 4;

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
    },
    beforeOpen: (details) async {
      // Drift disables foreign keys by default; the schema relies on them.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
