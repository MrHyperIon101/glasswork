import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/task_slots.dart';

final _created = DateTime(2026, 9, 1);

Task task(
  String id, {
  DateTime? startAt,
  int? estimateMin,
  TaskStatus status = TaskStatus.open,
  DateTime? deletedAt,
}) => Task(
  id: id,
  workspaceId: 'ws',
  listId: 'l',
  title: id,
  orderKey: 'a0',
  status: status,
  priority: 0,
  slipCount: 0,
  createdAt: _created,
  updatedAt: _created,
  fieldVersions: '{}',
  startAt: startAt?.toUtc(),
  estimateMin: estimateMin,
  deletedAt: deletedAt,
);

void main() {
  final fri = DateTime(2026, 9, 18);

  test('a task with a time lasts as long as its estimate, or an hour without one', () {
    final slots = TaskSlots.on(fri, [
      task('revise', startAt: DateTime(2026, 9, 18, 16), estimateMin: 120),
      task('call', startAt: DateTime(2026, 9, 18, 9, 30)),
      task('undated'),
      task('another day', startAt: DateTime(2026, 9, 19, 10), estimateMin: 30),
    ]);
    expect(slots, const [
      TaskSlot(taskId: 'call', title: 'call', startMin: 9 * 60 + 30, endMin: 10 * 60 + 30),
      TaskSlot(taskId: 'revise', title: 'revise', startMin: 16 * 60, endMin: 18 * 60),
    ]);
  });

  test('a task running past midnight is split between the two days', () {
    final late = [task('essay', startAt: DateTime(2026, 9, 18, 23, 30), estimateMin: 90)];
    expect(
      TaskSlots.on(fri, late).single,
      const TaskSlot(taskId: 'essay', title: 'essay', startMin: 23 * 60 + 30, endMin: 1440),
    );
    expect(
      TaskSlots.on(DateTime(2026, 9, 19), late).single,
      const TaskSlot(taskId: 'essay', title: 'essay', startMin: 0, endMin: 60),
    );
  });

  test('deleted tasks leave the day; done ones stay and say so', () {
    final slots = TaskSlots.on(fri, [
      task('gone', startAt: DateTime(2026, 9, 18, 8), deletedAt: _created),
      task('finished', startAt: DateTime(2026, 9, 18, 8), status: TaskStatus.done),
    ]);
    expect([for (final s in slots) (s.taskId, s.done)], [('finished', true)]);
  });

  test('the day a task has a time on, where you are', () {
    expect(
      TaskSlots.plannedDayOf(task('t', startAt: DateTime(2026, 9, 18, 23, 59))),
      DateTime(2026, 9, 18),
    );
    expect(TaskSlots.plannedDayOf(task('t')), isNull);
  });
}
