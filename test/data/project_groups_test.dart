import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/project_groups.dart';

final _now = DateTime(2026, 9, 18);

Board project(String id, {String? area}) => Board(
  id: id,
  createdAt: _now,
  updatedAt: _now,
  fieldVersions: '{}',
  workspaceId: 'ws',
  name: id,
  archived: false,
  viewDefault: BoardView.board,
  orderKey: 'a0',
  areaId: area,
);

Area area(String id) => Area(
  id: id,
  createdAt: _now,
  updatedAt: _now,
  fieldVersions: '{}',
  workspaceId: 'ws',
  name: id,
  orderKey: 'a0',
);

void main() {
  // Each group as its area and its projects' ids joined, since lists inside records only
  // compare equal to themselves.
  List<(String?, String)> shape(List<ProjectGroup> groups) => [
    for (final g in groups) (g.area?.id, g.projects.map((p) => p.id).join(' ')),
  ];

  test('projects in no area come first, then each area with its own, in order', () {
    final groups = ProjectGroups.of(
      [project('personal'), project('dbms', area: 'uni'), project('site', area: 'work'), project('os', area: 'uni')],
      [area('uni'), area('work'), area('empty')],
    );
    expect(shape(groups), [
      (null, 'personal'),
      ('uni', 'dbms os'),
      ('work', 'site'),
      ('empty', ''),
    ]);
  });

  test('a project whose area is gone lists with the projects in no area', () {
    final groups = ProjectGroups.of([project('dbms', area: 'deleted')], [area('uni')]);
    expect(shape(groups), [
      (null, 'dbms'),
      ('uni', ''),
    ]);
  });

  test('closed areas are kept as their ids, in any order, blanks ignored', () {
    expect(CollapsedAreas.parse(null), isEmpty);
    expect(CollapsedAreas.parse('b, a,,'), {'a', 'b'});
    expect(CollapsedAreas.format({'b', 'a'}), 'a,b');
    expect(CollapsedAreas.parse(CollapsedAreas.format({'x'})), {'x'});
  });
}
