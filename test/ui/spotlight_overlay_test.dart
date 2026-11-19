import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/ui/spotlight/spotlight_overlay.dart';

/// The app's own Spotlight: what it finds, and adding the line typed as a task.
void main() {
  testWidgets('finds a task by its words, and adds the line typed as one', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final app = ProviderContainer(overrides: [databaseProvider.overrideWith((ref) => db)]);
    addTearDown(() async {
      app.dispose();
      await db.close();
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app,
      child: const MaterialApp(home: Scaffold(body: Stack(children: [SpotlightOverlay()]))),
    ));
    final scope = (await tester.runAsync(() => app.read(appScopeProvider.future)))!;
    final section = (await tester.runAsync(() => db.select(db.lists).get()))!.first;
    await tester.runAsync(() => scope.tasks.create(
      listId: section.id,
      workspaceId: scope.workspace.id,
      title: 'DBMS lab report',
    ));

    app.read(spotlightOpenProvider.notifier).open();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Spotlight Search'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dbms');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.text('DBMS lab report'), findsOneWidget);
    expect(find.text('Add “dbms”'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'call mum tomorrow');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    // Ctrl+Return adds the line, whatever else it matched.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    // The close animation, then the write: each needs its own clock moved on.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    final titles = [for (final t in (await tester.runAsync(() => db.select(db.tasks).get()))!) t.title];
    expect(titles, contains('call mum'));
    expect(app.read(spotlightOpenProvider), isNull, reason: 'and it closes');
    // The offer to undo it runs out.
    await tester.pump(const Duration(seconds: 6));
  });
}
