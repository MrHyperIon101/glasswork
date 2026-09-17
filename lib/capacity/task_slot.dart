/// A task given a time: the part of it that falls on one day.
///
/// A task's time is its `start_at`, and it lasts as long as its estimate, so a task planned
/// from 16:00 for two hours is 16:00–18:00 on the time budget, on the home screen's day and
/// in the scheduler's figures, with nothing else to keep in step.
class TaskSlot {
  const TaskSlot({
    required this.taskId,
    required this.title,
    required this.startMin,
    required this.endMin,
    this.done = false,
  });

  final String taskId;
  final String title;

  /// Minutes past midnight of the day, clipped to it.
  final int startMin;
  final int endMin;

  final bool done;

  int get lengthMin => endMin - startMin;

  @override
  bool operator ==(Object other) =>
      other is TaskSlot &&
      other.taskId == taskId &&
      other.title == title &&
      other.startMin == startMin &&
      other.endMin == endMin &&
      other.done == done;

  @override
  int get hashCode => Object.hash(taskId, title, startMin, endMin, done);

  @override
  String toString() => 'TaskSlot($title $startMin–$endMin${done ? ', done' : ''})';
}
