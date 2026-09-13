import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/sync/account_link.dart';
import 'package:glasswork/sync/sync_auth.dart';
import 'package:glasswork/theme/tokens.dart';
import 'package:glasswork/ui/surface.dart';
import 'package:glasswork/ui/widgets/sync_sheet.dart';
import 'package:glasswork/ui/widgets/sync_status.dart';

/// Holds whatever state a test gives it, and does nothing else.
class _Held extends SyncController {
  _Held(this._initial);

  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

class _Open extends SyncSheetOpen {
  @override
  bool build() => true;
}

/// Set with `--dart-define=SCREENSHOTS=<directory>` to save what each state looks like.
const _screenshots = String.fromEnvironment('SCREENSHOTS');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const account = SyncAccount(userId: 'u', email: 'me@example.com');
  final boundary = GlobalKey();

  setUpAll(() async {
    await (FontLoader(AppFont.ui)
          ..addFont(rootBundle.load('fonts/InterVariable.ttf')))
        .load();
    try {
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    } on Object {
      // Icons render as boxes without it; the words are what these tests read.
    }
  });

  /// Fixed pumps rather than settling: a spinner never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> render(
    WidgetTester tester,
    SyncState state,
    Widget child, {
    Size size = const Size(900, 760),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncProvider.overrideWith(() => _Held(state)),
          syncSheetOpenProvider.overrideWith(_Open.new),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark, fontFamily: AppFont.ui),
          // A Scaffold, as the app has around everything: text fields need its Material.
          home: RepaintBoundary(
            key: boundary,
            child: Scaffold(backgroundColor: AppColour.base, body: child),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (_screenshots.isEmpty) return;
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_screenshots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  /// Unmounts, so anything ticking stops before the test ends.
  Future<void> finish(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  testWidgets('signed out, it asks for an email and a password', (tester) async {
    await render(tester, const SyncSignedOut(), const SyncSheet());
    await capture(tester, 'sheet_sign_in');

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('creating an account says how long the password must be', (tester) async {
    await render(tester, const SyncSignedOut(), const SyncSheet());

    await tester.tap(find.text('New here? Create an account'));
    await settle(tester);
    await capture(tester, 'sheet_create_account');

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(
      find.text('At least ${SyncAuth.minimumPasswordLength} characters'),
      findsOneWidget,
    );
    await finish(tester);
  });

  testWidgets('the password is hidden until asked for', (tester) async {
    await render(tester, const SyncSignedOut(), const SyncSheet());

    TextField password() => tester.widget<TextField>(find.byType(TextField).last);
    expect(password().obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
    await finish(tester);
  });

  testWidgets('a second device is shown what it holds before it chooses', (tester) async {
    await render(
      tester,
      const SyncChoosing(
        account: account,
        plan: AdoptAccount(
          workspaceId: 'w',
          device: DeviceContent(tasks: 14, projects: 2, blocks: 5, labels: 0),
        ),
      ),
      const SyncSheet(),
    );
    await capture(tester, 'sheet_choosing');

    expect(find.text('14 tasks · 2 projects · 5 timetable blocks'), findsOneWidget);
    expect(find.text("Add this device's work to the account"), findsOneWidget);
    expect(find.text("Use only the account's work"), findsOneWidget);
    expect(find.textContaining('backup copy is saved first'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('syncing, it shows the account and how things stand', (tester) async {
    await render(
      tester,
      SyncOn(account: account, lastSynced: DateTime.now()),
      const SyncSheet(),
    );
    await capture(tester, 'sheet_on');

    expect(find.text('me@example.com'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.textContaining('Everything stays on this device'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('offline, it counts what is waiting', (tester) async {
    await render(
      tester,
      const SyncOn(account: account, problem: SyncProblem.offline, pending: 3),
      const SyncSheet(),
    );

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('3 changes waiting'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('when setting up stops, it says why and offers to try again', (tester) async {
    await render(
      tester,
      const SyncLinking(
        account: account,
        error: "Couldn't reach the server. Check your connection and try again.",
      ),
      const SyncSheet(),
    );

    expect(find.text("Sync isn't set up yet"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the sidebar row reads as the sheet does', (tester) async {
    await render(
      tester,
      const SyncOn(account: account, problem: SyncProblem.offline, pending: 1),
      const Align(
        alignment: Alignment.bottomLeft,
        child: SizedBox(
          width: 262,
          child: VibrancyMaterial.sidebar(child: SyncStatusRow()),
        ),
      ),
      size: const Size(320, 120),
    );
    await capture(tester, 'sidebar_row');

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('1 change waiting'), findsOneWidget);
    await finish(tester);
  });
}
