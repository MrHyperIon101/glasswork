import 'ledger.dart';
import 'task_slot.dart';

/// Where an entry of the day falls against now.
enum AgendaTime { past, now, later }

/// One stretch of a day: a block from the timetable, a task given a time, or the free time
/// around them.
class AgendaEntry {
  const AgendaEntry._({
    required this.startMin,
    required this.endMin,
    required this.when,
    this.block,
    this.task,
    this.usable = true,
  });

  /// The block, for a block.
  final BlockSpan? block;

  /// The task, for a task given a time.
  final TaskSlot? task;

  final int startMin;
  final int endMin;
  final AgendaTime when;

  /// For free time, whether the ledger counts it: a stretch too short to use is not
  /// capacity, and says so. Always true for a block or a task.
  final bool usable;

  bool get free => block == null && task == null;

  int get lengthMin => endMin - startMin;

  @override
  String toString() =>
      'AgendaEntry(${block?.title ?? task?.title ?? 'free'} $startMin–$endMin, ${when.name}'
      '${usable ? '' : ', too short'})';
}

/// The day in order: each block, each task given a time, and the free time around them.
///
/// Free time is the ledger's own gaps, so the stretches listed are exactly the time the
/// rest of the app counts as free, and one it throws away as too short is marked that way.
/// A task given a time takes its part of a gap, and the free time either side of it is what
/// is left.
abstract final class DayAgenda {
  /// Free time shorter than this, left between a task and whatever comes next, is not
  /// worth a line of its own.
  static const shortestFreeMin = 5;

  static List<AgendaEntry> of(
    DayCapacity day,
    int nowMin, {
    List<TaskSlot> tasks = const [],
  }) {
    AgendaTime when(int start, int end) => end <= nowMin
        ? AgendaTime.past
        : start <= nowMin
        ? AgendaTime.now
        : AgendaTime.later;

    // By start, whatever order they came in, so each gap is cut up from its beginning.
    final slots = [...tasks]..sort((a, b) => a.startMin.compareTo(b.startMin));

    bool discarded(Gap gap) => day.discardedGaps.any(
      (d) => d.startMin == gap.startMin && d.endMin == gap.endMin,
    );

    /// What is left of [gap] once the tasks have their time.
    Iterable<(int, int)> freeIn(Gap gap) sync* {
      var cursor = gap.startMin;
      for (final task in slots) {
        if (task.endMin <= cursor || task.startMin >= gap.endMin) continue;
        if (task.startMin > cursor) yield (cursor, task.startMin);
        if (task.endMin > cursor) cursor = task.endMin;
      }
      if (gap.endMin > cursor) yield (cursor, gap.endMin);
    }

    final entries = [
      for (final block in day.blocks)
        AgendaEntry._(
          block: block,
          startMin: block.startMin,
          endMin: block.endMin,
          when: when(block.startMin, block.endMin),
        ),
      for (final task in slots)
        if (task.lengthMin > 0)
          AgendaEntry._(
            task: task,
            startMin: task.startMin,
            endMin: task.endMin,
            when: when(task.startMin, task.endMin),
          ),
      for (final gap in day.gaps)
        for (final (start, end) in freeIn(gap))
          // A whole gap is shown however short, since the ledger's word on it matters; a
          // sliver a task leaves is not.
          if (end - start >= (start == gap.startMin && end == gap.endMin ? 1 : shortestFreeMin))
            AgendaEntry._(
              startMin: start,
              endMin: end,
              when: when(start, end),
              usable: !discarded(gap),
            ),
    ];

    // In time order. Where two start together: blocks, then tasks, then free time, which
    // keeps the ledger's order among blocks.
    int rank(AgendaEntry e) => e.block != null
        ? 0
        : e.task != null
        ? 1
        : 2;
    final order = {for (final (i, entry) in entries.indexed) entry: i};
    return entries..sort((a, b) {
      final byStart = a.startMin.compareTo(b.startMin);
      if (byStart != 0) return byStart;
      final byKind = rank(a).compareTo(rank(b));
      return byKind != 0 ? byKind : order[a]!.compareTo(order[b]!);
    });
  }
}
