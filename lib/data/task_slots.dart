import '../capacity/ledger.dart' show minutesInDay;
import '../capacity/task_slot.dart';
import 'db/database.dart';
import 'db/tables.dart';

export '../capacity/task_slot.dart';

abstract final class TaskSlots {
  /// How long a task given a time lasts when it has no estimate.
  static const defaultLengthMin = 60;

  /// How long [task] takes once it has a time: its estimate, or [defaultLengthMin].
  static int lengthOf(Task task) => task.estimateMin ?? defaultLengthMin;

  /// The date [task] has a time on, where you are. Null when it has none.
  static DateTime? plannedDayOf(Task task) {
    final at = task.startAt?.toLocal();
    return at == null ? null : DateTime(at.year, at.month, at.day);
  }

  /// Tasks with a time that falls on [day], by when they start: the part of each on that
  /// date, in minutes as the clock reads them. Deleted tasks are left out; done ones stay,
  /// and say so.
  static List<TaskSlot> on(DateTime day, Iterable<Task> tasks) {
    final midnight = DateTime(day.year, day.month, day.day);
    final next = DateTime(day.year, day.month, day.day + 1);

    // By the clock, not by elapsed time, which a change of clocks would throw off.
    int minuteOf(DateTime at) {
      final date = DateTime(at.year, at.month, at.day);
      if (date.isBefore(midnight)) return 0;
      if (date.isAfter(midnight)) return minutesInDay;
      return at.hour * 60 + at.minute;
    }

    final slots = [
      for (final task in tasks)
        if (task.deletedAt == null)
          if (task.startAt?.toLocal() case final start?)
            if (start.add(Duration(minutes: lengthOf(task))) case final end
                when start.isBefore(next) && end.isAfter(midnight))
              TaskSlot(
                taskId: task.id,
                title: task.title,
                startMin: minuteOf(start),
                endMin: minuteOf(end),
                done: task.status == TaskStatus.done,
              ),
    ];
    return slots..sort((a, b) {
      final byStart = a.startMin.compareTo(b.startMin);
      return byStart != 0 ? byStart : a.taskId.compareTo(b.taskId);
    });
  }
}
