import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/project_groups.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/state/undo_controller.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/widgets/area_widgets.dart';
import 'package:glasswork/ui/widgets/field_controls.dart';

/// Areas in the sidebar: made, filled, closed, and deleted with a way back.
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

  Future<Area> newArea(WidgetTester tester, String name) async {
    await tester.tap(find.text('New area'));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('area-name')), name);
    await _settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Create'));
    await _settle(tester);
    final areas = (await tester.runAsync(() => db.select(db.areas).get()))!;
    return areas.singleWhere((a) => a.name == name);
  }

  Future<Board> project(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.boards).get()))!.first;

  /// Whether [label] sits below [above] in the sidebar.
  bool listedBelow(WidgetTester tester, Finder label, Finder above) =>
      tester.getTopLeft(label).dy > tester.getTopLeft(above).dy;

  testWidgets('a new area, a project moved into it from its settings, then closed', (tester) async {
    await start(tester);
    try {
      final area = await newArea(tester, 'University');
      final personal = await project(tester);
      expect(find.widgetWithText(AreaHeader, 'University'), findsOneWidget);
      expect(find.text('Drag a project here'), findsOneWidget);

      app.read(projectSettingsOpenProvider.notifier).open(personal.id);
      await _settle(tester);
      await tester.tap(find.byKey(ValueKey('project-area-${area.id}')));
      await _settle(tester);
      app.read(projectSettingsOpenProvider.notifier).close();
      await _settle(tester);

      expect((await project(tester)).areaId, area.id);
      final row = find.byKey(ValueKey('sidebar-project-${personal.id}'));
      expect(listedBelow(tester, row, find.widgetWithText(AreaHeader, 'University')), isTrue);

      // Closed, its projects are hidden, and it stays closed on this device.
      await tester.tap(find.widgetWithText(AreaHeader, 'University'));
      await _settle(tester);
      expect(row, findsNothing);
      final stored = await tester.runAsync(
        () => (db.select(db.localSettings)..where((s) => s.key.equals(CollapsedAreas.key)))
            .getSingle(),
      );
      expect(CollapsedAreas.parse(stored!.value), {area.id});
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a project dragged onto an area moves into it, and back onto Projects', (tester) async {
    await start(tester);
    try {
      final area = await newArea(tester, 'Work');
      final personal = await project(tester);
      final row = find.byKey(ValueKey('sidebar-project-${personal.id}'));

      Future<void> drag(Finder to) async {
        final gesture = await tester.startGesture(tester.getCenter(row));
        await tester.pump();
        for (var step = 1; step <= 10; step++) {
          await gesture.moveTo(
            Offset.lerp(tester.getCenter(row), tester.getCenter(to), step / 10)!,
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await _settle(tester);
      }

      await drag(find.byKey(ValueKey('area-${area.id}')));
      expect((await project(tester)).areaId, area.id);

      await drag(find.text('Projects'));
      expect((await project(tester)).areaId, isNull);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('deleting an area keeps its projects, and can be undone', (tester) async {
    await start(tester);
    try {
      final area = await newArea(tester, 'University');
      final personal = await project(tester);
      await tester.runAsync(() => app.read(appScopeProvider).value!.areas.moveProject(personal.id, area.id));
      await _settle(tester);

      await tester.tap(find.byTooltip('Rename or delete University'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(GhostButton, 'Delete area'));
      await _settle(tester);

      expect(find.widgetWithText(AreaHeader, 'University'), findsNothing);
      final row = find.byKey(ValueKey('sidebar-project-${personal.id}'));
      expect(row, findsOneWidget, reason: 'listed with the projects in no area');

      await tester.runAsync(() => app.read(undoProvider.notifier).undo());
      await _settle(tester);
      expect(find.widgetWithText(AreaHeader, 'University'), findsOneWidget);
      expect(listedBelow(tester, row, find.widgetWithText(AreaHeader, 'University')), isTrue);
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
