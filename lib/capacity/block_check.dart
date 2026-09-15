import 'ledger.dart';

/// Whether a fixed block can go where it has been put, and where it could go instead.
///
/// A block the ledger cannot count must never be accepted quietly. A class entered at
/// midnight used to save without complaint and then appear nowhere: the ledger counts only
/// waking hours, so the block was clipped away, and nothing said why.
///
/// Pure arithmetic over minutes past midnight, like the ledger it guards.

/// Why a block cannot go where it has been put.
sealed class BlockProblem {
  const BlockProblem();
}

/// Some of it falls while you sleep, on [weekdays]. Sleep is a floor, never time to spend,
/// so the ledger does not count that part.
final class DuringSleep extends BlockProblem {
  const DuringSleep({required this.weekdays});

  /// The days, of those it repeats on, when it falls in your sleep.
  final Set<int> weekdays;
}

/// It runs past midnight. A block repeats on the days it starts, so the part after
/// midnight lands on a day its rule knows nothing about.
final class PastMidnight extends BlockProblem {
  const PastMidnight();
}

/// It overlaps another block of the same timetable on a day they share.
final class Clash extends BlockProblem {
  const Clash({
    required this.title,
    required this.weekdays,
    required this.startMin,
    required this.endMin,
  });

  final String title;

  /// The days both happen, `DateTime.monday` to `DateTime.sunday`.
  final Set<int> weekdays;

  final int startMin;
  final int endMin;
}

abstract final class BlockCheck {
  /// Everything wrong with a block of [durationMin] starting at [startMin] on [weekdays],
  /// alongside [others], the rest of its timetable. Empty when it fits.
  static List<BlockProblem> problems({
    required int startMin,
    required int durationMin,
    required Set<int> weekdays,
    required CapacitySettings settings,
    List<FixedBlock> others = const [],
  }) {
    final endMin = startMin + durationMin;
    final asleep = {
      for (final day in weekdays)
        if (_overlapsSleep(startMin, endMin, day, settings)) day,
    };

    return [
      if (endMin > minutesInDay) const PastMidnight(),
      if (asleep.isNotEmpty) DuringSleep(weekdays: asleep),
      for (final other in others)
        if (other.recurrence.weekdays.intersection(weekdays) case final shared
            when shared.isNotEmpty &&
                startMin < other.endMin &&
                other.startMin < endMin)
          Clash(
            title: other.title,
            weekdays: shared,
            startMin: other.startMin,
            endMin: other.endMin,
          ),
    ];
  }

  /// The start nearest [startMin] at which a block of [durationMin] fits on every one of
  /// [weekdays]: awake, before midnight, and clear of [others]. Null when nothing that long
  /// is free on those days.
  static int? nearestFreeStart({
    required int startMin,
    required int durationMin,
    required Set<int> weekdays,
    required CapacitySettings settings,
    List<FixedBlock> others = const [],
  }) {
    // What is taken on any of the chosen days: that day's sleep, and every block sharing
    // one of them.
    final taken = <(int, int)>[
      for (final day in weekdays) ...settings.sleepIntervalsOn(day),
      for (final other in others)
        if (other.recurrence.weekdays.any(weekdays.contains))
          (other.startMin, other.endMin.clamp(0, minutesInDay)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final free = <(int, int)>[];
    var cursor = 0;
    for (final (start, end) in taken) {
      if (start > cursor) free.add((cursor, start));
      if (end > cursor) cursor = end;
    }
    if (cursor < minutesInDay) free.add((cursor, minutesInDay));

    int? best;
    for (final (start, end) in free) {
      if (end - start < durationMin) continue;
      // As close to where it was put as this stretch allows. An earlier stretch wins a tie.
      final candidate = startMin.clamp(start, end - durationMin);
      if (best == null || (candidate - startMin).abs() < (best - startMin).abs()) {
        best = candidate;
      }
    }
    return best;
  }

  static bool _overlapsSleep(
    int startMin,
    int endMin,
    int weekday,
    CapacitySettings settings,
  ) {
    bool overlaps(int from, int to, List<(int, int)> asleep) {
      for (final (sleepFrom, sleepTo) in asleep) {
        if (from < sleepTo && sleepFrom < to) return true;
      }
      return false;
    }

    final beforeMidnight = overlaps(
      startMin,
      endMin < minutesInDay ? endMin : minutesInDay,
      settings.sleepIntervalsOn(weekday),
    );
    // Past midnight, it is in the small hours of the next date, and that date's sleep.
    final afterMidnight =
        endMin > minutesInDay &&
        overlaps(
          0,
          endMin - minutesInDay,
          settings.sleepIntervalsOn(CapacitySettings.dayAfter(weekday)),
        );
    return beforeMidnight || afterMidnight;
  }
}
