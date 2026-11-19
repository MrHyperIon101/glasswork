import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/intel/focus_stats.dart';

/// What the focus timer has tracked, against fixed sessions.
void main() {
  final now = DateTime(2026, 9, 11, 15); // a Friday afternoon

  TrackedSession focus(DateTime start, int ran, {int planned = 25, String? task, bool open = false}) =>
      TrackedSession(
        startedAt: start,
        endedAt: open ? null : start.add(Duration(minutes: ran)),
        plannedMin: planned,
        taskId: task,
      );

  test('today, this week and each day, breaks counting for nothing', () {
    final stats = FocusStats.of([
      focus(DateTime(2026, 9, 11, 9), 25, task: 'lab'),
      focus(DateTime(2026, 9, 11, 10), 20, task: 'lab'),
      TrackedSession(startedAt: DateTime(2026, 9, 11, 9, 25), endedAt: DateTime(2026, 9, 11, 9, 30),
          plannedMin: 5, isBreak: true),
      focus(DateTime(2026, 9, 9, 14), 25, task: 'mail'),
      focus(DateTime(2026, 9, 1, 14), 25, task: 'old'), // more than a week ago
    ], now);
    expect(stats.todayMin, 45);
    expect(stats.weekMin, 70);
    expect(stats.byDay, [0, 0, 0, 0, 25, 0, 45]);
    expect(stats.byTask, {'lab': 45, 'mail': 25, 'old': 25});
  });

  test('a running session counts up to now; one left running, only to its length', () {
    final running = FocusStats.of([focus(DateTime(2026, 9, 11, 14, 50), 0, open: true)], now);
    expect(running.todayMin, 10);
    final forgotten = FocusStats.of([focus(DateTime(2026, 9, 11, 9), 0, open: true)], now);
    expect(forgotten.todayMin, 25, reason: 'set for 25 minutes, so 25, however long ago');
  });

  test('the streak runs back from today, and the morning does not break it', () {
    final days = [for (final d in [8, 9, 10]) focus(DateTime(2026, 9, d, 10), 25)];
    expect(FocusStats.of(days, now).streakDays, 3, reason: 'none yet today, but yesterday had some');
    expect(FocusStats.of([...days, focus(DateTime(2026, 9, 11, 9), 25)], now).streakDays, 4);
    expect(FocusStats.of([focus(DateTime(2026, 9, 8, 10), 25)], now).streakDays, 0);
  });
}
