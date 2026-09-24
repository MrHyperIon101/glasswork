import 'db/database.dart';
import 'task_stats.dart';

/// How a set of tasks is put in order on screen.
///
/// [manual] is the order the rows already carry — the fractional index a drag writes —
/// and it only means anything inside one section. A collection drawn from several
/// sections, like a smart view or a project's completed work, has no manual order to
/// respect: [TaskOrder.collected] falls back to [added] for those.
enum TaskSort {
  manual('Manual'),
  added('Added'),
  due('Due'),
  priority('Priority');

  const TaskSort(this.label);

  /// What the control calls it.
  final String label;

  /// The sort stored under [name], or null for anything unrecognised — a saved view from
  /// a newer version must not stop an older one opening it.
  static TaskSort? named(Object? name) {
    for (final sort in values) {
      if (sort.name == name) return sort;
    }
    return null;
  }
}

/// Orders tasks for display. Pure, and total: every comparison ends at the id, so two
/// devices showing the same tasks show them in the same order.
abstract final class TaskOrder {
  static List<Task> by(TaskSort sort, List<Task> tasks) => switch (sort) {
    TaskSort.manual => tasks,
    TaskSort.added => _sorted(tasks, _byAdded),
    TaskSort.due => _sorted(tasks, _byDue),
    TaskSort.priority => _sorted(tasks, _byPriority),
  };

  /// The order for a collection with no manual order of its own.
  static List<Task> collected(TaskSort sort, List<Task> tasks) =>
      by(sort == TaskSort.manual ? TaskSort.added : sort, tasks);

  /// Newest added first.
  ///
  /// `created_at` is kept to the second, so a handful of tasks pasted in at once all
  /// share one — and those are exactly the ones whose order a person remembers. The
  /// order key settles it: within a section it is the order they were appended in, and
  /// across sections it is at least the same answer on every device. The id is the last
  /// word, so the comparison is total.
  static int _byAdded(Task a, Task b) {
    final added = b.createdAt.compareTo(a.createdAt);
    if (added != 0) return added;
    final appended = b.orderKey.compareTo(a.orderKey);
    return appended != 0 ? appended : a.id.compareTo(b.id);
  }

  /// Soonest due first, and everything undated after everything dated — a task with no
  /// deadline is not due at the end of time, it is simply not in this ordering.
  static int _byDue(Task a, Task b) {
    final dueA = TaskStats.dueDayOf(a);
    final dueB = TaskStats.dueDayOf(b);
    if (dueA == null || dueB == null) {
      if (dueA == dueB) return _byAdded(a, b);
      return dueA == null ? 1 : -1;
    }
    final day = dueA.compareTo(dueB);
    return day != 0 ? day : _byAdded(a, b);
  }

  /// Highest priority first, then whichever is due soonest.
  static int _byPriority(Task a, Task b) {
    final priority = b.priority.compareTo(a.priority);
    return priority != 0 ? priority : _byDue(a, b);
  }

  static List<Task> _sorted(List<Task> tasks, int Function(Task, Task) compare) =>
      tasks.toList()..sort(compare);
}
