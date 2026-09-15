/// Reading times and durations as people type them.
///
/// Stepping a start time from 09:00 to midnight took thirty-six taps. These accept what a
/// person would naturally write — "930", "9:30", "9.30pm", "1h 30", "90m" — and return null
/// for anything they cannot read, so a field can put its old value back rather than guess.
abstract final class TimeEntry {
  static final _clock = RegExp(r'^(\d{1,2})(?:[:.h](\d{2}))?(am|pm|a|p)?$');
  static final _clockDigits = RegExp(r'^(\d{1,2})(\d{2})(am|pm|a|p)?$');
  static final _colonDuration = RegExp(r'^(\d{1,2}):(\d{2})$');
  static final _hoursDuration = RegExp(
    r'^(\d+(?:\.\d+)?)(?:h|hr|hrs|hour|hours)(?:(\d{1,2})(?:m|min|mins|minute|minutes)?)?$',
  );
  static final _minutesDuration = RegExp(r'^(\d+)(?:m|min|mins|minute|minutes)$');
  static final _bareNumber = RegExp(r'^(\d+(?:\.\d+)?)$');
  static final _percent = RegExp(r'^(\d{1,3})%?$');

  /// Minutes past midnight, from a time of day: "9", "930", "09:30", "9.30", "9pm",
  /// "12:15am", "midnight", "noon".
  static int? clock(String text) {
    final t = _normalise(text);
    if (t == 'midnight') return 0;
    if (t == 'noon' || t == 'midday') return 12 * 60;

    final match = _clock.firstMatch(t) ?? _clockDigits.firstMatch(t);
    if (match == null) return null;

    var hours = int.parse(match.group(1)!);
    final minutes = match.group(2) == null ? 0 : int.parse(match.group(2)!);
    if (minutes > 59) return null;

    if (match.group(3) case final suffix?) {
      if (hours < 1 || hours > 12) return null;
      hours = hours % 12 + (suffix.startsWith('p') ? 12 : 0);
    }
    if (hours > 23) return null;
    return hours * 60 + minutes;
  }

  /// Minutes, from a length of time: "90m", "1h", "1.5h", "1h 30", "1:30", "2 hours".
  ///
  /// A bare number under ten is hours and anything larger is minutes, since nobody means a
  /// nine-minute block or a forty-five-hour one. A bare decimal is always hours. With
  /// [bareMinutes], for something measured in minutes, a bare whole number always is.
  static int? duration(String text, {bool bareMinutes = false}) {
    final t = _normalise(text);

    if (_colonDuration.firstMatch(t) case final match?) {
      final minutes = int.parse(match.group(2)!);
      if (minutes > 59) return null;
      return int.parse(match.group(1)!) * 60 + minutes;
    }

    if (_hoursDuration.firstMatch(t) case final match?) {
      final hours = match.group(1)!;
      final extra = match.group(2) == null ? 0 : int.parse(match.group(2)!);
      // "1.5h30" says the same half hour twice, differently.
      if (extra > 59 || (extra > 0 && hours.contains('.'))) return null;
      return (double.parse(hours) * 60).round() + extra;
    }

    if (_minutesDuration.firstMatch(t) case final match?) {
      return int.parse(match.group(1)!);
    }

    if (_bareNumber.firstMatch(t) case final match?) {
      final number = match.group(1)!;
      final value = double.parse(number);
      if (number.contains('.') || (!bareMinutes && value < 10)) {
        return (value * 60).round();
      }
      return value.round();
    }

    return null;
  }

  /// A whole percentage, "65" or "65%".
  static int? percent(String text) {
    final match = _percent.firstMatch(_normalise(text));
    if (match == null) return null;
    final value = int.parse(match.group(1)!);
    return value > 100 ? null : value;
  }

  static String _normalise(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}
