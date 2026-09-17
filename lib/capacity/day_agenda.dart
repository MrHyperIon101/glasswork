import 'ledger.dart';

/// Where an entry of the day falls against now.
enum AgendaTime { past, now, later }

/// One stretch of a day: a block from the timetable, or the free time between blocks.
class AgendaEntry {
  const AgendaEntry._({
    required this.block,
    required this.startMin,
    required this.endMin,
    required this.when,
    required this.usable,
  });

  /// The block, or null for free time.
  final BlockSpan? block;

  final int startMin;
  final int endMin;
  final AgendaTime when;

  /// For free time, whether the ledger counts it: a stretch too short to use is not
  /// capacity, and says so. Always true for a block.
  final bool usable;

  bool get free => block == null;

  int get lengthMin => endMin - startMin;

  @override
  String toString() =>
      'AgendaEntry(${block?.title ?? 'free'} $startMin–$endMin, ${when.name}'
      '${usable ? '' : ', too short'})';
}

/// The day in order: each block, and the free time around the blocks.
///
/// Free time is the ledger's own gaps, so the stretches listed are exactly the time the
/// rest of the app counts as free, and one it throws away as too short is marked that way.
abstract final class DayAgenda {
  static List<AgendaEntry> of(DayCapacity day, int nowMin) {
    AgendaTime when(int start, int end) => end <= nowMin
        ? AgendaTime.past
        : start <= nowMin
        ? AgendaTime.now
        : AgendaTime.later;

    bool discarded(Gap gap) => day.discardedGaps.any(
      (d) => d.startMin == gap.startMin && d.endMin == gap.endMin,
    );

    final entries = [
      for (final block in day.blocks)
        AgendaEntry._(
          block: block,
          startMin: block.startMin,
          endMin: block.endMin,
          when: when(block.startMin, block.endMin),
          usable: true,
        ),
      for (final gap in day.gaps)
        if (gap.lengthMin > 0)
          AgendaEntry._(
            block: null,
            startMin: gap.startMin,
            endMin: gap.endMin,
            when: when(gap.startMin, gap.endMin),
            usable: !discarded(gap),
          ),
    ];

    // In time order. Free time never starts where a block does, since it is what the
    // blocks leave; blocks starting together keep the ledger's order.
    final order = {for (final (i, entry) in entries.indexed) entry: i};
    return entries..sort((a, b) {
      final byStart = a.startMin.compareTo(b.startMin);
      return byStart != 0 ? byStart : order[a]!.compareTo(order[b]!);
    });
  }
}
