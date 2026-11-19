import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/find_time.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/task_slot.dart';

void main() {
  DayCapacity day(DateTime date, List<Gap> gaps) => DayCapacity(
    date: date,
    committedMin: 0,
    wakingMin: 16 * 60,
    gaps: gaps,
    overheadMin: 0,
    usableMin: 0,
    sleepMin: 8 * 60,
    discardedGapMin: 0,
  );
  // Friday free 9–10 and 14–16; Saturday free 10–13.
  final days = [
    day(DateTime(2026, 9, 11), const [Gap(9 * 60, 10 * 60), Gap(14 * 60, 16 * 60)]),
    day(DateTime(2026, 9, 12), const [Gap(10 * 60, 13 * 60)]),
  ];
  List<TaskSlot> none(DateTime _) => const [];

  test('the first free time from now that holds it whole', () {
    expect(FindTime.next(days: days, slotsOn: none, minutes: 45, now: DateTime(2026, 9, 11, 8)),
        DateTime(2026, 9, 11, 9));
    expect(FindTime.next(days: days, slotsOn: none, minutes: 90, now: DateTime(2026, 9, 11, 8)),
        DateTime(2026, 9, 11, 14), reason: '9–10 is too short');
    expect(FindTime.next(days: days, slotsOn: none, minutes: 30, now: DateTime(2026, 9, 11, 9, 41)),
        DateTime(2026, 9, 11, 14), reason: 'from now, on the next five minutes, 9:45–10 is too short');
  });

  test('on to the next day, but never past the day it is due', () {
    expect(FindTime.next(days: days, slotsOn: none, minutes: 150, now: DateTime(2026, 9, 11, 8)),
        DateTime(2026, 9, 12, 10));
    expect(FindTime.next(days: days, slotsOn: none, minutes: 150, now: DateTime(2026, 9, 11, 8),
        dueDay: DateTime(2026, 9, 11)), isNull);
  });

  test("around tasks that already have the time", () {
    List<TaskSlot> busy(DateTime d) => d.day == 11
        ? const [TaskSlot(taskId: 't', title: 't', startMin: 9 * 60, endMin: 10 * 60)]
        : const [];
    expect(FindTime.next(days: days, slotsOn: busy, minutes: 30, now: DateTime(2026, 9, 11, 8)),
        DateTime(2026, 9, 11, 14));
  });
}
