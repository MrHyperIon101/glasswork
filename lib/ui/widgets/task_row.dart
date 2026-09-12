import 'package:flutter/widgets.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../theme/tokens.dart';
import '../format.dart';

/// One task in a list.
///
/// Deliberately **not** a glass surface. Glass is capped at about four on screen and a
/// list has dozens of rows; rows live inside the panel's glass instead.
class TaskRow extends StatefulWidget {
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
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task.status == TaskStatus.done;
    final due = Format.due(task, DateTime.now());

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppGlass.flatFill : null,
            borderRadius: AppRadius.surfaceAll,
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
                        color: done ? AppColour.textDim : AppColour.text,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColour.textDim,
                      ),
                    ),
                    if (due != null || task.estimateMin != null) ...[
                      const SizedBox(height: AppSpace.xs),
                      Row(
                        children: [
                          if (due != null)
                            Text(
                              due.label,
                              style: AppText.numeric.copyWith(
                                color: done ? AppColour.textDim : due.colour,
                              ),
                            ),
                          if (due != null && task.estimateMin != null)
                            Text('  ·  ', style: AppText.numeric),
                          if (task.estimateMin case final mins?)
                            Text(
                              Format.estimate(mins),
                              style: AppText.numeric,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (task.priority > 0) ...[
                const SizedBox(width: AppSpace.sm),
                _PriorityDot(priority: task.priority),
              ],
              // Revealed on hover so the row stays quiet at rest. Touch users reach it
              // through the detail sheet instead.
              AnimatedOpacity(
                duration: AppMotion.quick,
                opacity: _hovered ? 1 : 0,
                child: _DeleteButton(
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

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColour.done : null,
          border: Border.all(
            color: done ? AppColour.done : AppColour.textDim,
            width: 1.5,
          ),
        ),
        child: done
            ? const Center(
                child: Icon(
                  _CheckIcon.check,
                  size: 12,
                  color: AppColour.base,
                ),
              )
            : null,
      ),
    );
  }
}

/// Material's icon font ships with the app already; this pulls the two glyphs needed
/// without dragging in the whole Material widget layer.
abstract final class _CheckIcon {
  static const check = IconData(0xe5ca, fontFamily: 'MaterialIcons');
  static const close = IconData(0xe5cd, fontFamily: 'MaterialIcons');
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    final colour = switch (priority) {
      3 => AppColour.overdue,
      2 => AppColour.soon,
      _ => AppColour.textDim,
    };
    return Container(
      width: AppSpace.sm,
      height: AppSpace.sm,
      margin: const EdgeInsets.only(top: AppSpace.xs),
      decoration: BoxDecoration(color: colour, borderRadius: AppRadius.controlAll),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.only(left: AppSpace.sm),
        child: Icon(_CheckIcon.close, size: 16, color: AppColour.textDim),
      ),
    );
  }
}
