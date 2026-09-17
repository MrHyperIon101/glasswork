import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/day_agenda.dart';
import 'package:glasswork/capacity/day_now.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/capacity/recurrence.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/task_stats.dart';
import 'package:glasswork/ui/home_text.dart';

void main() {
  TaskStats stats({int overdue = 0, int due = 0, int done = 0, int estimate = 0}) => TaskStats(
    open: overdue + due,
    overdue: List.filled(overdue, _task),
    dueToday: List.filled(due, _task),
    completedToday: done,
    completedThisWeek: done,
    estimatedMinutesToday: estimate,
    untimedToday: 0,
    nextUp: null,
  );

  test('greets by the time of day', () {
    expect(HomeText.greeting(DateTime(2026, 9, 16, 2)), 'Good night');
    expect(HomeText.greeting(DateTime(2026, 9, 16, 9)), 'Good morning');
    expect(HomeText.greeting(DateTime(2026, 9, 16, 15)), 'Good afternoon');
    expect(HomeText.greeting(DateTime(2026, 9, 16, 20)), 'Good evening');
    expect(HomeText.longDate(DateTime(2026, 9, 16)), 'Wednesday, 16 September');
  });

  test('the day in a line, leaving out what is not there', () {
    expect(HomeText.summary(stats(), wontFit: 0), 'Nothing due today');
    expect(
      HomeText.summary(stats(overdue: 1, due: 3, estimate: 255), wontFit: 2),
      "4 tasks today · 4h 15m planned · 2 won't fit",
    );
    expect(HomeText.summary(stats(due: 1), wontFit: 0), '1 task today');
  });

  test('progress says how much of today is done', () {
    expect(HomeText.progress(stats()), 'A clear day');
    expect(HomeText.progress(stats(due: 4, done: 3)), '3 of 7 done');
    expect(HomeText.progress(stats(done: 2)), 'All 2 done');
  });

  group('the day, entry by entry', () {
    // Up 07:00, bed 23:30: a lecture, half an hour too short to use, then a lab.
    final day = CapacityLedger.forDay(DateTime(2026, 9, 16), const CapacitySettings(), [
      for (final (title, start, length) in [
        ('DBMS lecture', 9 * 60, 90),
        ('OS lab', 11 * 60, 120),
      ])
        FixedBlock(
          title: title,
          startMin: start,
          durationMin: length,
          recurrence: Recurrence.parse('FREQ=WEEKLY;BYDAY=WE'),
        ),
    ]);

    test('a block by its name and length, and what is left of it while it is on', () {
      final agenda = DayAgenda.of(day, 9 * 60 + 45);
      final lecture = agenda.firstWhere((e) => e.block?.title == 'DBMS lecture');
      final lab = agenda.firstWhere((e) => e.block?.title == 'OS lab');

      expect(HomeText.agendaTitle(lecture), 'DBMS lecture');
      expect(HomeText.agendaDetail(lecture, 9 * 60 + 45), '45m left');
      expect(HomeText.agendaDetail(lab, 9 * 60 + 45), '2h');
    });

    test('free time, and free time too short to count', () {
      final agenda = DayAgenda.of(day, 8 * 60);
      final morning = agenda.first;
      final between = agenda.firstWhere((e) => e.free && e.startMin == 10 * 60 + 30);
      final evening = agenda.last;

      expect(HomeText.agendaTitle(morning), 'Free');
      expect(HomeText.agendaDetail(morning, 8 * 60), '1h left');
      expect(HomeText.agendaDetail(between, 8 * 60), '30m · too short to count');
      expect(HomeText.agendaDetail(evening, 8 * 60), '10h 30m');
    });

    test('a day with nothing on it says so, and which day it is', () {
      final now = DateTime(2026, 9, 16, 10);
      expect(HomeText.nothingFixed(DateTime(2026, 9, 16), now), 'Nothing fixed today');
      expect(HomeText.nothingFixed(DateTime(2026, 9, 17), now), 'Nothing fixed tomorrow');
      expect(HomeText.nothingFixed(DateTime(2026, 9, 19), now), 'Nothing fixed on Saturday');
    });
  });

  group('right now', () {
    DayCapacity day(List<BlockSpan> blocks) => DayCapacity(
      date: DateTime(2026, 9, 16),
      committedMin: 0,
      wakingMin: 0,
      gaps: const [],
      overheadMin: 0,
      usableMin: 0,
      sleepMin: 0,
      discardedGapMin: 0,
      blocks: blocks,
      awake: const [(7 * 60, 23 * 60 + 30)],
    );
    const lecture = BlockSpan(title: 'DBMS lecture', startMin: 9 * 60, endMin: 10 * 60 + 30);

    test('in a block, free until one, free for the evening, and done', () {
      expect(
        HomeText.now(DayNow.of(day([lecture]), 10 * 60)),
        (title: 'In DBMS lecture', detail: 'Until 10:30 · 30m left'),
      );
      expect(
        HomeText.now(DayNow.of(day([lecture]), 7 * 60 + 30)),
        (title: 'Free until 09:00', detail: '1h 30m before DBMS lecture'),
      );
      expect(
        HomeText.now(DayNow.of(day([lecture]), 20 * 60), bedtimeMin: 23 * 60 + 30),
        (title: 'Free for the rest of the day', detail: '3h 30m until bed at 23:30'),
      );
      expect(HomeText.now(DayNow.of(day([lecture]), 23 * 60 + 40)).title, "The day's done");
      expect(
        HomeText.now(DayNow.of(day([lecture]), 5 * 60)),
        (title: 'Your day starts soon', detail: 'First up: DBMS lecture at 09:00'),
      );
    });
  });
}

final _task = Task(
  id: 't',
  workspaceId: 'ws',
  listId: 'l',
  title: 'task',
  orderKey: 'a0',
  status: TaskStatus.open,
  priority: 0,
  slipCount: 0,
  createdAt: DateTime(2026, 9, 16),
  updatedAt: DateTime(2026, 9, 16),
  fieldVersions: '{}',
);
