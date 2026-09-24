import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/task_order.dart';

final monday = DateTime(2026, 9, 14);

Task task({
  required String id,
  required int addedDaysAgo,
  String? dueDate,
  int priority = 0,
  String listId = 'l',
  String orderKey = 'a0',
  TaskStatus status = TaskStatus.open,
}) => Task(
  id: id,
  workspaceId: 'ws',
  listId: listId,
  title: id,
  orderKey: orderKey,
  status: status,
  priority: priority,
  slipCount: 0,
  createdAt: monday.subtract(Duration(days: addedDaysAgo)),
  updatedAt: monday,
  fieldVersions: '{}',
  dueDate: dueDate,
);

List<String> ids(List<Task> tasks) => [for (final t in tasks) t.id];

void main() {
  test('manual is the order the rows already carry', () {
    final tasks = [
      task(id: 'b', addedDaysAgo: 1),
      task(id: 'a', addedDaysAgo: 9),
    ];
    expect(ids(TaskOrder.by(TaskSort.manual, tasks)), ['b', 'a']);
  });

  test('added puts the newest first', () {
    final tasks = [
      task(id: 'old', addedDaysAgo: 30),
      task(id: 'new', addedDaysAgo: 1),
      task(id: 'middle', addedDaysAgo: 7),
    ];
    expect(ids(TaskOrder.by(TaskSort.added, tasks)), ['new', 'middle', 'old']);
  });

  test('several added in the same second keep the order they were appended in', () {
    // What a pasted list of tasks looks like: one timestamp, one after another.
    final tasks = [
      task(id: 'first', addedDaysAgo: 2, orderKey: 'a0'),
      task(id: 'second', addedDaysAgo: 2, orderKey: 'a1'),
      task(id: 'third', addedDaysAgo: 2, orderKey: 'a2'),
    ];
    expect(ids(TaskOrder.by(TaskSort.added, tasks)), [
      'third',
      'second',
      'first',
    ]);
  });

  test('added ends at the id, so every device shows the same order', () {
    final tasks = [
      task(id: 'zeta', addedDaysAgo: 2),
      task(id: 'alpha', addedDaysAgo: 2),
    ];
    expect(ids(TaskOrder.by(TaskSort.added, tasks)), ['alpha', 'zeta']);
    expect(ids(TaskOrder.by(TaskSort.added, tasks.reversed.toList())), [
      'alpha',
      'zeta',
    ]);
  });

  test('due is soonest first, and the undated come after everything dated', () {
    final tasks = [
      task(id: 'none', addedDaysAgo: 1),
      task(id: 'friday', addedDaysAgo: 2, dueDate: '2026-09-18'),
      task(id: 'tuesday', addedDaysAgo: 3, dueDate: '2026-09-15'),
    ];
    expect(ids(TaskOrder.by(TaskSort.due, tasks)), [
      'tuesday',
      'friday',
      'none',
    ]);
  });

  test('undated tasks keep the added order between themselves', () {
    final tasks = [
      task(id: 'older', addedDaysAgo: 9),
      task(id: 'newer', addedDaysAgo: 1),
    ];
    expect(ids(TaskOrder.by(TaskSort.due, tasks)), ['newer', 'older']);
  });

  test('priority is highest first, then whichever is due soonest', () {
    final tasks = [
      task(id: 'low-soon', addedDaysAgo: 1, priority: 1, dueDate: '2026-09-15'),
      task(id: 'high-late', addedDaysAgo: 2, priority: 3, dueDate: '2026-09-30'),
      task(id: 'high-soon', addedDaysAgo: 3, priority: 3, dueDate: '2026-09-16'),
    ];
    expect(ids(TaskOrder.by(TaskSort.priority, tasks)), [
      'high-soon',
      'high-late',
      'low-soon',
    ]);
  });

  test('a collection with no manual order of its own falls back to added', () {
    final tasks = [
      task(id: 'old', addedDaysAgo: 30, listId: 'one'),
      task(id: 'new', addedDaysAgo: 1, listId: 'two'),
    ];
    expect(ids(TaskOrder.collected(TaskSort.manual, tasks)), ['new', 'old']);
    // A sort that was asked for is still honoured.
    expect(ids(TaskOrder.collected(TaskSort.due, tasks)), ['new', 'old']);
  });

  test('sorting leaves the list it was given alone', () {
    final tasks = [
      task(id: 'old', addedDaysAgo: 30),
      task(id: 'new', addedDaysAgo: 1),
    ];
    TaskOrder.by(TaskSort.added, tasks);
    expect(ids(tasks), ['old', 'new']);
  });

  test('an unknown stored sort reads as none, not as a crash', () {
    expect(TaskSort.named('added'), TaskSort.added);
    expect(TaskSort.named('whatever-comes-next'), isNull);
    expect(TaskSort.named(null), isNull);
    expect(TaskSort.named(7), isNull);
  });
}
