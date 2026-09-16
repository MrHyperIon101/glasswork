import 'format.dart';

/// A moment offered as a quick choice, with the words to show on it.
class TimeChoice {
  const TimeChoice(this.label, this.at);

  final String label;

  /// Local time.
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is TimeChoice && other.label == label && other.at == at;

  @override
  int get hashCode => Object.hash(label, at);

  @override
  String toString() => 'TimeChoice($label, $at)';
}

/// The arithmetic behind choosing when to be reminded: the quick choices a picker offers,
/// where it starts, and how a chosen moment reads.
///
/// Pure, with the time passed in, so every label and moment a picker shows can be tested
/// against a fixed clock.
abstract final class ReminderChoice {
  /// Nearer than this, a reminder would have passed by the time it was saved.
  static const soonest = Duration(minutes: 1);

  /// Times of day offered as quick choices, in minutes past midnight.
  static const times = [9 * 60, 12 * 60, 15 * 60, 18 * 60, 21 * 60];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Shortly from [now], each moved up to the next five minutes so it lands on a time
  /// that reads cleanly.
  static List<TimeChoice> soon(DateTime now) => [
    for (final (label, wait) in const [
      ('In 15 min', Duration(minutes: 15)),
      ('In 30 min', Duration(minutes: 30)),
      ('In 1 hour', Duration(hours: 1)),
      ('In 3 hours', Duration(hours: 3)),
    ])
      TimeChoice(label, roundUp(now.add(wait))),
  ];

  /// Today, tomorrow and the days after, each as its midnight: "Today", "Tomorrow", "Fri 18".
  static List<TimeChoice> days(DateTime now, {int count = 7}) => [
    for (var i = 0; i < count; i++)
      () {
        final day = DateTime(now.year, now.month, now.day + i);
        return TimeChoice(switch (i) {
          0 => 'Today',
          1 => 'Tomorrow',
          _ => '${_weekdays[day.weekday - 1]} ${day.day}',
        }, day);
      }(),
  ];

  /// Where a picker starts: [existing] while it is still ahead, or else the first whole
  /// hour at least half an hour away — or 09:00 tomorrow, when that hour is already
  /// tomorrow's.
  static DateTime initial(DateTime now, {DateTime? existing}) {
    final kept = existing?.toLocal();
    if (kept != null && kept.difference(now) >= soonest) return kept;

    final soon = now.add(const Duration(minutes: 30));
    final hour = DateTime(soon.year, soon.month, soon.day, soon.hour);
    final next = hour.isBefore(soon)
        ? DateTime(hour.year, hour.month, hour.day, hour.hour + 1)
        : hour;
    if (_daysBetween(now, next) > 0) {
      return DateTime(now.year, now.month, now.day + 1, 9);
    }
    return next;
  }

  /// How [at] reads from [now]: "Today at 18:00, in 57 minutes", "Tomorrow at 09:00, in 16
  /// hours", "Sat 19 Sep at 18:00, in 3 days". Null once it is too near to set, or past.
  static String? describe(DateTime at, DateTime now) {
    final local = at.toLocal();
    final wait = local.difference(now);
    if (wait < soonest) return null;

    final days = _daysBetween(now, local);
    final day = switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => Format.dayAndDate(local),
    };
    return '$day at ${Format.clock(local.hour * 60 + local.minute)}, '
        '${_from(wait, days)}';
  }

  /// [at] moved up to the next five minutes, or left as it is when already on one.
  static DateTime roundUp(DateTime at) {
    final floor = DateTime(
      at.year,
      at.month,
      at.day,
      at.hour,
      at.minute - at.minute % 5,
    );
    return floor.isBefore(at)
        ? DateTime(floor.year, floor.month, floor.day, floor.hour, floor.minute + 5)
        : floor;
  }

  /// [day] at [minutes] past its midnight.
  static DateTime at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  static String _from(Duration wait, int days) {
    final minutes = (wait.inSeconds / 60).round();
    if (minutes < 60) return 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    final hours = (minutes / 60).round();
    if (hours < 24) return 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
    return 'in $days ${days == 1 ? 'day' : 'days'}';
  }

  /// Whole dates from [from] to [to], which a change of clocks cannot throw off.
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;
}
