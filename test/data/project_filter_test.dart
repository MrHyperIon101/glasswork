import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/project_filter.dart';

void main() {
  test('an empty filter round-trips', () {
    expect(ProjectFilter.decode(ProjectFilter.empty.encode()),
        ProjectFilter.empty);
  });

  test('a full filter round-trips', () {
    const filter = ProjectFilter(
      labelIds: {'a', 'b'},
      priorities: {2, 3},
      hideCompleted: true,
      onlyAtRisk: true,
    );
    expect(ProjectFilter.decode(filter.encode()), filter);
  });

  test('only non-default values are written', () {
    // Keeps stored views readable, and means adding an option later does not
    // invalidate filters already saved.
    expect(ProjectFilter.empty.encode(), '{}');
    expect(
      const ProjectFilter(hideCompleted: true).encode(),
      '{"hideCompleted":true}',
    );
  });

  test('encoding is stable regardless of set order', () {
    const a = ProjectFilter(labelIds: {'x', 'y'}, priorities: {3, 1});
    const b = ProjectFilter(labelIds: {'y', 'x'}, priorities: {1, 3});
    expect(a.encode(), b.encode());
  });

  group('decoding is tolerant, because a filter is a preference not data', () {
    test('null and empty mean no filter', () {
      expect(ProjectFilter.decode(null), ProjectFilter.empty);
      expect(ProjectFilter.decode(''), ProjectFilter.empty);
      expect(ProjectFilter.decode('   '), ProjectFilter.empty);
    });

    test('malformed json shows everything rather than throwing', () {
      // Throwing would make a bad row unopenable; showing everything is the
      // failure you can actually see and correct.
      expect(ProjectFilter.decode('not json'), ProjectFilter.empty);
      expect(ProjectFilter.decode('[1,2,3]'), ProjectFilter.empty);
    });

    test('wrong types in the right keys are ignored', () {
      expect(
        ProjectFilter.decode('{"labels":"nope","priorities":5}'),
        ProjectFilter.empty,
      );
    });

    test('mixed-type lists keep only what fits', () {
      final f = ProjectFilter.decode('{"labels":["a",7,null,"b"]}');
      expect(f.labelIds, {'a', 'b'});
    });
  });

  test('activeCount counts every dimension', () {
    expect(ProjectFilter.empty.activeCount, 0);
    expect(
      const ProjectFilter(
        labelIds: {'a', 'b'},
        priorities: {3},
        hideCompleted: true,
      ).activeCount,
      4,
    );
  });

  test('pruning drops labels that no longer exist', () {
    // A deleted label leaving a filter behind would hide tasks with no visible
    // cause: its chip is gone from the bar, so there is nothing to un-tick.
    const filter = ProjectFilter(labelIds: {'kept', 'gone'});
    final pruned = filter.pruned({'kept', 'other'});

    expect(pruned.labelIds, {'kept'});
  });

  test('pruning returns the same instance when nothing changed', () {
    const filter = ProjectFilter(labelIds: {'a'});
    expect(filter.pruned({'a', 'b'}), same(filter));
  });
}
