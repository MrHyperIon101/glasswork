import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/reminders/reminder_presets.dart';

void main() {
  /// A Tuesday afternoon.
  final now = DateTime(2026, 9, 15, 14, 3);

  List<(String, DateTime)> presets(
    DateTime now, {
    DateTime? dueAt,
    DateTime? dueDate,
  }) => [
    for (final p in ReminderPresets.of(now, dueAt: dueAt, dueDate: dueDate))
      (p.label, p.at),
  ];

  test('with no due date: in an hour, this evening, tomorrow morning', () {
    expect(presets(now), [
      ('In an hour', DateTime(2026, 9, 15, 15, 5)),
      ('This evening', DateTime(2026, 9, 15, 18)),
      ('Tomorrow morning', DateTime(2026, 9, 16, 9)),
    ]);
  });

  test('mornings and evenings are the times Settings has', () {
    List<(String, DateTime)> chosen({DateTime? dueDate}) => [
      for (final p in ReminderPresets.of(
        now,
        dueDate: dueDate,
        morningMin: 7 * 60 + 30,
        eveningMin: 20 * 60,
      ))
        (p.label, p.at),
    ];

    expect(chosen(), [
      ('In an hour', DateTime(2026, 9, 15, 15, 5)),
      ('This evening', DateTime(2026, 9, 15, 20)),
      ('Tomorrow morning', DateTime(2026, 9, 16, 7, 30)),
    ]);
    expect(
      chosen(dueDate: DateTime(2026, 9, 18)),
      containsAllInOrder([
        ('The evening before', DateTime(2026, 9, 17, 20)),
        ('The morning it is due', DateTime(2026, 9, 18, 7, 30)),
      ]),
    );
  });

  test('leaves out a choice that is only minutes away', () {
    expect(presets(DateTime(2026, 9, 15, 17, 50)), [
      ('In an hour', DateTime(2026, 9, 15, 18, 50)),
      ('Tomorrow morning', DateTime(2026, 9, 16, 9)),
    ]);
  });

  test('a timed task adds an hour before and the time itself', () {
    expect(
      presets(now, dueAt: DateTime(2026, 9, 17, 17)),
      containsAllInOrder([
        ('An hour before it is due', DateTime(2026, 9, 17, 16)),
        ('When it is due', DateTime(2026, 9, 17, 17)),
      ]),
    );
  });

  test('an all-day task adds the evening before and the morning of', () {
    expect(presets(now, dueDate: DateTime(2026, 9, 18)), [
      ('In an hour', DateTime(2026, 9, 15, 15, 5)),
      ('This evening', DateTime(2026, 9, 15, 18)),
      ('Tomorrow morning', DateTime(2026, 9, 16, 9)),
      ('The evening before', DateTime(2026, 9, 17, 18)),
      ('The morning it is due', DateTime(2026, 9, 18, 9)),
    ]);
  });

  test('never offers the same moment twice, keeping the plainer name', () {
    // Due tomorrow: the evening before is this evening, the morning of is tomorrow morning.
    expect(presets(now, dueDate: DateTime(2026, 9, 16)), [
      ('In an hour', DateTime(2026, 9, 15, 15, 5)),
      ('This evening', DateTime(2026, 9, 15, 18)),
      ('Tomorrow morning', DateTime(2026, 9, 16, 9)),
    ]);
  });
}
