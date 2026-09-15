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

  test('a date carries its day', () {
    expect(Format.dayAndDate(DateTime(2026, 9, 21)), 'Mon 21 Sep');
  });
}
