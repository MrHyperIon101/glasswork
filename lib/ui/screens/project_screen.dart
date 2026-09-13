import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../motion.dart';
import '../surface.dart';
import '../widgets/board_view.dart';
import '../widgets/calendar_view.dart';
import '../widgets/content_header.dart';
import '../widgets/confirm_dialog.dart';
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: project.name,
            subtitle: project.purpose ?? '${sections.length} sections',
            onMenu: onMenu,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewSwitcher(projectId: projectId, current: view),
                const SizedBox(width: AppSpace.sm),
                _SettingsButton(projectId: projectId),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _ProjectPulse(projectId: projectId, tasks: tasks),
          const SizedBox(height: AppSpace.lg),
          SavedViewsBar(projectId: projectId),
          const FilterBar(),
          const SizedBox(height: AppSpace.lg),
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
                  ClipRRect(
                    borderRadius: AppRadius.roundAll,
                    child: SizedBox(
                      height: 5,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: ColoredBox(color: AppColour.fill),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: AnimatedContainer(
                              duration: AppMotion.medium,
                              curve: AppMotion.standard,
                              decoration: const BoxDecoration(
                                color: AppColour.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.tint,
    this.note,
  });

  final String label;
  final String value;
  final Color? tint;
  final String? note;

  @override
  Widget build(BuildContext context) => Column(
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
  Widget build(BuildContext context) => MouseRegion(
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
        width: AppSize.control,
        height: AppSize.control,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _hovered ? AppColour.fill : null,
          borderRadius: AppRadius.mediumAll,
        ),
        child: const Icon(
          Icons.tune,
          size: 17,
          color: AppColour.labelSecondary,
        ),
      ),
    ),
  );
}

class _ViewSwitcher extends ConsumerWidget {
  const _ViewSwitcher({required this.projectId, required this.current});

  final String projectId;
  final BoardView current;

  static const _options = [
    (BoardView.board, Icons.view_kanban_outlined, 'Board'),
    (BoardView.list, Icons.format_list_bulleted, 'List'),
    (BoardView.calendar, Icons.calendar_month_outlined, 'Calendar'),
    (BoardView.timeline, Icons.timeline, 'Timeline'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppSize.control,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColour.fill,
        borderRadius: AppRadius.mediumAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (view, icon, label) in _options)
            GestureDetector(
              onTap: () {
                ref.read(projectViewModeProvider.notifier).set(projectId, view);
                // Persisted, so a project opens the way you last left it rather
                // than resetting every launch.
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  decoration: BoxDecoration(
                    color: view == current ? AppColour.elevated : null,
                    borderRadius: AppRadius.smallAll,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: view == current
                            ? AppColour.label
                            : AppColour.labelTertiary,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        label,
                        style: AppText.numeric.copyWith(
                          color: view == current
                              ? AppColour.label
                              : AppColour.labelTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// List view, grouped by section with headers.
class _SectionedList extends ConsumerWidget {
  const _SectionedList({required this.projectId, required this.tasks});

  final String projectId;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final sections = ref.watch(sectionsProvider(projectId)).value ?? const [];
    if (scope == null) return const SizedBox.shrink();

    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      child: ListView(
        children: [
          for (final section in sections) ...[
            _SectionHeader(
              section: section,
              count: tasks.where((t) => t.listId == section.id).length,
            ),
            for (final task in tasks.where((t) => t.listId == section.id))
              FadeSlideIn(
                key: ValueKey(task.id),
                child: TaskRow(
                  task: task,
                  onToggle: () => scope.tasks.setDone(
                    task.id,
                    done: task.status != TaskStatus.done,
                  ),
                  onTap: () =>
                      ref.read(openTaskProvider.notifier).open(task.id),
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
              ),
            if (tasks.where((t) => t.listId == section.id).isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.xs,
                  AppSpace.md,
                  AppSpace.md,
                ),
                child: Text(
                  'Nothing in ${section.name.toLowerCase()}',
                  style: AppText.footnote.copyWith(
                    color: AppColour.labelQuaternary,
                  ),
                ),
              ),
          ],

          // Sections were only addable from the board. The same project cannot have
          // different capabilities depending on which view you happen to be in.
          _AddSectionRow(projectId: projectId),
        ],
      ),
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
              Text(section.name.toUpperCase(), style: AppText.caption),
              const SizedBox(width: AppSpace.sm),
              Text(
                '${widget.count}',
                style: AppText.numeric.copyWith(
                  color: AppColour.labelQuaternary,
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                duration: AppMotion.quick,
                opacity: _hovered ? 1 : 0,
                child: Row(
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
                const Icon(Icons.add, size: 15, color: AppColour.labelTertiary),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        child: Text(
          label,
          style: AppText.numeric.copyWith(color: tint ?? AppColour.accent),
        ),
      ),
    ),
  );
}
