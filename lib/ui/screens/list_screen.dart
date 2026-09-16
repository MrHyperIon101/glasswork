import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';
import '../surface.dart';
import '../widgets/content_header.dart';
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
    final title = switch (destination) {
      _ when query.isNotEmpty => 'Search',
      TodayDestination() => 'Today',
      UpcomingDestination() => 'Next 7 days',
      AllDestination() => 'All open work',
      DoneDestination() => 'Completed',
      CapacityDestination() => 'Time budget',
      SettingsDestination() => 'Settings',
      NotesDestination() => 'Notes',
      ProjectDestination() => 'Project',
    };

    final open = tasks.where((t) => t.status != TaskStatus.done).length;
    final subtitle = query.isNotEmpty
        ? '${tasks.length} ${tasks.length == 1 ? 'result' : 'results'}'
        : destination is DoneDestination
        ? '${tasks.length} completed'
        : '$open open';

    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpace.sm : AppSpace.xl,
        gutter,
        compact ? AppSpace.md : AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: title,
            subtitle: subtitle,
            onMenu: onMenu,
            showNewTask: destination is! DoneDestination,
          ),
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

    // Manual order only means something inside a project. Smart views are queries, and
    // letting you drag rows there would imply an ordering the app cannot store.
    final reorderable =
        ref.watch(destinationProvider) is ProjectDestination &&
        ref.watch(searchQueryProvider).trim().isEmpty;

    Widget row(Task task) => FadeSlideIn(
      key: ValueKey(task.id),
      child: TaskRow(
      task: task,
      onToggle: () =>
          scope.tasks.setDone(task.id, done: task.status != TaskStatus.done),
      onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
      onDelete: () async {
        await scope.tasks.softDelete(task.id);
        ref
            .read(undoProvider.notifier)
            .offer(
              'Deleted "${task.title}"',
              () => scope.tasks.restore(task.id),
            );
      },
      ),
    );

    // onReorderItem hands back a newIndex already adjusted for the removed row, so no
    // off-by-one correction here.
    Future<void> onReorder(int oldIndex, int newIndex) async {
      if (newIndex == oldIndex) return;

      // Work on a copy to find the new neighbours, then write the single moved row.
      // Fractional indexing means exactly one row changes, whatever the distance.
      final after = [...open];
      final moved = after.removeAt(oldIndex);
      after.insert(newIndex, moved);

      await scope.tasks.moveBetween(
        moved.id,
        afterId: newIndex > 0 ? after[newIndex - 1].id : null,
        beforeId: newIndex < after.length - 1 ? after[newIndex + 1].id : null,
      );
    }

    return CustomScrollView(
      slivers: [
        if (reorderable)
          SliverReorderableList(
            itemCount: open.length,
            onReorderItem: onReorder,
            itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
              key: ValueKey(open[i].id),
              index: i,
              child: row(open[i]),
            ),
          )
        else
          SliverList.builder(
            itemCount: open.length,
            itemBuilder: (context, i) => row(open[i]),
          ),

        if (done.isNotEmpty && open.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.lg,
                AppSpace.md,
                AppSpace.sm,
              ),
              child: Text('Completed', style: AppText.caption),
            ),
          ),

        SliverList.builder(
          itemCount: done.length,
          itemBuilder: (context, i) => row(done[i]),
        ),
      ],
    );
  }
}

/// An empty list should hand you the action, not describe it.
class _AddFirstButton extends ConsumerStatefulWidget {
  const _AddFirstButton();

  @override
  ConsumerState<_AddFirstButton> createState() => _AddFirstButtonState();
}

class _AddFirstButtonState extends ConsumerState<_AddFirstButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => ref.read(composerOpenProvider.notifier).open(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.accent : AppColour.fill,
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 15,
                color: _hovered ? Colors.white : AppColour.accent,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'Add your first task',
                style: AppText.headline.copyWith(
                  color: _hovered ? Colors.white : AppColour.accent,
                ),
              ),
            ],
          ),
        ),
      ),
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
              searching ? Icons.search_off_rounded : Icons.inbox_outlined,
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
                  : 'Dates, priorities and estimates are read as you type.',
              style: AppText.footnote,
              textAlign: TextAlign.center,
            ),
            if (!searching) ...[
              const SizedBox(height: AppSpace.xl),
              const _AddFirstButton(),
            ],
          ],
        ),
      ),
    );
  }
}
