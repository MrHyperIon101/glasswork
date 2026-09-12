import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../surface.dart';

/// A month of a project's work, laid out by due date.
///
/// Deliberately not a general calendar: it shows only what is due, because the thing a
/// month view answers is "when is this landing", not "what does my day look like". The
/// day-shape question is the Time budget screen's, and it answers it better with a
/// timeline than a grid ever could.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  /// First of the displayed month.
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
  });

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(filteredProjectTasksProvider);

    // Group by due day once, rather than scanning the list per cell.
    final byDay = <DateTime, List<Task>>{};
    for (final task in tasks) {
      final due = TaskStats.dueDayOf(task);
      if (due == null) continue;
      (byDay[due] ??= []).add(task);
    }

    final undated = tasks
        .where((t) => TaskStats.dueDayOf(t) == null)
        .toList();

    // A calendar grid starts on the Monday of the week containing the 1st.
    final firstOfMonth = DateTime(_month.year, _month.month);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    final weeks = _weeksNeeded(firstOfMonth);

    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_monthName(_month), style: AppText.title3),
              const SizedBox(width: AppSpace.md),
              _Arrow(icon: Icons.chevron_left, onTap: () => _shift(-1)),
              _Arrow(icon: Icons.chevron_right, onTap: () => _shift(1)),
              const SizedBox(width: AppSpace.sm),
              _TextAction(
                label: 'Today',
                onTap: () => setState(() {
                  final now = DateTime.now();
                  _month = DateTime(now.year, now.month);
                }),
              ),
              const Spacer(),
              if (undated.isNotEmpty)
                Text(
                  '${undated.length} with no date, not shown',
                  style: AppText.numeric.copyWith(
                    color: AppColour.labelQuaternary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: Text(d, style: AppText.caption),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                for (var w = 0; w < weeks; w++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: _DayCell(
                              date: gridStart.add(Duration(days: w * 7 + d)),
                              month: _month.month,
                              tasks:
                                  byDay[gridStart.add(
                                    Duration(days: w * 7 + d),
                                  )] ??
                                  const [],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Five or six rows depending on how the month falls — a fixed six leaves an empty
  /// band most months and squashes the cells that matter.
  static int _weeksNeeded(DateTime firstOfMonth) {
    final daysInMonth = DateTime(
      firstOfMonth.year,
      firstOfMonth.month + 1,
      0,
    ).day;
    final leading = firstOfMonth.weekday - 1;
    return ((leading + daysInMonth) / 7).ceil();
  }

  static String _monthName(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _DayCell extends ConsumerStatefulWidget {
  const _DayCell({
    required this.date,
    required this.month,
    required this.tasks,
  });

  final DateTime date;
  final int month;
  final List<Task> tasks;

  @override
  ConsumerState<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends ConsumerState<_DayCell> {
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
    final inMonth = widget.date.month == widget.month;

    // Dropping a task on a day is the fastest way to reschedule, and the reason this
    // view is worth having over a list sorted by date.
    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (_) {
        if (!_dragOver) setState(() => _dragOver = true);
      },
      onLeave: (_) => setState(() => _dragOver = false),
      onAcceptWithDetails: (details) async {
        setState(() => _dragOver = false);
        final scope = ref.read(appScopeProvider).value;
        await scope?.tasks.setDue(
          details.data.id,
          dueAt: null,
          dueDate: _iso(widget.date),
        );
      },
      builder: (context, candidate, rejected) => AnimatedContainer(
        duration: AppMotion.quick,
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: _dragOver
              ? AppColour.accent.withValues(alpha: 0.18)
              : inMonth
              ? AppColour.fill
              : null,
          borderRadius: AppRadius.smallAll,
          border: isToday
              ? Border.all(color: AppColour.accent.withValues(alpha: 0.7))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.date.day}',
              style: AppText.numeric.copyWith(
                color: isToday
                    ? AppColour.accent
                    : inMonth
                    ? AppColour.labelSecondary
                    : AppColour.labelQuaternary,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ClipRect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final task in widget.tasks.take(3))
                      _MiniTask(task: task),
                    if (widget.tasks.length > 3)
                      Text(
                        '+${widget.tasks.length - 3} more',
                        style: AppText.numeric.copyWith(
                          fontSize: 9,
                          color: AppColour.labelQuaternary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _MiniTask extends ConsumerWidget {
  const _MiniTask({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = task.status == TaskStatus.done;
    final due = Format.due(task, DateTime.now());

    final chip = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: (done ? AppColour.grey : (due?.colour ?? AppColour.accent))
            .withValues(alpha: 0.2),
        borderRadius: AppRadius.smallAll,
      ),
      child: Text(
        task.title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: AppText.numeric.copyWith(
          fontSize: 9,
          color: done ? AppColour.labelTertiary : AppColour.label,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
    );

    return Draggable<Task>(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: const Offset(-60, -12),
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(width: 140, child: chip),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
          behavior: HitTestBehavior.opaque,
          child: Tooltip(message: task.title, child: chip),
        ),
      ),
    );
  }
}

class _Arrow extends StatefulWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_Arrow> createState() => _ArrowState();
}

class _ArrowState extends State<_Arrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: _hovered ? AppColour.fill : null,
          borderRadius: AppRadius.smallAll,
        ),
        child: Icon(widget.icon, size: 18, color: AppColour.labelSecondary),
      ),
    ),
  );
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: AppText.numeric.copyWith(color: AppColour.accent),
      ),
    ),
  );
}
