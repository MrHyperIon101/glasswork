import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/completed.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/task_order.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../motion.dart';
import '../surface.dart';
import '../task_actions.dart';
import '../widgets/board_view.dart';
import '../widgets/calendar_view.dart';
import '../widgets/completed_group.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/content_header.dart';
import '../widgets/filter_bar.dart';
import '../widgets/saved_views_bar.dart';
import '../widgets/task_row.dart';
import '../widgets/timeline_view.dart';

/// One project: its own dashboard, its own views, its own sections.
///
/// A project-scoped dashboard rather than only a global one, because "am I on top of
/// this project" and "am I on top of today" are different questions and the second one
/// hides the first.
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({required this.projectId, this.onMenu, super.key});

  final String projectId;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    final tasks = ref.watch(filteredProjectTasksProvider);
    final sections = ref.watch(sectionsProvider(projectId)).value ?? const [];

    final view =
        ref.watch(projectViewModeProvider)[projectId] ??
        project?.viewDefault ??
        BoardView.board;

    if (project == null) {
      return const Center(
        child: Text('This project is gone.', style: AppText.body),
      );
    }

    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpace.sm : AppSpace.xl,
        gutter,
        compact ? AppSpace.md : AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: project.name,
            subtitle: project.purpose ?? '${sections.length} sections',
            onMenu: onMenu,
            dense: true,
            // On a phone the switcher shares a line with the filter instead, lower down,
            // so the header costs no more height than it has to.
            accessory: compact
                ? null
                : _ViewSwitcher(projectId: projectId, current: view),
            actions: [_SettingsButton(projectId: projectId)],
          ),
          SizedBox(height: compact ? AppSpace.md : AppSpace.lg),
          _ProjectPulse(projectId: projectId, tasks: tasks),
          SizedBox(height: compact ? AppSpace.md : AppSpace.lg),
          SavedViewsBar(projectId: projectId),
          FilterBar(
            leading: compact
                ? _ViewSwitcher(
                    projectId: projectId,
                    current: view,
                    expand: true,
                  )
                : null,
          ),
          SizedBox(height: compact ? AppSpace.md : AppSpace.lg),
          Expanded(
            child: switch (view) {
              BoardView.board => BoardKanban(projectId: projectId),
              BoardView.calendar => CalendarView(projectId: projectId),
              BoardView.timeline => TimelineView(projectId: projectId),
              BoardView.list => _SectionedList(
                projectId: projectId,
                tasks: tasks,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// The project's own numbers. Scoped to this project, derived, nothing invented.
class _ProjectPulse extends ConsumerWidget {
  const _ProjectPulse({required this.projectId, required this.tasks});

  final String projectId;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final open = tasks.where((t) => t.status != TaskStatus.done).toList();
    final done = tasks.length - open.length;

    var overdue = 0;
    var estimate = 0;
    var untimed = 0;
    for (final t in open) {
      final due = TaskStats.dueDayOf(t);
      if (due != null && due.isBefore(today)) overdue++;
      if (t.estimateMin case final m?) {
        estimate += m;
      } else {
        untimed++;
      }
    }

    final ids = open.map((t) => t.id).toSet();
    final atRisk = schedule.impossible
        .where((s) => ids.contains(s.task.id))
        .length;

    final progress = tasks.isEmpty ? null : done / tasks.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoint.compact) {
          return _compact(
            open: open.length,
            overdue: overdue,
            atRisk: atRisk,
            estimate: estimate,
            untimed: untimed,
            done: done,
            progress: progress,
          );
        }

        return AppSurface(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.lg,
          ),
          child: Row(
            children: [
              _Stat(label: 'Open', value: '${open.length}'),
              _Divider(),
              _Stat(
                label: 'Overdue',
                value: '$overdue',
                tint: overdue > 0 ? AppColour.red : null,
              ),
              _Divider(),
              _Stat(
                label: "Won't fit",
                value: '$atRisk',
                tint: atRisk > 0 ? AppColour.red : null,
              ),
              _Divider(),
              _Stat(
                label: 'Work left',
                value: estimate == 0 ? '—' : Format.estimate(estimate),
                // A total that ignored unestimated tasks would be a lie by omission.
                note: untimed > 0 ? '+$untimed untimed' : null,
              ),
              const Spacer(),
              if (progress != null)
                SizedBox(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$done of ${tasks.length} done',
                        style: AppText.numeric,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      _Progress(value: progress),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The same figures in four narrow columns, for a phone. Run together as a sentence,
  /// they wrapped wherever the width ran out and parted a figure from what it counts.
  Widget _compact({
    required int open,
    required int overdue,
    required int atRisk,
    required int estimate,
    required int untimed,
    required int done,
    required double? progress,
  }) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(label: 'Open', value: '$open', compact: true),
              ),
              Expanded(
                child: _Stat(
                  label: 'Overdue',
                  value: '$overdue',
                  tint: overdue > 0 ? AppColour.red : null,
                  compact: true,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: "Won't fit",
                  value: '$atRisk',
                  tint: atRisk > 0 ? AppColour.red : null,
                  compact: true,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Work left',
                  value: estimate == 0 ? '—' : Format.estimate(estimate),
                  note: untimed > 0 ? '+$untimed untimed' : null,
                  compact: true,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(child: _Progress(value: progress)),
                const SizedBox(width: AppSpace.md),
                Text('$done of ${tasks.length} done', style: AppText.numeric),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.roundAll,
    child: SizedBox(
      height: 5,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColour.fill)),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              decoration: const BoxDecoration(color: AppColour.green),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.tint,
    this.note,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color? tint;
  final String? note;

  /// Sized for a column a quarter of a phone wide: a smaller figure that shrinks rather
  /// than spill out of its column, and the note under it instead of beside it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppText.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.title3.copyWith(color: tint ?? AppColour.label),
            ),
          ),
          if (note case final n?)
            Text(
              n,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.numeric.copyWith(color: AppColour.labelQuaternary),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppText.title.copyWith(color: tint ?? AppColour.label),
            ),
            if (note case final n?) ...[
              const SizedBox(width: AppSpace.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  n,
                  style: AppText.numeric.copyWith(
                    color: AppColour.labelQuaternary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5,
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
    color: AppColour.separator,
  );
}

class _SettingsButton extends ConsumerStatefulWidget {
  const _SettingsButton({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends ConsumerState<_SettingsButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = AppLayout.touch ? AppSize.touch : AppSize.control;

    return Tooltip(
      message: 'Project settings',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => ref
              .read(projectSettingsOpenProvider.notifier)
              .open(widget.projectId),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppMotion.quick,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColour.fill : null,
              borderRadius: AppRadius.mediumAll,
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 17,
              color: AppColour.labelSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewSwitcher extends ConsumerWidget {
  const _ViewSwitcher({
    required this.projectId,
    required this.current,
    this.expand = false,
  });

  final String projectId;
  final BoardView current;

  /// Fills the width with equal segments showing names only, as on a phone, where the
  /// room is for the names or the icons and names say more.
  final bool expand;

  static const _options = [
    (BoardView.board, Icons.view_kanban_outlined, 'Board'),
    (BoardView.list, Icons.format_list_bulleted_rounded, 'List'),
    (BoardView.calendar, Icons.calendar_month_outlined, 'Calendar'),
    (BoardView.timeline, Icons.timeline_rounded, 'Timeline'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget segment(BoardView view, IconData icon, String label) {
      final selected = view == current;
      final colour = selected ? AppColour.label : AppColour.labelTertiary;
      final name = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.numeric.copyWith(color: colour),
      );

      return GestureDetector(
        onTap: () {
          ref.read(projectViewModeProvider.notifier).set(projectId, view);
          // Persisted, so a project opens the way you last left it rather than
          // resetting every launch.
          ref
              .read(appScopeProvider)
              .value
              ?.projects
              .updateProject(projectId, viewDefault: view);
        },
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: AppMotion.quick,
            curve: AppMotion.standard,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: expand ? AppSpace.xs : AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColour.elevated : null,
              borderRadius: AppRadius.smallAll,
            ),
            child: expand
                ? name
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: colour),
                      const SizedBox(width: AppSpace.xs),
                      name,
                    ],
                  ),
          ),
        ),
      );
    }

    return Container(
      height: AppSize.control,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColour.fill,
        borderRadius: AppRadius.mediumAll,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final (view, icon, label) in _options)
            if (expand)
              Expanded(child: segment(view, icon, label))
            else
              segment(view, icon, label),
        ],
      ),
    );
  }
}

/// List view, grouped by section with headers, and finished work folded in under one of
/// its own.
///
/// A section shows the work still open in it. Completed tasks are not taken out of their
/// section — the row is untouched — they are simply drawn under Completed until they are
/// reopened, which is what puts them straight back where they were.
class _SectionedList extends ConsumerWidget {
  const _SectionedList({required this.projectId, required this.tasks});

  final String projectId;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final sections = ref.watch(sectionsProvider(projectId)).value ?? const [];
    if (scope == null) return const SizedBox.shrink();

    final completedSection = ref.watch(completedSectionProvider(projectId));
    final completed = TaskOrder.collected(
      ref.watch(effectiveProjectFilterProvider).sort,
      CompletedSection.done(tasks),
    );
    final folded = ref.watch(completedCollapsedProvider(projectId));

    Widget row(Task task) => TaskRow(
      task: task,
      onToggle: () =>
          setTaskDone(ref, task, done: task.status != TaskStatus.done),
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
    );

    Widget rows(List<Task> tasks) => AnimatedItems<Task>(
      items: tasks,
      keyOf: (task) => task.id,
      itemBuilder: (context, task) => row(task),
    );

    final children = <Widget>[];
    for (final section in sections) {
      final open = CompletedSection.openIn(tasks, section.id);
      // A section for finished work has nothing of its own to show once the work in it
      // is finished: Completed below is already that heading.
      if (section.id == completedSection?.id && open.isEmpty) continue;

      children
        ..add(_SectionHeader(section: section, count: open.length))
        ..add(rows(open));
      if (open.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.md,
            ),
            child: Text(
              'Nothing in ${section.name.toLowerCase()}',
              style: AppText.footnote.copyWith(color: AppColour.labelQuaternary),
            ),
          ),
        );
      }
    }

    if (completed.isNotEmpty) {
      children.add(CompletedHeader(ownerId: projectId, count: completed.length));
      if (!folded) children.add(rows(completed));
    }

    // Sections were only addable from the board. The same project cannot have
    // different capabilities depending on which view you happen to be in.
    children.add(_AddSectionRow(projectId: projectId));

    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      child: ListView(children: children),
    );
  }
}

/// A section heading with its own controls, so the list view is not a read-only
/// rendering of a board.
class _SectionHeader extends ConsumerStatefulWidget {
  const _SectionHeader({required this.section, required this.count});

  final BoardList section;
  final int count;

  @override
  ConsumerState<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends ConsumerState<_SectionHeader> {
  bool _hovered = false;
  bool _renaming = false;
  TextEditingController? _name;

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final scope = ref.watch(appScopeProvider).value;
    final sections =
        ref.watch(sectionsProvider(section.boardId)).value ?? const [];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.lg,
          AppSpace.md,
          AppSpace.xs,
        ),
        child: Row(
          children: [
            if (_renaming)
              Expanded(
                child: TextField(
                  controller: _name ??= TextEditingController(
                    text: section.name,
                  ),
                  autofocus: true,
                  style: AppText.caption.copyWith(color: AppColour.label),
                  cursorColor: AppColour.accent,
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      scope?.projects.renameSection(section.id, v.trim());
                    }
                    setState(() => _renaming = false);
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              )
            else ...[
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        section.name.toUpperCase(),
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      '${widget.count}',
                      style: AppText.numeric.copyWith(
                        color: AppColour.labelQuaternary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: AppMotion.quick,
                // Revealed on hover with a mouse. A touch screen has no hover, so there
                // they are simply shown.
                opacity: _hovered || AppLayout.touch ? 1 : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TinyAction(
                      label: 'Rename',
                      onTap: () => setState(() => _renaming = true),
                    ),
                    if (sections.length > 1)
                      _TinyAction(
                        label: 'Delete',
                        tint: AppColour.red,
                        onTap: () => _delete(section, sections),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BoardList section, List<BoardList> siblings) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    final count = await scope.projects.taskCountIn(section.id);
    if (!mounted) return;

    final ok = await confirm(
      context,
      title: 'Delete "${section.name}"?',
      detail: count == 0
          ? 'It has no tasks in it.'
          : '$count ${count == 1 ? 'task moves' : 'tasks move'} to the first '
                'remaining section. Nothing is lost.',
      confirmLabel: 'Delete section',
    );
    if (!ok) return;

    final deletion = await scope.projects.deleteSection(section.id);
    if (deletion == null) return;
    ref
        .read(undoProvider.notifier)
        .offer(
          'Deleted "${section.name}"',
          () => scope.projects.restoreSection(deletion),
        );
  }
}

class _AddSectionRow extends ConsumerWidget {
  const _AddSectionRow({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            final scope = ref.read(appScopeProvider).value;
            if (scope == null) return;
            await scope.projects.addSection(
              workspaceId: scope.workspace.id,
              boardId: projectId,
              name: 'New section',
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, size: 15, color: AppColour.labelTertiary),
                const SizedBox(width: AppSpace.sm),
                Text('Add section', style: AppText.footnote),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({required this.label, required this.onTap, this.tint});

  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppLayout.touch ? AppSpace.sm : 0,
        ),
        child: Text(
          label,
          style: AppText.numeric.copyWith(color: tint ?? AppColour.accent),
        ),
      ),
    ),
  );
}
