import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/widgets/field_controls.dart';
import 'package:glasswork/ui/widgets/task_composer.dart';
import 'package:glasswork/ui/widgets/task_time.dart';

/// A task given a time, which is what puts it on the time budget.
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

  Future<Task> stored(WidgetTester tester, String id) async => (await tester.runAsync(
    () => (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle(),
  ))!;

  Finder inDialog(Finder finder) => find.descendant(of: find.byType(TaskTimeDialog), matching: finder);

  final tomorrow = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }();

  testWidgets('a time chosen for a task goes on its day, and counts in its figures', (tester) async {
    await start(tester);
    try {
      final scope = app.read(appScopeProvider).value!;
      final list = (await tester.runAsync(() => db.select(db.lists).get()))!.first;
      final task = (await tester.runAsync(
        () => scope.tasks.create(listId: list.id, workspaceId: list.workspaceId, title: 'Revise DBMS'),
      ))!;
      await _settle(tester);

      app.read(openTaskProvider.notifier).open(task.id);
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('task-time')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('task-time')));
      await _settle(tester);

      await tester.tap(inDialog(find.byKey(const ValueKey('time-day-1'))));
      await _settle(tester);
      await tester.enterText(
        inDialog(find.descendant(of: find.byKey(const ValueKey('time-start')), matching: find.byType(TextField))),
        '16:00',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      await tester.enterText(
        inDialog(find.descendant(of: find.byKey(const ValueKey('time-length')), matching: find.byType(TextField))),
        '2h',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      await tester.tap(inDialog(find.widgetWithText(PrimaryButton, 'Set')));
      await _settle(tester);

      final row = await stored(tester, task.id);
      expect(row.startAt!.toLocal(), DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16));
      expect(row.estimateMin, 120);

      // Counted on its day, and drawn there.
      expect(app.read(scheduleProvider).allocatedOn(tomorrow), 120);
      expect(
        app.read(taskSlotsProvider(tomorrow)).map((s) => (s.title, s.startMin, s.endMin)),
        [('Revise DBMS', 16 * 60, 18 * 60)],
      );

      // And taken away again.
      await tester.tap(find.widgetWithText(ComposerChip, 'Remove'));
      await _settle(tester);
      expect((await stored(tester, task.id)).startAt, isNull);
      expect(app.read(scheduleProvider).allocatedOn(tomorrow), 0);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('"plan" typed in a new task gives it its time', (tester) async {
    await start(tester);
    try {
      app.read(composerOpenProvider.notifier).open();
      await _settle(tester);
      await tester.enterText(
        find.descendant(of: find.byType(TaskComposer), matching: find.byType(TextField)).first,
        'Lab report plan tomorrow 9am ~90m',
      );
      await _settle(tester);
      // The time is shown before the task exists, so a wrong reading is caught here.
      expect(find.textContaining('Tomorrow 09:00–10:30'), findsWidgets);

      await tester.tap(find.widgetWithText(PrimaryButton, 'Add task'));
      await _settle(tester);

      final task = (await tester.runAsync(() => db.select(db.tasks).get()))!
          .singleWhere((t) => t.title == 'Lab report');
      expect(task.startAt!.toLocal(), DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9));
      expect(task.estimateMin, 90);
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
