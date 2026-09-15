/// A quick choice of when to be reminded.
class ReminderPreset {
  const ReminderPreset(this.label, this.at);

  final String label;

  /// Local time.
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is ReminderPreset && other.label == label && other.at == at;

  @override
  int get hashCode => Object.hash(label, at);

  @override
  String toString() => 'ReminderPreset($label, $at)';
}

/// The quick choices a task offers for a reminder.
abstract final class ReminderPresets {
  /// Choices for a task due at [dueAt], or on [dueDate], as of [now]: only times far
  /// enough ahead to be worth setting, earliest first, never two at the same moment.
  static List<ReminderPreset> of(
    DateTime now, {
    DateTime? dueAt,
    DateTime? dueDate,
  }) {
    final candidates = [
      ReminderPreset('In an hour', _toFiveMinutes(now.add(const Duration(hours: 1)))),
      ReminderPreset('This evening', DateTime(now.year, now.month, now.day, 18)),
      ReminderPreset(
        'Tomorrow morning',
        DateTime(now.year, now.month, now.day + 1, 9),
      ),
      if (dueAt?.toLocal() case final due?) ...[
        ReminderPreset('An hour before it is due', due.subtract(const Duration(hours: 1))),
        ReminderPreset('When it is due', due),
      ] else if (dueDate case final day?) ...[
        ReminderPreset(
          'The evening before',
          DateTime(day.year, day.month, day.day - 1, 18),
        ),
        ReminderPreset(
          'The morning it is due',
          DateTime(day.year, day.month, day.day, 9),
        ),
      ],
    ];

    // Soonest first. Where two land on the same moment, the one listed first keeps its
    // name: "Tomorrow morning" rather than "The morning it is due", for a task due tomorrow.
    final ordered = candidates.indexed.toList()
      ..sort((a, b) {
        final byTime = a.$2.at.compareTo(b.$2.at);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });

    // A reminder only minutes away is no reminder at all.
    final soonest = now.add(const Duration(minutes: 15));
    final seen = <DateTime>{};
    return [
      for (final (_, preset) in ordered)
        if (preset.at.isAfter(soonest) && seen.add(preset.at)) preset,
    ];
  }

  /// Up to the next five minutes, so "in an hour" lands on a time that reads cleanly.
  static DateTime _toFiveMinutes(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute + (5 - t.minute % 5) % 5);
}
