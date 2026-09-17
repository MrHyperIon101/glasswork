import 'ledger.dart';
import 'task_slot.dart';

/// Something taking up part of a day: a block of the timetable, or a task given a time.
class Busy {
  const Busy({
    required this.title,
    required this.startMin,
    required this.endMin,
    this.taskId,
  });

  final String title;
  final int startMin;
  final int endMin;

  /// The task, where it is one.
  final String? taskId;

  bool get isTask => taskId != null;

  @override
  bool operator ==(Object other) =>
      other is Busy &&
      other.title == title &&
      other.startMin == startMin &&
      other.endMin == endMin &&
      other.taskId == taskId;

  @override
  int get hashCode => Object.hash(title, startMin, endMin, taskId);

  @override
  String toString() => 'Busy($title $startMin–$endMin${isTask ? ', task' : ''})';
}

/// Where a day stands at a moment: inside a block or a task given a time, free until the
/// next one, or done.
///
/// Worked out from what the ledger counted, so "free until 14:00" means exactly the time
/// the rest of the app counts as free.
class DayNow {
  const DayNow._({
    required this.current,
    required this.next,
    required this.untilMin,
    required this.awakeEndMin,
    required this.beforeWaking,
  });

  /// What is happening now.
  final Busy? current;

  /// What starts next.
  final Busy? next;

  /// Minutes until what comes next: [current] ending, [next] starting, or the end of the
  /// waking day. Zero once the day is done.
  final int untilMin;

  /// When the waking day ends, in minutes past midnight.
  final int awakeEndMin;

  /// Whether the day has not started yet.
  final bool beforeWaking;

  bool get dayDone => current == null && next == null && untilMin == 0 && !beforeWaking;

  /// Where [day] stands at [nowMin], among its blocks and [tasks]. A task already done
  /// takes no more of the day.
  static DayNow of(DayCapacity day, int nowMin, {List<TaskSlot> tasks = const []}) {
    final awakeStart = day.awake.isEmpty ? 0 : day.awake.first.$1;
    final awakeEnd = day.awake.isEmpty ? minutesInDay : day.awake.last.$2;

    final spans = [
      for (final block in day.blocks)
        Busy(title: block.title, startMin: block.startMin, endMin: block.endMin),
      for (final task in tasks)
        if (!task.done)
          Busy(
            title: task.title,
            startMin: task.startMin,
            endMin: task.endMin,
            taskId: task.taskId,
          ),
    ];

    Busy? current;
    Busy? next;
    for (final block in spans) {
      if (block.startMin <= nowMin && nowMin < block.endMin) {
        // Of blocks that overlap, the one ending last is what now is busy until.
        if (current == null || block.endMin > current.endMin) current = block;
      } else if (block.startMin > nowMin && (next == null || block.startMin < next.startMin)) {
        next = block;
      }
    }

    final until = current != null
        ? current.endMin - nowMin
        : next != null
        ? next.startMin - nowMin
        : (awakeEnd - nowMin).clamp(0, minutesInDay);

    return DayNow._(
      current: current,
      next: next,
      untilMin: until,
      awakeEndMin: awakeEnd,
      beforeWaking: nowMin < awakeStart,
    );
  }
}
