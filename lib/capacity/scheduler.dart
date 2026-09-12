import 'ledger.dart';

/// Backward-scheduled feasibility, computed forwards.
///
/// The naive approach — walk back from each deadline until the capacity between here and
/// there covers the estimate — double-counts: two tasks each conclude they own the same
/// free Wednesday, and both report fine right up until neither fits.
///
/// Instead this consumes one shared pool in deadline order. Sorting by due date and
/// allocating greedily is Jackson's rule, which provably minimises maximum lateness on a
/// single machine, and a single machine is exactly what a person is. One pass then yields
/// both the schedule and the slack.
///
/// Pure arithmetic: no network, no model, no clock of its own.

enum Feasibility {
  /// Finishes with days to spare.
  fine,

  /// Finishes on the due date itself. No room left for anything going wrong.
  tight,

  /// Does not fit at all at your current commitments.
  impossible,
}

/// A task as the scheduler sees it.
class PlannedTask {
  const PlannedTask({
    required this.id,
    required this.title,
    required this.dueDay,
    required this.estimateMin,
    this.priority = 0,
    this.estimateAssumed = false,
  });

  final String id;
  final String title;
  final DateTime dueDay;
  final int estimateMin;
  final int priority;

  /// True when the estimate is the app's guess rather than yours. Shown differently, so
  /// you can see which numbers it is inventing.
  final bool estimateAssumed;
}

/// Where a task landed.
class ScheduledTask {
  const ScheduledTask({
    required this.task,
    required this.startDay,
    required this.finishDay,
    required this.slackDays,
    required this.shortfallMin,
  });

  final PlannedTask task;

  /// Null when it could not be placed inside the horizon at all.
  final DateTime? startDay;
  final DateTime? finishDay;

  /// Days between finishing and the deadline. Negative means late.
  final int slackDays;

  /// Minutes that could not be placed before the deadline. Zero when it fits.
  final int shortfallMin;

  Feasibility get state {
    if (shortfallMin > 0 || slackDays < 0) return Feasibility.impossible;
    return slackDays == 0 ? Feasibility.tight : Feasibility.fine;
  }
}

class Schedule {
  const Schedule({required this.tasks, required this.allocatedByDay});

  final List<ScheduledTask> tasks;

  /// Minutes committed per day by this plan. Feeds the day load bars.
  final Map<DateTime, int> allocatedByDay;

  List<ScheduledTask> get impossible =>
      tasks.where((t) => t.state == Feasibility.impossible).toList();

  List<ScheduledTask> get tight =>
      tasks.where((t) => t.state == Feasibility.tight).toList();

  int allocatedOn(DateTime day) =>
      allocatedByDay[DateTime(day.year, day.month, day.day)] ?? 0;
}

abstract final class CapacityScheduler {
  /// Estimate applied when a task has none and there is no history to borrow from.
  ///
  /// Marked as assumed so the UI can show it differently — you should always be able to
  /// see which numbers are yours and which are the app's.
  static const assumedEstimateMin = 30;

  /// Allocates [tasks] across [capacity] in deadline order.
  ///
  /// [capacity] must be consecutive days starting at the planning date. Days with no
  /// usable minutes are skipped, not partially filled.
  ///
  /// Sleep cannot be scheduled into: usable minutes are derived from the waking window
  /// only, so the floor holds structurally rather than by a check somewhere.
  static Schedule run(List<PlannedTask> tasks, List<DayCapacity> capacity) {
    if (capacity.isEmpty) {
      return Schedule(
        tasks: [
          for (final t in tasks)
            ScheduledTask(
              task: t,
              startDay: null,
              finishDay: null,
              slackDays: -1,
              shortfallMin: t.estimateMin,
            ),
        ],
        allocatedByDay: const {},
      );
    }

    // Earliest deadline first. Priority and id break ties so the result is deterministic
    // — the same inputs must always produce the same plan, or nobody can trust it.
    final ordered = [...tasks]
      ..sort((a, b) {
        final byDue = a.dueDay.compareTo(b.dueDay);
        if (byDue != 0) return byDue;
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;
        return a.id.compareTo(b.id);
      });

    final remaining = [for (final day in capacity) day.usableMin];
    final allocated = <DateTime, int>{};
    final results = <ScheduledTask>[];

    var cursor = 0;

    for (final task in ordered) {
      var need = task.estimateMin;
      DateTime? startDay;
      DateTime? finishDay;

      while (need > 0 && cursor < capacity.length) {
        if (remaining[cursor] <= 0) {
          cursor++;
          continue;
        }

        final take = need < remaining[cursor] ? need : remaining[cursor];
        final day = capacity[cursor].date;

        startDay ??= day;
        finishDay = day;
        remaining[cursor] -= take;
        allocated.update(day, (v) => v + take, ifAbsent: () => take);
        need -= take;
      }

      // Anything still needed ran past the end of the horizon.
      final shortfall = need;
      final slack = finishDay == null
          ? -1
          : task.dueDay.difference(finishDay).inDays;

      results.add(
        ScheduledTask(
          task: task,
          startDay: startDay,
          finishDay: finishDay,
          slackDays: slack,
          shortfallMin: shortfall,
        ),
      );
    }

    return Schedule(tasks: results, allocatedByDay: allocated);
  }
}
