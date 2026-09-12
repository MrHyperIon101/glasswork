import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'glasswork'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Drift disables foreign keys by default; the schema relies on them.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
