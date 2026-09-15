import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';
import 'package:glasswork/capacity/setting_effects.dart';
import 'package:glasswork/capacity/timetable.dart';

/// A Monday.
final monday = DateTime(2026, 9, 14);

/// Classes 09:00–10:00 and 10:35–12:00 every day, leaving a 35-minute gap between them.
final classes = Timetable([
  ScheduleWindow(
    id: 'term',
    name: 'Term',
    blocks: [
      for (final (start, length) in [(9 * 60, 60), (10 * 60 + 35, 85)])
        FixedBlock(
          title: 'Class',
          startMin: start,
          durationMin: length,
          recurrence: Recurrence.parse('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU'),
        ),
    ],
  ),
]);

void main() {
  test('on a free week, overhead is taken in full and nothing is too short', () {
    final effects = SettingEffects.of(
      const CapacitySettings(),
      const Timetable.empty(),
      monday,
    );

    // 990 awake, less 150 of meals and buffer, times 0.65.
    expect(effects.usablePerDay, 546);
    expect(effects.overheadPerDay, 150);
    expect(effects.discardedPerDay, 0);
    // Fifteen more minutes of meals: 975 free, 536 to spend.
    expect(effects.mealsStep, -10);
    expect(effects.bufferStep, -10);
    // Five more points of focus on 840 free minutes: 588.
    expect(effects.focusStep, 42);
    expect(effects.minGapStep, 0);
    expect(effects.shortNights, isEmpty);
  });

  test('a longer shortest gap throws away a gap it used to count', () {
    // The 35-minute gap, less its share of the overhead, is 28.8 minutes: counted at 25,
    // thrown away at 30.
    final now = SettingEffects.of(const CapacitySettings(), classes, monday);
    expect(now.usablePerDay, 451);
    expect(now.discardedPerDay, 0);
    expect(now.minGapStep, -18);

    final stricter = SettingEffects.of(
      const CapacitySettings(minGapMin: 30),
      classes,
      monday,
    );
    expect(stricter.usablePerDay, 433);
    expect(stricter.discardedPerDay, 29);
  });

  test('focus cannot go past all of it', () {
    final effects = SettingEffects.of(
      const CapacitySettings(focusFactor: 1),
      const Timetable.empty(),
      monday,
    );
    expect(effects.focusStep, 0);
  });

  test('short nights are named by the day before them', () {
    final week = [...CapacitySettings.standardWeek];
    // To bed at 01:00 after Saturday, up at 07:00 on Sunday: six hours.
    week[DateTime.saturday - 1] = const DaySleep(wakeMin: 7 * 60, bedtimeMin: 60);

    final effects = SettingEffects.of(
      CapacitySettings(sleep: week),
      const Timetable.empty(),
      monday,
    );
    expect(effects.shortNights, {DateTime.saturday: 360});
  });
}
