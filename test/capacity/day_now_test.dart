import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/day_now.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/task_slot.dart';

void main() {
  DayCapacity day(List<BlockSpan> blocks, {(int, int) awake = (7 * 60, 23 * 60 + 30)}) => DayCapacity(
    date: DateTime(2026, 9, 16),
    committedMin: 0,
    wakingMin: awake.$2 - awake.$1,
    gaps: const [],
    overheadMin: 0,
    usableMin: 0,
    sleepMin: 0,
    discardedGapMin: 0,
    blocks: blocks,
    awake: [awake],
  );

  const lecture = BlockSpan(title: 'DBMS lecture', startMin: 9 * 60, endMin: 10 * 60 + 30);
  const lab = BlockSpan(title: 'Lab 6', startMin: 14 * 60, endMin: 16 * 60);
  Busy busy(BlockSpan block) =>
      Busy(title: block.title, startMin: block.startMin, endMin: block.endMin);

  test('inside a block: which, and until when', () {
    final now = DayNow.of(day([lecture, lab]), 10 * 60);
    expect(now.current, busy(lecture));
    expect(now.next, busy(lab));
    expect(now.untilMin, 30);
  });

  test('between blocks: free until the next one starts', () {
    final now = DayNow.of(day([lecture, lab]), 11 * 60 + 45);
    expect(now.current, isNull);
    expect(now.next, busy(lab));
    expect(now.untilMin, 2 * 60 + 15);
  });

  test('after the last block: free until the waking day ends, then done', () {
    final evening = DayNow.of(day([lecture, lab]), 20 * 60);
    expect((evening.current, evening.next, evening.untilMin), (null, null, 3 * 60 + 30));
    expect(evening.dayDone, isFalse);

    final late = DayNow.of(day([lecture, lab]), 23 * 60 + 45);
    expect(late.dayDone, isTrue);
  });

  test('before getting up, the day has not started', () {
    final early = DayNow.of(day([lecture]), 6 * 60);
    expect(early.beforeWaking, isTrue);
    expect(early.next, busy(lecture));
  });

  test('of overlapping blocks, now is busy until the later end', () {
    const long = BlockSpan(title: 'Travel', startMin: 9 * 60 + 30, endMin: 11 * 60);
    expect(DayNow.of(day([lecture, long]), 10 * 60).current, busy(long));
  });

  test('a task given a time is busy as a block is; one already done is not', () {
    const revise = TaskSlot(taskId: 'r', title: 'Revise', startMin: 11 * 60, endMin: 13 * 60);
    final during = DayNow.of(day([lecture, lab]), 12 * 60, tasks: const [revise]);
    expect(
      during.current,
      const Busy(title: 'Revise', startMin: 660, endMin: 780, taskId: 'r'),
    );
    expect((during.current!.isTask, during.untilMin), (true, 60));

    final before = DayNow.of(day([lecture, lab]), 10 * 60 + 45, tasks: const [revise]);
    expect((before.next?.title, before.untilMin), ('Revise', 15));

    const done = TaskSlot(
      taskId: 'r',
      title: 'Revise',
      startMin: 11 * 60,
      endMin: 13 * 60,
      done: true,
    );
    expect(DayNow.of(day([lecture, lab]), 12 * 60, tasks: const [done]).current, isNull);
  });
}
