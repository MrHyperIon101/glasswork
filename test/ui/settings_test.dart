import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/desktop/desktop_shell.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/reminders_controller.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/screens/settings_screen.dart';
import 'package:glasswork/ui/widgets/field_controls.dart';
import 'package:glasswork/ui/widgets/task_composer.dart';
import 'package:glasswork/ui/widgets/value_stepper.dart';

/// Settings changes what it says it changes: the reminder times the task sheets offer, how
/// long Snooze waits, and where a new task goes. And it can be reached, and left, the ways
/// it says.
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

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.text('Settings'));
    await _settle(tester);
  }

  /// Types into the stepper labelled [label], and leaves it, which is when it is taken in.
  Future<void> type(WidgetTester tester, String label, String text) async {
    final stepper = find.widgetWithText(ValueStepper, label);
    await tester.scrollUntilVisible(
      stepper,
      200,
      scrollable: _page(),
    );
    await tester.enterText(
      find.descendant(of: stepper, matching: find.byType(TextField)),
      text,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
  }

  testWidgets('opens from the sidebar, and back returns to where it was opened from', (
    tester,
  ) async {
    await start(tester);
    try {
      app.read(destinationProvider.notifier).go(const AllDestination());
      await _settle(tester);

      await openSettings(tester);
      expect(app.read(destinationProvider), isA<SettingsDestination>());
      expect(find.text('Mornings'), findsOneWidget);

      await _back(tester);
      expect(app.read(destinationProvider), isA<AllDestination>());
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a morning and an evening set here are the ones a new task offers', (
    tester,
  ) async {
    await start(tester);
    try {
      await openSettings(tester);
      await type(tester, 'Mornings', '8am');
      await type(tester, 'Evenings', '7.30pm');

      final preferences = (await tester.runAsync(
        () => app.read(appScopeProvider).value!.preferences.read(),
      ))!;
      expect((preferences.morningMin, preferences.eveningMin), (8 * 60, 19 * 60 + 30));
      expect(
        find.textContaining('so a morning reminder comes 1h after that'),
        findsOneWidget,
        reason: 'said against the 07:00 the time budget gets up at',
      );

      app.read(composerOpenProvider.notifier).open();
      await _settle(tester);
      final offered = find.descendant(
        of: find.byType(TaskComposer),
        matching: find.byType(ComposerChip),
      );
      final labels = [
        for (final chip in tester.widgetList<ComposerChip>(offered)) chip.label,
      ];
      expect(labels, contains('Tomorrow morning · 08:00'));
      if (TimeOfDay.now().hour * 60 + TimeOfDay.now().minute < 19 * 60 + 15) {
        expect(labels, contains('This evening · 19:30'));
      }
    } finally {
      await finish(tester);
    }
  });

  testWidgets('Snooze steps to the next length, and reminders wait that long', (tester) async {
    await start(tester);
    try {
      await openSettings(tester);
      final stepper = find.widgetWithText(ValueStepper, 'Snooze');
      await tester.scrollUntilVisible(
        stepper,
        200,
        scrollable: _page(),
      );
      await tester.tap(find.descendant(of: stepper, matching: find.byIcon(Icons.add_rounded)));
      await _settle(tester);

      expect(find.descendant(of: stepper, matching: find.text('15m')), findsOneWidget);
      expect(app.read(reminderServiceProvider).snooze, const Duration(minutes: 15));
    } finally {
      await finish(tester);
    }
  });

  testWidgets('a project chosen here is where a task added from Today goes', (tester) async {
    await start(tester);
    try {
      final scope = app.read(appScopeProvider).value!;
      final other = (await tester.runAsync(
        () => scope.projects.createProject(
          workspaceId: scope.workspace.id,
          name: 'Glasswork',
          sections: const ['Backlog', 'Shipped'],
        ),
      ))!;
      await _settle(tester);

      await openSettings(tester);
      final chip = find.widgetWithText(ComposerChip, 'Glasswork');
      await tester.scrollUntilVisible(chip, 200, scrollable: _page());
      // Built is not yet on screen: brought fully into view, so the tap lands on it.
      await tester.ensureVisible(chip);
      await _settle(tester);
      await tester.tap(chip);
      await _settle(tester);
      expect(
        find.text(
          'Tasks you add from Today, Next 7 days or All open work go to Glasswork, in Backlog.',
        ),
        findsOneWidget,
      );

      app.read(destinationProvider.notifier).go(const TodayDestination());
      app.read(composerOpenProvider.notifier).open();
      await _settle(tester);
      await tester.enterText(
        find
            .descendant(of: find.byType(TaskComposer), matching: find.byType(TextField))
            .first,
        'Write the release notes',
      );
      await _settle(tester);
      expect(
        tester
            .widget<ComposerChip>(
              find.descendant(
                of: find.byType(TaskComposer),
                matching: find.widgetWithText(ComposerChip, 'Glasswork'),
              ),
            )
            .selected,
        isTrue,
        reason: 'the sheet shows where the task will go',
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'Add task'));
      await _settle(tester);

      final backlog = (await tester.runAsync(
        () => (db.select(db.lists)
              ..where((l) => l.boardId.equals(other.id))
              ..orderBy([(l) => OrderingTerm(expression: l.orderKey)]))
            .get(),
      ))!.first;
      final task = (await tester.runAsync(
        () => (db.select(db.tasks)..where((t) => t.title.equals('Write the release notes')))
            .getSingle(),
      ))!;
      expect(task.listId, backlog.id);
    } finally {
      await finish(tester);
    }
  });

  testWidgets('the shortcuts Settings lists do what it says', (tester) async {
    await start(tester);
    try {
      Future<void> press(LogicalKeyboardKey key, {bool control = false}) async {
        if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(key);
        if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await _settle(tester);
      }

      await press(LogicalKeyboardKey.comma, control: true);
      expect(app.read(destinationProvider), isA<SettingsDestination>());
      await tester.scrollUntilVisible(find.text('Keyboard'), 200, scrollable: _page());
      expect(find.text('Ctrl+,'), findsOneWidget, reason: 'listed on a desktop');

      await press(LogicalKeyboardKey.keyN, control: true);
      expect(app.read(composerOpenProvider), isTrue);
      await press(LogicalKeyboardKey.escape);
      expect(app.read(composerOpenProvider), isFalse);

      final scope = app.read(appScopeProvider).value!;
      final list = (await tester.runAsync(() => db.select(db.lists).get()))!.first;
      final task = (await tester.runAsync(
        () => scope.tasks.create(
          listId: list.id,
          workspaceId: scope.workspace.id,
          title: 'Read chapter 8',
        ),
      ))!;
      app.read(openTaskProvider.notifier).open(task.id);
      await _settle(tester);
      await press(LogicalKeyboardKey.escape);
      expect(app.read(openTaskProvider), isNull, reason: 'Esc closes the task sheet too');

      await press(LogicalKeyboardKey.keyN, control: true);
      expect(
        app.read(composerOpenProvider),
        isTrue,
        reason: 'a closed sheet hands the keys back to the app behind it',
      );
      await press(LogicalKeyboardKey.escape);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester);
      expect(app.read(openNoteProvider), isNotNull, reason: 'Ctrl+Shift+N, a new note');
      expect(app.read(composerOpenProvider), isFalse);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('keeping it in the tray turns the tray on, where there is one', (tester) async {
    const channel = MethodChannel(DesktopShell.name);
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add('${call.method}(${call.arguments})');
      return switch (call.method) {
        'trayAvailable' => true,
        'setKeepInTray' => call.arguments,
        _ => null,
      };
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );

    await start(tester);
    try {
      await openSettings(tester);
      final toggle = find.byKey(const ValueKey('keep-in-tray'));
      await tester.scrollUntilVisible(toggle, 200, scrollable: _page());
      await tester.ensureVisible(toggle);
      await _settle(tester);
      expect(find.textContaining('Off: closing the window quits Glasswork'), findsOneWidget);

      await tester.tap(toggle);
      await _settle(tester);

      expect(app.read(preferencesProvider).value?.keepInTray, isTrue);
      expect(calls, contains('setKeepInTray(true)'));
      expect(find.text('On: closing the window keeps Glasswork in the tray.'), findsOneWidget);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}

/// Settings' own list, rather than the scrollable inside the search field above it.
Finder _page() => find
    .descendant(
      of: find.byType(SettingsScreen),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
      ),
    )
    .first;

/// The system back gesture, delivered the way the Android embedding delivers it.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await _settle(tester);
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
