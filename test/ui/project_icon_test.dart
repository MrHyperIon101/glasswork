import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/ui/project_icon.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/widgets/field_controls.dart';

/// A project's icon: one of the symbols, or an emoji or letters of your own.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('an icon as it is kept', () {
    test('a symbol is stored by name, and read back', () {
      expect(ProjectIcon.symbol('school'), 'sym:school');
      expect(ProjectIcon.symbolOf('sym:school'), Icons.school_rounded);
    });

    test('typed text, no icon, and a symbol this version lacks are not symbols', () {
      expect(ProjectIcon.symbolOf('📚'), isNull);
      expect(ProjectIcon.symbolOf(null), isNull);
      expect(ProjectIcon.symbolOf('sym:from_a_newer_version'), isNull);
    });

    test('typed text keeps two characters as a person counts them, without spaces', () {
      expect(ProjectIcon.typed('  📚 '), '📚');
      expect(ProjectIcon.typed('db project'), 'db');
      // A family emoji is several code points joined, and a flag is two: each is one.
      expect(ProjectIcon.typed('👩‍💻x'), '👩‍💻x');
      expect(ProjectIcon.typed('🇮🇳🇯🇵🇺🇸'), '🇮🇳🇯🇵');
      expect(ProjectIcon.typed('   '), isNull);
    });
  });

  group('choosing one', () {
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

    Future<String?> iconOf(WidgetTester tester, String projectId) async {
      final row = await tester.runAsync(
        () => (db.select(db.boards)..where((b) => b.id.equals(projectId))).getSingle(),
      );
      return row!.icon;
    }

    testWidgets('a symbol, then an emoji typed in, each saved to the project', (tester) async {
      await start(tester);
      try {
        final project = (await tester.runAsync(() => db.select(db.boards).get()))!.first;
        app.read(projectSettingsOpenProvider.notifier).open(project.id);
        await _settle(tester);

        await tester.tap(find.byKey(const ValueKey('project-icon')));
        await _settle(tester);
        await tester.ensureVisible(find.byKey(const ValueKey('icon-sym:school')));
        await tester.tap(find.byKey(const ValueKey('icon-sym:school')));
        await _settle(tester);
        expect(await iconOf(tester, project.id), 'sym:school');
        // The sidebar shows the symbol itself.
        expect(
          find.descendant(of: find.byType(AppShell), matching: find.byIcon(Icons.school_rounded)),
          findsWidgets,
        );

        await tester.tap(find.byKey(const ValueKey('project-icon')));
        await _settle(tester);
        await tester.enterText(find.byKey(const ValueKey('icon-typed')), ' 🎓 ');
        await _settle(tester);
        await tester.tap(find.widgetWithText(PrimaryButton, 'Use'));
        await _settle(tester);
        expect(await iconOf(tester, project.id), '🎓');
      } finally {
        await finish(tester);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('closing the picker keeps the icon there was', (tester) async {
      await start(tester);
      try {
        final project = (await tester.runAsync(() => db.select(db.boards).get()))!.first;
        final before = project.icon;
        app.read(projectSettingsOpenProvider.notifier).open(project.id);
        await _settle(tester);

        await tester.tap(find.byKey(const ValueKey('project-icon')));
        await _settle(tester);
        await tester.tap(find.widgetWithText(GhostButton, 'Cancel'));
        await _settle(tester);
        expect(await iconOf(tester, project.id), before);
      } finally {
        await finish(tester);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  });
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
