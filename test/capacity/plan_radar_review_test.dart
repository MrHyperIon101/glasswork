import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/daily_review.dart';
import 'package:glasswork/capacity/day_agenda.dart';
import 'package:glasswork/capacity/day_plan.dart';
import 'package:glasswork/capacity/deadline_radar.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/scheduler.dart';

/// Plan my day, the deadline radar and the evening's review, each against fixed days.
void main() {
  final friday = DateTime(2026, 9, 11);

  DayCapacity day(DateTime date, List<Gap> gaps, {int usable = 0}) => DayCapacity(
    date: date,
    committedMin: 0,
    wakingMin: 16 * 60,
    gaps: gaps,
    overheadMin: 0,
    usableMin: usable,
    sleepMin: 8 * 60,
    discardedGapMin: 0,
  );

  group('plan my day', () {
    // Free 9:00–10:00 and 14:00–16:00.
    final today = day(friday, const [Gap(9 * 60, 10 * 60), Gap(14 * 60, 16 * 60)]);
    PlanCandidate task(String id, int minutes) => PlanCandidate(taskId: id, title: id, minutes: minutes);

    test('each task whole into the first free time that holds it, in order', () {
      final plan = DayPlanner.plan(
        agenda: DayAgenda.of(today, 8 * 60),
        candidates: [task('a', 45), task('b', 90), task('c', 30)],
        nowMin: 8 * 60,
      );
      expect([for (final s in plan.slots) (s.taskId, s.startMin, s.endMin)], [
        ('a', 9 * 60, 9 * 60 + 45),
        ('b', 14 * 60, 15 * 60 + 30),
        ('c', 15 * 60 + 30, 16 * 60),
      ]);
      expect(plan.unplaced, isEmpty);
      expect(plan.plannedMin, 165);
    });

    test('never into the past, starting on the next five minutes', () {
      final plan = DayPlanner.plan(
        agenda: DayAgenda.of(today, 9 * 60 + 12),
        candidates: [task('a', 30)],
        nowMin: 9 * 60 + 12,
      );
      expect(plan.slots.single.startMin, 9 * 60 + 15);
    });

    test('what fits nowhere whole is left out and said so, not cut up', () {
      final plan = DayPlanner.plan(
        agenda: DayAgenda.of(today, 8 * 60),
        candidates: [task('long', 180), task('short', 20)],
        nowMin: 8 * 60,
      );
      expect(plan.unplaced.single.taskId, 'long');
      expect(plan.slots.single.taskId, 'short');
    });
  });

  group('deadline radar', () {
    test('each day its load against its time and what is due, then the tasks at risk', () {
      // Two hours a day, Friday to Monday.
      final days = [
        for (var i = 0; i < 4; i++)
          day(DateTime(2026, 9, 11 + i), const [], usable: 120),
      ];
      final schedule = CapacityScheduler.run([
        // 200 minutes by Friday: a day and a bit, so a day late.
        PlannedTask(id: 'late', title: 'late', dueDay: DateTime(2026, 9, 11), estimateMin: 200),
        // Then 100 by Sunday: finishes on Sunday itself.
        PlannedTask(id: 'tight', title: 'tight', dueDay: DateTime(2026, 9, 13), estimateMin: 100),
        // Then 30 by Monday: done on Sunday, a day to spare.
        PlannedTask(id: 'fits', title: 'fits', dueDay: DateTime(2026, 9, 14), estimateMin: 30),
      ], days);
      final radar = DeadlineRadar.of(schedule, days);
      expect(radar.days.map((d) => d.due), [['late'], <String>[], ['tight'], ['fits']]);
      expect(radar.days.map((d) => d.loadMin), [120, 120, 90, 0]);
      expect(radar.days.any((d) => d.over), isFalse);
      expect(radar.risks.map((r) => r.taskId), ['late', 'tight'], reason: "won't fit first, then tight");
    });
  });

  group('daily review', () {
    test('done today, what slipped, and focus against plan', () {
      final review = DailyReviewer.of(
        tasks: [
          ReviewTask(id: 'd', title: 'done', done: true, completedAt: DateTime(2026, 9, 11, 10)),
          ReviewTask(id: 'old', title: 'done before', done: true, completedAt: DateTime(2026, 9, 10, 10)),
          ReviewTask(id: 's1', title: 'slipped', dueDay: DateTime(2026, 9, 11)),
          ReviewTask(id: 's0', title: 'slipped earlier', dueDay: DateTime(2026, 9, 9)),
          ReviewTask(id: 'later', title: 'not yet', dueDay: DateTime(2026, 9, 12)),
        ],
        today: friday,
        focusMin: 75,
        plannedMin: 180,
      );
      expect(review.done.map((t) => t.id), ['d']);
      expect(review.slipped.map((t) => t.id), ['s0', 's1'], reason: 'oldest first');
      expect(review.focusMin, 75);
    });
  });
}
