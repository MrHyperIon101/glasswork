import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/ui/time_entry.dart';

void main() {
  group('a time of day', () {
    for (final (typed, minutes) in [
      ('9', 9 * 60),
      ('09:30', 9 * 60 + 30),
      ('9.30', 9 * 60 + 30),
      ('930', 9 * 60 + 30),
      ('0930', 9 * 60 + 30),
      ('2359', 23 * 60 + 59),
      ('9pm', 21 * 60),
      ('9:30 PM', 21 * 60 + 30),
      ('12am', 0),
      ('12:15am', 15),
      ('12pm', 12 * 60),
      ('0', 0),
      ('00:00', 0),
      ('midnight', 0),
      ('noon', 12 * 60),
    ]) {
      test('reads "$typed"', () => expect(TimeEntry.clock(typed), minutes));
    }

    for (final typed in ['24', '9:60', '13pm', '0am', '9:5', 'soon', '']) {
      test('refuses "$typed"', () => expect(TimeEntry.clock(typed), isNull));
    }
  });

  group('a length of time', () {
    for (final (typed, minutes) in [
      ('90m', 90),
      ('45 min', 45),
      ('1h', 60),
      ('1.5h', 90),
      ('1h 30', 90),
      ('1h30m', 90),
      ('2 hours', 120),
      ('1:30', 90),
      ('2', 120),
      ('1.5', 90),
      ('45', 45),
    ]) {
      test('reads "$typed"', () => expect(TimeEntry.duration(typed), minutes));
    }

    test('reads a bare whole number as minutes when asked to', () {
      expect(TimeEntry.duration('5', bareMinutes: true), 5);
      expect(TimeEntry.duration('1.5', bareMinutes: true), 90);
    });

    for (final typed in ['1:75', '1h 90', '1.5h30', 'an hour', '']) {
      test('refuses "$typed"', () => expect(TimeEntry.duration(typed), isNull));
    }
  });

  group('a percentage', () {
    test('reads with or without the sign', () {
      expect(TimeEntry.percent('65'), 65);
      expect(TimeEntry.percent('65 %'), 65);
    });

    test('refuses more than all of it', () {
      expect(TimeEntry.percent('150'), isNull);
    });
  });
}
