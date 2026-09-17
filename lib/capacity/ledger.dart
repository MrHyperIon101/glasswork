import 'recurrence.dart';
import 'timetable.dart';

/// The capacity ledger: how much of each day is actually yours.
///
/// Pure arithmetic. No I/O, no clock of its own, no model call — every figure it produces
/// can be traced back to the profile and the timetable, which is the whole point. If a
/// user cannot be told *why* the app said a thing, the feature is broken.

/// Minutes in a calendar day.
const minutesInDay = 1440;

/// One day's sleep: when you get up that morning, and when you go to bed that night.
///
/// A bedtime at or before the time you get up is after midnight, in the small hours of the
/// next date: up at 09:00 and to bed at 01:30 is a day that runs until half past one.
class DaySleep {
  const DaySleep({required this.wakeMin, required this.bedtimeMin});

  /// When you get up, in minutes past midnight.
  final int wakeMin;

  /// When you go to bed, in minutes past midnight.
  final int bedtimeMin;

  /// Bedtime counted from this day's midnight, so past [minutesInDay] when it falls after
  /// midnight.
  int get bedtimeFromMidnight =>
      bedtimeMin <= wakeMin ? bedtimeMin + minutesInDay : bedtimeMin;

  /// The length of the day, from getting up to going to bed.
  int get awakeMin => bedtimeFromMidnight - wakeMin;

  @override
  bool operator ==(Object other) =>
      other is DaySleep &&
      other.wakeMin == wakeMin &&
      other.bedtimeMin == bedtimeMin;

  @override
  int get hashCode => Object.hash(wakeMin, bedtimeMin);

  @override
  String toString() => 'DaySleep(up $wakeMin, bed $bedtimeMin)';
}

/// The constants a day is measured against.
class CapacitySettings {
  const CapacitySettings({
    this.sleep = standardWeek,
    this.sleepTargetMin = 450,
    this.mealsMin = 90,
    this.bufferMin = 60,
    this.focusFactor = 0.65,
    this.minGapMin = 25,
  });

  /// The same sleep on every day of the week.
  factory CapacitySettings.sameEveryDay({
    required int wakeMin,
    required int bedtimeMin,
    int sleepTargetMin = 450,
    int mealsMin = 90,
    int bufferMin = 60,
    double focusFactor = 0.65,
    int minGapMin = 25,
  }) => CapacitySettings(
    sleep: List.filled(7, DaySleep(wakeMin: wakeMin, bedtimeMin: bedtimeMin)),
    sleepTargetMin: sleepTargetMin,
    mealsMin: mealsMin,
    bufferMin: bufferMin,
    focusFactor: focusFactor,
    minGapMin: minGapMin,
  );

  /// Up at 07:00 and to bed at 23:30, all week.
  static const standardWeek = [
    DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30),
    DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30),
    DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30),
    DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30),
    DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30),
    DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30),
    DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30),
  ];

  /// Each day's sleep, seven of them, Monday first.
  final List<DaySleep> sleep;

  /// The least sleep wanted in a night. A floor to report short nights against, never
  /// time to spend.
  final int sleepTargetMin;

  final int mealsMin;
  final int bufferMin;
  final double focusFactor;
  final int minGapMin;

  int get overheadMin => mealsMin + bufferMin;

  /// A copy with some values changed, for asking what a different setting would do.
  CapacitySettings copyWith({
    List<DaySleep>? sleep,
    int? sleepTargetMin,
    int? mealsMin,
    int? bufferMin,
    double? focusFactor,
    int? minGapMin,
  }) => CapacitySettings(
    sleep: sleep ?? this.sleep,
    sleepTargetMin: sleepTargetMin ?? this.sleepTargetMin,
    mealsMin: mealsMin ?? this.mealsMin,
    bufferMin: bufferMin ?? this.bufferMin,
    focusFactor: focusFactor ?? this.focusFactor,
    minGapMin: minGapMin ?? this.minGapMin,
  );

  /// The sleep of the day that is [weekday], `DateTime.monday` to `DateTime.sunday`.
  DaySleep sleepOn(int weekday) => sleep[(weekday - 1) % 7];

  static int dayBefore(int weekday) =>
      weekday == DateTime.monday ? DateTime.sunday : weekday - 1;

  static int dayAfter(int weekday) =>
      weekday == DateTime.sunday ? DateTime.monday : weekday + 1;

  /// The hours awake within the calendar day that is [weekday], as [start, end) intervals
  /// in order.
  ///
  /// Usually one stretch, from getting up to going to bed. When the night before ran past
  /// midnight, the date also starts awake, until that bedtime; and when this day's bedtime
  /// is after midnight, it runs to the end of the date, the rest counting towards the next.
  List<(int, int)> wakingIntervalsOn(int weekday) {
    final today = sleepOn(weekday);
    final awake = <(int, int)>[];

    // The night before, where it ran past midnight, but never past getting up today.
    final lateNight = sleepOn(dayBefore(weekday)).bedtimeFromMidnight - minutesInDay;
    final lateNightEnd = lateNight < today.wakeMin ? lateNight : today.wakeMin;
    if (lateNightEnd > 0) awake.add((0, lateNightEnd));

    final end = today.bedtimeFromMidnight < minutesInDay
        ? today.bedtimeFromMidnight
        : minutesInDay;
    if (end > today.wakeMin) {
      if (awake.isNotEmpty && awake.last.$2 >= today.wakeMin) {
        // No sleep at all between the two.
        awake[awake.length - 1] = (awake.last.$1, end);
      } else {
        awake.add((today.wakeMin, end));
      }
    }
    return awake;
  }

  /// The hours asleep within the calendar day that is [weekday]: everything
  /// [wakingIntervalsOn] leaves out.
  List<(int, int)> sleepIntervalsOn(int weekday) {
    final asleep = <(int, int)>[];
    var cursor = 0;
    for (final (start, end) in wakingIntervalsOn(weekday)) {
      if (start > cursor) asleep.add((cursor, start));
      cursor = end;
    }
    if (cursor < minutesInDay) asleep.add((cursor, minutesInDay));
    return asleep;
  }

  /// Sleep between going to bed at [bedtimeMin] and next getting up at [wakeMin]: 23:30 to
  /// 07:00 is seven and a half hours, 01:00 to 09:30 eight and a half. Zero when they are
  /// the same minute.
  static int nightBetween(int bedtimeMin, int wakeMin) =>
      (wakeMin - bedtimeMin) % minutesInDay;

  /// Sleep in the night after the day that is [weekday]: from its bedtime to getting up the
  /// next day. Zero when the next day starts before this one ends.
  int nightAfter(int weekday) {
    final night =
        sleepOn(dayAfter(weekday)).wakeMin +
        minutesInDay -
        sleepOn(weekday).bedtimeFromMidnight;
    return night < 0 ? 0 : night;
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
    this.awake = const [],
    this.asleep = const [],
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

  /// Minutes of this date spent asleep. Present so it can be shown, never so it can be
  /// spent.
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

  /// The hours awake, as [start, end) intervals: everything else here is measured inside
  /// them.
  final List<(int, int)> awake;

  /// The hours asleep: the rest of the date.
  final List<(int, int)> asleep;

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
    final awake = settings.wakingIntervalsOn(day.weekday);
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
      sleepMin: minutesInDay - wakingMin,
      discardedGapMin: discarded,
      blocks: spans,
      discardedGaps: discardedGaps,
      awake: awake,
      asleep: settings.sleepIntervalsOn(day.weekday),
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
