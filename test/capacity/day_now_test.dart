import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/day_now.dart';
import 'package:glasswork/capacity/ledger.dart';

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

  test('inside a block: which, and until when', () {
    final now = DayNow.of(day([lecture, lab]), 10 * 60);
    expect(now.current, lecture);
    expect(now.next, lab);
    expect(now.untilMin, 30);
  });

  test('between blocks: free until the next one starts', () {
    final now = DayNow.of(day([lecture, lab]), 11 * 60 + 45);
    expect(now.current, isNull);
    expect(now.next, lab);
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
    expect(early.next, lecture);
  });

  test('of overlapping blocks, now is busy until the later end', () {
    const long = BlockSpan(title: 'Travel', startMin: 9 * 60 + 30, endMin: 11 * 60);
    expect(DayNow.of(day([lecture, long]), 10 * 60).current, long);
  });
}
