import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';

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

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task.status == TaskStatus.done;
    final due = Format.due(task, DateTime.now());
    final hasMeta = due != null || task.estimateMin != null;

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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.fill : null,
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Checkbox(done: done, onTap: widget.onToggle),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppText.body.copyWith(
                        color: done
                            ? AppColour.labelTertiary
                            : AppColour.label,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColour.labelTertiary,
                      ),
                    ),
                    if (hasMeta && !done) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (due != null)
                            Text(
                              due.label,
                              style: AppText.numeric.copyWith(
                                color: due.colour,
                              ),
                            ),
                          if (due != null && task.estimateMin != null)
                            Text(
                              '  ·  ',
                              style: AppText.numeric.copyWith(
                                color: AppColour.labelQuaternary,
                              ),
                            ),
                          if (task.estimateMin case final mins?)
                            Text(Format.estimate(mins), style: AppText.numeric),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!done) ...[
                Builder(
                  builder: (context) {
                    final plan = ref.watch(taskFeasibilityProvider(task.id));
                    if (plan == null || plan.state == Feasibility.fine) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpace.sm),
                      child: _FeasibilityFlag(plan: plan),
                    );
                  },
                ),
                if (task.priority > 0) ...[
                  const SizedBox(width: AppSpace.sm),
                  _PriorityFlag(priority: task.priority),
                ],
              ],
              // Revealed on hover so the row stays quiet at rest.
              AnimatedOpacity(
                duration: AppMotion.quick,
                opacity: _hovered ? 1 : 0,
                child: _RowButton(
                  icon: Icons.close,
                  onTap: _hovered ? widget.onDelete : null,
                ),
              ),
            ],
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: AnimatedContainer(
            duration: AppMotion.quick,
            curve: AppMotion.standard,
            width: 19,
            height: 19,
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
                ? const Icon(Icons.check, size: 12, color: AppColour.base)
                : null,
          ),
        ),
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
