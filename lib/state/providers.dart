import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/db/tables.dart';
import '../capacity/ledger.dart';
import '../capacity/scheduler.dart';
import '../capacity/setting_effects.dart';
import '../capacity/timetable.dart' as tt;
import '../data/repository/area_repository.dart';
import '../data/repository/capacity_repository.dart';
import '../data/preferences.dart';
import '../data/repository/label_repository.dart';
import '../data/repository/note_repository.dart';
import '../data/repository/preferences_repository.dart';
import '../data/repository/project_repository.dart';
import '../data/repository/subtask_repository.dart';
import '../data/repository/task_repository.dart';
import '../data/repository/workspace_repository.dart';
import '../data/project_filter.dart';
import '../data/task_slots.dart';
import '../data/task_stats.dart';
import '../sync/sync_writer.dart';

/// Everything the app needs once the database is open and seeded.
///
/// Bundled into one object so the UI awaits exactly once, at the root, instead of every
/// screen juggling loading states for things that are ready in milliseconds.
class AppScope {
  const AppScope({
    required this.db,
    required this.writer,
    required this.workspaces,
    required this.tasks,
    required this.subtasks,
    required this.capacity,
    required this.projects,
    required this.labels,
    required this.notes,
    required this.areas,
    required this.preferences,
    required this.workspace,
  });

  final AppDatabase db;

  /// The one writer for [db], shared by every repository. Two would each keep their own
  /// copy of the clock, and could mint the same clock twice.
  final SyncWriter writer;

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final SubtaskRepository subtasks;
  final CapacityRepository capacity;
  final ProjectRepository projects;
  final LabelRepository labels;
  final NoteRepository notes;
  final AreaRepository areas;
  final PreferencesRepository preferences;
  final Workspace workspace;
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final appScopeProvider = FutureProvider<AppScope>((ref) async {
  final db = ref.watch(databaseProvider);
  final writer = SyncWriter(
    db,
    clientId: await WorkspaceRepository.ensureClientId(db),
  );

  final workspaces = WorkspaceRepository(writer);
  final workspace = await workspaces.ensureSeeded();
  // Pinned, so a workspace later pulled from another device never takes this one's place
  // by being older. Only linking to an account moves it.
  await workspaces.setActive(workspace.id);

  final capacity = CapacityRepository(writer);
  await capacity.ensureProfile(workspace.id);
  await capacity.ensureFallbackSchedule(workspace.id);

  return AppScope(
    db: db,
    writer: writer,
    workspaces: workspaces,
    tasks: TaskRepository(writer),
    subtasks: SubtaskRepository(writer),
    capacity: capacity,
    projects: ProjectRepository(writer),
    labels: LabelRepository(writer),
    notes: NoteRepository(writer),
    areas: AreaRepository(writer),
    preferences: PreferencesRepository(db),
    workspace: workspace,
  );
});

/// How the app behaves on this device, as chosen in Settings.
final preferencesProvider = StreamProvider<Preferences>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.preferences.watch();
});

// --- navigation -------------------------------------------------------------

/// Where the sidebar is pointing.
sealed class Destination {
  const Destination();
}

/// The bento dashboard.
class TodayDestination extends Destination {
  const TodayDestination();
}

/// Everything with a due date in the next week.
class UpcomingDestination extends Destination {
  const UpcomingDestination();
}

/// Every open task, whatever list it is in.
class AllDestination extends Destination {
  const AllDestination();
}

class DoneDestination extends Destination {
  const DoneDestination();
}

/// The capacity ledger and timetable.
class CapacityDestination extends Destination {
  const CapacityDestination();
}

class SettingsDestination extends Destination {
  const SettingsDestination();
}

/// Quick notes.
class NotesDestination extends Destination {
  const NotesDestination();
}

/// A project. Sections live inside it rather than being navigated to directly — a
/// section is a column of a project, not a place.
class ProjectDestination extends Destination {
  const ProjectDestination(this.projectId);
  final String projectId;

  @override
  bool operator ==(Object other) =>
      other is ProjectDestination && other.projectId == projectId;

  @override
  int get hashCode => projectId.hashCode;
}

class SelectedDestination extends Notifier<Destination> {
  @override
  Destination build() => const TodayDestination();

  /// Where Settings was opened from, for going back to it.
  Destination _beforeSettings = const TodayDestination();

  void go(Destination destination) {
    if (destination is SettingsDestination && state is! SettingsDestination) {
      _beforeSettings = state;
    }
    state = destination;
  }

  /// Leaves Settings for wherever it was opened from.
  void leaveSettings() {
    if (state is SettingsDestination) state = _beforeSettings;
  }
}

final destinationProvider =
    NotifierProvider<SelectedDestination, Destination>(SelectedDestination.new);

// --- data -------------------------------------------------------------------

final projectsProvider = StreamProvider<List<Board>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.projects.watchProjects(scope.workspace.id);
});

final areasProvider = StreamProvider<List<Area>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.areas.watchAll(scope.workspace.id);
});

/// The areas the sidebar shows closed on this device.
final collapsedAreasProvider = StreamProvider<Set<String>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.preferences.watchCollapsedAreas();
});

/// Every section in the workspace, so task rows can name their column without a
/// query each.
final allSectionsProvider = StreamProvider<List<BoardList>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.workspaces.watchLists(scope.workspace.id);
});

/// The project currently open, if any.
final currentProjectIdProvider = Provider<String?>((ref) {
  final d = ref.watch(destinationProvider);
  return d is ProjectDestination ? d.projectId : null;
});

final currentProjectProvider = Provider<Board?>((ref) {
  final id = ref.watch(currentProjectIdProvider);
  if (id == null) return null;
  for (final p in ref.watch(projectsProvider).value ?? const <Board>[]) {
    if (p.id == id) return p;
  }
  return null;
});

final sectionsProvider = StreamProvider.family<List<BoardList>, String>((
  ref,
  projectId,
) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.projects.watchSections(projectId);
});

final fieldsProvider = StreamProvider.family<List<FieldDef>, String>((
  ref,
  projectId,
) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.projects.watchFields(projectId);
});

/// task id -> field id -> raw value.
final fieldValuesProvider =
    StreamProvider.family<Map<String, Map<String, String?>>, String>((
  ref,
  projectId,
) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.projects.watchFieldValues(projectId);
});

/// Which view a project is being shown in. Remembered per project for the session.
class ProjectViewMode extends Notifier<Map<String, BoardView>> {
  @override
  Map<String, BoardView> build() => {};

  void set(String projectId, BoardView view) =>
      state = {...state, projectId: view};
}

final projectViewModeProvider =
    NotifierProvider<ProjectViewMode, Map<String, BoardView>>(
  ProjectViewMode.new,
);

/// Every live task in the workspace. The smart views and the dashboard all derive from
/// this one stream rather than each running their own query.
final allTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.tasks.watchAll(scope.workspace.id);
});

/// Dashboard figures. Pure derivation, so every number on screen is traceable.
final statsProvider = Provider<TaskStats?>((ref) {
  final tasks = ref.watch(allTasksProvider).value;
  if (tasks == null) return null;
  return TaskStats.from(tasks, DateTime.now());
});

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

/// Tasks for the current destination, or search results when a query is active.
final visibleTasksProvider = Provider<List<Task>>((ref) {
  final all = ref.watch(allTasksProvider).value ?? const <Task>[];
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (query.isNotEmpty) {
    return all
        .where(
          (t) =>
              t.title.toLowerCase().contains(query) ||
              (t.notesMd?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);

  return switch (ref.watch(destinationProvider)) {
    TodayDestination() ||
    CapacityDestination() ||
    NotesDestination() ||
    SettingsDestination() => const <Task>[],
    DoneDestination() =>
      all.where((t) => t.status == TaskStatus.done).toList(),
    AllDestination() => all.where((t) => t.status != TaskStatus.done).toList(),
    UpcomingDestination() => all.where((t) {
      if (t.status == TaskStatus.done) return false;
      final due = TaskStats.dueDayOf(t);
      if (due == null) return false;
      return !due.isBefore(startOfToday) &&
          due.isBefore(startOfToday.add(const Duration(days: 8)));
    }).toList(),
    ProjectDestination(:final projectId) => _tasksInProject(ref, all, projectId),
  };
});

List<Task> _tasksInProject(Ref ref, List<Task> all, String projectId) {
  final sections = ref
      .watch(sectionsProvider(projectId))
      .value
      ?.map((s) => s.id)
      .toSet();
  if (sections == null) return const [];
  return all.where((t) => sections.contains(t.listId)).toList();
}

/// The project new tasks land in.
///
/// Inside a project, that project. From a smart view there is no project in context, so
/// capture goes to the project chosen in Settings, or else the first — the composer always
/// shows which, and lets you change it.
final captureProjectIdProvider = Provider<String?>((ref) {
  if (ref.watch(currentProjectIdProvider) case final open?) return open;
  final projects = ref.watch(projectsProvider).value ?? const <Board>[];
  final chosen = ref.watch(preferencesProvider).value?.captureProjectId;
  if (chosen != null && projects.any((p) => p.id == chosen)) return chosen;
  return projects.firstOrNull?.id;
});

/// The section new tasks land in: the first of [captureProjectIdProvider]'s.
final captureListIdProvider = Provider<String?>((ref) {
  final projectId = ref.watch(captureProjectIdProvider);
  if (projectId == null) return null;

  final sections = ref.watch(sectionsProvider(projectId)).value;
  return (sections == null || sections.isEmpty) ? null : sections.first.id;
});

/// The task whose detail sheet is open, if any.
class OpenTask extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String taskId) => state = taskId;
  void close() => state = null;
}

final openTaskProvider = NotifierProvider<OpenTask, String?>(OpenTask.new);

/// Live view of the task the sheet is showing, so edits reflect immediately.
final openTaskDetailProvider = StreamProvider<Task?>((ref) async* {
  final id = ref.watch(openTaskProvider);
  if (id == null) {
    yield null;
    return;
  }
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.tasks.watchTask(id);
});

final subtasksProvider = StreamProvider.family<List<Subtask>, String>((
  ref,
  taskId,
) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.subtasks.watchFor(taskId);
});

// --- capacity ---------------------------------------------------------------

/// How far ahead the scheduler plans. Beyond this a deadline is too distant for the
/// arithmetic to say anything useful.
const capacityHorizonDays = 28;

final capacityProfileProvider = StreamProvider<CapacityProfile?>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.capacity.watchProfile(scope.workspace.id);
});

final commitmentsProvider = StreamProvider<List<Commitment>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.capacity.watchCommitments(scope.workspace.id);
});

/// Named timetable sets — one per semester, placement, or holiday pattern.
final schedulesProvider = StreamProvider<List<TimetableSet>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.capacity.watchSchedules(scope.workspace.id);
});

/// The day-resolving timetable. Which set applies can change partway through the
/// horizon, which is exactly why this exists rather than one flat block list.
final timetableProvider = Provider<tt.Timetable>((ref) {
  final sets = ref.watch(schedulesProvider).value ?? const <TimetableSet>[];
  final commitments = ref.watch(commitmentsProvider).value ?? const [];
  return CapacityMapping.timetable(sets, commitments);
});

/// The set governing today, for the UI to name.
final activeScheduleProvider = Provider<tt.ScheduleWindow?>((ref) {
  return ref.watch(timetableProvider).windowFor(DateTime.now());
});

/// Per-day capacity across the horizon. Pure derivation from profile + timetable.
final dayCapacityProvider = Provider<List<DayCapacity>>((ref) {
  final profile = ref.watch(capacityProfileProvider).value;

  return CapacityLedger.forRange(
    DateTime.now(),
    capacityHorizonDays,
    CapacityMapping.settings(profile),
    ref.watch(timetableProvider),
  );
});

/// What each capacity setting does to the figures, for the profile to explain itself with.
final settingEffectsProvider = Provider<SettingEffects>((ref) {
  return SettingEffects.of(
    CapacityMapping.settings(ref.watch(capacityProfileProvider).value),
    ref.watch(timetableProvider),
    DateTime.now(),
  );
});

/// Commitments whose recurrence could not be read. Surfaced rather than swallowed.
final rejectedCommitmentsProvider = Provider<List<String>>((ref) {
  final commitments = ref.watch(commitmentsProvider).value ?? const [];
  final (_, rejected) = CapacityMapping.blocksOf(commitments);
  return rejected;
});

/// Open, dated tasks in the form the scheduler understands.
///
/// Shared by the live schedule and by the at-capture preview, so a warning shown before
/// you commit is computed exactly the same way as the badge shown afterwards.
final plannedTasksProvider = Provider<List<PlannedTask>>((ref) {
  final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);

  final planned = <PlannedTask>[];
  for (final task in tasks) {
    if (task.status == TaskStatus.done) continue;
    final due = TaskStats.dueDayOf(task);
    // A task given a time counts on its day, deadline or not.
    final day = TaskSlots.plannedDayOf(task);
    if (due == null && day == null) continue;

    // Beyond the horizon the arithmetic cannot say anything honest, so it says nothing.
    if (day == null && due!.difference(startOfToday).inDays > capacityHorizonDays) continue;

    planned.add(
      PlannedTask(
        id: task.id,
        title: task.title,
        dueDay: due,
        plannedDay: day,
        // With a time, the time's own length; without, the scheduler's assumption.
        estimateMin:
            task.estimateMin ??
            (day == null ? CapacityScheduler.assumedEstimateMin : TaskSlots.defaultLengthMin),
        priority: task.priority,
        estimateAssumed: task.estimateMin == null,
      ),
    );
  }
  return planned;
});

/// The tasks given a time on a day, as that day's timeline draws them.
final taskSlotsProvider = Provider.family<List<TaskSlot>, DateTime>((ref, day) {
  return TaskSlots.on(day, ref.watch(allTasksProvider).value ?? const <Task>[]);
});

/// The plan: what fits, what does not, and how each day is loaded.
final scheduleProvider = Provider<Schedule>((ref) {
  return CapacityScheduler.run(
    ref.watch(plannedTasksProvider),
    ref.watch(dayCapacityProvider),
  );
});

/// What would happen if [candidate] were added.
///
/// Runs before the write, so the app can say "this does not fit" at the moment you commit
/// rather than after — which is the entire difference between an advisor and a report.
/// Returns null when the candidate carries no deadline for the arithmetic to work against.
ScheduledTask? previewFeasibility(WidgetRef ref, PlannedTask candidate) {
  final schedule = CapacityScheduler.run(
    [...ref.read(plannedTasksProvider), candidate],
    ref.read(dayCapacityProvider),
  );
  for (final t in schedule.tasks) {
    if (t.task.id == candidate.id) return t;
  }
  return null;
}

/// Feasibility for one task, for the row and the detail sheet.
final taskFeasibilityProvider = Provider.family<ScheduledTask?, String>((
  ref,
  taskId,
) {
  final schedule = ref.watch(scheduleProvider);
  for (final t in schedule.tasks) {
    if (t.task.id == taskId) return t;
  }
  return null;
});

/// Whether the task composer is open.
class ComposerOpen extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

final composerOpenProvider = NotifierProvider<ComposerOpen, bool>(
  ComposerOpen.new,
);

/// Whether the new-project sheet is open.
class NewProjectOpen extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

final newProjectOpenProvider = NotifierProvider<NewProjectOpen, bool>(
  NewProjectOpen.new,
);

// --- notes ------------------------------------------------------------------

/// Every live note, pinned first, then the most recently written.
final notesProvider = StreamProvider<List<Note>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.notes.watchAll(scope.workspace.id);
});

/// The note open in the editor: one already written, or a new one that has no row until
/// something is typed into it.
class NoteEditing {
  const NoteEditing(this.serial, {this.note});

  /// Tells one opening from the next, so a new note asked for while one is open starts
  /// afresh.
  final int serial;

  /// The note as it was when opened. Null for a new one.
  final Note? note;
}

class OpenNote extends Notifier<NoteEditing?> {
  int _serial = 0;

  @override
  NoteEditing? build() => null;

  void edit(Note note) => state = NoteEditing(++_serial, note: note);
  void create() => state = NoteEditing(++_serial);
  void close() => state = null;
}

final openNoteProvider = NotifierProvider<OpenNote, NoteEditing?>(OpenNote.new);

// --- labels -----------------------------------------------------------------

final labelsProvider = StreamProvider<List<Label>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.labels.watchAll(scope.workspace.id);
});

/// task id -> label ids.
final labelAssignmentsProvider = StreamProvider<Map<String, Set<String>>>((
  ref,
) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.labels.watchAssignments(scope.workspace.id);
});

/// Labels on one task, resolved to rows so widgets get names and colours directly.
final labelsForTaskProvider = Provider.family<List<Label>, String>((
  ref,
  taskId,
) {
  final ids = ref.watch(labelAssignmentsProvider).value?[taskId] ?? const {};
  if (ids.isEmpty) return const [];
  final all = ref.watch(labelsProvider).value ?? const <Label>[];
  return all.where((l) => ids.contains(l.id)).toList();
});

// --- project filtering ------------------------------------------------------

/// Filters applied to the project currently open.
///
/// Held in memory rather than persisted: a filter is how you are looking right now, and
/// one that survived a restart would quietly hide work. Saved views are the deliberate
/// way to keep one.
class ProjectFilterState extends Notifier<ProjectFilter> {
  @override
  ProjectFilter build() => ProjectFilter.empty;

  void toggleLabel(String id) => state = state.copyWith(
    labelIds: state.labelIds.contains(id)
        ? (state.labelIds.toSet()..remove(id))
        : (state.labelIds.toSet()..add(id)),
  );

  void togglePriority(int p) => state = state.copyWith(
    priorities: state.priorities.contains(p)
        ? (state.priorities.toSet()..remove(p))
        : (state.priorities.toSet()..add(p)),
  );

  void setHideCompleted(bool v) => state = state.copyWith(hideCompleted: v);
  void setOnlyAtRisk(bool v) => state = state.copyWith(onlyAtRisk: v);
  void clear() => state = ProjectFilter.empty;

  /// Applies a saved view's filter wholesale.
  void replace(ProjectFilter filter) => state = filter;
}

final projectFilterProvider =
    NotifierProvider<ProjectFilterState, ProjectFilter>(ProjectFilterState.new);

/// The filter as it can actually be applied.
///
/// Label ids for labels that have since been deleted are dropped. Left in, they would
/// hide tasks with no visible cause — the chip is gone from the bar, so there would be
/// nothing to un-tick.
final effectiveProjectFilterProvider = Provider<ProjectFilter>((ref) {
  final filter = ref.watch(projectFilterProvider);
  if (filter.labelIds.isEmpty) return filter;
  final known = {
    for (final l in ref.watch(labelsProvider).value ?? const <Label>[]) l.id,
  };
  return filter.pruned(known);
});

/// Tasks for the open project after filters. Every view reads this, so a filter cannot
/// apply in one and not another.
final filteredProjectTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(visibleTasksProvider);
  final filter = ref.watch(effectiveProjectFilterProvider);
  if (filter.isEmpty) return tasks;

  final assignments = ref.watch(labelAssignmentsProvider).value ?? const {};
  final atRisk = {
    for (final s in ref.watch(scheduleProvider).impossible) s.task.id,
  };

  return tasks.where((t) {
    if (filter.hideCompleted && t.status == TaskStatus.done) return false;
    if (filter.onlyAtRisk && !atRisk.contains(t.id)) return false;
    if (filter.priorities.isNotEmpty &&
        !filter.priorities.contains(t.priority)) {
      return false;
    }
    if (filter.labelIds.isNotEmpty) {
      final own = assignments[t.id] ?? const <String>{};
      if (!filter.labelIds.any(own.contains)) return false;
    }
    return true;
  }).toList();
});

/// Which timetable set the Time budget screen is editing.
///
/// Defaults to whichever governs today, so you land on the one in force rather than
/// having to find it.
class EditingSchedule extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final editingScheduleProvider =
    NotifierProvider<EditingSchedule, String?>(EditingSchedule.new);

final editingScheduleIdProvider = Provider<String?>((ref) {
  final chosen = ref.watch(editingScheduleProvider);
  if (chosen != null) return chosen;
  final active = ref.watch(activeScheduleProvider);
  if (active != null) return active.id;
  return (ref.watch(schedulesProvider).value ?? const <TimetableSet>[])
      .firstOrNull
      ?.id;
});

/// Which project's settings sheet is open, if any.
class ProjectSettingsOpen extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String projectId) => state = projectId;
  void close() => state = null;
}

final projectSettingsOpenProvider =
    NotifierProvider<ProjectSettingsOpen, String?>(ProjectSettingsOpen.new);

// --- saved views ------------------------------------------------------------

final projectViewsProvider =
    StreamProvider.family<List<ProjectView>, String>((ref, projectId) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.projects.watchViews(projectId);
});

/// The saved view matching the current kind and filter exactly, if any.
///
/// Compared rather than remembered by id, so nudging a filter shows the view as no
/// longer selected instead of claiming you are still in it.
final matchingSavedViewProvider = Provider.family<ProjectView?, String>((
  ref,
  projectId,
) {
  final views = ref.watch(projectViewsProvider(projectId)).value ?? const [];
  final filter = ref.watch(projectFilterProvider);
  final kind = ref.watch(projectViewModeProvider)[projectId];

  for (final view in views) {
    if (ProjectFilter.decode(view.filterJson) != filter) continue;
    if (kind != null && _kindOf(view.kind) != kind) continue;
    return view;
  }
  return null;
});

BoardView _kindOf(ViewKind kind) => switch (kind) {
  ViewKind.board => BoardView.board,
  ViewKind.list => BoardView.list,
  ViewKind.calendar => BoardView.calendar,
  ViewKind.timeline => BoardView.timeline,
};

ViewKind viewKindOf(BoardView view) => switch (view) {
  BoardView.board => ViewKind.board,
  BoardView.list => ViewKind.list,
  BoardView.calendar => ViewKind.calendar,
  BoardView.timeline => ViewKind.timeline,
};

BoardView boardViewOf(ViewKind kind) => _kindOf(kind);
