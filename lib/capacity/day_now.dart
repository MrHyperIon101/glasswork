import 'ledger.dart';

/// Where a day stands at a moment: inside a block, free until the next one, or done.
///
/// Worked out from what the ledger counted, so "free until 14:00" means exactly the time
/// the rest of the app counts as free.
class DayNow {
  const DayNow._({
    required this.current,
    required this.next,
    required this.untilMin,
    required this.awakeEndMin,
    required this.beforeWaking,
  });

  /// The block happening now.
  final BlockSpan? current;

  /// The next block to start.
  final BlockSpan? next;

  /// Minutes until what comes next: [current] ending, [next] starting, or the end of the
  /// waking day. Zero once the day is done.
  final int untilMin;

  /// When the waking day ends, in minutes past midnight.
  final int awakeEndMin;

  /// Whether the day has not started yet.
  final bool beforeWaking;

  bool get dayDone => current == null && next == null && untilMin == 0 && !beforeWaking;

  static DayNow of(DayCapacity day, int nowMin) {
    final awakeStart = day.awake.isEmpty ? 0 : day.awake.first.$1;
    final awakeEnd = day.awake.isEmpty ? minutesInDay : day.awake.last.$2;

    BlockSpan? current;
    BlockSpan? next;
    for (final block in day.blocks) {
      if (block.startMin <= nowMin && nowMin < block.endMin) {
        // Of blocks that overlap, the one ending last is what now is busy until.
        if (current == null || block.endMin > current.endMin) current = block;
      } else if (block.startMin > nowMin && (next == null || block.startMin < next.startMin)) {
        next = block;
      }
    }

    final until = current != null
        ? current.endMin - nowMin
        : next != null
        ? next.startMin - nowMin
        : (awakeEnd - nowMin).clamp(0, minutesInDay);

    return DayNow._(
      current: current,
      next: next,
      untilMin: until,
      awakeEndMin: awakeEnd,
      beforeWaking: nowMin < awakeStart,
    );
  }
}
