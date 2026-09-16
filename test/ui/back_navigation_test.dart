import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/app_config.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/ui/screens/app_shell.dart';

/// Back on Android dismisses what the shell has open, topmost first, and only then leaves
/// the app.
///
/// The shell draws its sheets itself rather than pushing routes, so the navigator knows
/// nothing about them: without a handler, a back gesture meant to close a sheet closed the
/// whole app.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'back closes sheets, then the drawer, then a search, and only then leaves',
    (tester) async {
      // Narrow enough for the sidebar to be a drawer.
      tester.view
        ..physicalSize = const Size(820, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final leaves = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') leaves.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final db = AppDatabase(NativeDatabase.memory());
      try {
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
        final app = ProviderScope.containerOf(
          tester.element(find.byType(AppShell)),
        );

        app.read(composerOpenProvider.notifier).open();
        app.read(syncSheetOpenProvider.notifier).open();
        await _settle(tester);

        await _back(tester);
        expect(app.read(syncSheetOpenProvider), isFalse);
        expect(
          app.read(composerOpenProvider),
          isTrue,
          reason: 'only the sheet on top closes',
        );

        await _back(tester);
        expect(app.read(composerOpenProvider), isFalse);

        await tester.tap(find.byIcon(Icons.menu_rounded).first);
        await _settle(tester);
        expect(find.text(AppConfig.name), findsOneWidget);
        await _back(tester);
        expect(find.text(AppConfig.name), findsNothing);

        app.read(searchQueryProvider.notifier).set('lab');
        await _settle(tester);
        await _back(tester);
        expect(app.read(searchQueryProvider), isEmpty);

        expect(leaves, isEmpty, reason: 'every back so far closed something');
        await _back(tester);
        expect(leaves, ['SystemNavigator.pop']);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(db.close);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

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
