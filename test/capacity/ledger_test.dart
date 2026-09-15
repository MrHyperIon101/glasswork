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

void main() {
  group('waking hours', () {
    test('are the day minus the sleep block', () {
      // Sleep 23:30 for 7h30 -> wake 07:00, awake 07:00-23:30 = 990 minutes.
      const s = CapacitySettings();
      expect(s.wakeMin, 7 * 60);
      expect(s.sleepIntervals, [(0, 7 * 60), (23 * 60 + 30, 1440)]);
      expect(s.wakingIntervals, [(7 * 60, 23 * 60 + 30)]);
    });

    test('include the hours before a bedtime after midnight', () {
      // Bed at 01:00 for 7h30: awake until 01:00, and again from 08:30.
      const s = CapacitySettings(sleepStartMin: 60, sleepTargetMin: 450);
      expect(s.sleepIntervals, [(60, 8 * 60 + 30)]);
      expect(s.wakingIntervals, [(0, 60), (8 * 60 + 30, 1440)]);
    });

    test('are one stretch after waking with bedtime at midnight', () {
      const s = CapacitySettings(sleepStartMin: 0, sleepTargetMin: 480);
      expect(s.wakingIntervals, [(8 * 60, 1440)]);
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
  });

  group('a bedtime after midnight', () {
    const late = CapacitySettings(sleepStartMin: 60, sleepTargetMin: 450);

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

    test('are clipped to the waking window', () {
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
