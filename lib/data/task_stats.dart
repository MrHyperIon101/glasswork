import 'db/database.dart';
import 'db/tables.dart';

/// Everything the Today dashboard shows, derived from the task list.
///
/// A pure function of (tasks, now) so every figure on screen is traceable and testable.
/// The capacity engine in phase 2 will add the harder numbers — usable minutes, load,
/// feasibility — and it lands here alongside these rather than inside a widget.
class TaskStats {
  const TaskStats({
    required this.open,
    required this.overdue,
    required this.dueToday,
    required this.completedToday,
    required this.completedThisWeek,
    required this.estimatedMinutesToday,
    required this.untimedToday,
    required this.nextUp,
    this.doneByDay = const [0, 0, 0, 0, 0, 0, 0],
    this.nextReminder,
  });

  final int open;
  final List<Task> overdue;
  final List<Task> dueToday;
  final int completedToday;
  final int completedThisWeek;

  /// Total estimate across today's tasks. Only counts tasks that have one.
  final int estimatedMinutesToday;

  /// How many of today's tasks carry no estimate. Shown next to the total, because a
  /// total that silently ignores half the work is worse than no total.
  final int untimedToday;

  /// Soonest upcoming task that isn't already overdue.
  final Task? nextUp;

  /// Tasks completed on each of the last seven days, six days ago first and today last.
  final List<int> doneByDay;

  /// The open task whose reminder comes soonest, among those still to come.
  final Task? nextReminder;

  int get todayTotal => dueToday.length + overdue.length;

  /// Share of today's work already done, 0..1. Null when there is nothing due.
  double? get todayProgress {
    final total = todayTotal + completedToday;
    if (total == 0) return null;
    return completedToday / total;
  }

  static TaskStats from(List<Task> tasks, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final overdue = <Task>[];
    final dueToday = <Task>[];
    final doneByDay = List.filled(7, 0);
    Task? nextReminder;
    var open = 0;
    var completedToday = 0;
    var completedThisWeek = 0;
    var estimate = 0;
    var untimed = 0;
    Task? nextUp;

    for (final task in tasks) {
      if (task.deletedAt != null) continue;

      if (task.status == TaskStatus.done) {
        final at = task.completedAt;
        if (at != null) {
          final local = at.toLocal();
          final day = DateTime(local.year, local.month, local.day);
          if (!day.isBefore(weekStart)) completedThisWeek++;
          if (day == today) completedToday++;
          // Whole dates back from today, which a change of clocks cannot throw off.
          final ago = DateTime.utc(today.year, today.month, today.day)
              .difference(DateTime.utc(day.year, day.month, day.day))
              .inDays;
          if (ago >= 0 && ago < 7) doneByDay[6 - ago]++;
        }
        continue;
      }

      open++;

      if (task.remindAt case final remind? when remind.isAfter(now)) {
        if (nextReminder == null || remind.isBefore(nextReminder.remindAt!)) {
          nextReminder = task;
        }
      }

      final due = dueDayOf(task);
      if (due == null) continue;

      if (_isOverdue(task, now, today)) {
        overdue.add(task);
      } else if (due == today) {
        dueToday.add(task);
      } else if (due.isAfter(today)) {
        if (nextUp == null || due.isBefore(dueDayOf(nextUp)!)) nextUp = task;
      }
    }

    for (final task in [...overdue, ...dueToday]) {
      final mins = task.estimateMin;
      if (mins == null) {
        untimed++;
      } else {
        estimate += mins;
      }
    }

    int bySoonest(Task a, Task b) {
      final da = a.dueAt ?? DateTime(9999);
      final db = b.dueAt ?? DateTime(9999);
      return da.compareTo(db);
    }

    return TaskStats(
      open: open,
      overdue: overdue..sort(bySoonest),
      dueToday: dueToday..sort(bySoonest),
      completedToday: completedToday,
      completedThisWeek: completedThisWeek,
      estimatedMinutesToday: estimate,
      untimedToday: untimed,
      nextUp: nextUp,
      doneByDay: doneByDay,
      nextReminder: nextReminder,
    );
  }

  /// The calendar day a task is due, whichever field carries it.
  static DateTime? dueDayOf(Task task) {
    if (task.dueAt case final at?) return DateTime(at.year, at.month, at.day);
    if (task.dueDate case final iso?) {
      final parts = iso.split('-');
      if (parts.length != 3) return null;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) return null;
      return DateTime(y, m, d);
    }
    return null;
  }

  /// A timed task is late the moment its instant passes. An all-day task is late only
  /// once the whole day has gone — it has no instant to be late against.
  static bool _isOverdue(Task task, DateTime now, DateTime today) {
    if (task.dueAt case final at?) return at.isBefore(now);
    final day = dueDayOf(task);
    return day != null && day.isBefore(today);
  }
}
