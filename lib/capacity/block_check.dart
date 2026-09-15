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

/// Some of it falls while you sleep. Sleep is a floor, never time to spend, so the ledger
/// does not count that part.
final class DuringSleep extends BlockProblem {
  const DuringSleep({required this.bedtimeMin, required this.wakeMin});

  final int bedtimeMin;
  final int wakeMin;
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
    return [
      if (endMin > minutesInDay) const PastMidnight(),
      if (_overlapsSleep(startMin, endMin, settings))
        DuringSleep(bedtimeMin: settings.bedtimeMin, wakeMin: settings.wakeMin),
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
    // What is taken on any of the chosen days: sleep, and every block sharing one of them.
    final taken = <(int, int)>[
      ...settings.sleepIntervals,
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
    CapacitySettings settings,
  ) {
    // Anything past midnight falls in the small hours of the next day, whose sleep is the
    // same as this one's.
    final parts = [
      (startMin, endMin < minutesInDay ? endMin : minutesInDay),
      if (endMin > minutesInDay) (0, endMin - minutesInDay),
    ];
    for (final (from, to) in parts) {
      for (final (sleepFrom, sleepTo) in settings.sleepIntervals) {
        if (from < sleepTo && sleepFrom < to) return true;
      }
    }
    return false;
  }
}
