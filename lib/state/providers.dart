import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/db/tables.dart';
import '../data/repository/task_repository.dart';
import '../data/repository/workspace_repository.dart';
import '../data/task_stats.dart';

/// Everything the app needs once the database is open and seeded.
///
/// Bundled into one object so the UI awaits exactly once, at the root, instead of every
/// screen juggling loading states for things that are ready in milliseconds.
class AppScope {
  const AppScope({
    required this.db,
    required this.workspaces,
    required this.tasks,
    required this.workspace,
  });

  final AppDatabase db;
  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final Workspace workspace;
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final appScopeProvider = FutureProvider<AppScope>((ref) async {
  final db = ref.watch(databaseProvider);
  final workspaces = WorkspaceRepository(db);

  final workspace = await workspaces.ensureSeeded();
  final clientId = await workspaces.clientId();

  return AppScope(
    db: db,
    workspaces: workspaces,
    tasks: TaskRepository(db, clientId: clientId),
    workspace: workspace,
  );
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

class ListDestination extends Destination {
  const ListDestination(this.listId);
  final String listId;

  @override
  bool operator ==(Object other) =>
      other is ListDestination && other.listId == listId;

  @override
  int get hashCode => listId.hashCode;
}

class SelectedDestination extends Notifier<Destination> {
  @override
  Destination build() => const TodayDestination();

  void go(Destination destination) => state = destination;
}

final destinationProvider =
    NotifierProvider<SelectedDestination, Destination>(SelectedDestination.new);

// --- data -------------------------------------------------------------------

final listsProvider = StreamProvider<List<BoardList>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.workspaces.watchLists(scope.workspace.id);
});

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
    TodayDestination() => const <Task>[],
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
    ListDestination(:final listId) => all
        .where((t) => t.listId == listId)
        .toList(),
  };
});

/// The list new tasks go into. Smart views have no list of their own, so capture falls
/// back to the first list — an inbox.
final captureListIdProvider = Provider<String?>((ref) {
  final destination = ref.watch(destinationProvider);
  if (destination is ListDestination) return destination.listId;
  final lists = ref.watch(listsProvider).value;
  return (lists == null || lists.isEmpty) ? null : lists.first.id;
});
