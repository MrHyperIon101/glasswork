import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/desktop/desktop_shell.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/ui/widgets/window_controls.dart';

/// The window's own buttons, drawn in the app because the Linux window has no bar of its
/// own. What matters is that each one reaches the runner, and that a phone has none.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(DesktopShell.name);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late AppDatabase db;
  late List<MethodCall> calls;

  Future<void> start(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'windowToggleMaximize' => true,
        'windowMaximized' => false,
        'trayAvailable' => false,
        _ => null,
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

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
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  testWidgets('each button asks the runner for the thing it draws', (tester) async {
    await start(tester);
    try {
      expect(find.byType(WindowControls), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('window-minimize')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('window-zoom')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('window-close')));
      await _settle(tester);

      expect(
        [for (final call in calls) call.method]..removeWhere(
          (m) => m == 'trayAvailable' || m == 'setKeepInTray' || m == 'windowMaximized',
        ),
        ['windowMinimize', 'windowToggleMaximize', 'windowClose'],
      );
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a maximised window offers to put itself back', (tester) async {
    await start(tester);
    try {
      final zoom = find.byKey(const ValueKey('window-zoom'));
      expect(tester.widget<Tooltip>(_tooltipOf(zoom)).message, 'Maximise');

      await tester.tap(zoom);
      await _settle(tester);

      expect(tester.widget<Tooltip>(_tooltipOf(zoom)).message, 'Restore');
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a phone has no window to control, so draws nothing', (tester) async {
    await start(tester);
    try {
      expect(find.byType(WindowControls), findsWidgets);
      expect(find.byKey(const ValueKey('window-close')), findsNothing);
      expect(calls.where((c) => c.method.startsWith('window')), isEmpty);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}

Finder _tooltipOf(Finder button) =>
    find.descendant(of: button, matching: find.byType(Tooltip)).first;

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
