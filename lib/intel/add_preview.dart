import '../capacity/scheduler.dart';
import '../ui/format.dart';

/// What adding a task would mean for the days before it is due, in a sentence, worked out
/// before it is added by running the scheduler with it among the rest. Pure.
abstract final class AddPreview {
  /// "Fits — done by Thursday, 2 days to spare", "Tight — done on the day it is due",
  /// "Won't fit by Friday — 1h 30m short. Start today." Null when there is no deadline to
  /// fit before.
  static String? sentence(ScheduledTask? plan, {required DateTime today}) {
    if (plan == null) return null;
    final due = plan.task.dueDay;
    if (due == null) return null;
    final startsToday = plan.startDay != null && _same(plan.startDay!, today);
    switch (plan.state) {
      case Feasibility.fine:
        final days = plan.slackDays;
        return 'Fits — done by ${_day(plan.finishDay!, today)}, '
            '$days ${days == 1 ? 'day' : 'days'} to spare';
      case Feasibility.tight:
        return 'Tight — done on the day it is due, nothing spare'
            '${startsToday ? '. Start today.' : ''}';
      case Feasibility.impossible:
        if (plan.shortfallMin > 0) {
          return "Won't fit by ${_day(due, today)} — ${Format.estimate(plan.shortfallMin)} short"
              '${startsToday ? '. Start today.' : ''}';
        }
        final late = -plan.slackDays;
        return "Won't fit — $late ${late == 1 ? 'day' : 'days'} past ${_day(due, today)}";
    }
  }

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Today, Tomorrow, a weekday within the week, or the date.
  static String _day(DateTime day, DateTime today) {
    final d = DateTime.utc(day.year, day.month, day.day);
    final t = DateTime.utc(today.year, today.month, today.day);
    final diff = d.difference(t).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (diff > 1 && diff < 7) return weekdays[day.weekday - 1];
    return '${day.day} ${months[day.month - 1]}';
  }
}
