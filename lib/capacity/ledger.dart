import 'recurrence.dart';
import 'timetable.dart';

/// The capacity ledger: how much of each day is actually yours.
///
/// Pure arithmetic. No I/O, no clock of its own, no model call — every figure it produces
/// can be traced back to the profile and the timetable, which is the whole point. If a
/// user cannot be told *why* the app said a thing, the feature is broken.

/// Minutes in a calendar day.
const minutesInDay = 1440;

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

  /// Bedtime, as minutes past midnight.
  final int sleepStartMin;
  final int mealsMin;
  final int bufferMin;
  final double focusFactor;
  final int minGapMin;

  int get overheadMin => mealsMin + bufferMin;

  /// Bedtime within one day, however it was stored.
  int get bedtimeMin => sleepStartMin % minutesInDay;

  /// Minutes past midnight when the day starts.
  int get wakeMin => (bedtimeMin + sleepTargetMin) % minutesInDay;

  /// When you are asleep within one calendar day, as [start, end) intervals in order.
  ///
  /// Sleep usually crosses midnight, which puts it at both ends of the day: the small
  /// hours until waking, and the late evening from bedtime. With bedtime at or after
  /// midnight it is a single stretch in the early morning.
  List<(int, int)> get sleepIntervals {
    final end = bedtimeMin + sleepTargetMin;
    if (end <= minutesInDay) return [(bedtimeMin, end)];
    return [(0, end - minutesInDay), (bedtimeMin, minutesInDay)];
  }

  /// The rest of the calendar day, as [start, end) intervals in order.
  ///
  /// One stretch when bedtime is before midnight. Two when it is after: the hours before
  /// bed are as much yours as the evening is, and leaving them out is how a block at
  /// midnight once went uncounted, and undrawn, for anyone who stays up past it.
  List<(int, int)> get wakingIntervals {
    final awake = <(int, int)>[];
    var cursor = 0;
    for (final (start, end) in sleepIntervals) {
      if (start > cursor) awake.add((cursor, start));
      cursor = end;
    }
    if (cursor < minutesInDay) awake.add((cursor, minutesInDay));
    return awake;
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

/// A block as it falls on one day: the part inside waking hours, which is the only part
/// the arithmetic counts, and so the only part a timeline may draw.
class BlockSpan {
  const BlockSpan({
    required this.title,
    required this.startMin,
    required this.endMin,
  });

  final String title;
  final int startMin;
  final int endMin;
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
    this.blocks = const [],
    this.discardedGaps = const [],
  });

  final DateTime date;

  /// Time taken by commitments inside the waking hours.
  final int committedMin;

  /// Length of the waking hours before anything is deducted.
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

  /// The day's commitments as counted, in start order: clipped to waking hours, one entry
  /// for each waking stretch a block reaches. Overlapping blocks each appear, though the
  /// time they share is subtracted once.
  final List<BlockSpan> blocks;

  /// The gaps behind [discardedGapMin].
  final List<Gap> discardedGaps;

  /// Free time after overhead, before the focus factor.
  int get freeMin => gaps.fold(0, (sum, g) => sum + g.lengthMin) - overheadMin;

  /// What is left of [usableMin] once [allocatedMin] of planned work is taken out of it.
  /// Negative when more is planned than fits.
  int spareAfter(int allocatedMin) => usableMin - allocatedMin;
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
    final awake = settings.wakingIntervals;
    final wakingMin = awake.fold(0, (sum, w) => sum + (w.$2 - w.$1));

    // Commitments on this day, clipped to the hours you are awake.
    final spans = <BlockSpan>[];
    for (final block in blocks) {
      if (!block.recurrence.occursOn(day)) continue;
      for (final (windowStart, windowEnd) in awake) {
        final start = block.startMin.clamp(windowStart, windowEnd);
        final end = block.endMin.clamp(windowStart, windowEnd);
        if (end > start) {
          spans.add(BlockSpan(title: block.title, startMin: start, endMin: end));
        }
      }
    }
    spans.sort((a, b) => a.startMin.compareTo(b.startMin));

    // Merge overlaps, so a double-booked hour is not subtracted twice. Sleep separates the
    // waking stretches, so nothing merges across one.
    final merged = <Gap>[];
    for (final span in spans) {
      if (merged.isNotEmpty && span.startMin <= merged.last.endMin) {
        final last = merged.removeLast();
        merged.add(
          Gap(
            last.startMin,
            last.endMin > span.endMin ? last.endMin : span.endMin,
          ),
        );
      } else {
        merged.add(Gap(span.startMin, span.endMin));
      }
    }

    final committedMin = merged.fold(0, (sum, g) => sum + g.lengthMin);

    // Whatever is left between them, within each waking stretch.
    final gaps = <Gap>[];
    for (final (windowStart, windowEnd) in awake) {
      var cursor = windowStart;
      for (final busy in merged) {
        if (busy.endMin <= windowStart || busy.startMin >= windowEnd) continue;
        if (busy.startMin > cursor) gaps.add(Gap(cursor, busy.startMin));
        cursor = busy.endMin;
      }
      if (cursor < windowEnd) gaps.add(Gap(cursor, windowEnd));
    }

    final freeTotal = gaps.fold(0, (sum, g) => sum + g.lengthMin);
    final overhead = settings.overheadMin.clamp(0, freeTotal);

    // Meals and buffer are spread across the day rather than taken off one block,
    // because that is how they actually fall.
    var usable = 0.0;
    var discarded = 0;
    final discardedGaps = <Gap>[];
    for (final gap in gaps) {
      final share = freeTotal == 0 ? 0.0 : overhead * (gap.lengthMin / freeTotal);
      final adjusted = gap.lengthMin - share;

      // The honest part: fragments are not capacity. Six hours between classes in
      // twenty-minute slivers will not produce six hours of assignment.
      if (adjusted < settings.minGapMin) {
        discarded += adjusted > 0 ? adjusted.round() : 0;
        discardedGaps.add(gap);
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
      // Down to the minute, since a minute not quite there cannot be spent, but only past
      // what floating point loses: the same free time split across two gaps can sum to
      // 545.9999 where it is 546.
      usableMin: (usable + 1e-6).floor(),
      sleepMin: settings.sleepTargetMin,
      discardedGapMin: discarded,
      blocks: spans,
      discardedGaps: discardedGaps,
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
    return [
      for (var i = 0; i < days; i++)
        () {
          // Built from the date rather than added as a duration: across the night clocks go
          // back, adding a day's worth of hours lands on the same date twice.
          final day = DateTime(from.year, from.month, from.day + i);
          return forDay(day, settings, timetable.blocksOn(day));
        }(),
    ];
  }
}
