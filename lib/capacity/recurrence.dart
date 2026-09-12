/// Expansion of the recurrence rules commitments actually use.
///
/// A timetable is weekly. Rather than pull in a full RFC 5545 implementation for a
/// problem that does not need one, this understands `FREQ=WEEKLY` with `BYDAY`, plus
/// optional `UNTIL`, and **throws on anything else**.
///
/// Rejecting loudly matters more than coping here. Every capacity figure in the app is
/// derived from these expansions, so a rule that was silently misread would quietly
/// corrupt the whole ledger — the app would be confidently wrong, which is the one
/// failure mode it exists to avoid.
library;

class RecurrenceError implements Exception {
  const RecurrenceError(this.message);
  final String message;

  @override
  String toString() => 'RecurrenceError: $message';
}

/// A parsed weekly rule.
class WeeklyRecurrence {
  const WeeklyRecurrence({required this.weekdays, this.until});

  /// `DateTime.monday` … `DateTime.sunday`.
  final Set<int> weekdays;

  /// Last day the rule applies, inclusive. Null means forever.
  final DateTime? until;

  bool occursOn(DateTime day) {
    if (until != null && day.isAfter(until!)) return false;
    return weekdays.contains(day.weekday);
  }
}

abstract final class Recurrence {
  static const _byDay = {
    'MO': DateTime.monday,
    'TU': DateTime.tuesday,
    'WE': DateTime.wednesday,
    'TH': DateTime.thursday,
    'FR': DateTime.friday,
    'SA': DateTime.saturday,
    'SU': DateTime.sunday,
  };

  /// Parses `FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20261231`.
  static WeeklyRecurrence parse(String rrule) {
    final parts = <String, String>{};
    for (final chunk in rrule.split(';')) {
      if (chunk.trim().isEmpty) continue;
      final eq = chunk.indexOf('=');
      if (eq < 0) {
        throw RecurrenceError('malformed segment "$chunk" in "$rrule"');
      }
      parts[chunk.substring(0, eq).trim().toUpperCase()] = chunk
          .substring(eq + 1)
          .trim()
          .toUpperCase();
    }

    final freq = parts['FREQ'];
    if (freq != 'WEEKLY') {
      throw RecurrenceError(
        'only FREQ=WEEKLY is supported, got "${freq ?? 'nothing'}". '
        'Commitments are timetable blocks; anything else needs a real RRULE library.',
      );
    }

    // INTERVAL=1 is the default and is fine; anything else changes which weeks are
    // affected and would silently halve or third the load.
    final interval = parts['INTERVAL'];
    if (interval != null && interval != '1') {
      throw RecurrenceError('INTERVAL=$interval is not supported');
    }

    final byDay = parts['BYDAY'];
    if (byDay == null || byDay.isEmpty) {
      throw RecurrenceError('BYDAY is required, got "$rrule"');
    }

    final weekdays = <int>{};
    for (final token in byDay.split(',')) {
      final day = _byDay[token.trim()];
      if (day == null) {
        throw RecurrenceError('unknown weekday "$token" in "$rrule"');
      }
      weekdays.add(day);
    }

    return WeeklyRecurrence(weekdays: weekdays, until: _parseUntil(parts['UNTIL']));
  }

  /// Accepts `YYYYMMDD` and `YYYYMMDDTHHMMSSZ`, the two forms a calendar export emits.
  static DateTime? _parseUntil(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final date = raw.split('T').first;
    if (date.length != 8) {
      throw RecurrenceError('cannot read UNTIL="$raw"');
    }
    final y = int.tryParse(date.substring(0, 4));
    final m = int.tryParse(date.substring(4, 6));
    final d = int.tryParse(date.substring(6, 8));
    if (y == null || m == null || d == null) {
      throw RecurrenceError('cannot read UNTIL="$raw"');
    }
    return DateTime(y, m, d);
  }

  /// Builds an RRULE string from weekdays. Used by the timetable importer.
  static String weekly(Set<int> weekdays, {DateTime? until}) {
    final names = {for (final e in _byDay.entries) e.value: e.key};
    final ordered = weekdays.toList()..sort();
    final days = ordered.map((d) => names[d]).join(',');
    final suffix = until == null
        ? ''
        : ';UNTIL=${until.year.toString().padLeft(4, '0')}'
              '${until.month.toString().padLeft(2, '0')}'
              '${until.day.toString().padLeft(2, '0')}';
    return 'FREQ=WEEKLY;BYDAY=$days$suffix';
  }
}
