import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/ui/format.dart';

void main() {
  test('a time of day is two-digit hours and minutes, wrapping past midnight', () {
    expect(Format.clock(0), '00:00');
    expect(Format.clock(9 * 60 + 5), '09:05');
    expect(Format.clock(24 * 60 + 60), '01:00');
  });

  test('a span reads from its start to its end', () {
    expect(Format.clockSpan(9 * 60, 90), '09:00–10:30');
    // Never "25:00": the end of a block that runs late is still a time of day.
    expect(Format.clockSpan(23 * 60, 120), '23:00–01:00');
  });

  test('days read the way a person says them', () {
    expect(Format.weekdays({1, 2, 3, 4, 5, 6, 7}), 'Every day');
    expect(Format.weekdays({1, 2, 3, 4, 5}), 'Weekdays');
    expect(Format.weekdays({6, 7}), 'Weekends');
    expect(Format.weekdays({5, 1, 3}), 'Mon Wed Fri');
  });

  test('days end a sentence', () {
    expect(Format.onDays({1, 2, 3, 4, 5, 6, 7}), 'every day');
    expect(Format.onDays({1, 2, 3, 4, 5}), 'on weekdays');
    expect(Format.onDays({6, 7}), 'at weekends');
    expect(Format.onDays({2}), 'on Tue');
  });

  test('a reminder time says no more than it needs to', () {
    final now = DateTime(2026, 9, 15, 14);
    expect(Format.reminderTime(DateTime(2026, 9, 15, 15, 5), now), '15:05');
    expect(Format.reminderTime(DateTime(2026, 9, 16, 9), now), 'Tomorrow 09:00');
    expect(Format.reminderTime(DateTime(2026, 9, 18, 9), now), 'Fri 09:00');
    expect(Format.reminderTime(DateTime(2026, 9, 25, 9), now), '25 Sep 09:00');
  });

  test('hours are short enough for a narrow column', () {
    expect(Format.hoursShort(45), '45m');
    expect(Format.hoursShort(60), '1h');
    expect(Format.hoursShort(6 * 60 + 30), '6.5h');
    expect(Format.hoursShort(7 * 60 + 12), '7.2h');
    // To the nearest tenth: 1h 57m is closer to 2h than to 1.9h.
    expect(Format.hoursShort(117), '2h');
  });

  test('a date carries its day', () {
    expect(Format.dayAndDate(DateTime(2026, 9, 21)), 'Mon 21 Sep');
  });
}
