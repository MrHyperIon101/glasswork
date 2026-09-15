import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../surface.dart';
import 'task_row.dart';

/// A month of a project's work, laid out by due date.
///
/// Deliberately not a general calendar: it shows only what is due, because the thing a
/// month view answers is "when is this landing", not "what does my day look like". The
/// day-shape question is the Time budget screen's, and it answers it better with a
/// timeline than a grid ever could.
///
/// On a phone, seven columns leave no room to write titles into the days, so days show
/// dots and the selected day's tasks are listed under the grid, where they can be read
/// and ticked off.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  /// First of the displayed month.
  late DateTime _month;

  /// The day a phone lists under the grid.
  late DateTime _selected;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  void _shift(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
    _selected = _month;
  });

  void _goToToday() => setState(() {
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
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

    final undated = tasks.where((t) => TaskStats.dueDayOf(t) == null).length;

    // A calendar grid starts on the Monday of the week containing the 1st.
    final firstOfMonth = DateTime(_month.year, _month.month);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    final weeks = _weeksNeeded(firstOfMonth);
    DateTime dateAt(int week, int day) =>
        gridStart.add(Duration(days: week * 7 + day));

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoint.compact;

        final header = Row(
          children: [
            Flexible(
              child: Text(
                _monthName(_month),
                style: AppText.title3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            _Arrow(icon: Icons.chevron_left, onTap: () => _shift(-1)),
            _Arrow(icon: Icons.chevron_right, onTap: () => _shift(1)),
            const SizedBox(width: AppSpace.sm),
            _TextAction(label: 'Today', onTap: _goToToday),
            if (!compact && undated > 0) ...[
              const Spacer(),
              Text(
                '$undated with no date, not shown',
                style: AppText.numeric.copyWith(
                  color: AppColour.labelQuaternary,
                ),
              ),
            ],
          ],
        );

        final weekdays = Row(
          children: [
            for (final name in compact ? _letters : _names)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.xs),
                  child: Text(
                    name,
                    style: AppText.caption,
                    textAlign: compact ? TextAlign.center : TextAlign.start,
                  ),
                ),
              ),
          ],
        );

        if (compact) {
          // One scroll for the month and the day under it. Given only the height the grid
          // left over, the day's list showed part of a single task.
          return AppSurface(
            padding: const EdgeInsets.all(AppSpace.md),
            child: ListView(
              children: [
                header,
                const SizedBox(height: AppSpace.sm),
                weekdays,
                for (var w = 0; w < weeks; w++)
                  SizedBox(
                    height: AppSize.dayCell,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: _CompactDayCell(
                              date: dateAt(w, d),
                              month: _month.month,
                              tasks: byDay[dateAt(w, d)] ?? const [],
                              selected: DateUtils.isSameDay(
                                dateAt(w, d),
                                _selected,
                              ),
                              onSelect: () =>
                                  setState(() => _selected = dateAt(w, d)),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.sm),
                const AppDivider(),
                _DayAgenda(
                  day: _selected,
                  tasks: byDay[_selected] ?? const [],
                  undated: undated,
                ),
              ],
            ),
          );
        }

        return AppSurface(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: AppSpace.md),
              weekdays,
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
                                  date: dateAt(w, d),
                                  month: _month.month,
                                  tasks: byDay[dateAt(w, d)] ?? const [],
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
      },
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

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

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
    final isToday = DateUtils.isSameDay(widget.date, DateTime.now());
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
}

/// A day in a phone's month grid: its number, and a dot for each of up to three tasks.
class _CompactDayCell extends ConsumerStatefulWidget {
  const _CompactDayCell({
    required this.date,
    required this.month,
    required this.tasks,
    required this.selected,
    required this.onSelect,
  });

  final DateTime date;
  final int month;
  final List<Task> tasks;
  final bool selected;
  final VoidCallback onSelect;

  @override
  ConsumerState<_CompactDayCell> createState() => _CompactDayCellState();
}

class _CompactDayCellState extends ConsumerState<_CompactDayCell> {
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(widget.date, now);
    final inMonth = widget.date.month == widget.month;

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
      builder: (context, candidate, rejected) => GestureDetector(
        onTap: widget.onSelect,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: _dragOver
                ? AppColour.accent.withValues(alpha: 0.18)
                : widget.selected
                ? AppColour.fillStrong
                : null,
            borderRadius: AppRadius.smallAll,
            border: isToday
                ? Border.all(color: AppColour.accent.withValues(alpha: 0.7))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.date.day}',
                style: AppText.numeric.copyWith(
                  color: isToday
                      ? AppColour.accent
                      : inMonth
                      ? AppColour.label
                      : AppColour.labelQuaternary,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final task in widget.tasks.take(3))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.status == TaskStatus.done
                              ? AppColour.grey
                              : Format.due(task, now)?.colour ?? AppColour.accent,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The selected day's tasks, under a phone's month grid.
class _DayAgenda extends ConsumerWidget {
  const _DayAgenda({
    required this.day,
    required this.tasks,
    required this.undated,
  });

  final DateTime day;
  final List<Task> tasks;
  final int undated;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;

    Widget row(Task task) => TaskRow(
      task: task,
      onToggle: () => scope?.tasks.setDone(
        task.id,
        done: task.status != TaskStatus.done,
      ),
      onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
      onDelete: () async {
        if (scope == null) return;
        await scope.tasks.softDelete(task.id);
        ref
            .read(undoProvider.notifier)
            .offer(
              'Deleted "${task.title}"',
              () => scope.tasks.restore(task.id),
            );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xs),
          child: Text(
            '${_weekdays[day.weekday - 1]} ${Format.shortDate(day)}',
            style: AppText.caption,
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Text(
              'Nothing due',
              style: AppText.footnote.copyWith(
                color: AppColour.labelQuaternary,
              ),
            ),
          )
        else
          // Long-press one and drop it on a day above to move it there.
          for (final task in tasks)
            AdaptiveDraggable<Task>(
              key: ValueKey(task.id),
              data: task,
              feedback: _DragLabel(title: task.title),
              childWhenDragging: Opacity(opacity: 0.3, child: row(task)),
              child: row(task),
            ),
        if (undated > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.md),
            child: Text(
              '$undated with no date, not shown',
              style: AppText.numeric.copyWith(
                color: AppColour.labelQuaternary,
              ),
            ),
          ),
      ],
    );
  }
}

/// What follows a finger dragging a task from a phone's day list.
class _DragLabel extends StatelessWidget {
  const _DragLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(-80, -40),
    child: Container(
      width: 180,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AppColour.elevated,
        borderRadius: AppRadius.mediumAll,
        border: Border.all(color: AppColour.accent),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.callout.copyWith(
          color: AppColour.label,
          decoration: TextDecoration.none,
        ),
      ),
    ),
  );
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

    return AdaptiveDraggable<Task>(
      data: task,
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
        padding: EdgeInsets.all(AppLayout.touch ? AppSpace.sm : AppSpace.xs),
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.touch ? AppSpace.sm : 0,
        ),
        child: Text(
          label,
          style: AppText.numeric.copyWith(color: AppColour.accent),
        ),
      ),
    ),
  );
}
