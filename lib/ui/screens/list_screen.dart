import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../surface.dart';
import '../widgets/content_header.dart';
import '../widgets/quick_add.dart';
import '../widgets/task_row.dart';

/// A flat task list: a specific list, a smart view, or search results.
class ListScreen extends ConsumerWidget {
  const ListScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(visibleTasksProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final destination = ref.watch(destinationProvider);
    final lists = ref.watch(listsProvider).value ?? const <BoardList>[];

    final title = switch (destination) {
      _ when query.isNotEmpty => 'Search',
      TodayDestination() => 'Today',
      UpcomingDestination() => 'Upcoming',
      AllDestination() => 'All tasks',
      DoneDestination() => 'Done',
      ListDestination(:final listId) =>
        lists.where((l) => l.id == listId).map((l) => l.name).firstOrNull ??
            'List',
    };

    final open = tasks.where((t) => t.status != TaskStatus.done).length;
    final subtitle = query.isNotEmpty
        ? '${tasks.length} ${tasks.length == 1 ? 'result' : 'results'}'
        : destination is DoneDestination
        ? '${tasks.length} completed'
        : '$open open';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(title: title, subtitle: subtitle, onMenu: onMenu),
          const SizedBox(height: AppSpace.xl),
          Expanded(
            child: AppSurface(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.md,
              ),
              child: tasks.isEmpty
                  ? _EmptyState(query: query, title: title)
                  : _Rows(tasks: tasks),
            ),
          ),
          if (destination is! DoneDestination) ...[
            const SizedBox(height: AppSpace.lg),
            const QuickAdd(),
          ],
        ],
      ),
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    if (scope == null) return const SizedBox.shrink();

    // Open work first, completed collapsed to the bottom — finishing something should
    // move it out of the way without making it vanish.
    final open = tasks.where((t) => t.status != TaskStatus.done).toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();
    final ordered = [...open, ...done];

    return ListView.builder(
      itemCount: ordered.length + (done.isEmpty || open.isEmpty ? 0 : 1),
      itemBuilder: (context, i) {
        // Divider between the open block and the done block.
        if (open.isNotEmpty && done.isNotEmpty && i == open.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.lg,
              AppSpace.md,
              AppSpace.sm,
            ),
            child: Text('Completed', style: AppText.caption),
          );
        }

        final index = open.isNotEmpty && done.isNotEmpty && i > open.length
            ? i - 1
            : i;
        final task = ordered[index];

        return TaskRow(
          key: ValueKey(task.id),
          task: task,
          onToggle: () => scope.tasks.setDone(
            task.id,
            done: task.status != TaskStatus.done,
          ),
          onTap: () {},
          onDelete: () async {
            await scope.tasks.softDelete(task.id);
            ref
                .read(undoProvider.notifier)
                .offer(
                  'Deleted "${task.title}"',
                  () => scope.tasks.restore(task.id),
                );
          },
        );
      },
    );
  }
}

/// Empty states say what to do next, never "Nothing here yet".
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.title});

  final String query;
  final String title;

  @override
  Widget build(BuildContext context) {
    final searching = query.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.inbox_outlined,
              size: 28,
              color: AppColour.labelQuaternary,
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              searching
                  ? 'Nothing matches "$query"'
                  : 'Nothing in $title yet',
              style: AppText.body.copyWith(color: AppColour.labelSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              searching
                  ? 'Try a shorter word, or check another list.'
                  : 'Type below — dates and flags are read as you go.',
              style: AppText.footnote,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
