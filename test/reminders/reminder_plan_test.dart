import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/reminders/reminder_plan.dart';

final now = DateTime.utc(2026, 9, 15, 12);

Task task(
  String id, {
  DateTime? remindAt,
  TaskStatus status = TaskStatus.open,
  DateTime? deletedAt,
}) => Task(
  id: id,
  createdAt: now,
  updatedAt: now,
  deletedAt: deletedAt,
  fieldVersions: '{}',
  workspaceId: 'ws',
  listId: 'list',
  title: 'Task $id',
  orderKey: 'a',
  status: status,
  priority: 0,
  slipCount: 0,
  remindAt: remindAt,
);

void main() {
  test('only open, live tasks with a reminder still ahead, soonest first', () {
    final plan = ReminderPlan.upcoming([
      task('later', remindAt: now.add(const Duration(days: 2))),
      task('sooner', remindAt: now.add(const Duration(hours: 1))),
      task('past', remindAt: now.subtract(const Duration(minutes: 1))),
      task('none'),
      task(
        'done',
        remindAt: now.add(const Duration(hours: 3)),
        status: TaskStatus.done,
      ),
      task(
        'deleted',
        remindAt: now.add(const Duration(hours: 3)),
        deletedAt: now,
      ),
    ], now);

    expect([for (final r in plan) r.taskId], ['sooner', 'later']);
    expect(plan.first.at, now.add(const Duration(hours: 1)));
    expect(plan.first.at.isUtc, isTrue);
    expect(plan.first.title, 'Task sooner');
  });

  test('describes each reminder with what it is given', () {
    final plan = ReminderPlan.upcoming(
      [task('a', remindAt: now.add(const Duration(hours: 1)))],
      now,
      describe: (t) => 'About ${t.id}',
    );
    expect(plan.single.body, 'About a');
  });

  test('keeps to the limit', () {
    final plan = ReminderPlan.upcoming(
      [
        for (var i = 0; i < 10; i++)
          task('t$i', remindAt: now.add(Duration(minutes: i + 1))),
      ],
      now,
      limit: 3,
    );
    expect([for (final r in plan) r.taskId], ['t0', 't1', 't2']);
  });

  test('a notification id is stable, positive, and differs between tasks', () {
    const id = '3f2b8c1e-0d5a-4e7b-9c4f-1a2b3c4d5e6f';
    expect(ReminderPlan.notificationId(id), ReminderPlan.notificationId(id));
    expect(ReminderPlan.notificationId(id), inInclusiveRange(0, 0x7fffffff));
    expect(
      ReminderPlan.notificationId(id),
      isNot(ReminderPlan.notificationId('3f2b8c1e-0d5a-4e7b-9c4f-1a2b3c4d5e70')),
    );
  });
}
