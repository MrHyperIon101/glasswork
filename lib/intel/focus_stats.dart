/// What the focus timer has tracked: time focused today, this week and on each day, the
/// streak of days with some, and the time on each task. Pure: sessions in, figures out.
library;

/// A focus session as the figures see it.
class TrackedSession {
  const TrackedSession({
    required this.startedAt,
    required this.plannedMin,
    this.endedAt,
    this.taskId,
    this.isBreak = false,
  });

  final DateTime startedAt;
  final DateTime? endedAt;
  final int plannedMin;
  final String? taskId;
  final bool isBreak;

  /// When it ended, or for one still running, now — but never past its planned length.
  DateTime endAt(DateTime now) {
    final planned = startedAt.add(Duration(minutes: plannedMin));
    final end = endedAt ?? now;
    return end.isAfter(planned) ? planned : end;
  }

  /// Whole minutes it ran for, at [now].
  int minutesAt(DateTime now) {
    final ran = endAt(now).difference(startedAt);
    return ran.isNegative ? 0 : ran.inMinutes;
  }
}

class FocusStats {
  const FocusStats({
    required this.todayMin,
    required this.weekMin,
    required this.byDay,
    required this.streakDays,
    required this.byTask,
  });

  /// Minutes focused today.
  final int todayMin;

  /// Minutes focused in the last seven days, today included.
  final int weekMin;

  /// Minutes focused on each of the last seven days, the oldest first, today last.
  final List<int> byDay;

  /// Days in a row, up to today, with some focus. Today still counts while it has none yet,
  /// if yesterday had some: a streak is not broken by the morning.
  final int streakDays;

  /// Minutes focused on each task, by its id.
  final Map<String, int> byTask;

  /// Works the figures out at [now]. Breaks are not focus, and count for nothing.
  static FocusStats of(List<TrackedSession> sessions, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final perDay = <DateTime, int>{};
    final byTask = <String, int>{};
    for (final s in sessions) {
      if (s.isBreak) continue;
      final minutes = s.minutesAt(now);
      if (minutes <= 0) continue;
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      perDay[day] = (perDay[day] ?? 0) + minutes;
      if (s.taskId case final id?) byTask[id] = (byTask[id] ?? 0) + minutes;
    }
    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
    final byDay = [for (var n = 6; n >= 0; n--) perDay[daysAgo(n)] ?? 0];

    var streak = 0;
    for (var n = (perDay[today] ?? 0) > 0 ? 0 : 1; (perDay[daysAgo(n)] ?? 0) > 0; n++) {
      streak++;
    }
    return FocusStats(
      todayMin: perDay[today] ?? 0,
      weekMin: byDay.fold(0, (a, b) => a + b),
      byDay: byDay,
      streakDays: streak,
      byTask: byTask,
    );
  }
}
