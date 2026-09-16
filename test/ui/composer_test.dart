import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
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

/// Adding tasks: a reminder typed into the title or chosen in the picker, and a list added
/// all at once, one task a line.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  /// The app with New task open.
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
    ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    ).read(composerOpenProvider.notifier).open();
    await _settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  Future<List<Task>> tasks(WidgetTester tester) async => (await tester.runAsync(
    () => (db.select(db.tasks)
          ..orderBy([(t) => OrderingTerm(expression: t.orderKey)]))
        .get(),
  ))!;

  Finder title() => find
      .descendant(of: find.byType(TaskComposer), matching: find.byType(TextField))
      .first;

  Finder button(String label) => find.widgetWithText(PrimaryButton, label);

  DateTime tomorrowAt(int hour, [int minute = 0]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  testWidgets('a reminder typed into the title is set on the task', (tester) async {
    await start(tester);
    try {
      await tester.enterText(title(), 'Call the bank remind tomorrow 9am');
      await _settle(tester);
      expect(find.textContaining('Tomorrow at 09:00'), findsOneWidget);

      await tester.tap(button('Add task'));
      await _settle(tester);

      final task = (await tasks(tester)).singleWhere((t) => t.title == 'Call the bank');
      expect(task.remindAt?.toLocal(), tomorrowAt(9));
    } finally {
      await finish(tester);
    }
  });

  testWidgets('a time chosen in the picker is set on the task', (tester) async {
    await start(tester);
    try {
      await tester.enterText(title(), 'Stretch');
      final choose = find.byKey(const ValueKey('reminder-choose'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await _settle(tester);

      final dialog = find.byType(Dialog);
      await tester.tap(find.descendant(of: dialog, matching: find.text('Tomorrow')));
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('reminder-time')),
          matching: find.byType(TextField),
        ),
        '6.30pm',
      );
      await _settle(tester);
      expect(find.textContaining('Tomorrow at 18:30'), findsOneWidget);

      await tester.tap(button('Set reminder'));
      await _settle(tester);
      expect(
        find.textContaining('Tomorrow at 18:30'),
        findsOneWidget,
        reason: 'the composer says what is set',
      );

      await tester.tap(button('Add task'));
      await _settle(tester);

      final task = (await tasks(tester)).singleWhere((t) => t.title == 'Stretch');
      expect(task.remindAt?.toLocal(), tomorrowAt(18, 30));
    } finally {
      await finish(tester);
    }
  });

  testWidgets('a pasted list adds a task a line, each read for its own details', (
    tester,
  ) async {
    await start(tester);
    try {
      await tester.tap(find.text('Add several at once'));
      await _settle(tester);
      await tester.enterText(
        find.byKey(const ValueKey('composer-list')),
        '- Write the tests !high ~2h\n- Ship it remind tomorrow 9am\n\n- Tidy up #chores\n',
      );
      await _settle(tester);

      await tester.tap(button('Add 3 tasks'));
      await _settle(tester);

      final added = await tasks(tester);
      expect(
        [for (final t in added) t.title],
        containsAllInOrder(['Write the tests', 'Ship it', 'Tidy up']),
      );
      final tests = added.singleWhere((t) => t.title == 'Write the tests');
      expect((tests.priority, tests.estimateMin), (3, 120));
      expect(
        added.singleWhere((t) => t.title == 'Ship it').remindAt?.toLocal(),
        tomorrowAt(9),
      );
      final labels = (await tester.runAsync(() => db.select(db.labels).get()))!;
      expect([for (final l in labels) l.name], contains('chores'));
    } finally {
      await finish(tester);
    }
  });
}

/// Lets queries, streams and animations finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Held extends SyncController {
  _Held(this._state);

  final SyncState _state;

  @override
  SyncState build() => _state;
}
