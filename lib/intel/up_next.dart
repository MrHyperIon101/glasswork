/// A task Up next may choose.
class UpNextCandidate {
  const UpNextCandidate({
    required this.id,
    required this.title,
    required this.minutes,
    this.dueDay,
    this.priority = 0,
    this.startDay,
  });

  final String id;
  final String title;
  final int minutes;
  final DateTime? dueDay;
  final int priority;

  /// The day the scheduler would start it on.
  final DateTime? startDay;
}

/// Up next: the one open task to start now. Of the work the scheduler puts on today — what is
/// overdue, then what is due soonest, the more important first — the first that fits in the
/// time before the next fixed thing in the day, or else simply the first. Pure.
abstract final class UpNext {
  static UpNextCandidate? pick(List<UpNextCandidate> open, {required DateTime today, int? freeMin}) {
    final day = DateTime(today.year, today.month, today.day);
    bool onToday(DateTime? d) => d != null && !DateTime(d.year, d.month, d.day).isAfter(day);
    final now = [
      for (final t in open)
        if (onToday(t.startDay) || onToday(t.dueDay)) t,
    ]..sort((a, b) {
        final byDue = (a.dueDay ?? DateTime(9999)).compareTo(b.dueDay ?? DateTime(9999));
        if (byDue != 0) return byDue;
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
      });
    if (now.isEmpty) return null;
    if (freeMin != null) {
      for (final t in now) {
        if (t.minutes <= freeMin) return t;
      }
    }
    return now.first;
  }
}
