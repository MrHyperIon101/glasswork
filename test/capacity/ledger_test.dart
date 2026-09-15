import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';
import 'package:glasswork/capacity/timetable.dart';

/// A Wednesday.
final wed = DateTime(2026, 9, 16);
final thu = DateTime(2026, 9, 17);

FixedBlock block(
  String title,
  int startMin,
  int durationMin, {
  String rrule = 'FREQ=WEEKLY;BYDAY=WE',
}) => FixedBlock(
  title: title,
  startMin: startMin,
  durationMin: durationMin,
  recurrence: Recurrence.parse(rrule),
);

/// Up at 08:30 and to bed at 01:00, every day: a bedtime after midnight.
final late = CapacitySettings.sameEveryDay(wakeMin: 8 * 60 + 30, bedtimeMin: 60);

/// The standard week, with [changes] made to some days.
CapacitySettings weekWith(Map<int, DaySleep> changes) => CapacitySettings(
  sleep: [
    for (var day = DateTime.monday; day <= DateTime.sunday; day++)
      changes[day] ?? CapacitySettings.standardWeek[day - 1],
  ],
);

void main() {
  group('a day of sleep', () {
    test('ends at a bedtime later the same day', () {
      const day = DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30);
      expect(day.bedtimeFromMidnight, 23 * 60 + 30);
      expect(day.awakeMin, 990);
    });

    test('runs past midnight when bedtime is earlier than getting up', () {
      const day = DaySleep(wakeMin: 8 * 60 + 30, bedtimeMin: 60);
      expect(day.bedtimeFromMidnight, 1440 + 60);
      expect(day.awakeMin, 990);
    });
  });

  group('waking hours', () {
    test('are the date minus the sleep either side of the day', () {
      const s = CapacitySettings();
      expect(s.sleepIntervalsOn(DateTime.wednesday), [(0, 7 * 60), (23 * 60 + 30, 1440)]);
      expect(s.wakingIntervalsOn(DateTime.wednesday), [(7 * 60, 23 * 60 + 30)]);
    });

    test('include the small hours of a night that ran past midnight', () {
      expect(late.sleepIntervalsOn(DateTime.wednesday), [(60, 8 * 60 + 30)]);
      expect(late.wakingIntervalsOn(DateTime.wednesday), [(0, 60), (8 * 60 + 30, 1440)]);
    });

    test('follow each day, and the night before it', () {
      // To bed at 02:00 after Friday, up at 10:00 on Saturday.
      final s = weekWith({
        DateTime.friday: const DaySleep(wakeMin: 7 * 60, bedtimeMin: 2 * 60),
        DateTime.saturday: const DaySleep(wakeMin: 10 * 60, bedtimeMin: 23 * 60 + 30),
      });

      expect(s.wakingIntervalsOn(DateTime.friday), [(7 * 60, 1440)]);
      expect(s.wakingIntervalsOn(DateTime.saturday), [(0, 2 * 60), (10 * 60, 23 * 60 + 30)]);
      expect(s.wakingIntervalsOn(DateTime.sunday), [(7 * 60, 23 * 60 + 30)]);
    });

    test('never run past getting up the next day', () {
      // To bed at 09:00 the morning after Tuesday, though Wednesday starts at 07:00: a night
      // with no sleep in it at all.
      final s = weekWith({
        DateTime.tuesday: const DaySleep(wakeMin: 10 * 60, bedtimeMin: 9 * 60),
      });
      expect(s.wakingIntervalsOn(DateTime.wednesday), [(0, 23 * 60 + 30)]);
      expect(s.nightAfter(DateTime.tuesday), 0);
    });
  });

  group('a night', () {
    test('runs from a bedtime to getting up the next day', () {
      expect(const CapacitySettings().nightAfter(DateTime.monday), 450);
      expect(late.nightAfter(DateTime.sunday), 450);
    });

    test('takes the next day as it is set', () {
      final s = weekWith({
        DateTime.saturday: const DaySleep(wakeMin: 9 * 60, bedtimeMin: 23 * 60 + 30),
      });
      // Friday 23:30 to Saturday 09:00.
      expect(s.nightAfter(DateTime.friday), 570);
    });
  });

  group('a free day', () {
    test('deducts overhead and applies the focus factor', () {
      const s = CapacitySettings();
      final day = CapacityLedger.forDay(wed, s, []);

      expect(day.committedMin, 0);
      expect(day.wakingMin, 990);
      // 990 free, minus 150 overhead = 840, times 0.65 = 546.
      expect(day.overheadMin, 150);
      expect(day.usableMin, 546);
      expect(day.awake, [(7 * 60, 23 * 60 + 30)]);
    });

    test('never reports sleep as available', () {
      final day = CapacityLedger.forDay(wed, const CapacitySettings(), []);
      expect(day.sleepMin, 450);
      expect(day.usableMin, lessThan(day.wakingMin));
      // The floor is not part of any spendable figure.
      expect(day.usableMin + day.committedMin, lessThan(1440 - day.sleepMin));
    });

    test('says what is left once work is planned into it', () {
      final day = CapacityLedger.forDay(wed, const CapacitySettings(), []);
      expect(day.spareAfter(0), 546);
      expect(day.spareAfter(500), 46);
      expect(day.spareAfter(600), -54);
    });
  });

  group('sleep', () {
    test('a block while asleep is not counted, and not listed to draw', () {
      final day = CapacityLedger.forDay(wed, const CapacitySettings(), [
        block('Night study', 0, 60),
      ]);
      expect(day.committedMin, 0);
      expect(day.blocks, isEmpty);
      expect(day.usableMin, 546);
    });

    test('a block running into bedtime counts until bedtime', () {
      final day = CapacityLedger.forDay(wed, const CapacitySettings(), [
        block('Late lab', 23 * 60, 90),
      ]);
      expect(day.committedMin, 30);
      expect(day.blocks.single.endMin, 23 * 60 + 30);
    });

    test('a lie-in on one day moves only that day', () {
      final s = weekWith({
        DateTime.wednesday: const DaySleep(wakeMin: 10 * 60, bedtimeMin: 23 * 60 + 30),
      });
      final lieIn = CapacityLedger.forDay(wed, s, []);
      final usual = CapacityLedger.forDay(thu, s, []);

      expect(lieIn.wakingMin, 810);
      expect(usual.wakingMin, 990);
      // 810 awake, minus 150 = 660, times 0.65 = 429.
      expect(lieIn.usableMin, 429);
    });
  });

  group('a bedtime after midnight', () {
    test('counts a block at midnight, which you are awake for', () {
      final day = CapacityLedger.forDay(wed, late, [
        block('Night study', 0, 45),
      ]);
      expect(day.committedMin, 45);
      expect(
        [for (final b in day.blocks) (b.title, b.startMin, b.endMin)],
        [('Night study', 0, 45)],
      );
    });

    test('gives a free day as much time as an earlier bedtime of the same length', () {
      // 990 minutes awake either way, here as 00:00-01:00 and 08:30-24:00.
      final day = CapacityLedger.forDay(wed, late, []);
      expect(day.wakingMin, 990);
      expect(
        [for (final g in day.gaps) (g.startMin, g.endMin)],
        [(0, 60), (8 * 60 + 30, 1440)],
      );
      expect(day.usableMin, 546);
    });

    test('does not merge blocks across the night', () {
      final day = CapacityLedger.forDay(wed, late, [
        block('Before bed', 0, 60),
        block('After waking', 8 * 60 + 30, 60),
      ]);
      expect(day.committedMin, 120);
    });
  });

  group('commitments', () {
    test('are subtracted only on the days they occur', () {
      const s = CapacitySettings();
      final blocks = [block('DBMS', 9 * 60, 60)];

      final onDay = CapacityLedger.forDay(wed, s, blocks);
      final offDay = CapacityLedger.forDay(thu, s, blocks);

      expect(onDay.committedMin, 60);
      expect(offDay.committedMin, 0);
      expect(onDay.usableMin, lessThan(offDay.usableMin));
    });

    test('overlapping blocks are not subtracted twice', () {
      const s = CapacitySettings();
      final overlapping = CapacityLedger.forDay(wed, s, [
        block('A', 9 * 60, 120),
        block('B', 10 * 60, 120),
      ]);

      // 09:00-12:00 is three hours whichever way you book it.
      expect(overlapping.committedMin, 180);
    });

    test('are clipped to the waking hours', () {
      const s = CapacitySettings();
      // A block from 06:00 for two hours, but the day starts at 07:00.
      final day = CapacityLedger.forDay(wed, s, [block('Early', 6 * 60, 120)]);
      expect(day.committedMin, 60);
    });
  });

  group('fragmentation', () {
    test('short gaps between classes yield nothing usable', () {
      // Six one-hour classes with 20-minute gaps: plenty of raw free time, almost none
      // of it in a usable block.
      const s = CapacitySettings(mealsMin: 0, bufferMin: 0);
      final blocks = <FixedBlock>[];
      var t = 8 * 60;
      for (var i = 0; i < 6; i++) {
        blocks.add(block('Class $i', t, 60));
        t += 80;
      }

      final day = CapacityLedger.forDay(wed, s, blocks);
      expect(day.discardedGapMin, 100);
      // The five 20-minute gaps between the classes, and only those.
      expect([for (final g in day.discardedGaps) g.lengthMin], [20, 20, 20, 20, 20]);

      // The same free minutes in one block are worth much more.
      final oneBlock = CapacityLedger.forDay(wed, s, [
        block('All day', 8 * 60, 360),
      ]);
      expect(oneBlock.usableMin, greaterThan(day.usableMin));
    });

    test('a gap exactly at the threshold still counts', () {
      const s = CapacitySettings(
        mealsMin: 0,
        bufferMin: 0,
        minGapMin: 60,
        focusFactor: 1,
      );
      // Leaves a single 60-minute gap from 07:00 to 08:00, then busy to end of day.
      final day = CapacityLedger.forDay(wed, s, [
        block('Rest of day', 8 * 60, 930),
      ]);
      expect(day.usableMin, 60);
    });
  });

  test('a fully committed day has no usable time and does not go negative', () {
    const s = CapacitySettings();
    final day = CapacityLedger.forDay(wed, s, [
      block('Everything', 0, 1440),
    ]);

    expect(day.usableMin, 0);
    expect(day.overheadMin, 0, reason: 'nothing to deduct overhead from');
  });

  test('forRange produces consecutive days', () {
    final days = CapacityLedger.forRange(
      wed,
      5,
      const CapacitySettings(),
      const Timetable.empty(),
    );
    expect(days, hasLength(5));
    expect(days.first.date, DateTime(2026, 9, 16));
    expect(days.last.date, DateTime(2026, 9, 20));
  });
}
