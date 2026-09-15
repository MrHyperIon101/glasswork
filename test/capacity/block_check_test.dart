import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/block_check.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';

FixedBlock block(
  String title,
  int startMin,
  int durationMin, {
  String byday = 'MO,WE,FR',
}) => FixedBlock(
  title: title,
  startMin: startMin,
  durationMin: durationMin,
  recurrence: Recurrence.parse('FREQ=WEEKLY;BYDAY=$byday'),
);

/// Up at 07:00 and to bed at 23:30, every day.
const settings = CapacitySettings();
const mondays = {DateTime.monday};

/// The standard week, with [changes] made to some days.
CapacitySettings weekWith(Map<int, DaySleep> changes) => CapacitySettings(
  sleep: [
    for (var day = DateTime.monday; day <= DateTime.sunday; day++)
      changes[day] ?? CapacitySettings.standardWeek[day - 1],
  ],
);

void main() {
  final dbms = block('DBMS lecture', 9 * 60, 90);

  group('problems', () {
    test('none for a block in free waking time', () {
      expect(
        BlockCheck.problems(
          startMin: 11 * 60,
          durationMin: 60,
          weekdays: mondays,
          settings: settings,
          others: [dbms],
        ),
        isEmpty,
      );
    });

    test('a block at midnight falls while asleep, on every day it repeats', () {
      final problems = BlockCheck.problems(
        startMin: 0,
        durationMin: 60,
        weekdays: {1, 2, 3, 4, 5},
        settings: settings,
      );

      expect((problems.single as DuringSleep).weekdays, {1, 2, 3, 4, 5});
    });

    test('ending at bedtime, or starting on waking, is fine', () {
      expect(
        BlockCheck.problems(
          startMin: 22 * 60 + 30,
          durationMin: 60,
          weekdays: mondays,
          settings: settings,
        ),
        isEmpty,
      );
      expect(
        BlockCheck.problems(
          startMin: 7 * 60,
          durationMin: 60,
          weekdays: mondays,
          settings: settings,
        ),
        isEmpty,
      );
    });

    test('with a bedtime after midnight, midnight is awake', () {
      final late = CapacitySettings.sameEveryDay(wakeMin: 9 * 60, bedtimeMin: 2 * 60);
      expect(
        BlockCheck.problems(
          startMin: 0,
          durationMin: 60,
          weekdays: mondays,
          settings: late,
        ),
        isEmpty,
      );
    });

    test('sleep is checked day by day', () {
      // Up late only after Friday, so 00:30 is awake on Saturday and asleep on Tuesday.
      final s = weekWith({
        DateTime.friday: const DaySleep(wakeMin: 7 * 60, bedtimeMin: 2 * 60),
      });
      final problems = BlockCheck.problems(
        startMin: 30,
        durationMin: 60,
        weekdays: {DateTime.tuesday, DateTime.saturday},
        settings: s,
      );
      expect((problems.single as DuringSleep).weekdays, {DateTime.tuesday});
    });

    test('running past midnight is a problem of its own', () {
      final problems = BlockCheck.problems(
        startMin: 22 * 60,
        durationMin: 3 * 60,
        weekdays: mondays,
        settings: settings,
      );
      expect(problems.whereType<PastMidnight>(), hasLength(1));
      expect(problems.whereType<DuringSleep>(), hasLength(1));
    });

    test('past midnight, the next day\'s sleep is the one that counts', () {
      // Friday runs until 02:00, so a block from 23:00 to 01:00 is awake throughout.
      final s = weekWith({
        DateTime.friday: const DaySleep(wakeMin: 7 * 60, bedtimeMin: 2 * 60),
      });
      final problems = BlockCheck.problems(
        startMin: 23 * 60,
        durationMin: 2 * 60,
        weekdays: {DateTime.friday},
        settings: s,
      );
      expect(problems.single, isA<PastMidnight>());
    });

    test('a clash names the other block and only the days they share', () {
      final problems = BlockCheck.problems(
        startMin: 9 * 60 + 30,
        durationMin: 60,
        weekdays: {DateTime.monday, DateTime.tuesday},
        settings: settings,
        others: [dbms],
      );

      final clash = problems.single as Clash;
      expect(clash.title, 'DBMS lecture');
      expect(clash.weekdays, {DateTime.monday});
      expect((clash.startMin, clash.endMin), (9 * 60, 10 * 60 + 30));
    });

    test('no clash on days the other does not happen, or when they only touch', () {
      expect(
        BlockCheck.problems(
          startMin: 9 * 60,
          durationMin: 60,
          weekdays: {DateTime.tuesday},
          settings: settings,
          others: [dbms],
        ),
        isEmpty,
      );
      expect(
        BlockCheck.problems(
          startMin: 10 * 60 + 30,
          durationMin: 60,
          weekdays: mondays,
          settings: settings,
          others: [dbms],
        ),
        isEmpty,
      );
    });
  });

  group('nearest free start', () {
    int? nearest(
      int startMin,
      int durationMin, {
      Set<int> weekdays = mondays,
      List<FixedBlock> others = const [],
      CapacitySettings with_ = settings,
    }) => BlockCheck.nearestFreeStart(
      startMin: startMin,
      durationMin: durationMin,
      weekdays: weekdays,
      settings: with_,
      others: others,
    );

    test('moves a block out of sleep to when you wake', () {
      expect(nearest(0, 60), 7 * 60);
    });

    test('moves a late block back so it ends by bedtime', () {
      expect(nearest(23 * 60, 2 * 60), 21 * 60 + 30);
    });

    test('waits for the latest start of the days chosen', () {
      // A lie-in until 10:00 on Saturday.
      final s = weekWith({
        DateTime.saturday: const DaySleep(wakeMin: 10 * 60, bedtimeMin: 23 * 60 + 30),
      });
      expect(
        nearest(8 * 60, 60, weekdays: {DateTime.friday, DateTime.saturday}, with_: s),
        10 * 60,
      );
    });

    test('picks whichever side of a clash is closer', () {
      // 09:30 for an hour hits DBMS, 09:00–10:30. Before it the latest start is 08:00,
      // ninety minutes away; after it, 10:30 is sixty.
      expect(nearest(9 * 60 + 30, 60, others: [dbms]), 10 * 60 + 30);
    });

    test('keeps clear of blocks on every chosen day', () {
      // A Tuesday lab straight after DBMS pushes the later option to 11:30, and 08:00 is
      // now the closer one.
      final lab = block('Lab', 10 * 60 + 30, 60, byday: 'TU');
      expect(
        nearest(
          9 * 60 + 30,
          60,
          weekdays: {DateTime.monday, DateTime.tuesday},
          others: [dbms, lab],
        ),
        8 * 60,
      );
    });

    test('is null when nothing that long is free', () {
      expect(nearest(9 * 60, 17 * 60), isNull);
    });

    test('suggests a time with no problems', () {
      final start = nearest(9 * 60 + 30, 60, others: [dbms])!;
      expect(
        BlockCheck.problems(
          startMin: start,
          durationMin: 60,
          weekdays: mondays,
          settings: settings,
          others: [dbms],
        ),
        isEmpty,
      );
    });
  });
}
