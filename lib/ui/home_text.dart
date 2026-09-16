import '../capacity/day_now.dart';
import '../data/task_stats.dart';
import 'format.dart';

/// What the Today screen says, worked out from the figures behind it.
///
/// Pure, with the time passed in, so every sentence on the home screen is checked by a test
/// rather than assembled inside a widget.
abstract final class HomeText {
  static String greeting(DateTime now) {
    if (now.hour < 5) return 'Good night';
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String longDate(DateTime now) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  /// The day in a line: "4 tasks today · 4h 15m planned · 2 won't fit".
  static String summary(TaskStats stats, {required int wontFit}) => [
    switch (stats.todayTotal) {
      0 => 'Nothing due today',
      1 => '1 task today',
      final n => '$n tasks today',
    },
    if (stats.estimatedMinutesToday > 0) '${Format.estimate(stats.estimatedMinutesToday)} planned',
    if (wontFit > 0) "$wontFit won't fit",
  ].join(' · ');

  /// "3 of 7 done", or what there is when nothing is due.
  static String progress(TaskStats stats) {
    final total = stats.todayTotal + stats.completedToday;
    if (total == 0) return 'A clear day';
    if (stats.todayTotal == 0) return 'All ${stats.completedToday} done';
    return '${stats.completedToday} of $total done';
  }

  /// Where the day stands right now, in two lines.
  static ({String title, String detail}) now(DayNow now, {int? bedtimeMin}) {
    if (now.beforeWaking) {
      final first = now.next;
      return (
        title: 'Your day starts soon',
        detail: first == null
            ? 'Nothing fixed on today'
            : 'First up: ${first.title} at ${Format.clock(first.startMin)}',
      );
    }
    if (now.current case final block?) {
      return (
        title: 'In ${block.title}',
        detail: 'Until ${Format.clock(block.endMin)} · ${Format.estimate(now.untilMin)} left',
      );
    }
    if (now.next case final block?) {
      return (
        title: 'Free until ${Format.clock(block.startMin)}',
        detail: '${Format.estimate(now.untilMin)} before ${block.title}',
      );
    }
    if (now.dayDone) return (title: "The day's done", detail: 'Time to rest');
    return (
      title: 'Free for the rest of the day',
      detail: bedtimeMin == null
          ? '${Format.estimate(now.untilMin)} of the day left'
          : '${Format.estimate(now.untilMin)} until bed at ${Format.clock(bedtimeMin)}',
    );
  }
}
