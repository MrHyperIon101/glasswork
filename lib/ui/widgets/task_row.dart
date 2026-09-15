import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../motion.dart';
import 'task_chips.dart';

/// One task in a list.
///
/// Rows are plain surfaces, never vibrancy: a list has dozens of them and each
/// `BackdropFilter` costs a capture. Depth here comes from a hover fill, the way a
/// Finder or Mail row behaves.
class TaskRow extends ConsumerStatefulWidget {
  const TaskRow({
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  ConsumerState<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<TaskRow> {
  bool _hovered = false;

  /// Narrower than this, a row's flags join its date and estimate under the title rather
  /// than standing to the right of it, where they would take the title's width.
  static const _flagsBesideFrom = 480.0;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task.status == TaskStatus.done;
    final due = Format.due(task, DateTime.now());
    final hasLabels = ref.watch(labelsForTaskProvider(task.id)).isNotEmpty;
    final plan = done ? null : ref.watch(taskFeasibilityProvider(task.id));
    final touch = AppLayout.touch;

    final flags = [
      if (plan != null && plan.state != Feasibility.fine)
        _FeasibilityFlag(plan: plan),
      if (!done && task.priority > 0) _PriorityFlag(priority: task.priority),
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          padding: touch
              ? const EdgeInsets.all(AppSpace.xs)
              : const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.fill : null,
            borderRadius: AppRadius.mediumAll,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final flagsBeside = constraints.maxWidth >= _flagsBesideFrom;

              final meta = [
                // Dots rather than names: a row already carries a due date and an
                // estimate, and four label names would push the title out.
                if (hasLabels) TaskLabelChips(taskId: task.id, dense: true),
                if (due != null)
                  Text(
                    due.label,
                    style: AppText.numeric.copyWith(color: due.colour),
                  ),
                if (due != null && task.estimateMin != null)
                  Text(
                    '·',
                    style: AppText.numeric.copyWith(
                      color: AppColour.labelQuaternary,
                    ),
                  ),
                if (task.estimateMin case final mins?)
                  Text(Format.estimate(mins), style: AppText.numeric),
                if (task.remindAt?.toLocal() case final at?
                    when at.isAfter(DateTime.now()))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 12,
                        color: AppColour.labelTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        Format.reminderTime(at, DateTime.now()),
                        style: AppText.numeric,
                      ),
                    ],
                  ),
                if (!flagsBeside) ...flags,
              ];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Checkbox(done: done, onTap: widget.onToggle),
                  SizedBox(width: touch ? AppSpace.xs : AppSpace.md),
                  Expanded(
                    child: Padding(
                      // Level with the middle of the larger checkbox a finger gets.
                      padding: EdgeInsets.only(top: touch ? AppSpace.sm : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: AppText.body.copyWith(
                              color: done
                                  ? AppColour.labelTertiary
                                  : AppColour.label,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColour.labelTertiary,
                            ),
                          ),
                          if (!done && meta.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: meta,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (flagsBeside)
                    for (final flag in flags)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpace.sm),
                        child: flag,
                      ),
                  // Revealed on hover so the row stays quiet at rest. A touch screen has no
                  // hover, so there a task is deleted from its sheet instead.
                  if (!touch)
                    AnimatedOpacity(
                      duration: AppMotion.quick,
                      opacity: _hovered ? 1 : 0,
                      child: _RowButton(
                        icon: Icons.close,
                        onTap: _hovered ? widget.onDelete : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatefulWidget {
  const _Checkbox({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  State<_Checkbox> createState() => _CheckboxState();
}

class _CheckboxState extends State<_Checkbox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final touch = AppLayout.touch;
    final size = touch ? 22.0 : 19.0;

    final circle = CheckPop(
      done: widget.done,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.standard,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.done ? AppColour.green : null,
          border: Border.all(
            color: widget.done
                ? AppColour.green
                : _hovered
                ? AppColour.labelSecondary
                : AppColour.labelQuaternary,
            width: 1.5,
          ),
        ),
        child: widget.done
            ? Icon(Icons.check, size: size * 0.63, color: AppColour.base)
            : null,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        // A finger gets a target bigger than the circle it can see.
        child: touch
            ? SizedBox.square(
                dimension: AppSize.touch - AppSpace.sm,
                child: Center(child: circle),
              )
            : Padding(padding: const EdgeInsets.only(top: 1), child: circle),
      ),
    );
  }
}

/// Says what the arithmetic concluded, and by how much.
///
/// "Won't fit" on its own invites an argument; "2h 30m short" is a fact you can act on.
class _FeasibilityFlag extends StatelessWidget {
  const _FeasibilityFlag({required this.plan});

  final ScheduledTask plan;

  @override
  Widget build(BuildContext context) {
    final impossible = plan.state == Feasibility.impossible;
    final colour = impossible ? AppColour.red : AppColour.orange;

    final label = impossible
        ? (plan.shortfallMin > 0
              ? '${Format.estimate(plan.shortfallMin)} short'
              : "Won't fit")
        : 'No slack';

    return Tooltip(
      message: impossible
          ? 'At your current commitments this does not fit before the deadline.'
          : 'This finishes on the day it is due. Nothing can go wrong.',
      child: Container(
        margin: const EdgeInsets.only(top: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.16),
          borderRadius: AppRadius.smallAll,
        ),
        child: Text(label, style: AppText.numeric.copyWith(color: colour)),
      ),
    );
  }
}

class _PriorityFlag extends StatelessWidget {
  const _PriorityFlag({required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    final (colour, label) = switch (priority) {
      3 => (AppColour.red, 'High'),
      2 => (AppColour.orange, 'Med'),
      _ => (AppColour.grey, 'Low'),
    };

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.16),
        borderRadius: AppRadius.smallAll,
      ),
      child: Text(
        label,
        style: AppText.numeric.copyWith(color: colour),
      ),
    );
  }
}

class _RowButton extends StatelessWidget {
  const _RowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpace.sm, top: 1),
        child: Icon(icon, size: 15, color: AppColour.labelTertiary),
      ),
    );
  }
}
