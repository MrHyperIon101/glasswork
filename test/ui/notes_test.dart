import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/state/undo_controller.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/widgets/note_widgets.dart';

/// Quick notes: jotted down, written in, pinned, and deleted with a way back.
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

  Future<List<Note>> stored(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.notes).get()))!;

  testWidgets('a note jotted down is kept on Return, and the field clears for the next', (
    tester,
  ) async {
    await start(tester);
    try {
      app.read(destinationProvider.notifier).go(const NotesDestination());
      await _settle(tester);

      final field = find.descendant(
        of: find.byType(QuickNoteField),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Groceries\nmilk and eggs');
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);

      final notes = await stored(tester);
      expect([for (final n in notes) (n.title, n.bodyMd)], [('Groceries', 'milk and eggs')]);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.widgetWithText(NoteCard, 'Groceries'), findsOneWidget);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a new note has no row until something is written in it', (tester) async {
    await start(tester);
    try {
      app.read(openNoteProvider.notifier).create();
      await _settle(tester);
      await tester.tap(find.text('Done'));
      await _settle(tester);
      expect(await stored(tester), isEmpty, reason: 'opened and closed, nothing left behind');

      app.read(openNoteProvider.notifier).create();
      await _settle(tester);
      await tester.enterText(find.byKey(const ValueKey('note-title')), 'Ideas');
      await tester.enterText(find.byKey(const ValueKey('note-body')), 'A widget for the phone');
      await _settle(tester);

      final notes = await stored(tester);
      expect(notes, hasLength(1), reason: 'written in twice, created once');
      expect((notes.single.title, notes.single.bodyMd), ('Ideas', 'A widget for the phone'));
    } finally {
      await finish(tester);
    }
  });

  testWidgets('pinned from its sheet, and deleted with a way back', (tester) async {
    await start(tester);
    try {
      final scope = app.read(appScopeProvider).value!;
      final note = (await tester.runAsync(
        () => scope.notes.create(workspaceId: scope.workspace.id, title: 'Lecture notes'),
      ))!;
      await _settle(tester);

      app.read(openNoteProvider.notifier).edit(note);
      await _settle(tester);
      await tester.tap(find.byTooltip('Pin to the top'));
      await _settle(tester);
      expect((await stored(tester)).single.pinned, isTrue);

      await tester.tap(find.byTooltip('Delete note'));
      await _settle(tester);
      expect(app.read(openNoteProvider), isNull, reason: 'the sheet closes with it');
      expect((await stored(tester)).single.deletedAt, isNotNull);
      expect(app.read(undoProvider)?.label, 'Deleted "Lecture notes"');

      await tester.runAsync(() => app.read(undoProvider.notifier).undo());
      await _settle(tester);
      expect((await stored(tester)).single.deletedAt, isNull);
    } finally {
      await finish(tester);
    }
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
