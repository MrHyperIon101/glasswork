/// Parses a quick-add line like
/// `submit dbms lab tmrw 5pm !high #uni ~4h remind tmrw 9am`
/// into structured fields.
///
/// The grammar is deliberately small and explicit. Date parsing is a swamp, and a parser
/// that tries to be clever is one that silently misreads you. The requirement is not
/// accuracy in every phrasing — it is that whatever it *did* read is visible and
/// removable, which is what [ParsedQuickAdd.spans] is for.
library;

/// One recognised fragment of the input, so the UI can show it as a removable chip.
class ParseSpan {
  const ParseSpan({
    required this.start,
    required this.end,
    required this.kind,
    required this.label,
  });

  final int start;
  final int end;
  final ParseKind kind;

  /// How to render it: "Tomorrow 17:00", "high", "uni", "4h".
  final String label;
}

enum ParseKind { due, priority, label, estimate, reminder }

class ParsedQuickAdd {
  const ParsedQuickAdd({
    required this.title,
    required this.spans,
    this.dueAt,
    this.dueDate,
    this.priority = 0,
    this.labels = const [],
    this.estimateMin,
    this.remindAt,
  });

  /// The input with every recognised fragment removed.
  final String title;
  final List<ParseSpan> spans;

  /// Set when a time of day was given.
  final DateTime? dueAt;

  /// `YYYY-MM-DD` when only a date was given. Never a timestamp — an all-day task has
  /// no instant, and storing one breaks "due today" the moment you travel.
  final String? dueDate;

  final int priority;
  final List<String> labels;
  final int? estimateMin;

  /// When to be reminded, in local time: "remind tomorrow 9am", "remind in 2h".
  final DateTime? remindAt;
}

abstract final class QuickAddParser {
  static const _weekdays = {
    'mon': DateTime.monday,
    'monday': DateTime.monday,
    'tue': DateTime.tuesday,
    'tues': DateTime.tuesday,
    'tuesday': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'wednesday': DateTime.wednesday,
    'thu': DateTime.thursday,
    'thur': DateTime.thursday,
    'thurs': DateTime.thursday,
    'thursday': DateTime.thursday,
    'fri': DateTime.friday,
    'friday': DateTime.friday,
    'sat': DateTime.saturday,
    'saturday': DateTime.saturday,
    'sun': DateTime.sunday,
    'sunday': DateTime.sunday,
  };

  /// Weekday names longest first, so "tuesday" is never read as "tue" and a stray "sday".
  static final _weekdayPattern =
      (_weekdays.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
          .join('|');

  /// "remind [me] [at|on]" then either "in 2h", or a day, a time, or both.
  ///
  /// Groups: 1–2 an amount and unit; 3 the day; 4–6 a time with am or pm; 7–8 a 24-hour
  /// time; 9 noon or midnight.
  static final _remind = RegExp(
    r'\bremind(?:\s+me)?(?:\s+(?:at|on))?\s+(?:'
    r'in\s+(\d+)\s*(minutes?|mins?|m|hours?|hrs?|h|days?|d)\b'
    r'|'
    r'(?:(today|tonight|tmrw|tomorrow|(?:next\s+)?(?:'
    '$_weekdayPattern'
    r'))\b)?'
    r'(?:\s*(?:at\s+)?(?:(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b'
    r'|(\d{1,2}):(\d{2})\b|(noon|midnight)\b))?'
    r')',
    caseSensitive: false,
  );

  static const _priorities = {
    'high': 3,
    'hi': 3,
    '1': 3,
    'med': 2,
    'medium': 2,
    '2': 2,
    'low': 1,
    '3': 1,
  };

  /// The tasks in a pasted list: one a line, blank lines skipped, and a leading bullet,
  /// number or checkbox taken off, so a list copied from notes or a document adds cleanly.
  static List<String> splitLines(String text) => [
    for (final line in text.split(RegExp(r'\r?\n')))
      if (line
              .replaceFirst(RegExp(r'^\s*(?:[-*•+]|\d+[.)])\s+'), '')
              .replaceFirst(RegExp(r'^\s*\[[ xX]?\]\s*'), '')
              .trim()
          case final task when task.isNotEmpty)
        task,
  ];

  /// [now] is injected so the whole thing is a pure function and can be tested against
  /// fixed dates rather than whatever today happens to be.
  ///
  /// A reminder that names a day but no time is at [morningMin], minutes past midnight: the
  /// morning chosen in Settings.
  static ParsedQuickAdd parse(
    String input, {
    required DateTime now,
    int morningMin = 9 * 60,
  }) {
    final spans = <ParseSpan>[];
    final today = DateTime(now.year, now.month, now.day);

    // --- remind <when> ---
    // Read first, and blanked out of everything read after it, so its day and time are
    // never also taken for the due date.
    DateTime? remindAt;
    var rest = input;
    for (final m in _remind.allMatches(input)) {
      final at = _reminderFrom(m, now, morningMin);
      if (at == null) continue;
      remindAt = at;
      spans.add(
        ParseSpan(
          start: m.start,
          end: m.end,
          kind: ParseKind.reminder,
          label:
              'remind ${_dateLabel(DateTime(at.year, at.month, at.day), today)} '
              '${_timeLabel((hour: at.hour, minute: at.minute))}',
        ),
      );
      rest = input.replaceRange(m.start, m.end, ' ' * (m.end - m.start));
      break;
    }

    var priority = 0;
    final labels = <String>[];
    int? estimateMin;
    DateTime? date;
    ({int hour, int minute})? time;

    // --- !priority ---
    for (final m in RegExp(
      r'(?:^|\s)(![A-Za-z0-9]+)',
    ).allMatches(rest)) {
      final word = m.group(1)!.substring(1).toLowerCase();
      final value = _priorities[word];
      if (value == null) continue;
      priority = value;
      spans.add(
        ParseSpan(
          start: m.start + m.group(0)!.indexOf('!'),
          end: m.end,
          kind: ParseKind.priority,
          label: word,
        ),
      );
    }

    // --- #label ---
    for (final m in RegExp(r'(?:^|\s)(#[A-Za-z0-9_-]+)').allMatches(rest)) {
      final word = m.group(1)!.substring(1);
      labels.add(word);
      spans.add(
        ParseSpan(
          start: m.start + m.group(0)!.indexOf('#'),
          end: m.end,
          kind: ParseKind.label,
          label: word,
        ),
      );
    }

    // --- ~estimate ---
    final est = RegExp(
      r'(?:^|\s)~(\d+)\s*(m|min|mins|h|hr|hrs)\b',
      caseSensitive: false,
    ).firstMatch(rest);
    if (est != null) {
      final n = int.parse(est.group(1)!);
      final unit = est.group(2)!.toLowerCase();
      estimateMin = unit.startsWith('h') ? n * 60 : n;
      spans.add(
        ParseSpan(
          start: est.start + est.group(0)!.indexOf('~'),
          end: est.end,
          kind: ParseKind.estimate,
          label: unit.startsWith('h') ? '${n}h' : '${n}m',
        ),
      );
    }

    // --- relative days ---
    final rel = RegExp(
      r'\b(today|tonight|tmrw|tomorrow|in\s+(\d+)\s+(day|days|week|weeks))\b',
      caseSensitive: false,
    ).firstMatch(rest);
    if (rel != null) {
      final word = rel.group(1)!.toLowerCase();
      if (word == 'today' || word == 'tonight') {
        date = today;
      } else if (word == 'tmrw' || word == 'tomorrow') {
        date = today.add(const Duration(days: 1));
      } else {
        final n = int.parse(rel.group(2)!);
        final unit = rel.group(3)!.toLowerCase();
        date = today.add(Duration(days: unit.startsWith('week') ? n * 7 : n));
      }
      spans.add(
        ParseSpan(
          start: rel.start,
          end: rel.end,
          kind: ParseKind.due,
          label: _dateLabel(date, today),
        ),
      );
    }

    // --- weekday, optionally "next" ---
    if (date == null) {
      // The trailing \b is what stops "tue" matching inside "tuesday".
      final wd = RegExp(
        r'\b(next\s+)?(' + _weekdays.keys.join('|') + r')\b',
        caseSensitive: false,
      ).firstMatch(rest);
      if (wd != null) {
        final target = _weekdays[wd.group(2)!.toLowerCase()]!;
        final forceNextWeek = wd.group(1) != null;
        var delta = (target - today.weekday) % 7;
        if (delta == 0) delta = 7; // "tue" on a Tuesday means the next one
        if (forceNextWeek && delta < 7) delta += 7;
        date = today.add(Duration(days: delta));
        spans.add(
          ParseSpan(
            start: wd.start,
            end: wd.end,
            kind: ParseKind.due,
            label: _dateLabel(date, today),
          ),
        );
      }
    }

    // --- time of day ---
    final tm = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b|\b(\d{1,2}):(\d{2})\b',
      caseSensitive: false,
    ).firstMatch(rest);
    if (tm != null) {
      if (tm.group(3) != null) {
        var hour = int.parse(tm.group(1)!);
        final minute = int.parse(tm.group(2) ?? '0');
        final pm = tm.group(3)!.toLowerCase() == 'pm';
        if (hour == 12) hour = 0;
        time = (hour: pm ? hour + 12 : hour, minute: minute);
      } else {
        time = (hour: int.parse(tm.group(4)!), minute: int.parse(tm.group(5)!));
      }
      if (time.hour < 24 && time.minute < 60) {
        spans.add(
          ParseSpan(
            start: tm.start,
            end: tm.end,
            kind: ParseKind.due,
            label: _timeLabel(time),
          ),
        );
      } else {
        time = null;
      }
    }

    // A bare time with no date means today, or tomorrow if it has already passed.
    if (time != null && date == null) {
      final candidate = DateTime(
        today.year,
        today.month,
        today.day,
        time.hour,
        time.minute,
      );
      date = candidate.isAfter(now)
          ? today
          : today.add(const Duration(days: 1));
    }

    DateTime? dueAt;
    String? dueDate;
    if (date != null) {
      if (time != null) {
        dueAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      } else {
        dueDate = _isoDate(date);
      }
    }

    return ParsedQuickAdd(
      title: _stripSpans(input, spans),
      spans: spans..sort((a, b) => a.start.compareTo(b.start)),
      dueAt: dueAt,
      dueDate: dueDate,
      priority: priority,
      labels: labels,
      estimateMin: estimateMin,
      remindAt: remindAt,
    );
  }

  /// The moment a "remind" phrase means, or null when it names no day and no time.
  static DateTime? _reminderFrom(RegExpMatch m, DateTime now, int morningMin) {
    final today = DateTime(now.year, now.month, now.day);

    if (m.group(1) case final amount?) {
      final n = int.parse(amount);
      final unit = m.group(2)!.toLowerCase();
      final wait = unit.startsWith('d')
          ? Duration(days: n)
          : unit.startsWith('h')
          ? Duration(hours: n)
          : Duration(minutes: n);
      if (wait == Duration.zero) return null;
      final at = now.add(wait);
      return DateTime(at.year, at.month, at.day, at.hour, at.minute);
    }

    ({int hour, int minute})? time;
    if (m.group(6) case final meridiem?) {
      final hour = int.parse(m.group(4)!);
      if (hour < 1 || hour > 12) return null;
      time = (
        hour: hour % 12 + (meridiem.toLowerCase() == 'pm' ? 12 : 0),
        minute: int.parse(m.group(5) ?? '0'),
      );
    } else if (m.group(7) case final hour?) {
      time = (hour: int.parse(hour), minute: int.parse(m.group(8)!));
    } else if (m.group(9) case final word?) {
      time = word.toLowerCase() == 'noon'
          ? (hour: 12, minute: 0)
          : (hour: 0, minute: 0);
    }
    if (time != null && (time.hour > 23 || time.minute > 59)) return null;

    final dayWord = m.group(3)?.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (dayWord == null) {
      if (time == null) return null;
      // A time alone is the next one to come: today, or tomorrow once it has passed.
      final candidate = DateTime(
        today.year,
        today.month,
        today.day,
        time.hour,
        time.minute,
      );
      return candidate.isAfter(now)
          ? candidate
          : DateTime(today.year, today.month, today.day + 1, time.hour, time.minute);
    }

    final day = switch (dayWord) {
      'today' || 'tonight' => today,
      'tmrw' || 'tomorrow' => DateTime(today.year, today.month, today.day + 1),
      _ => _nextWeekday(dayWord, today),
    };
    // A day alone means its morning; tonight, its evening.
    time ??= dayWord == 'tonight'
        ? (hour: 20, minute: 0)
        : (hour: morningMin ~/ 60, minute: morningMin % 60);
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  /// "fri" or "next fri", counted as the due date's weekdays are.
  static DateTime _nextWeekday(String word, DateTime today) {
    final forceNextWeek = word.startsWith('next ');
    final target = _weekdays[word.replaceFirst('next ', '')]!;
    var delta = (target - today.weekday) % 7;
    if (delta == 0) delta = 7;
    if (forceNextWeek && delta < 7) delta += 7;
    return DateTime(today.year, today.month, today.day + delta);
  }

  static String _stripSpans(String input, List<ParseSpan> spans) {
    if (spans.isEmpty) return input.trim();
    final ordered = [...spans]..sort((a, b) => b.start.compareTo(a.start));
    var out = input;
    for (final s in ordered) {
      out = out.replaceRange(s.start, s.end, ' ');
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _dateLabel(DateTime d, DateTime today) {
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const names = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    if (diff < 7) return names[d.weekday - 1];
    return '${d.day}/${d.month}';
  }

  static String _timeLabel(({int hour, int minute}) t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
