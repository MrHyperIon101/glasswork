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

  /// One-line statement of what the project is for. Shown under its title, because a
  /// project name alone rarely says enough six weeks later.
  TextColumn get purpose => text().nullable()();

  TextColumn get icon => text().nullable()();
  IntColumn get colour => integer().nullable()();

  /// Archived projects stay queryable but leave the sidebar.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
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

  /// JSON array of the dirty column names, e.g. `["priority","title"]`.
  ///
  /// Names, not values. Values are read from the row at push time together with their
  /// real per-field clocks in `field_versions`, which is what lets repeated edits to one
  /// row coalesce into a single entry without misstating when each field was written.
  /// See `SyncWriter`.
  TextColumn get changedFields => text()();

  /// The newest clock that touched this entry, as an encoded `Hlc`.
  ///
  /// Replaced on every coalesce. A push removes an entry only if this is unchanged since
  /// it read it, so an edit landing mid-push is never lost.
  TextColumn get hlc => text()();

  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Local-only key/value store. No [SyncColumns] — these are per-device facts, not
/// content: the client identity, UI preferences, the sync cursor.
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// What kind of fixed block a commitment is.
enum CommitmentKind { classes, lab, work, travel, personal }

/// The capacity ledger's constants. One row per workspace.
///
/// These are the numbers every capacity figure in the app is derived from, so they are
/// deliberately explicit rather than hidden behind heuristics.
class CapacityProfiles extends Table with SyncColumns, WorkspaceScoped {
  /// Protected floor, not a resource. No code path may schedule into it or offer it as a
  /// way to make something fit.
  IntColumn get sleepTargetMin =>
      integer().withDefault(const Constant(450))();

  /// When sleep begins, as minutes past midnight. Needed because gaps are computed over
  /// a real waking window, not just a duration subtracted from 1440.
  IntColumn get sleepStartMin =>
      integer().withDefault(const Constant(23 * 60 + 30))();

  IntColumn get mealsMin => integer().withDefault(const Constant(90))();

  /// Transit, admin, life.
  IntColumn get bufferMin => integer().withDefault(const Constant(60))();

  /// Six free hours is not six hours of assignment. Tuned from completion data later.
  RealColumn get focusFactor => real().withDefault(const Constant(0.65))();

  /// A gap shorter than this yields nothing usable. Fragmentation costs more than the
  /// raw minutes suggest, and pretending otherwise is how a day looks fine on paper and
  /// isn't.
  IntColumn get minGapMin => integer().withDefault(const Constant(25))();
}

/// Fixed blocks: classes, labs, travel, work.
///
/// Commitments are things that happen to you; tasks are things you choose. Keeping them
/// in separate tables is what makes the arithmetic clean — a timetable is not a backlog.
@TableIndex(name: 'commitment_workspace', columns: {#workspaceId})
class Commitments extends Table with SyncColumns, WorkspaceScoped {
  /// Which named set this block belongs to. Null means it predates schedules and is
  /// treated as belonging to the fallback.
  TextColumn get scheduleId => text().nullable()();

  TextColumn get title => text()();

  /// Recurrence. Only `FREQ=WEEKLY` with `BYDAY` is understood today; see
  /// `capacity/recurrence.dart`, which rejects anything else rather than guessing.
  TextColumn get rrule => text()();

  /// Minutes past midnight.
  IntColumn get startMin => integer()();
  IntColumn get durationMin => integer()();

  TextColumn get location => text().nullable()();
  TextColumn get kind =>
      textEnum<CommitmentKind>().withDefault(const Constant('classes'))();
}

/// What a custom field holds.
enum FieldType { text, number, select, multiSelect, date, checkbox, url }

/// How a saved view renders its tasks.
enum ViewKind { list, board, calendar, timeline }

/// A user-defined column on a project's tasks.
///
/// Fields belong to a project, not to the workspace: a design project wants Stage and
/// Figma link, a dev project wants Component and PR. Sharing one global set would force
/// every project to carry every other project's vocabulary.
@TableIndex(name: 'fielddef_board', columns: {#boardId})
class FieldDefs extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get name => text()();
  TextColumn get type => textEnum<FieldType>()();

  /// JSON array of choices, for [FieldType.select] and [FieldType.multiSelect].
  /// Each entry is `{"label": ..., "colour": ...}`.
  TextColumn get optionsJson => text().withDefault(const Constant('[]'))();

  TextColumn get orderKey => text()();

  /// Whether it appears as a column in list and board views, or only in the detail sheet.
  BoolColumn get showInline => boolean().withDefault(const Constant(true))();
}

/// One task's value for one field.
///
/// Stored as text and decoded per [FieldDefs.type]. A column-per-type table would be
/// faster to query and far worse to extend; fields are read in small batches alongside
/// their tasks, so the decode cost is irrelevant here.
@TableIndex(name: 'fieldvalue_task', columns: {#taskId})
@TableIndex(name: 'fieldvalue_field', columns: {#fieldId})
class FieldValues extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get fieldId => text().references(FieldDefs, #id)();
  TextColumn get value => text().nullable()();
}

/// A saved way of looking at a project.
///
/// Views are queries plus a renderer, never new screens — adding one must not require a
/// new widget class, which is the same rule the smart views follow.
@TableIndex(name: 'projectview_board', columns: {#boardId})
class ProjectViews extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<ViewKind>()();

  /// The query DSL: `{"status": "open", "labels": ["uni"], "due": "<=7d"}`.
  TextColumn get filterJson => text().withDefault(const Constant('{}'))();

  /// Field id or built-in key ('list', 'priority', 'due') to group columns by in a
  /// board view.
  TextColumn get groupBy => text().nullable()();

  TextColumn get orderKey => text()();
}

/// A named, date-ranged set of commitments — one semester's timetable, a placement, a
/// holiday pattern.
///
/// The alternative is one flat list you rebuild by hand every term, which is both a chore
/// and quietly wrong: the ledger plans four weeks ahead, so in the last week of a
/// semester it would still be subtracting classes that have finished.
// 'Schedule' is already the capacity scheduler's output; this is the stored set.
@DataClassName('TimetableSet')
@TableIndex(name: 'schedule_workspace', columns: {#workspaceId})
class Schedules extends Table with SyncColumns, WorkspaceScoped {
  TextColumn get name => text()();

  /// Inclusive bounds as 'YYYY-MM-DD'. Text rather than timestamps for the same reason
  /// all-day dates are: a semester starts on a date, not at an instant in a timezone.
  TextColumn get startsOn => text().nullable()();
  TextColumn get endsOn => text().nullable()();

  /// Applies to any day no dated set covers — the between-terms default.
  BoolColumn get isFallback => boolean().withDefault(const Constant(false))();

  TextColumn get orderKey => text()();
}
