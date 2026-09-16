import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/ui/block_style.dart';

void main() {
  test('a block keeps its colour however its title is typed', () {
    expect(BlockStyle.colourOf('DBMS lecture'), BlockStyle.colourOf('  dbms LECTURE '));
    expect(BlockStyle.palette, contains(BlockStyle.colourOf('Lab 6')));
  });

  test('different blocks mostly get different colours', () {
    final titles = ['DBMS lecture', 'Operating systems', 'Lab 6', 'Gym', 'Commute', 'Tutorial'];
    expect({for (final t in titles) BlockStyle.colourOf(t)}.length, greaterThanOrEqualTo(4));
  });

  test('together, blocks get different colours, the same whatever order they come in', () {
    final titles = ['DBMS lecture', 'Computer networks', 'Operating systems lab', 'Gym', 'Commute'];
    final assigned = BlockStyle.assign(titles);

    expect(assigned.values.toSet(), hasLength(titles.length));
    expect(BlockStyle.assign(titles.reversed), assigned);
    expect(BlockStyle.colourIn(assigned, ' dbms LECTURE'), assigned['dbms lecture']);
    expect(
      BlockStyle.colourIn(assigned, 'Not in any timetable'),
      BlockStyle.colourOf('Not in any timetable'),
    );
  });

  test('once there are more blocks than colours, some share', () {
    final many = [for (var i = 0; i < BlockStyle.palette.length + 3; i++) 'Block $i'];
    expect(BlockStyle.assign(many).values.toSet(), hasLength(BlockStyle.palette.length));
  });

  test('a short name: an acronym it starts with, or the first letters of its words', () {
    expect(BlockStyle.abbreviate('DBMS lecture'), 'DBMS');
    expect(BlockStyle.abbreviate('Operating systems lab'), 'OSL');
    expect(BlockStyle.abbreviate('Lab 6: triggers'), 'L6T');
    expect(BlockStyle.abbreviate('Lab 6'), 'L6');
    expect(BlockStyle.abbreviate('Gym'), 'Gym');
    expect(BlockStyle.abbreviate('Commute'), 'Com');
    expect(BlockStyle.abbreviate('Theory of computation'), 'TC');
    expect(BlockStyle.abbreviate('   '), '·');
  });
}
