import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repository/task_repository.dart';
import '../data/repository/workspace_repository.dart';

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

/// Lists in the workspace.
final listsProvider = StreamProvider<List<BoardList>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  yield* scope.workspaces.watchLists(scope.workspace.id);
});

/// Which list the main view is showing. Null means "first available".
class SelectedList extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? listId) => state = listId;
}

final selectedListProvider = NotifierProvider<SelectedList, String?>(
  SelectedList.new,
);

/// The list actually being shown, resolving the null default to the first list.
final activeListIdProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedListProvider);
  if (selected != null) return selected;
  final lists = ref.watch(listsProvider).value;
  return (lists == null || lists.isEmpty) ? null : lists.first.id;
});

/// Tasks in the active list, or search results when a query is active.
final visibleTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final scope = await ref.watch(appScopeProvider.future);
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isNotEmpty) {
    yield* scope.tasks.search(query);
    return;
  }

  final listId = ref.watch(activeListIdProvider);
  if (listId == null) {
    yield const [];
    return;
  }
  yield* scope.tasks.watchList(listId);
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
