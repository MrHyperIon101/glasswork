import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/day_agenda.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';

/// A Wednesday.
final wed = DateTime(2026, 9, 16);

FixedBlock block(String title, int startMin, int durationMin) => FixedBlock(
  title: title,
  startMin: startMin,
  durationMin: durationMin,
  recurrence: Recurrence.parse('FREQ=WEEKLY;BYDAY=WE'),
);

/// What each entry is and when, in order: a block's title or "free", with its times.
List<(String, int, int, AgendaTime)> shape(List<AgendaEntry> entries) => [
  for (final e in entries) (e.block?.title ?? 'free', e.startMin, e.endMin, e.when),
];

void main() {
  // Up 07:00, bed 23:30; 150 minutes of meals and buffer shared across the free time.
  const settings = CapacitySettings();
  final day = CapacityLedger.forDay(wed, settings, [
    block('Gym', 7 * 60, 60),
    block('DBMS lecture', 9 * 60, 90),
    block('Computer networks', 11 * 60, 60),
  ]);

  test('lists the blocks and the free time between them, in order', () {
    final agenda = DayAgenda.of(day, 9 * 60 + 30);
    expect(shape(agenda), [
      ('Gym', 420, 480, AgendaTime.past),
      ('free', 480, 540, AgendaTime.past),
      ('DBMS lecture', 540, 630, AgendaTime.now),
      ('free', 630, 660, AgendaTime.later),
      ('Computer networks', 660, 720, AgendaTime.later),
      ('free', 720, 1410, AgendaTime.later),
    ]);
  });

  test('marks free time the ledger throws away as too short', () {
    final agenda = DayAgenda.of(day, 9 * 60 + 30);
    // Half an hour, less its share of meals and buffer, is under the 25 minutes that count.
    expect([for (final e in agenda) if (e.free) (e.startMin, e.usable)], [
      (480, true),
      (630, false),
      (720, true),
    ]);
    expect(agenda.where((e) => !e.free).every((e) => e.usable), isTrue);
  });

  test('an entry is over the moment it ends, and now from the moment it starts', () {
    final agenda = DayAgenda.of(day, 10 * 60 + 30);
    expect(agenda[2].when, AgendaTime.past);
    expect((agenda[3].startMin, agenda[3].when), (630, AgendaTime.now));
  });

  test('overlapping blocks are both listed, and free time starts after the later', () {
    final busy = CapacityLedger.forDay(wed, settings, [
      block('DBMS lecture', 9 * 60, 90),
      block('Travel', 9 * 60 + 30, 90),
    ]);
    expect(shape(DayAgenda.of(busy, 6 * 60)), [
      ('free', 420, 540, AgendaTime.later),
      ('DBMS lecture', 540, 630, AgendaTime.later),
      ('Travel', 570, 660, AgendaTime.later),
      ('free', 660, 1410, AgendaTime.later),
    ]);
  });

  test('a day with nothing fixed is one stretch of free time', () {
    final empty = CapacityLedger.forDay(wed, settings, const []);
    expect(shape(DayAgenda.of(empty, 12 * 60)), [('free', 420, 1410, AgendaTime.now)]);
  });

  test('the small hours of a late night come first, apart from the day', () {
    // Up 08:30 and to bed at 01:00, so the date starts awake until one.
    final late = CapacitySettings.sameEveryDay(wakeMin: 8 * 60 + 30, bedtimeMin: 60);
    final night = CapacityLedger.forDay(wed, late, [block('DBMS lecture', 9 * 60, 90)]);
    expect(shape(DayAgenda.of(night, 30)), [
      ('free', 0, 60, AgendaTime.now),
      ('free', 510, 540, AgendaTime.later),
      ('DBMS lecture', 540, 630, AgendaTime.later),
      ('free', 630, 1440, AgendaTime.later),
    ]);
  });
}
