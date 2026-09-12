import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';
import 'package:glasswork/capacity/timetable.dart';

FixedBlock block(String title, {String byday = 'MO'}) => FixedBlock(
  title: title,
  startMin: 9 * 60,
  durationMin: 60,
  recurrence: Recurrence.parse('FREQ=WEEKLY;BYDAY=$byday'),
);

ScheduleWindow window(
  String name, {
  DateTime? from,
  DateTime? to,
  bool fallback = false,
  String block_ = 'Class',
}) => ScheduleWindow(
  id: name,
  name: name,
  startsOn: from,
  endsOn: to,
  isFallback: fallback,
  blocks: [block(block_)],
);

void main() {
  test('an undated set applies to every day', () {
    final t = Timetable([window('Only one')]);
    expect(t.windowFor(DateTime(2026, 1, 1))?.name, 'Only one');
    expect(t.windowFor(DateTime(2030, 6, 6))?.name, 'Only one');
  });

  test('a dated set applies only inside its range, inclusively', () {
    final t = Timetable([
      window('Sem V', from: DateTime(2026, 7, 1), to: DateTime(2026, 12, 15)),
    ]);

    expect(t.windowFor(DateTime(2026, 6, 30)), isNull);
    expect(t.windowFor(DateTime(2026, 7, 1))?.name, 'Sem V');
    expect(t.windowFor(DateTime(2026, 12, 15))?.name, 'Sem V');
    expect(t.windowFor(DateTime(2026, 12, 16)), isNull);
  });

  /// The reason dated sets exist rather than a switch you flip.
  test('a horizon crossing a changeover gets the right set on each side', () {
    final t = Timetable([
      window('Sem V', from: DateTime(2026, 7, 1), to: DateTime(2026, 12, 15)),
      window('Sem VI', from: DateTime(2026, 12, 16), to: DateTime(2027, 5, 30)),
    ]);

    expect(t.windowFor(DateTime(2026, 12, 14))?.name, 'Sem V');
    expect(t.windowFor(DateTime(2026, 12, 16))?.name, 'Sem VI');
  });

  test('the most recently started set wins when two overlap', () {
    // A placement sitting inside a semester is the more specific answer.
    final t = Timetable([
      window('Sem V', from: DateTime(2026, 7, 1), to: DateTime(2026, 12, 15)),
      window('Placement', from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 30)),
    ]);

    expect(t.windowFor(DateTime(2026, 8, 20))?.name, 'Sem V');
    expect(t.windowFor(DateTime(2026, 9, 10))?.name, 'Placement');
    expect(t.windowFor(DateTime(2026, 10, 1))?.name, 'Sem V');
  });

  test('a dated set beats an undated one on days it covers', () {
    final t = Timetable([
      window('Always'),
      window('Sem V', from: DateTime(2026, 7, 1), to: DateTime(2026, 12, 15)),
    ]);

    expect(t.windowFor(DateTime(2026, 8, 1))?.name, 'Sem V');
    expect(t.windowFor(DateTime(2027, 1, 1))?.name, 'Always');
  });

  test('the fallback covers gaps between dated sets', () {
    final t = Timetable([
      window('Sem V', from: DateTime(2026, 7, 1), to: DateTime(2026, 12, 15)),
      window('Between terms', fallback: true),
    ]);

    expect(t.windowFor(DateTime(2026, 8, 1))?.name, 'Sem V');
    expect(t.windowFor(DateTime(2026, 12, 20))?.name, 'Between terms');
  });

  test('nothing covering a day means no commitments, not a crash', () {
    final t = Timetable([
      window('Sem V', from: DateTime(2026, 7, 1), to: DateTime(2026, 12, 15)),
    ]);
    expect(t.blocksOn(DateTime(2027, 3, 1)), isEmpty);
    expect(const Timetable.empty().blocksOn(DateTime(2026, 1, 1)), isEmpty);
  });

  test('the ledger changes capacity across a changeover', () {
    const settings = CapacitySettings();
    final t = Timetable([
      // A Monday class in Sem V only.
      ScheduleWindow(
        id: 'v',
        name: 'Sem V',
        startsOn: DateTime(2026, 9, 1),
        endsOn: DateTime(2026, 9, 20),
        blocks: [block('Maths', byday: 'MO')],
      ),
    ]);

    // 2026-09-14 and 2026-09-21 are both Mondays, either side of the end date.
    final days = CapacityLedger.forRange(DateTime(2026, 9, 14), 8, settings, t);

    expect(days.first.committedMin, 60, reason: 'inside Sem V');
    expect(days.last.committedMin, 0, reason: 'Sem V has ended');
    expect(days.last.usableMin, greaterThan(days.first.usableMin));
  });
}
