import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';
import 'package:glasswork/capacity/slot_check.dart';

void main() {
  // A Wednesday up 07:00 to 23:30, with a lecture 09:00–10:30 and a lab 14:00–17:00.
  final day = CapacityLedger.forDay(DateTime(2026, 9, 16), const CapacitySettings(), [
    for (final (title, start, length) in [
      ('DBMS lecture', 9 * 60, 90),
      ('OS lab', 14 * 60, 180),
    ])
      FixedBlock(
        title: title,
        startMin: start,
        durationMin: length,
        recurrence: Recurrence.parse('FREQ=WEEKLY;BYDAY=WE'),
      ),
  ]);

  test('free time has nothing in the way', () {
    expect(SlotCheck.problems(day, startMin: 11 * 60, lengthMin: 120), isEmpty);
  });

  test('a clash names what it overlaps, and sleep and midnight say so', () {
    final problems = SlotCheck.problems(day, startMin: 11 * 60, lengthMin: 4 * 60);
    expect(problems, hasLength(1));
    final clash = problems.single as SlotClash;
    expect((clash.title, clash.startMin, clash.endMin), ('OS lab', 14 * 60, 17 * 60));

    expect(
      SlotCheck.problems(day, startMin: 23 * 60, lengthMin: 90).map((p) => p.runtimeType),
      containsAll([SlotAsleep, SlotPastMidnight]),
    );
    expect(
      SlotCheck.problems(day, startMin: 6 * 60, lengthMin: 30).single,
      isA<SlotAsleep>(),
    );
  });

  test('another task with a time is a clash too', () {
    final problems = SlotCheck.problems(
      day,
      startMin: 12 * 60,
      lengthMin: 60,
      others: const [('Call the bank', 12 * 60 + 30, 13 * 60)],
    );
    expect((problems.single as SlotClash).title, 'Call the bank');
  });

  test('the next free time long enough, from a time, around other tasks', () {
    expect(SlotCheck.nextFree(day, lengthMin: 60), 7 * 60);
    expect(SlotCheck.nextFree(day, lengthMin: 60, fromMin: 9 * 60 + 15), 10 * 60 + 30);
    // 10:30–14:00 is free, but a task at 11:00–13:30 leaves only half an hour either side.
    expect(
      SlotCheck.nextFree(
        day,
        lengthMin: 60,
        fromMin: 10 * 60 + 30,
        others: const [('Revise', 11 * 60, 13 * 60 + 30)],
      ),
      17 * 60,
    );
    expect(SlotCheck.nextFree(day, lengthMin: 12 * 60), isNull);
  });
}
