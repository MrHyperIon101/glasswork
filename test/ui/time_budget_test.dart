import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/repository/capacity_repository.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/state/undo_controller.dart';
import 'package:glasswork/sync/sync_writer.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/screens/capacity_screen.dart';
import 'package:glasswork/ui/widgets/block_dialog.dart';
import 'package:glasswork/ui/widgets/field_controls.dart';

/// Adding and changing timetable blocks, from the Time budget screen.
///
/// A block could once be saved where it could never count — at midnight, while asleep, on
/// top of a class — and then appeared nowhere. These check that the dialog says what is in
/// the way, offers a time that is free, and saves only what it showed.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer app;

  Future<List<Commitment>> blocks() => app
      .read(appScopeProvider)
      .value!
      .capacity
      .watchCommitments(app.read(appScopeProvider).value!.workspace.id)
      .first;

  /// The app on the Time budget screen, with a DBMS lecture on Mon, Wed and Fri 09:00–10:30.
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

    final scope = app.read(appScopeProvider).value!;
    await tester.runAsync(
      () => scope.capacity.addCommitment(
        workspaceId: scope.workspace.id,
        scheduleId: app.read(editingScheduleIdProvider)!,
        title: 'DBMS lecture',
        weekdays: {1, 3, 5},
        startMin: 9 * 60,
        durationMin: 90,
      ),
    );
    app.read(destinationProvider.notifier).go(const CapacityDestination());
    await _settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(BlockDialog), matching: finder);

  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );

  bool canSave(WidgetTester tester, String label) =>
      tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, label)).enabled;

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find
          .descendant(
            of: find.byType(CapacityScreen),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical,
            ),
          )
          .first,
    );
    await _settle(tester);
  }

  testWidgets('a block on top of a class offers the nearest free time, and saves there', (
    tester,
  ) async {
    await start(tester);
    try {
      await scrollTo(tester, find.text('Add block'));
      await tester.tap(find.text('Add block'));
      await _settle(tester);

      await tester.enterText(inDialog(find.byType(TextField)).first, 'Tutorial');
      await tester.tap(inDialog(find.text('M')));
      await tester.enterText(field('block-start'), '9:30');
      await _settle(tester);

      expect(find.textContaining('Overlaps DBMS lecture'), findsOneWidget);
      expect(canSave(tester, 'Add'), isFalse);

      await tester.tap(find.text('Move to 10:30'));
      await _settle(tester);
      expect(find.textContaining('Overlaps'), findsNothing);
      expect(canSave(tester, 'Add'), isTrue);

      await tester.tap(find.widgetWithText(PrimaryButton, 'Add'));
      await _settle(tester);

      final tutorial = (await tester.runAsync(blocks))!.singleWhere(
        (c) => c.title == 'Tutorial',
      );
      expect(
        (tutorial.startMin, tutorial.durationMin, tutorial.rrule),
        (10 * 60 + 30, 60, 'FREQ=WEEKLY;BYDAY=MO'),
      );
    } finally {
      await finish(tester);
    }
  });

  testWidgets('a block while asleep is refused until it is moved to when you wake', (
    tester,
  ) async {
    await start(tester);
    try {
      await scrollTo(tester, find.text('Add block'));
      await tester.tap(find.text('Add block'));
      await _settle(tester);

      await tester.enterText(inDialog(find.byType(TextField)).first, 'Night study');
      await tester.tap(inDialog(find.text('Every day')));
      await tester.enterText(field('block-start'), 'midnight');
      await _settle(tester);

      expect(find.textContaining('Falls while you sleep'), findsOneWidget);
      expect(canSave(tester, 'Add'), isFalse);

      await tester.tap(find.text('Move to 07:00'));
      await _settle(tester);
      // The move replaces what was typed, and leaving the field must not bring it back.
      FocusManager.instance.primaryFocus?.unfocus();
      await _settle(tester);
      expect(find.textContaining('Falls while you sleep'), findsNothing);
      expect(canSave(tester, 'Add'), isTrue);
    } finally {
      await finish(tester);
    }
  });

  testWidgets('editing a block writes only what changed', (tester) async {
    await start(tester);
    try {
      // By its days and times: its name is also on the week's timelines.
      final row = find.text('Mon Wed Fri · 09:00–10:30');
      await scrollTo(tester, row);
      await tester.runAsync(() => db.delete(db.outbox).go());
      await tester.tap(row);
      await _settle(tester);

      expect(find.text('Edit block'), findsOneWidget);
      await tester.enterText(field('block-end'), '11:00');
      await _settle(tester);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Save'));
      await _settle(tester);

      final lecture = (await tester.runAsync(blocks))!.single;
      expect((lecture.startMin, lecture.durationMin), (9 * 60, 120));
      final queued = (await tester.runAsync(() => db.select(db.outbox).get()))!;
      expect(
        SyncWriter.decodeFieldNames(queued.single.changedFields),
        {'duration_min'},
      );
    } finally {
      await finish(tester);
    }
  });

  Future<CapacityProfile> profile(WidgetTester tester) async {
    final scope = app.read(appScopeProvider).value!;
    final row = await tester.runAsync(
      () => scope.capacity.watchProfile(scope.workspace.id).first,
    );
    return row!;
  }

  testWidgets('a bedtime typed for one day changes that day, and only it syncs', (
    tester,
  ) async {
    await start(tester);
    try {
      await scrollTo(tester, find.byKey(const ValueKey('bedtime-Fri')));
      await tester.runAsync(() => db.delete(db.outbox).go());

      await tester.enterText(field('bedtime-Fri'), '1:30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);

      final sleep = CapacityMapping.sleepOf(await profile(tester));
      expect(
        sleep[DateTime.friday - 1],
        const DaySleep(wakeMin: 7 * 60, bedtimeMin: 90),
      );
      expect(sleep[DateTime.thursday - 1], CapacitySettings.standardWeek[3]);
      final queued = (await tester.runAsync(() => db.select(db.outbox).get()))!;
      expect(
        SyncWriter.decodeFieldNames(queued.single.changedFields),
        {'bedtime_fri_min'},
      );

      // Friday's night now starts after midnight, and is short: the row says how short.
      expect(find.text('5h 30m'), findsOneWidget);
      expect(find.text('Only 5h 30m of sleep before Sat'), findsOneWidget);
    } finally {
      await finish(tester);
    }
  });

  testWidgets('getting up, typed in a night, sets the morning after it', (tester) async {
    await start(tester);
    try {
      // Monday night's "Up at" is when Tuesday starts.
      await scrollTo(tester, find.byKey(const ValueKey('wake-Tue')));
      await tester.runAsync(() => db.delete(db.outbox).go());

      await tester.enterText(field('wake-Tue'), '8:15');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);

      final sleep = CapacityMapping.sleepOf(await profile(tester));
      expect(
        sleep[DateTime.tuesday - 1],
        const DaySleep(wakeMin: 8 * 60 + 15, bedtimeMin: 23 * 60 + 30),
      );
      expect(sleep[DateTime.monday - 1], CapacitySettings.standardWeek[0]);
      final queued = (await tester.runAsync(() => db.select(db.outbox).get()))!;
      expect(
        SyncWriter.decodeFieldNames(queued.single.changedFields),
        {'wake_tue_min'},
      );
      expect(find.text('8h 45m'), findsOneWidget);
    } finally {
      await finish(tester);
    }
  });

  testWidgets('sleep set for several nights sets their bedtimes and the mornings after', (
    tester,
  ) async {
    await start(tester);
    try {
      await scrollTo(tester, find.text('Set several nights'));
      await tester.tap(find.text('Set several nights'));
      await _settle(tester);

      final dialog = find.byType(Dialog);
      Finder time(int index) =>
          find.descendant(of: dialog, matching: find.byType(TextField)).at(index);

      await tester.tap(find.descendant(of: dialog, matching: find.text('Before weekends')));
      await tester.enterText(time(0), '1:00');
      await tester.enterText(time(1), '9:30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(find.text('8h 30m of sleep.'), findsOneWidget);

      await tester.tap(find.widgetWithText(PrimaryButton, 'Set'));
      await _settle(tester);

      // Friday and Saturday nights: to bed at one, up at half past nine the next day.
      final sleep = CapacityMapping.sleepOf(await profile(tester));
      expect(sleep[DateTime.friday - 1], const DaySleep(wakeMin: 7 * 60, bedtimeMin: 60));
      expect(
        sleep[DateTime.saturday - 1],
        const DaySleep(wakeMin: 9 * 60 + 30, bedtimeMin: 60),
      );
      expect(
        sleep[DateTime.sunday - 1],
        const DaySleep(wakeMin: 9 * 60 + 30, bedtimeMin: 23 * 60 + 30),
      );
      expect(sleep[DateTime.thursday - 1], CapacitySettings.standardWeek[3]);
      expect(sleep[DateTime.monday - 1], CapacitySettings.standardWeek[0]);
    } finally {
      await finish(tester);
    }
  });

  testWidgets('deleting a block can be undone', (tester) async {
    await start(tester);
    try {
      await scrollTo(tester, find.byTooltip('Delete block'));
      await tester.tap(find.byTooltip('Delete block'));
      await _settle(tester);
      expect(await tester.runAsync(blocks), isEmpty);

      await tester.runAsync(() => app.read(undoProvider.notifier).undo());
      await _settle(tester);
      expect((await tester.runAsync(blocks))!.single.title, 'DBMS lecture');
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
