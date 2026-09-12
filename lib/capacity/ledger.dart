import 'recurrence.dart';
import 'timetable.dart';

/// The capacity ledger: how much of each day is actually yours.
///
/// Pure arithmetic. No I/O, no clock of its own, no model call — every figure it produces
/// can be traced back to the profile and the timetable, which is the whole point. If a
/// user cannot be told *why* the app said a thing, the feature is broken.

/// The constants a day is measured against.
class CapacitySettings {
  const CapacitySettings({
    this.sleepTargetMin = 450,
    this.sleepStartMin = 23 * 60 + 30,
    this.mealsMin = 90,
    this.bufferMin = 60,
    this.focusFactor = 0.65,
    this.minGapMin = 25,
  });

  /// Protected floor. Reported, never spent.
  final int sleepTargetMin;
  final int sleepStartMin;
  final int mealsMin;
  final int bufferMin;
  final double focusFactor;
  final int minGapMin;

  int get overheadMin => mealsMin + bufferMin;

  /// Minutes past midnight when the day starts.
  int get wakeMin => (sleepStartMin + sleepTargetMin) % 1440;

  /// The waking window within one calendar day, as [start, end).
  ///
  /// When bedtime falls after midnight the window simply runs to the end of the day
  /// rather than wrapping — a day is a calendar day here, because that is what a due date
  /// means.
  (int, int) get wakingWindow {
    final wake = wakeMin;
    return (wake, sleepStartMin > wake ? sleepStartMin : 1440);
  }
}

/// A recurring fixed block — a class, a lab, a commute.
class FixedBlock {
  const FixedBlock({
    required this.title,
    required this.startMin,
    required this.durationMin,
    required this.recurrence,
  });

  final String title;
  final int startMin;
  final int durationMin;
  final WeeklyRecurrence recurrence;

  int get endMin => startMin + durationMin;
}

/// A free interval within the waking day.
class Gap {
  const Gap(this.startMin, this.endMin);

  final int startMin;
  final int endMin;

  int get lengthMin => endMin - startMin;
}

/// One day's arithmetic, fully itemised so the UI can explain itself.
class DayCapacity {
  const DayCapacity({
    required this.date,
    required this.committedMin,
    required this.wakingMin,
    required this.gaps,
    required this.overheadMin,
    required this.usableMin,
    required this.sleepMin,
    required this.discardedGapMin,
  });

  final DateTime date;

  /// Time taken by commitments inside the waking window.
  final int committedMin;

  /// Length of the waking window before anything is deducted.
  final int wakingMin;

  final List<Gap> gaps;

  /// Meals and buffer, as actually deducted (never more than the free time available).
  final int overheadMin;

  /// What you can realistically expect to get done. Everything downstream compares
  /// against this, never against raw free time.
  final int usableMin;

  /// The floor. Present so it can be shown, never so it can be spent.
  final int sleepMin;

  /// Free minutes thrown away because they came in fragments too short to use. Surfaced
  /// rather than hidden, because a day with six hours free in ten-minute slivers is not a
  /// day with six hours free.
  final int discardedGapMin;

  /// Free time after overhead, before the focus factor.
  int get freeMin => gaps.fold(0, (sum, g) => sum + g.lengthMin) - overheadMin;
}

abstract final class CapacityLedger {
  /// Capacity for a single day.
  ///
  /// [blocks] are the commitments already known to apply to this date. Callers with
  /// multiple timetables should use [forRange], which resolves the right set per day.
  static DayCapacity forDay(
    DateTime date,
    CapacitySettings settings,
    List<FixedBlock> blocks,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    final (windowStart, windowEnd) = settings.wakingWindow;
    final wakingMin = windowEnd - windowStart;

    // Commitments on this day, clipped to the waking window.
    final busy = <Gap>[];
    for (final block in blocks) {
      if (!block.recurrence.occursOn(day)) continue;
      final start = block.startMin.clamp(windowStart, windowEnd);
      final end = block.endMin.clamp(windowStart, windowEnd);
      if (end > start) busy.add(Gap(start, end));
    }
    busy.sort((a, b) => a.startMin.compareTo(b.startMin));

    // Merge overlaps, so a double-booked hour is not subtracted twice.
    final merged = <Gap>[];
    for (final block in busy) {
      if (merged.isNotEmpty && block.startMin <= merged.last.endMin) {
        final last = merged.removeLast();
        merged.add(Gap(last.startMin, last.endMin > block.endMin ? last.endMin : block.endMin));
      } else {
        merged.add(block);
      }
    }

    final committedMin = merged.fold(0, (sum, g) => sum + g.lengthMin);

    // Whatever is left between them.
    final gaps = <Gap>[];
    var cursor = windowStart;
    for (final block in merged) {
      if (block.startMin > cursor) gaps.add(Gap(cursor, block.startMin));
      cursor = block.endMin;
    }
    if (cursor < windowEnd) gaps.add(Gap(cursor, windowEnd));

    final freeTotal = gaps.fold(0, (sum, g) => sum + g.lengthMin);
    final overhead = settings.overheadMin.clamp(0, freeTotal);

    // Meals and buffer are spread across the day rather than taken off one block,
    // because that is how they actually fall.
    var usable = 0.0;
    var discarded = 0;
    for (final gap in gaps) {
      final share = freeTotal == 0 ? 0.0 : overhead * (gap.lengthMin / freeTotal);
      final adjusted = gap.lengthMin - share;

      // The honest part: fragments are not capacity. Six hours between classes in
      // twenty-minute slivers will not produce six hours of assignment.
      if (adjusted < settings.minGapMin) {
        discarded += adjusted > 0 ? adjusted.round() : 0;
        continue;
      }
      usable += adjusted * settings.focusFactor;
    }

    return DayCapacity(
      date: day,
      committedMin: committedMin,
      wakingMin: wakingMin,
      gaps: gaps,
      overheadMin: overhead,
      usableMin: usable.floor(),
      sleepMin: settings.sleepTargetMin,
      discardedGapMin: discarded,
    );
  }

  /// Capacity for a run of consecutive days starting at [from].
  ///
  /// Resolves the governing timetable per day rather than once for the range. This is
  /// the point of dated timetables: a horizon that crosses a semester boundary gets the
  /// right classes on each side of it, instead of being confidently wrong after the
  /// changeover.
  static List<DayCapacity> forRange(
    DateTime from,
    int days,
    CapacitySettings settings,
    Timetable timetable,
  ) {
    final start = DateTime(from.year, from.month, from.day);
    return [
      for (var i = 0; i < days; i++)
        () {
          final day = start.add(Duration(days: i));
          return forDay(day, settings, timetable.blocksOn(day));
        }(),
    ];
  }
}
