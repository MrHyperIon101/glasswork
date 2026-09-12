import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/task_stats.dart';

/// Wednesday, mid-afternoon.
final now = DateTime(2026, 9, 16, 15, 0);

Task task({
  String id = 't',
  String title = 'task',
  TaskStatus status = TaskStatus.open,
  DateTime? dueAt,
  String? dueDate,
  DateTime? completedAt,
  DateTime? deletedAt,
  int? estimateMin,
}) {
  return Task(
    id: id,
    workspaceId: 'ws',
    listId: 'l',
    title: title,
    orderKey: 'a0',
    status: status,
    priority: 0,
    slipCount: 0,
    createdAt: now,
    updatedAt: now,
    fieldVersions: '{}',
    dueAt: dueAt,
    dueDate: dueDate,
    completedAt: completedAt,
    deletedAt: deletedAt,
    estimateMin: estimateMin,
  );
}

void main() {
  test('counts open tasks and ignores completed ones', () {
    final stats = TaskStats.from([
      task(id: '1'),
      task(id: '2'),
      task(id: '3', status: TaskStatus.done, completedAt: now),
    ], now);

    expect(stats.open, 2);
  });

  test('tombstoned tasks are invisible to every figure', () {
    final stats = TaskStats.from([
      task(id: '1', deletedAt: now, dueDate: '2026-09-16'),
    ], now);

    expect(stats.open, 0);
    expect(stats.dueToday, isEmpty);
    expect(stats.overdue, isEmpty);
  });

  test('a timed task is overdue the moment its instant passes', () {
    final stats = TaskStats.from([
      task(id: 'past', dueAt: DateTime(2026, 9, 16, 14, 0)),
      task(id: 'later', dueAt: DateTime(2026, 9, 16, 16, 0)),
    ], now);

    expect(stats.overdue.map((t) => t.id), ['past']);
    expect(stats.dueToday.map((t) => t.id), ['later']);
  });

  test('an all-day task is not overdue until the day has gone', () {
    // Due today all-day, and it is already 15:00 — still not late.
    final stats = TaskStats.from([
      task(id: 'today', dueDate: '2026-09-16'),
      task(id: 'yesterday', dueDate: '2026-09-15'),
    ], now);

    expect(stats.dueToday.map((t) => t.id), ['today']);
    expect(stats.overdue.map((t) => t.id), ['yesterday']);
  });

  test('estimate totals today and counts what it could not include', () {
    final stats = TaskStats.from([
      task(id: '1', dueDate: '2026-09-16', estimateMin: 60),
      task(id: '2', dueDate: '2026-09-16', estimateMin: 30),
      task(id: '3', dueDate: '2026-09-16'),
      task(id: '4', dueDate: '2026-09-15', estimateMin: 15),
      // Not due today, so out of the total entirely.
      task(id: '5', dueDate: '2026-09-20', estimateMin: 500),
    ], now);

    expect(stats.estimatedMinutesToday, 105);
    expect(stats.untimedToday, 1);
  });

  test('completed counts are scoped to today and to the week', () {
    final stats = TaskStats.from([
      task(
        id: 'today',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 9, 16, 9),
      ),
      task(
        id: 'monday',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 9, 14, 9),
      ),
      // Previous week — inside neither.
      task(
        id: 'lastweek',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 9, 11, 9),
      ),
    ], now);

    expect(stats.completedToday, 1);
    expect(stats.completedThisWeek, 2);
  });

  test('next up is the soonest future task, never an overdue one', () {
    final stats = TaskStats.from([
      task(id: 'late', dueDate: '2026-09-10'),
      task(id: 'far', dueDate: '2026-09-30'),
      task(id: 'near', dueDate: '2026-09-18'),
    ], now);

    expect(stats.nextUp?.id, 'near');
  });

  test('progress is null when nothing is due rather than zero', () {
    expect(TaskStats.from([], now).todayProgress, isNull);
  });

  test('progress counts today completions against today total', () {
    final stats = TaskStats.from([
      task(id: '1', dueDate: '2026-09-16'),
      task(id: '2', dueDate: '2026-09-16'),
      task(
        id: '3',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 9, 16, 10),
      ),
      task(
        id: '4',
        status: TaskStatus.done,
        completedAt: DateTime(2026, 9, 16, 11),
      ),
    ], now);

    expect(stats.todayTotal, 2);
    expect(stats.todayProgress, 0.5);
  });

  test('tasks with no due date count as open but land in no bucket', () {
    final stats = TaskStats.from([task(id: 'someday')], now);

    expect(stats.open, 1);
    expect(stats.dueToday, isEmpty);
    expect(stats.overdue, isEmpty);
    expect(stats.nextUp, isNull);
  });
}
