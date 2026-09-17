import 'ledger.dart';

/// What stands in the way of giving a task a time on a day.
sealed class SlotProblem {
  const SlotProblem();
}

/// It runs past midnight, into a day of its own.
final class SlotPastMidnight extends SlotProblem {
  const SlotPastMidnight();
}

/// Some of it falls while you are asleep. Sleep is a floor, never time to spend.
final class SlotAsleep extends SlotProblem {
  const SlotAsleep();
}

/// It overlaps something else on the day: a block of the timetable, or another task with a
/// time.
final class SlotClash extends SlotProblem {
  const SlotClash({required this.title, required this.startMin, required this.endMin});

  final String title;
  final int startMin;
  final int endMin;
}

/// Whether a task can have a time where it has been put, and where it could go instead.
///
/// Worked out from what the ledger counted for the date, so "free from 12:00" means the time
/// the rest of the app counts as free.
abstract final class SlotCheck {
  /// Everything in the way of [lengthMin] from [startMin] on [day], beside [others], the
  /// other things with a time that day, as (title, start, end). Empty when it fits.
  static List<SlotProblem> problems(
    DayCapacity day, {
    required int startMin,
    required int lengthMin,
    List<(String, int, int)> others = const [],
  }) {
    final endMin = startMin + lengthMin;
    bool overlaps(int start, int end) => startMin < end && start < endMin;

    return [
      if (endMin > minutesInDay) const SlotPastMidnight(),
      if (day.asleep.any((s) => overlaps(s.$1, s.$2))) const SlotAsleep(),
      for (final block in day.blocks)
        if (overlaps(block.startMin, block.endMin))
          SlotClash(title: block.title, startMin: block.startMin, endMin: block.endMin),
      for (final (title, start, end) in others)
        if (overlaps(start, end)) SlotClash(title: title, startMin: start, endMin: end),
    ];
  }

  /// The earliest start, at or after [fromMin], from which [lengthMin] runs through free time
  /// alone: none of the day's blocks, none of [others], no sleep. Null when nothing that long
  /// is left.
  static int? nextFree(
    DayCapacity day, {
    required int lengthMin,
    int fromMin = 0,
    List<(String, int, int)> others = const [],
  }) {
    // The ledger's gaps, less the time other tasks already have.
    for (final gap in day.gaps) {
      var start = gap.startMin > fromMin ? gap.startMin : fromMin;
      final taken = [
        for (final (_, s, e) in others)
          if (s < gap.endMin && e > start) (s, e),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      for (final (s, e) in taken) {
        if (s - start >= lengthMin) return start;
        if (e > start) start = e;
      }
      if (gap.endMin - start >= lengthMin) return start;
    }
    return null;
  }
}
