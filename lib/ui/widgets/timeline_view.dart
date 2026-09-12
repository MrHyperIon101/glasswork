import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../surface.dart';

/// When work is actually going to happen, against when it is due.
///
/// Not a conventional Gantt. A Gantt draws bars you positioned by hand; this draws where
/// the scheduler says each task *will* fit, given your real capacity — so a bar
/// overrunning its deadline marker is not a planning opinion, it is arithmetic. That is
/// the whole reason this view earns its place over a sorted list.
class TimelineView extends ConsumerWidget {
  const TimelineView({required this.projectId, super.key});

  final String projectId;

  /// Days across. Matches the planning horizon; beyond it the scheduler says nothing.
  static const _days = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(filteredProjectTasksProvider);
    final schedule = ref.watch(scheduleProvider);

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    // Only tasks the scheduler placed. Undated work has no position on a timeline, and
    // inventing one would be a claim the arithmetic never made.
    final rows = <(Task, ScheduledTask)>[];
    for (final task in tasks) {
      if (task.status == TaskStatus.done) continue;
      if (TaskStats.dueDayOf(task) == null) continue;
      final plan = schedule.tasks
          .where((s) => s.task.id == task.id)
          .firstOrNull;
      if (plan == null) continue;
      rows.add((task, plan));
    }
    rows.sort((a, b) => a.$2.task.dueDay.compareTo(b.$2.task.dueDay));

    final undated = tasks
        .where(
          (t) =>
              t.status != TaskStatus.done && TaskStats.dueDayOf(t) == null,
        )
        .length;

    if (rows.isEmpty) {
      return AppSurface(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timeline,
                  size: 26,
                  color: AppColour.labelQuaternary,
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  'Nothing with a deadline in the next four weeks',
                  style: AppText.body.copyWith(
                    color: AppColour.labelSecondary,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  undated == 0
                      ? 'Give a task a due date and an estimate to see it here.'
                      : '$undated ${undated == 1 ? 'task has' : 'tasks have'} '
                            'no due date, so the planner cannot place them.',
                  style: AppText.footnote,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Planned against deadlines', style: AppText.caption),
              const SizedBox(width: AppSpace.md),
              _Key(colour: AppColour.accent, label: 'when it will happen'),
              const SizedBox(width: AppSpace.md),
              _Key(colour: AppColour.red, label: "won't make it"),
              const Spacer(),
              if (undated > 0)
                Text(
                  '$undated undated, not shown',
                  style: AppText.numeric.copyWith(
                    color: AppColour.labelQuaternary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          _Ruler(start: start, days: _days),
          const SizedBox(height: AppSpace.xs),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final (task, plan) = rows[i];
                return _TimelineRow(
                  task: task,
                  plan: plan,
                  start: start,
                  days: _days,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Ruler extends StatelessWidget {
  const _Ruler({required this.start, required this.days});

  final DateTime start;
  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: _TimelineRow.labelWidth),
        Expanded(
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (var i = 0; i < days; i++)
                  Expanded(
                    child: Center(
                      // Every seventh day only; 28 labels in a row is a smear.
                      child: i % 7 == 0
                          ? Text(
                              _label(start.add(Duration(days: i))),
                              style: AppText.numeric.copyWith(
                                fontSize: 9,
                                color: AppColour.labelQuaternary,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _label(DateTime d) => '${d.day}/${d.month}';
}

class _TimelineRow extends ConsumerStatefulWidget {
  const _TimelineRow({
    required this.task,
    required this.plan,
    required this.start,
    required this.days,
  });

  static const labelWidth = 190.0;

  final Task task;
  final ScheduledTask plan;
  final DateTime start;
  final int days;

  @override
  ConsumerState<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends ConsumerState<_TimelineRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final impossible = plan.state == Feasibility.impossible;

    final startIndex = plan.startDay == null
        ? 0
        : plan.startDay!.difference(widget.start).inDays;
    final finishIndex = plan.finishDay == null
        ? startIndex
        : plan.finishDay!.difference(widget.start).inDays;
    final dueIndex = plan.task.dueDay.difference(widget.start).inDays;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => ref.read(openTaskProvider.notifier).open(widget.task.id),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered ? AppColour.fill : null,
            borderRadius: AppRadius.smallAll,
          ),
          child: Row(
            children: [
              SizedBox(
                width: _TimelineRow.labelWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpace.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.callout.copyWith(
                            color: AppColour.label,
                          ),
                        ),
                      ),
                      if (widget.task.estimateMin case final m?)
                        Text(
                          Format.estimate(m),
                          style: AppText.numeric.copyWith(
                            color: AppColour.labelQuaternary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cell = constraints.maxWidth / widget.days;

                    return Stack(
                      children: [
                        // Week separators, so a four-week span stays readable.
                        for (var i = 0; i < widget.days; i += 7)
                          Positioned(
                            left: i * cell,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 0.5,
                              color: AppColour.separator,
                            ),
                          ),

                        // The deadline, drawn even when it falls before the bar ends —
                        // that overlap is the point.
                        if (dueIndex >= 0 && dueIndex < widget.days)
                          Positioned(
                            left: (dueIndex + 1) * cell - 1,
                            top: 2,
                            bottom: 2,
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                color: impossible
                                    ? AppColour.red
                                    : AppColour.labelTertiary,
                                borderRadius: AppRadius.smallAll,
                              ),
                            ),
                          ),

                        // Where the work actually lands.
                        if (plan.startDay != null)
                          Positioned(
                            left: (startIndex.clamp(0, widget.days - 1)) * cell + 1,
                            width:
                                ((finishIndex - startIndex + 1).clamp(
                                      1,
                                      widget.days,
                                    )) *
                                    cell -
                                2,
                            top: 7,
                            height: 16,
                            child: Tooltip(
                              message: _tooltip(plan),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: impossible
                                      ? AppColour.red.withValues(alpha: 0.75)
                                      : AppColour.accent.withValues(
                                          alpha: 0.75,
                                        ),
                                  borderRadius: AppRadius.smallAll,
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            left: 2,
                            top: 9,
                            child: Text(
                              'no room in the next four weeks',
                              style: AppText.numeric.copyWith(
                                fontSize: 9,
                                color: AppColour.red,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _tooltip(ScheduledTask plan) {
    final slack = plan.slackDays;
    if (plan.shortfallMin > 0) {
      return '${Format.estimate(plan.shortfallMin)} of this has nowhere to go '
          'before the deadline';
    }
    if (slack < 0) {
      return 'Finishes ${-slack} ${-slack == 1 ? 'day' : 'days'} late';
    }
    if (slack == 0) return 'Finishes on the day it is due — no slack';
    return 'Finishes with $slack ${slack == 1 ? 'day' : 'days'} spare';
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.colour, required this.label});

  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.75),
          borderRadius: AppRadius.smallAll,
        ),
      ),
      const SizedBox(width: AppSpace.xs),
      Text(label, style: AppText.footnote),
    ],
  );
}
