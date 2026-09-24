import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/completed.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';

final when = DateTime(2026, 9, 14);

BoardList section(String name, {bool isDoneColumn = false, String? id}) => BoardList(
  id: id ?? name.toLowerCase(),
  createdAt: when,
  updatedAt: when,
  fieldVersions: '{}',
  workspaceId: 'ws',
  boardId: 'b',
  name: name,
  orderKey: 'a0',
  isDoneColumn: isDoneColumn,
);

Task task(String id, {required String listId, bool done = false}) => Task(
  id: id,
  workspaceId: 'ws',
  listId: listId,
  title: id,
  orderKey: 'a0',
  status: done ? TaskStatus.done : TaskStatus.open,
  priority: 0,
  slipCount: 0,
  createdAt: when,
  updatedAt: when,
  fieldVersions: '{}',
  completedAt: done ? when : null,
);

void main() {
  group('which section holds finished work', () {
    test('the flagged one, whatever it is called', () {
      final sections = [
        section('To do'),
        section('Shipped', isDoneColumn: true),
        section('Done'),
      ];
      expect(CompletedSection.of(sections)?.name, 'Shipped');
    });

    test('by name where nothing is flagged, so an older board still files things', () {
      expect(
        CompletedSection.of([section('To do'), section('Done')])?.name,
        'Done',
      );
      expect(
        CompletedSection.of([section('Backlog'), section('  COMPLETED ')])?.name,
        '  COMPLETED ',
      );
    });

    test('none, where a project has no such section', () {
      expect(
        CompletedSection.of([section('To do'), section('In progress')]),
        isNull,
      );
      expect(CompletedSection.of(const []), isNull);
    });

    test('two flagged sections resolve the same way on every device', () {
      // Both devices flagged one offline; the merge keeps both flags.
      final sections = [
        section('Ready', isDoneColumn: true),
        section('Shipped', isDoneColumn: true),
      ];
      expect(CompletedSection.of(sections)?.name, 'Ready');
      expect(CompletedSection.of(sections)?.name, 'Ready');
    });
  });

  group('what each column shows', () {
    final tasks = [
      task('open-todo', listId: 'todo'),
      task('done-todo', listId: 'todo', done: true),
      task('open-done-section', listId: 'done'),
      task('done-elsewhere', listId: 'doing', done: true),
    ];

    test('a section shows the work still open in it', () {
      expect(
        [for (final t in CompletedSection.openIn(tasks, 'todo')) t.id],
        ['open-todo'],
      );
    });

    test('finished work is collected wherever it was filed', () {
      expect(
        [for (final t in CompletedSection.done(tasks)) t.id],
        ['done-todo', 'done-elsewhere'],
      );
    });

    test('a task left open in the completed section is still shown there', () {
      expect(
        [for (final t in CompletedSection.openIn(tasks, 'done')) t.id],
        ['open-done-section'],
      );
    });
  });
}
