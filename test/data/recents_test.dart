import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/recents.dart';

final t0 = DateTime.utc(2026, 11, 18, 12);

void main() {
  test('newest first, each thing once', () {
    var list = <Recent>[];
    list = Recents.record(list, Recent(RecentKind.task, 'a', t0));
    list = Recents.record(list, Recent(RecentKind.note, 'n', t0.add(const Duration(minutes: 1))));
    list = Recents.record(list, Recent(RecentKind.task, 'a', t0.add(const Duration(minutes: 2))));
    expect([for (final r in list) r.id], ['a', 'n']);
    expect(list.first.at, t0.add(const Duration(minutes: 2)));
  });

  test('a task and a project may share an id without being the same thing', () {
    var list = Recents.record(const [], Recent(RecentKind.task, 'x', t0));
    list = Recents.record(list, Recent(RecentKind.project, 'x', t0));
    expect(list, hasLength(2));
  });

  test('keeps only the most recent few', () {
    var list = <Recent>[];
    for (var i = 0; i < Recents.keep + 5; i++) {
      list = Recents.record(list, Recent(RecentKind.task, '$i', t0.add(Duration(minutes: i))));
    }
    expect(list, hasLength(Recents.keep));
    expect(list.first.id, '${Recents.keep + 4}');
  });

  test('something deleted leaves Recents', () {
    final list = Recents.record(const [], Recent(RecentKind.note, 'gone', t0));
    expect(Recents.without(list, RecentKind.note, 'gone'), isEmpty);
  });

  test('round-trips, and a damaged row reads as what it can', () {
    final list = [Recent(RecentKind.project, 'p', t0), Recent(RecentKind.task, 't', t0)];
    expect(Recents.parse(Recents.format(list)), list);
    expect(Recents.parse('not json'), isEmpty);
    expect(
      Recents.parse('[{"k":"task","id":"ok","at":"2026-11-18T12:00:00Z"},{"k":"planet","id":1}]'),
      [Recent(RecentKind.task, 'ok', t0)],
    );
  });
}
