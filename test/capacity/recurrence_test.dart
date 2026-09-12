import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/recurrence.dart';

void main() {
  test('parses a weekday timetable rule', () {
    final r = Recurrence.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');
    expect(r.weekdays, {DateTime.monday, DateTime.wednesday, DateTime.friday});
    expect(r.until, isNull);
  });

  test('occursOn matches only the listed weekdays', () {
    final r = Recurrence.parse('FREQ=WEEKLY;BYDAY=WE');
    expect(r.occursOn(DateTime(2026, 9, 16)), isTrue); // Wednesday
    expect(r.occursOn(DateTime(2026, 9, 17)), isFalse);
  });

  test('UNTIL ends the rule, inclusive', () {
    final r = Recurrence.parse('FREQ=WEEKLY;BYDAY=WE;UNTIL=20260916');
    expect(r.occursOn(DateTime(2026, 9, 16)), isTrue);
    expect(r.occursOn(DateTime(2026, 9, 23)), isFalse);
  });

  test('accepts the timestamped UNTIL form calendars export', () {
    final r = Recurrence.parse('FREQ=WEEKLY;BYDAY=WE;UNTIL=20261231T235959Z');
    expect(r.until, DateTime(2026, 12, 31));
  });

  // Silently misreading a rule would corrupt every downstream capacity figure, so the
  // unsupported cases must fail loudly rather than guess.
  test('rejects non-weekly frequencies rather than guessing', () {
    expect(
      () => Recurrence.parse('FREQ=DAILY;BYDAY=MO'),
      throwsA(isA<RecurrenceError>()),
    );
    expect(
      () => Recurrence.parse('FREQ=MONTHLY;BYDAY=MO'),
      throwsA(isA<RecurrenceError>()),
    );
  });

  test('rejects intervals other than every week', () {
    expect(
      () => Recurrence.parse('FREQ=WEEKLY;INTERVAL=2;BYDAY=TU'),
      throwsA(isA<RecurrenceError>()),
    );
  });

  test('rejects a missing or unknown BYDAY', () {
    expect(
      () => Recurrence.parse('FREQ=WEEKLY'),
      throwsA(isA<RecurrenceError>()),
    );
    expect(
      () => Recurrence.parse('FREQ=WEEKLY;BYDAY=XX'),
      throwsA(isA<RecurrenceError>()),
    );
  });

  test('weekly() round-trips through parse', () {
    final rule = Recurrence.weekly({DateTime.tuesday, DateTime.thursday});
    expect(rule, 'FREQ=WEEKLY;BYDAY=TU,TH');
    expect(Recurrence.parse(rule).weekdays, {
      DateTime.tuesday,
      DateTime.thursday,
    });
  });

  test('weekly() round-trips an UNTIL date', () {
    final rule = Recurrence.weekly({DateTime.monday}, until: DateTime(2026, 12, 5));
    expect(Recurrence.parse(rule).until, DateTime(2026, 12, 5));
  });
}
