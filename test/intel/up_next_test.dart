import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/intel/up_next.dart';

void main() {
  final today = DateTime(2026, 9, 11, 15);

  UpNextCandidate task(String id, {int minutes = 30, DateTime? due, DateTime? start, int priority = 0}) =>
      UpNextCandidate(id: id, title: id, minutes: minutes, dueDay: due, startDay: start, priority: priority);

  test('overdue first, then soonest due, the more important first', () {
    final pick = UpNext.pick([
      task('soon', due: DateTime(2026, 9, 11)),
      task('late', due: DateTime(2026, 9, 9)),
      task('later', due: DateTime(2026, 9, 20), start: DateTime(2026, 9, 11)),
    ], today: today);
    expect(pick?.id, 'late');
    expect(
      UpNext.pick([task('a', due: DateTime(2026, 9, 11)), task('b', due: DateTime(2026, 9, 11), priority: 3)],
          today: today)?.id,
      'b',
    );
  });

  test('the first that fits before the next fixed thing, or else the first', () {
    final open = [task('long', minutes: 120, due: DateTime(2026, 9, 11)), task('short', minutes: 20, due: DateTime(2026, 9, 11))];
    expect(UpNext.pick(open, today: today, freeMin: 30)?.id, 'short');
    expect(UpNext.pick(open, today: today, freeMin: 10)?.id, 'long');
  });

  test('nothing, when nothing is on today', () {
    expect(UpNext.pick([task('next week', due: DateTime(2026, 9, 18), start: DateTime(2026, 9, 14))], today: today), isNull);
  });
}
