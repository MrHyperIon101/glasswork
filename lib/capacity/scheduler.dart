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
    this.plannedDay,
  }) : assert(
         dueDay != null || plannedDay != null,
         'a task with neither a deadline nor a time has nothing to be planned against',
       );

  final String id;
  final String title;

  /// Null only for a task given a time with no deadline, which is here for the time it
  /// takes on its day and has no feasibility of its own.
  final DateTime? dueDay;

  final int estimateMin;
  final int priority;

  /// The day the task has been given a time on. Its minutes go on that day, whatever the
  /// pass would have chosen; a day it overfills shows as over, rather than moving the work.
  final DateTime? plannedDay;

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
  ///
  /// A task with a time today or later is placed on that day first, its whole estimate
  /// taken from that day. One whose time has passed is placed like any other, since the time
  /// it had is gone. A task with a time and no deadline counts on its day and nowhere else.
  static Schedule run(List<PlannedTask> tasks, List<DayCapacity> capacity) {
    if (capacity.isEmpty) {
      return Schedule(
        tasks: [
          for (final t in tasks)
            if (t.dueDay != null)
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

    final remaining = [for (final day in capacity) day.usableMin];
    final allocated = <DateTime, int>{};
    final results = <ScheduledTask>[];

    final first = _date(capacity.first.date);
    final dayIndex = {
      for (final (i, day) in capacity.indexed) _date(day.date): i,
    };

    final floating = <PlannedTask>[];
    for (final task in tasks) {
      final planned = task.plannedDay == null ? null : _date(task.plannedDay!);
      if (planned == null || planned.isBefore(first)) {
        if (task.dueDay != null) floating.add(task);
        continue;
      }

      // Beyond the horizon it is still where it was put, just outside what is counted.
      if (dayIndex[planned] case final i?) {
        remaining[i] -= task.estimateMin;
        allocated.update(
          capacity[i].date,
          (v) => v + task.estimateMin,
          ifAbsent: () => task.estimateMin,
        );
      }
      if (task.dueDay case final due?) {
        results.add(
          ScheduledTask(
            task: task,
            startDay: planned,
            finishDay: planned,
            slackDays: _daysBetween(planned, due),
            shortfallMin: 0,
          ),
        );
      }
    }

    // Earliest deadline first. Priority and id break ties so the result is deterministic
    // — the same inputs must always produce the same plan, or nobody can trust it.
    final ordered = floating
      ..sort((a, b) {
        final byDue = a.dueDay!.compareTo(b.dueDay!);
        if (byDue != 0) return byDue;
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;
        return a.id.compareTo(b.id);
      });

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
      final slack = finishDay == null ? -1 : _daysBetween(finishDay, task.dueDay!);

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

  static DateTime _date(DateTime day) => DateTime(day.year, day.month, day.day);

  /// Whole dates from [from] to [to], which a change of clocks between them cannot throw off.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;
}
