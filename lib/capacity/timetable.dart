import 'ledger.dart';

/// Named, date-ranged sets of commitments — a semester's timetable, a placement, a
/// holiday.
///
/// A single flat list of commitments means rebuilding it by hand every term, and worse,
/// it is *wrong* about the future: the ledger plans four weeks ahead, so on the last week
/// of a semester it would still be subtracting classes that have finished.
///
/// Giving each set a date range fixes both. You enter Sem V once with its dates, enter
/// Sem VI with its own, and every day the ledger evaluates picks the set that actually
/// covers it — including days after a changeover you have not reached yet.

/// One named set of recurring blocks, optionally bounded by dates.
class ScheduleWindow {
  const ScheduleWindow({
    required this.id,
    required this.name,
    required this.blocks,
    this.startsOn,
    this.endsOn,
    this.isFallback = false,
  });

  final String id;
  final String name;
  final List<FixedBlock> blocks;

  /// Inclusive bounds. Null means open-ended on that side.
  final DateTime? startsOn;
  final DateTime? endsOn;

  /// Applies to any day no dated set covers. At most one should be marked, and
  /// [Timetable] tolerates more than one by taking the first.
  final bool isFallback;

  bool covers(DateTime day) {
    if (isFallback) return false;
    if (startsOn != null && day.isBefore(startsOn!)) return false;
    if (endsOn != null && day.isAfter(endsOn!)) return false;
    // A set with no dates at all and no fallback flag still counts as always-on, which
    // is what a single-timetable user ends up with.
    return true;
  }
}

/// Every set, with the rule for deciding which one a given day belongs to.
class Timetable {
  const Timetable(this.windows);

  const Timetable.empty() : windows = const [];

  final List<ScheduleWindow> windows;

  /// The set governing [day], or null when nothing does.
  ///
  /// Where several cover the same day — a placement inside a semester, say — the one
  /// that started most recently wins. That is the more specific answer, and picking by
  /// start date makes it predictable rather than depending on row order.
  ScheduleWindow? windowFor(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);

    ScheduleWindow? best;
    for (final w in windows) {
      if (!w.covers(d)) continue;
      if (best == null) {
        best = w;
        continue;
      }
      final a = w.startsOn;
      final b = best.startsOn;
      // A dated set beats an undated one; between two dated, the later start wins.
      if (b == null && a != null) {
        best = w;
      } else if (a != null && b != null && a.isAfter(b)) {
        best = w;
      }
    }

    if (best != null) return best;

    for (final w in windows) {
      if (w.isFallback) return w;
    }
    return null;
  }

  /// Blocks in force on [day].
  List<FixedBlock> blocksOn(DateTime day) => windowFor(day)?.blocks ?? const [];
}
