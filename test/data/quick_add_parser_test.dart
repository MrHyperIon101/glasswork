import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/quick_add_parser.dart';

void main() {
  // A Friday, so weekday arithmetic is exercised across a week boundary.
  final now = DateTime(2026, 9, 11, 9, 0);

  ParsedQuickAdd parse(String s) => QuickAddParser.parse(s, now: now);

  test('plain text is left alone', () {
    final r = parse('buy milk');
    expect(r.title, 'buy milk');
    expect(r.dueAt, isNull);
    expect(r.dueDate, isNull);
    expect(r.priority, 0);
    expect(r.spans, isEmpty);
  });

  test('parses the full example line', () {
    final r = parse('submit dbms lab tmrw 5pm !high #uni ~4h');

    expect(r.title, 'submit dbms lab');
    expect(r.dueAt, DateTime(2026, 9, 12, 17, 0));
    expect(r.dueDate, isNull, reason: 'a time was given, so it is not all-day');
    expect(r.priority, 3);
    expect(r.labels, ['uni']);
    expect(r.estimateMin, 240);
  });

  test('date without a time is all-day, stored as text', () {
    final r = parse('dentist tomorrow');
    expect(r.title, 'dentist');
    expect(r.dueDate, '2026-09-12');
    expect(r.dueAt, isNull);
  });

  test('today resolves to today', () {
    expect(parse('gym today').dueDate, '2026-09-11');
  });

  test('weekday picks the next occurrence, not today', () {
    // now is a Friday; "fri" must mean next Friday.
    expect(parse('standup fri').dueDate, '2026-09-18');
    // Monday is three days out.
    expect(parse('standup mon').dueDate, '2026-09-14');
  });

  test('"next <weekday>" skips a further week', () {
    expect(parse('review next mon').dueDate, '2026-09-21');
  });

  test('longer weekday names are not shadowed by short ones', () {
    expect(parse('call tuesday').dueDate, parse('call tue').dueDate);
  });

  test('in N days and weeks', () {
    expect(parse('ping in 3 days').dueDate, '2026-09-14');
    expect(parse('ping in 2 weeks').dueDate, '2026-09-25');
  });

  test('24-hour and 12-hour times both work', () {
    expect(parse('call today 17:30').dueAt, DateTime(2026, 9, 11, 17, 30));
    expect(parse('call today 5:30pm').dueAt, DateTime(2026, 9, 11, 17, 30));
    expect(parse('call today 9am').dueAt, DateTime(2026, 9, 11, 9, 0));
  });

  test('midnight and noon do not wrap wrongly', () {
    expect(parse('x today 12am').dueAt, DateTime(2026, 9, 11, 0, 0));
    expect(parse('x today 12pm').dueAt, DateTime(2026, 9, 11, 12, 0));
  });

  test('a bare time already past today rolls to tomorrow', () {
    // now is 09:00; 8am has gone.
    expect(parse('standup 8am').dueAt, DateTime(2026, 9, 12, 8, 0));
    // 5pm has not.
    expect(parse('standup 5pm').dueAt, DateTime(2026, 9, 11, 17, 0));
  });

  test('priority words and numbers', () {
    expect(parse('a !high').priority, 3);
    expect(parse('a !med').priority, 2);
    expect(parse('a !low').priority, 1);
    expect(parse('a !2').priority, 2);
  });

  test('unknown priority words are left in the title', () {
    final r = parse('deploy !yesterday');
    expect(r.priority, 0);
    expect(r.title, 'deploy !yesterday');
  });

  test('multiple labels', () {
    final r = parse('read paper #uni #ml');
    expect(r.labels, ['uni', 'ml']);
    expect(r.title, 'read paper');
  });

  test('estimates in minutes and hours', () {
    expect(parse('a ~30m').estimateMin, 30);
    expect(parse('a ~90min').estimateMin, 90);
    expect(parse('a ~2h').estimateMin, 120);
    expect(parse('a ~1hr').estimateMin, 60);
  });

  test('spans cover what was consumed, in order, so chips can be shown', () {
    final r = parse('submit lab tmrw 5pm !high #uni');

    expect(r.spans.map((s) => s.kind), [
      ParseKind.due,
      ParseKind.due,
      ParseKind.priority,
      ParseKind.label,
    ]);
    for (final s in r.spans) {
      expect(s.start, lessThan(s.end));
      expect(s.end, lessThanOrEqualTo('submit lab tmrw 5pm !high #uni'.length));
    }
    expect(r.spans.map((s) => s.label), ['Tomorrow', '17:00', 'high', 'uni']);
  });

  test('a hash inside a word is not a label', () {
    expect(parse('issue C#12 fix').labels, isEmpty);
  });
}
