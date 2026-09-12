import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../glass/glass_surface.dart';
import '../widgets/quick_add.dart';
import '../widgets/task_row.dart';
import '../widgets/undo_toast.dart';

/// Width at which the list sidebar earns its space.
const _sidebarBreakpoint = 900.0;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider);

    return scope.when(
      loading: () => const _Centered(child: Text('', style: AppText.body)),
      error: (e, _) => _Centered(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          child: Text(
            "The local database didn't open.\n\n$e",
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (_) => const _Layout(),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}

class _Layout extends ConsumerWidget {
  const _Layout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _sidebarBreakpoint;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide) ...[
                    const SizedBox(width: 240, child: _Sidebar()),
                    const SizedBox(width: AppSpace.xl),
                  ],
                  const Expanded(child: _TaskPanel()),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpace.xxxl,
              child: const Center(child: UndoToast()),
            ),
          ],
        );
      },
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(listsProvider);
    final activeId = ref.watch(activeListIdProvider);

    return GlassSurface.onBackdrop(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpace.md,
              bottom: AppSpace.lg,
            ),
            child: Text('Lists', style: AppText.tiny),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final list in lists.value ?? const <BoardList>[])
                  _SidebarItem(
                    label: list.name,
                    selected: list.id == activeId,
                    onTap: () =>
                        ref.read(selectedListProvider.notifier).select(list.id),
                  ),
              ],
            ),
          ),
          _SidebarItem(
            label: '+  New list',
            selected: false,
            onTap: () => _createList(ref),
          ),
        ],
      ),
    );
  }

  Future<void> _createList(WidgetRef ref) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    final boards = await scope.db.select(scope.db.boards).get();
    if (boards.isEmpty) return;

    final created = await scope.workspaces.createList(
      workspaceId: scope.workspace.id,
      boardId: boards.first.id,
      name: 'New list',
    );
    ref.read(selectedListProvider.notifier).select(created.id);
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppGlass.flatFill : null,
          borderRadius: AppRadius.controlAll,
        ),
        child: Text(
          label,
          style: AppText.body.copyWith(
            color: selected ? AppColour.text : AppColour.textDim,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TaskPanel extends ConsumerWidget {
  const _TaskPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(visibleTasksProvider);
    final query = ref.watch(searchQueryProvider);
    final lists = ref.watch(listsProvider).value ?? const <BoardList>[];
    final activeId = ref.watch(activeListIdProvider);

    final listName = lists
        .where((l) => l.id == activeId)
        .map((l) => l.name)
        .firstOrNull;

    return GlassSurface.onBackdrop(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  query.isNotEmpty ? 'Search' : (listName ?? 'Tasks'),
                  style: AppText.title,
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              const SizedBox(width: 260, child: _SearchField()),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Expanded(
            child: switch (tasks) {
              AsyncError(:final error) => Text('$error', style: AppText.body),
              AsyncData(:final value) when value.isEmpty => _EmptyState(
                searching: query.isNotEmpty,
                query: query,
                listName: listName,
              ),
              AsyncData(:final value) => _TaskList(tasks: value),
              _ => const SizedBox.shrink(),
            },
          ),
          const SizedBox(height: AppSpace.lg),
          const QuickAdd(),
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    if (scope == null) return const SizedBox.shrink();

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
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

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppGlass.flatFill,
        borderRadius: AppRadius.controlAll,
        border: Border.all(color: AppGlass.edge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        child: TextField(
          controller: _controller,
          style: AppText.small.copyWith(color: AppColour.text),
          cursorColor: AppColour.accent,
          onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            hintText: 'Search tasks and notes',
            hintStyle: AppText.small,
          ),
        ),
      ),
    );
  }
}

/// Empty states say what to do next, never "Nothing here yet".
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.searching,
    required this.query,
    required this.listName,
  });

  final bool searching;
  final String query;
  final String? listName;

  @override
  Widget build(BuildContext context) {
    final message = searching
        ? 'Nothing matches "$query". Try a shorter word.'
        : 'No tasks in ${listName ?? 'this list'} yet.\n'
              'Type one below — dates and flags are parsed as you go.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxxl),
        child: Text(
          message,
          style: AppText.body.copyWith(color: AppColour.textDim),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
