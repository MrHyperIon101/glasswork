import 'package:drift/drift.dart';

import '../data/db/database.dart';

extension SyncedTables on AppDatabase {
  /// Every table that syncs, parents before children.
  ///
  /// A pull is applied in this order. A synced table missing from this list would never
  /// sync, and nothing would say so — which is why a test checks it against the schema.
  List<TableInfo<Table, Object?>> get syncedTables => [
    workspaces,
    boards,
    lists,
    tasks,
    subtasks,
    labels,
    taskLabels,
    notes,
    capacityProfiles,
    schedules,
    commitments,
    fieldDefs,
    fieldValues,
    projectViews,
  ];
}
