/// Parses a quick-add line like
/// `submit dbms lab tmrw 5pm !high #uni ~4h`
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

enum ParseKind { due, priority, label, estimate }

class ParsedQuickAdd {
  const ParsedQuickAdd({
    required this.title,
    required this.spans,
    this.dueAt,
    this.dueDate,
    this.priority = 0,
    this.labels = const [],
    this.estimateMin,
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

  /// [now] is injected so the whole thing is a pure function and can be tested against
  /// fixed dates rather than whatever today happens to be.
  static ParsedQuickAdd parse(String input, {required DateTime now}) {
    final spans = <ParseSpan>[];

    var priority = 0;
    final labels = <String>[];
    int? estimateMin;
    DateTime? date;
    ({int hour, int minute})? time;

    // --- !priority ---
    for (final m in RegExp(
      r'(?:^|\s)(![A-Za-z0-9]+)',
    ).allMatches(input)) {
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
    for (final m in RegExp(r'(?:^|\s)(#[A-Za-z0-9_-]+)').allMatches(input)) {
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
    ).firstMatch(input);
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
    final today = DateTime(now.year, now.month, now.day);

    final rel = RegExp(
      r'\b(today|tonight|tmrw|tomorrow|in\s+(\d+)\s+(day|days|week|weeks))\b',
      caseSensitive: false,
    ).firstMatch(input);
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
      ).firstMatch(input);
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
    ).firstMatch(input);
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
    );
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
