/// A task as the evening's review sees it.
class ReviewTask {
  const ReviewTask({required this.id, required this.title, this.completedAt, this.dueDay, this.done = false});

  final String id;
  final String title;
  final bool done;
  final DateTime? completedAt;

  /// The day it is due, if it has one.
  final DateTime? dueDay;
}

class DailyReview {
  const DailyReview({required this.done, required this.slipped, required this.focusMin, required this.plannedMin});

  /// Finished today.
  final List<ReviewTask> done;

  /// Due today or before, and still open: what to decide about before tomorrow.
  final List<ReviewTask> slipped;

  /// Minutes focused today, and minutes of work the plan had for today.
  final int focusMin;
  final int plannedMin;

  /// "3 done, 2 slipped · 1h 40m focused of 3h planned" — the day in a line, worked out by
  /// the caller's own formatting from these figures.
  bool get isEmpty => done.isEmpty && slipped.isEmpty && focusMin == 0;
}

/// The day, looked back on: what got done, what slipped, and focus against plan. Pure.
abstract final class DailyReviewer {
  static DailyReview of({
    required List<ReviewTask> tasks,
    required DateTime today,
    required int focusMin,
    required int plannedMin,
  }) {
    bool isToday(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;
    final end = DateTime(today.year, today.month, today.day + 1);
    return DailyReview(
      done: [
        for (final t in tasks)
          if (t.done && t.completedAt != null && isToday(t.completedAt!.toLocal())) t,
      ],
      slipped: [
        for (final t in tasks)
          if (!t.done && t.dueDay != null && t.dueDay!.isBefore(end)) t,
      ]..sort((a, b) => a.dueDay!.compareTo(b.dueDay!)),
      focusMin: focusMin,
      plannedMin: plannedMin,
    );
  }
}
