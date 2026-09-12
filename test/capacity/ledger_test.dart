import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';

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
  group('waking window', () {
    test('is the day minus the sleep block', () {
      // Sleep 23:30 for 7h30 -> wake 07:00, window 07:00-23:30 = 990 minutes.
      const s = CapacitySettings();
      expect(s.wakeMin, 7 * 60);
      expect(s.wakingWindow, (7 * 60, 23 * 60 + 30));
    });

    test('runs to midnight when bedtime is after it', () {
      const s = CapacitySettings(sleepStartMin: 60, sleepTargetMin: 450);
      final (start, end) = s.wakingWindow;
      expect(start, 8 * 60 + 30);
      expect(end, 1440);
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
      expect(day.discardedGapMin, greaterThan(0));

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
    final days = CapacityLedger.forRange(wed, 5, const CapacitySettings(), []);
    expect(days, hasLength(5));
    expect(days.first.date, DateTime(2026, 9, 16));
    expect(days.last.date, DateTime(2026, 9, 20));
  });
}
