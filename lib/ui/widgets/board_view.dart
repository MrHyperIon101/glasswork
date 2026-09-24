import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/completed.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/task_order.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../motion.dart';
import '../task_actions.dart';
import 'completed_group.dart';
import 'task_chips.dart';

/// Kanban board for a project.
///
/// Columns are the project's sections — the same rows the list view groups by, not a
/// parallel concept. Dragging a card writes exactly one row: the section change and the
/// new fractional order key are a single update, so a cross-column move never loses the
/// task's identity, its steps or its history.
///
/// The last column is finished work, wherever it is filed: the section the project calls
/// Done, or one the board adds when it has none. Dropping a card there ticks it off and
/// dragging it out again reopens it, and because ticking moves nothing, a card reopened
/// anywhere else goes back to the section it always had.
class BoardKanban extends ConsumerWidget {
  const BoardKanban({required this.projectId, super.key});

  final String projectId;

  static const _columnWidth = 286.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(sectionsProvider(projectId)).value ?? const [];
    final tasks = ref.watch(filteredProjectTasksProvider);

    if (sections.isEmpty) {
      return Center(
        child: Text('This project has no sections yet.', style: AppText.body),
      );
    }

    final completedSection = ref.watch(completedSectionProvider(projectId));
    final completed = TaskOrder.collected(
      ref.watch(effectiveProjectFilterProvider).sort,
      CompletedSection.done(tasks),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Where a full-width column would fill the view, a column leaves the next one
        // showing at the edge, so it is plain there is more to swipe to.
        final width = (constraints.maxWidth - AppSpace.huge).clamp(
          0.0,
          _columnWidth,
        );

        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final section in sections)
              if (section.id != completedSection?.id)
                _Column(
                  projectId: projectId,
                  section: section,
                  width: width,
                  tasks: CompletedSection.openIn(tasks, section.id),
                ),
            _CompletedColumn(
              projectId: projectId,
              section: completedSection,
              width: width,
              // Anything open still filed under the section stays visible above the
              // finished work rather than disappearing with it.
              open: completedSection == null
                  ? const []
                  : CompletedSection.openIn(tasks, completedSection.id),
              completed: completed,
            ),
            const _AddSectionColumn(),
          ],
        );
      },
    );
  }
}

/// Finished work, drawn where a board expects it: the far end.
class _CompletedColumn extends ConsumerStatefulWidget {
  const _CompletedColumn({
    required this.projectId,
    required this.section,
    required this.width,
    required this.open,
    required this.completed,
  });

  final String projectId;

  /// The section the project files finished work under, where it has one. Without one
  /// this column belongs to no section, and dropping on it only ticks the card off.
  final BoardList? section;

  final double width;
  final List<Task> open;
  final List<Task> completed;

  @override
  ConsumerState<_CompletedColumn> createState() => _CompletedColumnState();
}

class _CompletedColumnState extends ConsumerState<_CompletedColumn> {
  bool _dragOver = false;

  /// Folded, the column keeps its place on the board but gives its width back to the
  /// work still open.
  static const _foldedWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final folded = ref.watch(completedCollapsedProvider(widget.projectId));

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) =>
          details.data.status != TaskStatus.done,
      onMove: (_) {
        if (!_dragOver) setState(() => _dragOver = true);
      },
      onLeave: (_) => setState(() => _dragOver = false),
      onAcceptWithDetails: (details) async {
        setState(() => _dragOver = false);
        await setTaskDone(ref, details.data, done: true);
      },
      builder: (context, candidate, rejected) => AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.quick),
        curve: AppMotion.standard,
        width: folded ? _foldedWidth : widget.width,
        margin: const EdgeInsets.only(right: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: _dragOver ? AppColour.fillStrong : AppColour.surface,
          borderRadius: AppRadius.largeAll,
          border: Border.all(
            color: _dragOver
                ? AppColour.green.withValues(alpha: 0.6)
                : const Color(0x00000000),
          ),
        ),
        child: folded
            ? _Folded(projectId: widget.projectId, count: widget.completed.length)
            : Column(
                children: [
                  CompletedHeader(
                    ownerId: widget.projectId,
                    count: widget.completed.length,
                    dense: true,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: AppSpace.xs),
                      children: [
                        for (final task in widget.open)
                          _CardSlot(
                            task: task,
                            section: widget.section!,
                            above: null,
                          ),
                        for (final task in widget.completed) _Card(task: task),
                        if (widget.open.isEmpty && widget.completed.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpace.lg),
                            child: Text(
                              'Drop here to tick it off',
                              textAlign: TextAlign.center,
                              style: AppText.footnote.copyWith(
                                color: AppColour.labelQuaternary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The folded column: its name on its side, and how much is in it.
class _Folded extends ConsumerWidget {
  const _Folded({required this.projectId, required this.count});

  final String projectId;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Pressable(
    onTap: () {
      final scope = ref.read(appScopeProvider).value;
      scope?.preferences.setCompletedCollapsed(projectId, collapsed: false);
    },
    child: Tooltip(
      message: 'Show completed',
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpace.sm),
            child: Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 16,
              color: AppColour.labelTertiary,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          AnimatedCount(count, style: AppText.numeric),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'Completed',
                textAlign: TextAlign.center,
                style: AppText.caption,
                overflow: TextOverflow.clip,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Column extends ConsumerStatefulWidget {
  const _Column({
    required this.projectId,
    required this.section,
    required this.width,
    required this.tasks,
  });

  final String projectId;
  final BoardList section;
  final double width;
  final List<Task> tasks;

  @override
  ConsumerState<_Column> createState() => _ColumnState();
}

class _ColumnState extends ConsumerState<_Column> {
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final open = widget.tasks
        .where((t) => t.status != TaskStatus.done)
        .toList();

    final limit = section.wipLimit;
    final overLimit = limit != null && open.length > limit;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        // Dropping into the column it already lives in is handled by the card-level
        // targets, which know where in the order it went — unless the card is finished,
        // where the drop means "pick this up again" and the section it names is the one
        // it never left.
        return details.data.listId != section.id ||
            details.data.status == TaskStatus.done;
      },
      onMove: (_) {
        if (!_dragOver) setState(() => _dragOver = true);
      },
      onLeave: (_) => setState(() => _dragOver = false),
      onAcceptWithDetails: (details) async {
        setState(() => _dragOver = false);
        final scope = ref.read(appScopeProvider).value;
        if (details.data.listId != section.id) {
          await scope?.tasks.moveToSection(details.data.id, section.id);
        }
        // Dragged out of the completed column, a card is being picked up again.
        if (details.data.status == TaskStatus.done) {
          await setTaskDone(ref, details.data, done: false);
        }
      },
      builder: (context, candidate, rejected) {
        return AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          width: widget.width,
          margin: const EdgeInsets.only(right: AppSpace.md),
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: _dragOver ? AppColour.fillStrong : AppColour.surface,
            borderRadius: AppRadius.largeAll,
            border: Border.all(
              color: _dragOver
                  ? AppColour.accent.withValues(alpha: 0.6)
                  : const Color(0x00000000),
            ),
          ),
          child: Column(
            children: [
              _ColumnHeader(
                section: section,
                count: open.length,
                overLimit: overLimit,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  children: [
                    for (final (i, task) in widget.tasks.indexed)
                      _CardSlot(
                        task: task,
                        section: section,
                        above: i == 0 ? null : widget.tasks[i - 1],
                      ),
                    if (widget.tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpace.lg),
                        child: Text(
                          'Drop here',
                          textAlign: TextAlign.center,
                          style: AppText.footnote.copyWith(
                            color: AppColour.labelQuaternary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _AddCardButton(
                projectId: widget.projectId,
                sectionId: section.id,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColumnHeader extends ConsumerWidget {
  const _ColumnHeader({
    required this.section,
    required this.count,
    required this.overLimit,
  });

  final BoardList section;
  final int count;
  final bool overLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              section.name,
              style: AppText.headline,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Over a WIP limit the count states the excess rather than only turning red:
          // "7" tells you nothing, "7 / 5" tells you to stop starting things.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: overLimit
                  ? AppColour.red.withValues(alpha: 0.18)
                  : AppColour.fill,
              borderRadius: AppRadius.smallAll,
            ),
            child: Text(
              section.wipLimit == null ? '$count' : '$count / ${section.wipLimit}',
              style: AppText.numeric.copyWith(
                color: overLimit ? AppColour.red : AppColour.labelSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card plus the drop zone immediately above it, so a drag can land in a precise
/// position rather than only at the end of a column.
class _CardSlot extends ConsumerStatefulWidget {
  const _CardSlot({
    required this.task,
    required this.section,
    required this.above,
  });

  final Task task;
  final BoardList section;

  /// The card above this one, which becomes the lower bound of the new order key.
  final Task? above;

  @override
  ConsumerState<_CardSlot> createState() => _CardSlotState();
}

class _CardSlotState extends ConsumerState<_CardSlot> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DragTarget<Task>(
          onWillAcceptWithDetails: (d) => d.data.id != widget.task.id,
          onMove: (_) {
            if (!_hovering) setState(() => _hovering = true);
          },
          onLeave: (_) => setState(() => _hovering = false),
          onAcceptWithDetails: (details) async {
            setState(() => _hovering = false);
            final scope = ref.read(appScopeProvider).value;
            await scope?.tasks.moveToSection(
              details.data.id,
              widget.section.id,
              afterId: widget.above?.id,
              beforeId: widget.task.id,
            );
            if (details.data.status == TaskStatus.done &&
                widget.task.status != TaskStatus.done) {
              await setTaskDone(ref, details.data, done: false);
            }
          },
          builder: (context, candidate, rejected) => AnimatedContainer(
            duration: AppMotion.quick,
            height: _hovering ? 34 : 6,
            margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            decoration: BoxDecoration(
              color: _hovering
                  ? AppColour.accent.withValues(alpha: 0.18)
                  : null,
              borderRadius: AppRadius.smallAll,
            ),
          ),
        ),
        _Card(task: widget.task),
      ],
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = _CardBody(task: task);

    return AdaptiveDraggable<Task>(
      data: task,
      feedback: Transform.translate(
        offset: const Offset(-130, -26),
        child: Opacity(
          opacity: 0.92,
          child: SizedBox(width: 262, child: _CardBody(task: task, lifted: true)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class _CardBody extends ConsumerStatefulWidget {
  const _CardBody({required this.task, this.lifted = false});

  final Task task;
  final bool lifted;

  @override
  ConsumerState<_CardBody> createState() => _CardBodyState();
}

class _CardBodyState extends ConsumerState<_CardBody> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task.status == TaskStatus.done;
    final due = Format.due(task, DateTime.now());
    final plan = ref.watch(taskFeasibilityProvider(task.id));
    final steps = ref.watch(subtasksProvider(task.id)).value ?? const [];
    final now = DateTime.now();
    final reminder = task.remindAt?.toLocal();
    final remindsLater = !done && reminder != null && reminder.isAfter(now);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: widget.lifted
                ? AppColour.elevated
                : _hovered
                ? AppColour.elevated
                : AppColour.base,
            borderRadius: AppRadius.mediumAll,
            border: Border.all(
              color: widget.lifted ? AppColour.accent : AppColour.separator,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        color: done
                            ? AppColour.labelTertiary
                            : AppColour.label,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColour.labelTertiary,
                      ),
                    ),
                  ),
                  if (task.priority > 0) ...[
                    const SizedBox(width: AppSpace.sm),
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: switch (task.priority) {
                          3 => AppColour.red,
                          2 => AppColour.orange,
                          _ => AppColour.grey,
                        },
                        borderRadius: AppRadius.roundAll,
                      ),
                    ),
                  ],
                ],
              ),
              // Labels and the project's inline fields, above the timing row: they say
              // what kind of work this is, which is what you scan a board for.
              Builder(
                builder: (context) {
                  final projectId = ref.watch(currentProjectIdProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ref
                          .watch(labelsForTaskProvider(task.id))
                          .isNotEmpty) ...[
                        const SizedBox(height: AppSpace.sm),
                        TaskLabelChips(taskId: task.id),
                      ],
                      if (projectId != null) ...[
                        const SizedBox(height: AppSpace.xs),
                        InlineFieldChips(task: task, projectId: projectId),
                      ],
                    ],
                  );
                },
              ),
              if (due != null ||
                  task.estimateMin != null ||
                  steps.isNotEmpty ||
                  remindsLater ||
                  (plan != null && plan.state != Feasibility.fine)) ...[
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    if (due != null)
                      _Pill(label: due.label, tint: due.colour),
                    if (task.estimateMin case final m?)
                      _Pill(label: Format.estimate(m)),
                    if (remindsLater)
                      _Pill(
                        icon: Icons.notifications_none_rounded,
                        label: Format.reminderTime(reminder, now),
                      ),
                    if (steps.isNotEmpty)
                      _Pill(
                        label:
                            '${steps.where((s) => s.done).length}/${steps.length}',
                      ),
                    if (plan != null && plan.state == Feasibility.impossible)
                      _Pill(
                        label: plan.shortfallMin > 0
                            ? '${Format.estimate(plan.shortfallMin)} short'
                            : "Won't fit",
                        tint: AppColour.red,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.tint, this.icon});

  final String label;
  final Color? tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colour = tint ?? AppColour.labelSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 1),
      decoration: BoxDecoration(
        color: (tint ?? AppColour.grey).withValues(alpha: 0.16),
        borderRadius: AppRadius.smallAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final glyph?) ...[
            Icon(glyph, size: 12, color: colour),
            const SizedBox(width: AppSpace.xs),
          ],
          Text(label, style: AppText.numeric.copyWith(color: colour)),
        ],
      ),
    );
  }
}

class _AddCardButton extends ConsumerWidget {
  const _AddCardButton({required this.projectId, required this.sectionId});

  final String projectId;
  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ref.read(composerOpenProvider.notifier).open(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(AppLayout.touch ? AppSpace.md : AppSpace.sm),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, size: 15, color: AppColour.labelTertiary),
              const SizedBox(width: AppSpace.xs),
              Text('Add a card', style: AppText.footnote),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSectionColumn extends ConsumerWidget {
  const _AddSectionColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final scope = ref.read(appScopeProvider).value;
          final projectId = ref.read(currentProjectIdProvider);
          if (scope == null || projectId == null) return;
          await scope.projects.addSection(
            workspaceId: scope.workspace.id,
            boardId: projectId,
            name: 'New section',
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.largeAll,
            border: Border.all(color: AppColour.separator, width: 0.5),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 15, color: AppColour.labelTertiary),
                const SizedBox(width: AppSpace.xs),
                Text('Add section', style: AppText.footnote),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
