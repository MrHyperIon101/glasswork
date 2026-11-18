import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/recents.dart';
import 'package:glasswork/search/spotlight_index.dart';

final now = DateTime(2026, 11, 18, 20);

SpotlightItem task(String id, String title, {bool done = false, String subtitle = ''}) =>
    SpotlightItem(kind: SpotlightKind.task, id: id, title: title, done: done, subtitle: subtitle);

List<String> titles(List<SpotlightHit> hits) => [for (final h in hits) h.item.title];

void main() {
  test('nothing typed finds nothing — Recents answer an empty query instead', () {
    expect(SpotlightIndex.search('  ', [task('a', 'Lab')], now: now), isEmpty);
  });

  test('the whole title, then its start, then a word in it, then anywhere in it', () {
    final items = [
      task('1', 'Collaborate on slides'),   // "lab" inside a word
      task('2', 'DBMS lab report'),         // a word starts with it
      task('3', 'Lab report'),              // the title starts with it
      task('4', 'Lab'),                     // the whole title
    ];
    expect(titles(SpotlightIndex.search('lab', items, now: now)), [
      'Lab',
      'Lab report',
      'DBMS lab report',
      'Collaborate on slides',
    ]);
  });

  test('every word of the query starting a word, in any order', () {
    final hits = SpotlightIndex.search('rep dbms', [task('1', 'DBMS lab report')], now: now);
    expect(titles(hits), ['DBMS lab report']);
  });

  test('its letters in order find it, below anything that matches outright', () {
    final items = [task('1', 'DBMS report'), task('2', 'dbrp notes')];
    expect(titles(SpotlightIndex.search('dbrp', items, now: now)), ['dbrp notes', 'DBMS report']);
    expect(SpotlightIndex.search('zq', items, now: now), isEmpty);
  });

  test('an action answers to its other words', () {
    const budget = SpotlightItem(
      kind: SpotlightKind.action,
      id: 'time-budget',
      title: 'Time budget',
      keywords: ['timetable', 'sleep'],
    );
    expect(titles(SpotlightIndex.search('timetable', [budget], now: now)), ['Time budget']);
  });

  test('finished work is still found, below what is still to do', () {
    final items = [task('1', 'Lab one', done: true), task('2', 'Lab two')];
    expect(titles(SpotlightIndex.search('lab', items, now: now)), ['Lab two', 'Lab one']);
  });

  test('what was opened lately is nudged up among equals', () {
    final items = [task('a', 'Lab alpha'), task('b', 'Lab bravo')];
    final recents = [Recent(RecentKind.task, 'b', now.subtract(const Duration(minutes: 5)))];
    expect(
      titles(SpotlightIndex.search('lab', items, recents: recents, now: now)),
      ['Lab bravo', 'Lab alpha'],
    );
  });

  test('but never past a better kind of match', () {
    final items = [task('exact', 'Lab'), task('recent', 'Collaborate')];
    final recents = [Recent(RecentKind.task, 'recent', now)];
    expect(
      titles(SpotlightIndex.search('lab', items, recents: recents, now: now)).first,
      'Lab',
    );
  });

  test('the same query gives the same order whatever order things came in', () {
    final items = [task('b', 'Lab'), task('a', 'Lab')];
    final forwards = SpotlightIndex.search('lab', items, now: now);
    final backwards = SpotlightIndex.search('lab', items.reversed.toList(), now: now);
    expect([for (final h in forwards) h.item.id], [for (final h in backwards) h.item.id]);
  });

  test('a result is named kind and id together', () {
    expect(task('x1', 'Lab').key, 'task:x1');
  });
}
