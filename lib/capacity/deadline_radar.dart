import 'ledger.dart';
import 'scheduler.dart';

/// One day on the radar: how much there is to do then against how much time there is, and
/// what falls due.
class RadarDay {
  const RadarDay({required this.date, required this.capacityMin, required this.loadMin, required this.due});

  final DateTime date;

  /// Usable minutes that day, as the ledger counts them.
  final int capacityMin;

  /// Minutes of work the scheduler put on it.
  final int loadMin;

  /// The ids of the tasks due that day.
  final List<String> due;

  /// How full it is, 0 to 1 and past 1 when more is planned than fits.
  double get fill => capacityMin <= 0 ? (loadMin > 0 ? 2 : 0) : loadMin / capacityMin;

  bool get over => loadMin > capacityMin;
}

/// A task the radar warns about.
class RadarRisk {
  const RadarRisk({required this.plan});

  final ScheduledTask plan;

  String get taskId => plan.task.id;
  Feasibility get state => plan.state;
}

class Radar {
  const Radar({required this.days, required this.risks});

  final List<RadarDay> days;

  /// What will not fit, then what will only just, the soonest due first.
  final List<RadarRisk> risks;
}

/// The next fortnight at a glance: each day's load against its time, its deadlines, and the
/// tasks at risk. All of it straight from the scheduler's own plan, so it can never disagree
/// with a task's badge. Pure.
abstract final class DeadlineRadar {
  static Radar of(Schedule schedule, List<DayCapacity> capacity, {int days = 14}) {
    DateTime dateOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final dueBy = <DateTime, List<String>>{};
    for (final t in schedule.tasks) {
      if (t.task.dueDay case final due?) (dueBy[dateOf(due)] ??= []).add(t.task.id);
    }
    final radarDays = [
      for (final day in capacity.take(days))
        RadarDay(
          date: dateOf(day.date),
          capacityMin: day.usableMin,
          loadMin: schedule.allocatedOn(day.date),
          due: dueBy[dateOf(day.date)] ?? const [],
        ),
    ];
    final risks = [
      for (final t in schedule.tasks)
        if (t.state != Feasibility.fine) RadarRisk(plan: t),
    ]..sort((a, b) {
        final byState = (a.state == Feasibility.impossible ? 0 : 1)
            .compareTo(b.state == Feasibility.impossible ? 0 : 1);
        if (byState != 0) return byState;
        return a.plan.task.dueDay!.compareTo(b.plan.task.dueDay!);
      });
    return Radar(days: radarDays, risks: risks);
  }
}
