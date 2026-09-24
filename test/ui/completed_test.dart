import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/ui/motion.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/widgets/completed_group.dart';
import 'package:glasswork/ui/widgets/task_row.dart';

/// Finishing something: where it goes, how it comes back, and what it says while it
/// still can be taken back.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer app;

  Future<void> start(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) => db),
          syncProvider.overrideWith(() => _Held(const SyncSignedOut())),
        ],
        child: const GlassworkApp(),
      ),
    );
    await _settle(tester);
    app = ProviderScope.containerOf(tester.element(find.byType(AppShell)));
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  /// The project's sections, in the order the board draws them.
  Future<List<BoardList>> sections(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.lists).get()))!;

  Future<Task> add(WidgetTester tester, String title, BoardList section) async =>
      (await tester.runAsync(
        () => app.read(appScopeProvider).value!.tasks.create(
          listId: section.id,
          workspaceId: section.workspaceId,
          title: title,
        ),
      ))!;

  Future<void> openProjectAsList(WidgetTester tester) async {
    final board = (await tester.runAsync(() => db.select(db.boards).get()))!.single;
    app.read(destinationProvider.notifier).go(ProjectDestination(board.id));
    app.read(projectViewModeProvider.notifier).set(board.id, BoardView.list);
    await _settle(tester);
  }

  Finder tick(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(TaskRow)),
    matching: find.byType(AnimatedCheck),
  );

  testWidgets('a completed task is filed under Completed, and comes back where it was', (
    tester,
  ) async {
    await start(tester);
    try {
      final todo = (await sections(tester)).first;
      await add(tester, 'Write the report', todo);
      await openProjectAsList(tester);

      expect(find.byType(CompletedHeader), findsNothing, reason: 'nothing done yet');
      expect(find.text('Nothing in to do'), findsNothing);

      await tester.tap(tick('Write the report'));
      await _settle(tester);

      // It left the section it was filed under — which now says it is empty — and is
      // drawn under the one heading for finished work.
      expect(find.byType(CompletedHeader), findsOneWidget);
      expect(find.text('Nothing in to do'), findsOneWidget);
      expect(find.text('Write the report'), findsOneWidget);
      final stored = (await tester.runAsync(() => db.select(db.tasks).get()))!.single;
      expect(stored.status, TaskStatus.done);
      expect(stored.listId, todo.id, reason: 'the row itself did not move');

      // Ticking is undoable, like every other way of making work disappear.
      expect(find.textContaining('Completed "Write the report"'), findsOneWidget);

      await tester.tap(tick('Write the report'));
      await _settle(tester);

      expect(find.byType(CompletedHeader), findsNothing);
      expect(find.text('Nothing in to do'), findsNothing);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('the completed heading counts what it holds, and folds away', (tester) async {
    await start(tester);
    try {
      final all = await sections(tester);
      final todo = all.first;
      final doing = all[1];
      // Finished work from two different sections, and one thing still to do.
      final first = await add(tester, 'Read the brief', todo);
      final second = await add(tester, 'Draft it', doing);
      await add(tester, 'Send it', todo);
      final tasks = app.read(appScopeProvider).value!.tasks;
      await tester.runAsync(() => tasks.setDone(first.id, done: true));
      await tester.runAsync(() => tasks.setDone(second.id, done: true));
      await openProjectAsList(tester);

      expect(find.byType(CompletedHeader), findsOneWidget);
      expect(find.text('2'), findsWidgets, reason: 'the heading says how much is in it');
      expect(find.text('Read the brief'), findsOneWidget);

      await tester.tap(find.byType(CompletedHeader));
      await _settle(tester);

      expect(find.text('Read the brief'), findsNothing, reason: 'folded away');
      expect(find.text('Draft it'), findsNothing);
      expect(find.byType(CompletedHeader), findsOneWidget);
      expect(find.text('Send it'), findsOneWidget, reason: 'open work is untouched');

      await tester.tap(find.byType(CompletedHeader));
      await _settle(tester);
      expect(find.text('Read the brief'), findsOneWidget);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a card dropped on Completed is ticked off, and dragged out is picked up again', (
    tester,
  ) async {
    await start(tester);
    try {
      final all = await sections(tester);
      final todo = all.first;
      await add(tester, 'Write the report', todo);
      final board = (await tester.runAsync(() => db.select(db.boards).get()))!.single;
      app.read(destinationProvider.notifier).go(ProjectDestination(board.id));
      app.read(projectViewModeProvider.notifier).set(board.id, BoardView.board);
      await _settle(tester);

      Future<void> dragTo(Finder card, Finder onto) async {
        final gesture = await tester.startGesture(tester.getCenter(card));
        await tester.pump(const Duration(milliseconds: 60));
        await gesture.moveTo(tester.getCenter(onto));
        await tester.pump(const Duration(milliseconds: 60));
        await gesture.up();
        await _settle(tester);
      }

      await dragTo(find.text('Write the report'), find.byType(CompletedHeader));

      var stored = (await tester.runAsync(() => db.select(db.tasks).get()))!.single;
      expect(stored.status, TaskStatus.done, reason: 'dropping it there finished it');
      expect(stored.listId, todo.id, reason: 'and moved nothing');
      expect(find.textContaining('Completed "Write the report"'), findsOneWidget);

      // Back out of it: the column it came from is empty now, so it offers the drop.
      await dragTo(find.text('Write the report'), find.text('Drop here').first);

      stored = (await tester.runAsync(() => db.select(db.tasks).get()))!.single;
      expect(stored.status, TaskStatus.open, reason: 'dragged out, it is open again');
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a smart view lists the newest first, whichever section it came from', (
    tester,
  ) async {
    await start(tester);
    try {
      final all = await sections(tester);
      // Added oldest first. In the section itself that is the order they sit in; a smart
      // view is a collection, and shows what was added last at the top.
      for (final title in ['First', 'Second', 'Third']) {
        await add(tester, title, all.first);
      }
      await add(tester, 'Elsewhere', all[1]);
      app.read(destinationProvider.notifier).go(const AllDestination());
      await _settle(tester);

      final titles = [
        for (final row in tester.widgetList<TaskRow>(find.byType(TaskRow)))
          row.task.title,
      ];
      // All four were added in the same second, which is all `created_at` keeps, so the
      // order they were appended in settles it — reversed. Across sections there is
      // nothing to compare but the id, which is a tie nobody can see and every device
      // breaks the same way.
      expect(titles.where((t) => t != 'Elsewhere'), ['Third', 'Second', 'First']);
      expect(titles, contains('Elsewhere'));
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}

/// Lets queries, streams and animations finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Held extends SyncController {
  _Held(this._state);

  final SyncState _state;

  @override
  SyncState build() => _state;
}
