import 'package:drift/drift.dart';

/// Status of a task. Stored by name, not index, so reordering the enum is safe.
enum TaskStatus { open, done, archived }

/// Which view a board opens in. A "list view" board is just a board with one list —
/// same tables, no special case.
enum BoardView { list, board, calendar, timeline }

/// The tail every synced row carries.
///
/// Added from the very first schema even though nothing syncs until phase 4: retrofitting
/// it later means touching every table.
///
/// Note that [updatedAt] and [fieldVersions] are two different clocks and are not
/// interchangeable — see docs/architecture.md. [updatedAt] is the delta-pull cursor and is set by the
/// server. [fieldVersions] holds per-field hybrid logical clocks set by the client, and is
/// what resolves conflicts.
mixin SyncColumns on Table {
  TextColumn get id => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  TextColumn get clientId => text().nullable()();

  /// JSON map of field name -> hybrid logical clock.
  TextColumn get fieldVersions =>
      text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Denormalised workspace key. Redundant, and worth it: it lets the Postgres RLS policy
/// key off the row directly instead of a join-per-row subquery.
mixin WorkspaceScoped on Table {
  TextColumn get workspaceId => text()();
}

class Workspaces extends Table with SyncColumns {
  TextColumn get name => text()();
}

@TableIndex(name: 'board_workspace', columns: {#workspaceId})
class Boards extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get colour => integer().nullable()();
  TextColumn get viewDefault =>
      textEnum<BoardView>().withDefault(const Constant('list'))();

  /// Fractional index. Never an int, never a reindex loop.
  TextColumn get orderKey => text()();
}

// Without this, drift singularises `Lists` into a row class called `List`, which shadows
// dart:core's List inside the generated file and breaks compilation.
@DataClassName('BoardList')
@TableIndex(name: 'list_board', columns: {#boardId})
class Lists extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get name => text()();
  TextColumn get orderKey => text()();
  IntColumn get wipLimit => integer().nullable()();
  BoolColumn get isDoneColumn =>
      boolean().withDefault(const Constant(false))();
}

@TableIndex(name: 'task_list_order', columns: {#listId, #orderKey})
@TableIndex(name: 'task_workspace_due', columns: {#workspaceId, #dueAt})
@TableIndex(name: 'task_workspace_updated', columns: {#workspaceId, #updatedAt})
class Tasks extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get listId => text().references(Lists, #id)();
  TextColumn get title => text()();
  TextColumn get notesMd => text().nullable()();
  TextColumn get orderKey => text()();

  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(const Constant('open'))();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Timed due date, stored UTC.
  DateTimeColumn get dueAt => dateTime().nullable()();

  /// All-day due date as 'YYYY-MM-DD'. Deliberately text, not a timestamp: an all-day
  /// task has no instant and no timezone, and storing one breaks "due today" the moment
  /// you travel or the server is UTC. At most one of [dueAt] / [dueDate] is set.
  TextColumn get dueDate => text().nullable()();

  DateTimeColumn get startAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// RRULE string, expanded client-side only.
  TextColumn get rrule => text().nullable()();
  TextColumn get parentTaskId => text().nullable()();

  // --- capacity engine (phase 2) ---

  IntColumn get estimateMin => integer().nullable()();
  IntColumn get actualMin => integer().nullable()();

  /// 'YYYY-MM-DD', same reasoning as [dueDate].
  TextColumn get scheduledFor => text().nullable()();

  /// Three slips means something is wrong with the task, not with your discipline.
  IntColumn get slipCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastDeferredAt => dateTime().nullable()();
}

@TableIndex(name: 'subtask_task_order', columns: {#taskId, #orderKey})
class Subtasks extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  TextColumn get orderKey => text()();
}

class Labels extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get name => text()();
  IntColumn get colour => integer().nullable()();
}

@TableIndex(name: 'tasklabel_label', columns: {#labelId})
class TaskLabels extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get labelId => text().references(Labels, #id)();
}

class Notes extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get title => text()();
  TextColumn get bodyMd => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
}

/// Local-only write queue. Deliberately has no [SyncColumns] — it never syncs, it *is*
/// the sync mechanism.
///
/// Entries record the **fields that changed**, not a row snapshot. A full-row write would
/// clobber fields this device never touched, which defeats per-field conflict resolution.
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();

  TextColumn get targetTable => text()();
  TextColumn get rowId => text()();

  /// JSON object of changed field name -> new value.
  TextColumn get changedFields => text()();

  /// Hybrid logical clock at the time of the edit, as 'wallMs:counter:clientId'.
  TextColumn get hlc => text()();

  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
}
