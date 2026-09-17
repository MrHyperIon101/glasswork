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
  DateTime? remindAt,
  int priority = 0,
}) {
  return Task(
    id: id,
    workspaceId: 'ws',
    listId: 'l',
    title: title,
    orderKey: 'a0',
    status: status,
    priority: priority,
    slipCount: 0,
    createdAt: now,
    updatedAt: now,
    fieldVersions: '{}',
    dueAt: dueAt,
    dueDate: dueDate,
    completedAt: completedAt,
    deletedAt: deletedAt,
    estimateMin: estimateMin,
    remindAt: remindAt,
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

  test('completions are counted for each of the last seven days, today last', () {
    final stats = TaskStats.from([
      task(id: 'today', status: TaskStatus.done, completedAt: now),
      task(id: 'today2', status: TaskStatus.done, completedAt: now.subtract(const Duration(hours: 5))),
      task(id: 'yesterday', status: TaskStatus.done, completedAt: DateTime(2026, 9, 15, 23, 59)),
      task(id: 'six ago', status: TaskStatus.done, completedAt: DateTime(2026, 9, 10, 8)),
      task(id: 'seven ago', status: TaskStatus.done, completedAt: DateTime(2026, 9, 9, 8)),
      task(id: 'open'),
    ], now);

    expect(stats.doneByDay, [1, 0, 0, 0, 0, 1, 2]);
  });

  test('the next reminder is the soonest still to come on an open task', () {
    final stats = TaskStats.from([
      task(id: 'passed', remindAt: now.subtract(const Duration(minutes: 5))),
      task(id: 'later', remindAt: now.add(const Duration(hours: 3))),
      task(id: 'soon', remindAt: now.add(const Duration(minutes: 20))),
      task(
        id: 'done',
        status: TaskStatus.done,
        completedAt: now,
        remindAt: now.add(const Duration(minutes: 1)),
      ),
    ], now);

    expect(stats.nextReminder?.id, 'soon');
  });

  test('next up is the soonest future task, never an overdue one', () {
    final stats = TaskStats.from([
      task(id: 'late', dueDate: '2026-09-10'),
      task(id: 'far', dueDate: '2026-09-30'),
      task(id: 'near', dueDate: '2026-09-18'),
    ], now);

    expect(stats.nextUp?.id, 'near');
  });

  test('coming up is the next week after today, soonest first', () {
    final stats = TaskStats.from([
      task(id: 'today', dueDate: '2026-09-16'),
      task(id: 'late', dueDate: '2026-09-15'),
      task(id: 'sat', dueDate: '2026-09-19'),
      task(id: 'tomorrow all day', dueDate: '2026-09-17'),
      task(id: 'tomorrow 9am', dueAt: DateTime(2026, 9, 17, 9)),
      task(id: 'tomorrow, urgent', dueDate: '2026-09-17', priority: 3),
      // A week from today is the last day in; the day after is not.
      task(id: 'a week on', dueDate: '2026-09-23'),
      task(id: 'eight days on', dueDate: '2026-09-24'),
      task(id: 'done', dueDate: '2026-09-18', status: TaskStatus.done, completedAt: now),
      task(id: 'undated'),
    ], now);

    expect(stats.comingUp.map((t) => t.id), [
      'tomorrow 9am',
      'tomorrow, urgent',
      'tomorrow all day',
      'sat',
      'a week on',
    ]);
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
