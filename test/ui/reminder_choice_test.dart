import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/ui/reminder_choice.dart';

void main() {
  /// A Wednesday afternoon.
  final now = DateTime(2026, 9, 16, 17, 3);

  test('soon choices land on five-minute marks', () {
    expect(ReminderChoice.soon(now), [
      TimeChoice('In 15 min', DateTime(2026, 9, 16, 17, 20)),
      TimeChoice('In 30 min', DateTime(2026, 9, 16, 17, 35)),
      TimeChoice('In 1 hour', DateTime(2026, 9, 16, 18, 5)),
      TimeChoice('In 3 hours', DateTime(2026, 9, 16, 20, 5)),
    ]);
  });

  test('days are today and tomorrow, then each by weekday and date', () {
    final days = ReminderChoice.days(now, count: 4);
    expect([for (final d in days) d.label], ['Today', 'Tomorrow', 'Fri 18', 'Sat 19']);
    expect(days.first.at, DateTime(2026, 9, 16));
    expect(days[2].at, DateTime(2026, 9, 18));
  });

  test('a picker starts on the first whole hour half an hour away, or tomorrow morning', () {
    expect(ReminderChoice.initial(now), DateTime(2026, 9, 16, 18));
    expect(ReminderChoice.initial(DateTime(2026, 9, 16, 17, 30)), DateTime(2026, 9, 16, 18));
    expect(ReminderChoice.initial(DateTime(2026, 9, 16, 17, 31)), DateTime(2026, 9, 16, 19));
    expect(ReminderChoice.initial(DateTime(2026, 9, 16, 22, 50)), DateTime(2026, 9, 17, 9));
    expect(ReminderChoice.initial(DateTime(2026, 9, 16, 23, 40)), DateTime(2026, 9, 17, 9));
  });

  test('a reminder already set is where a picker starts, while it is still ahead', () {
    final set = DateTime(2026, 9, 20, 8, 15);
    expect(ReminderChoice.initial(now, existing: set), set);
    expect(
      ReminderChoice.initial(now, existing: DateTime(2026, 9, 16, 12)),
      DateTime(2026, 9, 16, 18),
    );
  });

  test('a chosen moment reads as its day, its time and how long until it', () {
    expect(
      ReminderChoice.describe(DateTime(2026, 9, 16, 18), now),
      'Today at 18:00, in 57 minutes',
    );
    expect(
      ReminderChoice.describe(DateTime(2026, 9, 16, 17, 4), now),
      'Today at 17:04, in 1 minute',
    );
    expect(
      ReminderChoice.describe(DateTime(2026, 9, 17, 9), now),
      'Tomorrow at 09:00, in 16 hours',
    );
    expect(
      ReminderChoice.describe(DateTime(2026, 9, 19, 18), now),
      'Sat 19 Sep at 18:00, in 3 days',
    );
  });

  test('a moment too near to set, or already past, reads as nothing', () {
    expect(ReminderChoice.describe(DateTime(2026, 9, 16, 17, 3, 30), now), isNull);
    expect(ReminderChoice.describe(DateTime(2026, 9, 16, 12), now), isNull);
  });

  test('a time on a day', () {
    expect(ReminderChoice.at(DateTime(2026, 9, 18), 18 * 60 + 30), DateTime(2026, 9, 18, 18, 30));
  });
}
