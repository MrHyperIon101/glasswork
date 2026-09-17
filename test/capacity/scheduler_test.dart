import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/scheduler.dart';

final mon = DateTime(2026, 9, 14);

DateTime day(int offset) => mon.add(Duration(days: offset));

/// A run of identical days with [usable] minutes each, so tests exercise the allocator
/// rather than the ledger.
List<DayCapacity> flatCapacity(int days, int usable) => [
  for (var i = 0; i < days; i++)
    DayCapacity(
      date: day(i),
      committedMin: 0,
      wakingMin: 990,
      gaps: const [],
      overheadMin: 0,
      usableMin: usable,
      sleepMin: 450,
      discardedGapMin: 0,
    ),
];

PlannedTask task(
  String id, {
  required int? dueInDays,
  required int estimateMin,
  int priority = 0,
  int? plannedInDays,
}) => PlannedTask(
  id: id,
  title: id,
  dueDay: dueInDays == null ? null : day(dueInDays),
  estimateMin: estimateMin,
  priority: priority,
  plannedDay: plannedInDays == null ? null : day(plannedInDays),
);

void main() {
  test('a task that fits finishes with slack', () {
    final schedule = CapacityScheduler.run([
      task('a', dueInDays: 3, estimateMin: 120),
    ], flatCapacity(7, 240));

    final result = schedule.tasks.single;
    expect(result.startDay, day(0));
    expect(result.finishDay, day(0));
    expect(result.slackDays, 3);
    expect(result.state, Feasibility.fine);
    expect(result.shortfallMin, 0);
  });

  test('work spills across days when it exceeds one day of capacity', () {
    final schedule = CapacityScheduler.run([
      task('big', dueInDays: 5, estimateMin: 500),
    ], flatCapacity(7, 240));

    final result = schedule.tasks.single;
    expect(result.startDay, day(0));
    expect(result.finishDay, day(2), reason: '240 + 240 + 20');
    expect(schedule.allocatedOn(day(0)), 240);
    expect(schedule.allocatedOn(day(2)), 20);
  });

  test('finishing exactly on the due date is tight, not fine', () {
    // 240/day, due end of day 1, needs 480 -> finishes on day 1.
    final schedule = CapacityScheduler.run([
      task('a', dueInDays: 1, estimateMin: 480),
    ], flatCapacity(7, 240));

    expect(schedule.tasks.single.finishDay, day(1));
    expect(schedule.tasks.single.slackDays, 0);
    expect(schedule.tasks.single.state, Feasibility.tight);
  });

  test('work that cannot fit before the deadline is impossible', () {
    final schedule = CapacityScheduler.run([
      task('a', dueInDays: 1, estimateMin: 900),
    ], flatCapacity(7, 240));

    final result = schedule.tasks.single;
    expect(result.state, Feasibility.impossible);
    expect(result.slackDays, lessThan(0));
    expect(schedule.impossible, hasLength(1));
  });

  /// The reason this algorithm exists.
  test('two tasks cannot both claim the same free day', () {
    // One day of capacity, two tasks each needing all of it, both due that day.
    final schedule = CapacityScheduler.run([
      task('a', dueInDays: 0, estimateMin: 240),
      task('b', dueInDays: 0, estimateMin: 240),
    ], flatCapacity(1, 240));

    // A per-task backward walk would call both feasible. Sharing one pool cannot.
    expect(schedule.impossible, hasLength(1));
    expect(schedule.allocatedOn(day(0)), 240, reason: 'never over-allocated');
  });

  test('earlier deadlines are served first regardless of input order', () {
    final schedule = CapacityScheduler.run([
      task('later', dueInDays: 5, estimateMin: 240),
      task('sooner', dueInDays: 1, estimateMin: 240),
    ], flatCapacity(7, 240));

    final sooner = schedule.tasks.firstWhere((t) => t.task.id == 'sooner');
    final later = schedule.tasks.firstWhere((t) => t.task.id == 'later');

    expect(sooner.startDay, day(0));
    expect(later.startDay, day(1));
  });

  test('priority breaks ties between equal deadlines', () {
    final schedule = CapacityScheduler.run([
      task('low', dueInDays: 2, estimateMin: 240, priority: 1),
      task('high', dueInDays: 2, estimateMin: 240, priority: 3),
    ], flatCapacity(7, 240));

    expect(
      schedule.tasks.firstWhere((t) => t.task.id == 'high').startDay,
      day(0),
    );
  });

  test('the same inputs always produce the same plan', () {
    final tasks = [
      task('a', dueInDays: 2, estimateMin: 100),
      task('b', dueInDays: 2, estimateMin: 100),
      task('c', dueInDays: 1, estimateMin: 100),
    ];

    final first = CapacityScheduler.run(tasks, flatCapacity(7, 240));
    final second = CapacityScheduler.run(
      tasks.reversed.toList(),
      flatCapacity(7, 240),
    );

    expect(
      first.tasks.map((t) => '${t.task.id}:${t.startDay}'),
      second.tasks.map((t) => '${t.task.id}:${t.startDay}'),
    );
  });

  test('fully committed days are skipped, not partially filled', () {
    final capacity = [
      flatCapacity(1, 0).single, // today is gone
      ...flatCapacity(3, 240).map(
        (d) => DayCapacity(
          date: d.date.add(const Duration(days: 1)),
          committedMin: 0,
          wakingMin: 990,
          gaps: const [],
          overheadMin: 0,
          usableMin: 240,
          sleepMin: 450,
          discardedGapMin: 0,
        ),
      ),
    ];

    final schedule = CapacityScheduler.run([
      task('a', dueInDays: 3, estimateMin: 120),
    ], capacity);

    expect(schedule.allocatedOn(day(0)), 0);
    expect(schedule.tasks.single.startDay, day(1));
  });

  test('an already overdue task reports as impossible', () {
    final schedule = CapacityScheduler.run([
      PlannedTask(
        id: 'late',
        title: 'late',
        dueDay: day(-3),
        estimateMin: 60,
      ),
    ], flatCapacity(7, 240));

    expect(schedule.tasks.single.state, Feasibility.impossible);
  });

  test('no capacity at all is reported honestly, not as success', () {
    final schedule = CapacityScheduler.run([
      task('a', dueInDays: 3, estimateMin: 60),
    ], const []);

    expect(schedule.tasks.single.state, Feasibility.impossible);
    expect(schedule.tasks.single.shortfallMin, 60);
    expect(schedule.tasks.single.startDay, isNull);
  });

  test('allocation never exceeds a day of capacity', () {
    final schedule = CapacityScheduler.run([
      for (var i = 0; i < 20; i++)
        task('t$i', dueInDays: 6, estimateMin: 200),
    ], flatCapacity(7, 240));

    for (var i = 0; i < 7; i++) {
      expect(schedule.allocatedOn(day(i)), lessThanOrEqualTo(240));
    }
  });

  group('a task given a time', () {
    ScheduledTask planOf(Schedule schedule, String id) =>
        schedule.tasks.singleWhere((t) => t.task.id == id);

    test('takes its minutes from its own day, before the pass places the rest', () {
      final schedule = CapacityScheduler.run([
        task('essay', dueInDays: 1, estimateMin: 300),
        task('revise', dueInDays: 5, estimateMin: 120, plannedInDays: 2),
        task('lab', dueInDays: 3, estimateMin: 240),
      ], flatCapacity(7, 240));

      final revise = planOf(schedule, 'revise');
      expect((revise.startDay, revise.finishDay, revise.slackDays), (day(2), day(2), 3));
      expect(revise.state, Feasibility.fine);

      // The essay fills Monday and an hour of Tuesday; the lab takes the rest of Tuesday and
      // the hour Wednesday has left beside the revision.
      expect(planOf(schedule, 'essay').finishDay, day(1));
      expect(planOf(schedule, 'lab').finishDay, day(2));
      expect(
        [for (var i = 0; i < 4; i++) schedule.allocatedOn(day(i))],
        [240, 240, 180, 0],
      );
    });

    test('a time that overfills its day shows the day over, and moves nothing', () {
      final schedule = CapacityScheduler.run([
        task('marathon', dueInDays: 2, estimateMin: 300, plannedInDays: 0),
        task('email', dueInDays: 1, estimateMin: 60),
      ], flatCapacity(3, 240));

      expect(schedule.allocatedOn(day(0)), 300);
      expect(planOf(schedule, 'email').startDay, day(1));
    });

    test('a time after the deadline cannot work', () {
      final schedule = CapacityScheduler.run([
        task('late', dueInDays: 2, estimateMin: 60, plannedInDays: 4),
      ], flatCapacity(7, 240));

      expect(planOf(schedule, 'late').slackDays, -2);
      expect(planOf(schedule, 'late').state, Feasibility.impossible);
    });

    test('with no deadline, it counts on its day and has no plan of its own', () {
      final schedule = CapacityScheduler.run([
        task('gym', dueInDays: null, estimateMin: 90, plannedInDays: 1),
      ], flatCapacity(3, 240));

      expect(schedule.tasks, isEmpty);
      expect(schedule.allocatedOn(day(1)), 90);
    });

    test('a time already gone is placed like any other task', () {
      final schedule = CapacityScheduler.run([
        task('missed', dueInDays: 3, estimateMin: 60, plannedInDays: -1),
      ], flatCapacity(7, 240));

      expect(planOf(schedule, 'missed').startDay, day(0));
    });

    test('a time beyond the horizon stays where it was put, counted nowhere inside it', () {
      final schedule = CapacityScheduler.run([
        task('trip', dueInDays: 12, estimateMin: 120, plannedInDays: 10),
      ], flatCapacity(7, 240));

      expect(planOf(schedule, 'trip').startDay, day(10));
      expect(planOf(schedule, 'trip').state, Feasibility.fine);
      expect([for (var i = 0; i < 7; i++) schedule.allocatedOn(day(i))], everyElement(0));
    });
  });
}
