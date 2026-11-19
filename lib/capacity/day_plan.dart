import 'day_agenda.dart';

/// A task Plan my day may give a time to: one of today's, in the order the scheduler would
/// do them.
class PlanCandidate {
  const PlanCandidate({required this.taskId, required this.title, required this.minutes});

  final String taskId;
  final String title;

  /// How long to give it: its estimate, or the length a task given a time has without one.
  final int minutes;
}

/// A time Plan my day gives a task today, in minutes past midnight.
class PlanSlot {
  const PlanSlot({required this.taskId, required this.title, required this.startMin, required this.endMin});

  final String taskId;
  final String title;
  final int startMin;
  final int endMin;

  int get lengthMin => endMin - startMin;
}

class DayPlan {
  const DayPlan({required this.slots, required this.unplaced});

  static const empty = DayPlan(slots: [], unplaced: []);

  /// What gets a time, in time order.
  final List<PlanSlot> slots;

  /// What does not fit whole into any of today's free time that is left.
  final List<PlanCandidate> unplaced;

  int get plannedMin => slots.fold(0, (sum, s) => sum + s.lengthMin);

  bool get isEmpty => slots.isEmpty && unplaced.isEmpty;
}

/// Plan my day: today's work laid into today's free time, in the order the scheduler does it.
///
/// Free time is the agenda's — the ledger's own gaps, less the tasks already given a time — so
/// nothing is ever planned into sleep, a class, a meal or the past. Each task goes whole into
/// the first stretch that holds it, from the next five minutes on; one that fits nowhere whole
/// is left unplaced and said so, rather than cut up. Pure.
abstract final class DayPlanner {
  /// Starts fall on these minutes, so a plan reads 10:35 rather than 10:37.
  static const _step = 5;

  static DayPlan plan({
    required List<AgendaEntry> agenda,
    required List<PlanCandidate> candidates,
    required int nowMin,
  }) {
    int up(int min) => (min + _step - 1) ~/ _step * _step;
    // What is left of each stretch of free time, from now on.
    final free = <(int, int)>[
      for (final e in agenda)
        if (e.free && e.usable && e.endMin > nowMin)
          (up(e.startMin > nowMin ? e.startMin : nowMin), e.endMin),
    ].where((f) => f.$2 - f.$1 >= _step).toList();

    final slots = <PlanSlot>[];
    final unplaced = <PlanCandidate>[];
    for (final task in candidates) {
      final i = free.indexWhere((f) => f.$2 - f.$1 >= task.minutes);
      if (i < 0) {
        unplaced.add(task);
        continue;
      }
      final (start, end) = free[i];
      slots.add(PlanSlot(taskId: task.taskId, title: task.title, startMin: start, endMin: start + task.minutes));
      final rest = up(start + task.minutes);
      if (end - rest >= _step) {
        free[i] = (rest, end);
      } else {
        free.removeAt(i);
      }
    }
    slots.sort((a, b) => a.startMin.compareTo(b.startMin));
    return DayPlan(slots: slots, unplaced: unplaced);
  }
}
