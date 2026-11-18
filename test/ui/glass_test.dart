import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/preferences.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/theme/tokens.dart';
import 'package:glasswork/ui/glass/glass_surface.dart';
import 'package:glasswork/ui/glass/liquid_glass.dart';
import 'package:glasswork/ui/screens/app_shell.dart';

/// Glass: which look is drawn, and what each one puts on screen.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('the shader ships with the app', () {
    // A shader named in code but missing from the assets fails only on a real device, as a
    // surface drawn frosted for no visible reason.
    expect(File('shaders/liquid_glass.frag').existsSync(), isTrue);
    expect(File('pubspec.yaml').readAsStringSync(), contains('- shaders/liquid_glass.frag'));
  });

  group('the look drawn', () {
    ProviderContainer containerWith(Glass? chosen) {
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWith(
            (ref) => Stream.value(Preferences(glass: chosen)),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<Glass> drawn(Glass? chosen) async {
      final container = containerWith(chosen);
      // Listened to, as a screen would, so the stream is read rather than left waiting.
      final sub = container.listen(glassProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(preferencesProvider.future);
      return container.read(glassProvider);
    }

    test('is Liquid until something is chosen, where the shader runs', () async {
      expect(await drawn(null), LiquidGlass.runs ? Glass.liquid : Glass.frosted);
    });

    test('never Liquid where the shader cannot run', () async {
      // Tests draw without Impeller's shader filters, as some devices do.
      expect(ui.ImageFilter.isShaderFilterSupported && LiquidGlass.runs, isFalse);
      expect(await drawn(Glass.liquid), Glass.frosted);
    });

    test('is what was chosen otherwise', () async {
      expect(await drawn(Glass.frosted), Glass.frosted);
      expect(await drawn(Glass.solid), Glass.solid);
    });
  });

  group('a surface', () {
    Future<void> pumpSurface(WidgetTester tester, Glass chosen, {double? blur}) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWith(
                (ref) => Stream.value(Preferences(glass: chosen)),
              ),
            ],
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: GlassSurface(
                  blur: blur ?? AppMaterial.cardBlur,
                  child: const SizedBox(width: 200, height: 100, child: Text('Card')),
                ),
              ),
            ),
          ),
        );

    testWidgets('solid shows nothing through it', (tester) async {
      await pumpSurface(tester, Glass.solid);
      await tester.pump();
      expect(find.text('Card'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('frosted, a floating surface blurs what is behind it, clipped to its corners', (
      tester,
    ) async {
      await pumpSurface(tester, Glass.frosted, blur: AppMaterial.sheetBlur);
      await tester.pump();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        find.ancestor(of: find.byType(BackdropFilter), matching: find.byType(ClipRRect)),
        findsOneWidget,
      );
    });

    testWidgets('a card has only the soft backdrop behind it, so takes no blur pass', (
      tester,
    ) async {
      await pumpSurface(tester, Glass.frosted);
      await tester.pump();
      expect(find.text('Card'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  testWidgets('choosing a look in Settings keeps it on this device', (tester) async {
    tester.view
      ..physicalSize = const Size(1440, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
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
    final app = ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    try {
      app.read(destinationProvider.notifier).go(const SettingsDestination());
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('glass-solid')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('glass-solid')));
      await _settle(tester);

      expect(app.read(glassProvider), Glass.solid);
      expect(find.textContaining('the most battery on a phone'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
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
