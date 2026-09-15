import '../data/db/database.dart';
import '../data/db/tables.dart';

/// A reminder a device should raise.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.taskId,
    required this.at,
    required this.title,
    this.body = '',
  });

  /// The platform's notification id. Stable for a task, so a reminder moved to a new time
  /// replaces its earlier notification instead of adding a second.
  final int id;

  final String taskId;

  /// When, in UTC.
  final DateTime at;

  final String title;

  /// A line under the title, such as when the task is due.
  final String body;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.taskId == taskId &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, taskId, at, title, body);

  @override
  String toString() => 'PlannedReminder($taskId at $at: $title)';
}

/// Which reminders a device should have scheduled.
///
/// Pure, so the same tasks always give the same plan, and a device only asks its platform
/// to change anything when the plan actually changes.
abstract final class ReminderPlan {
  /// The most a device holds at once. Android refuses more than 500 alarms from an app,
  /// and nobody needs more than the next few dozen: later ones are scheduled as these fire
  /// and the plan is worked out again.
  static const limit = 64;

  /// Reminders still ahead of [now], soonest first, for tasks that are open and not
  /// deleted. [describe] writes each one's body.
  static List<PlannedReminder> upcoming(
    Iterable<Task> tasks,
    DateTime now, {
    String Function(Task task)? describe,
    int limit = limit,
  }) {
    final planned = [
      for (final task in tasks)
        if (task.remindAt case final at?
            when task.deletedAt == null &&
                task.status == TaskStatus.open &&
                at.isAfter(now))
          PlannedReminder(
            id: notificationId(task.id),
            taskId: task.id,
            at: at.toUtc(),
            title: task.title,
            body: describe?.call(task) ?? '',
          ),
    ]..sort((a, b) {
        final byTime = a.at.compareTo(b.at);
        return byTime != 0 ? byTime : a.taskId.compareTo(b.taskId);
      });
    return planned.take(limit).toList();
  }

  /// A notification id for [taskId]: a 31-bit FNV-1a hash, since platform ids are signed
  /// 32-bit integers and task ids are UUIDs.
  static int notificationId(String taskId) {
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
