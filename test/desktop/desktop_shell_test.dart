import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/desktop/desktop_shell.dart';

/// The Dart side of the desktop channel, against a runner played by the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(DesktopShell.name);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('asks the runner about the tray, and turns it on and off', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'trayAvailable' => true,
        'setKeepInTray' => call.arguments,
        _ => null,
      };
    });
    final shell = DesktopShell();

    expect(await shell.trayAvailable(), isTrue);
    expect(await shell.setKeepInTray(true), isTrue);
    expect(await shell.setKeepInTray(false), isFalse);
    expect(
      [for (final call in calls) '${call.method}(${call.arguments})'],
      ['trayAvailable(null)', 'setKeepInTray(true)', 'setKeepInTray(false)'],
    );
  });

  test('with no runner to answer, there is simply no tray', () async {
    final shell = DesktopShell();
    expect(await shell.trayAvailable(), isFalse);
    expect(await shell.setKeepInTray(true), isFalse);
  });

  test("the window's own buttons reach the runner", () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'windowToggleMaximize' ? true : null;
    });
    final shell = DesktopShell();

    await shell.minimize();
    expect(await shell.toggleMaximize(), isTrue);
    await shell.closeWindow();
    await shell.startDrag();

    expect(
      [for (final call in calls) call.method],
      ['windowMinimize', 'windowToggleMaximize', 'windowClose', 'windowDrag'],
    );
  });

  test('with no runner answering, the buttons do nothing rather than throw', () async {
    final shell = DesktopShell();
    await shell.minimize();
    await shell.closeWindow();
    await shell.startDrag();
    expect(await shell.toggleMaximize(), isFalse);
    expect(await shell.maximized(), isFalse);
  });

  test('the desktop can maximise the window without the app being asked', () async {
    final heard = <bool>[];
    DesktopShell().listen(
      onNewTask: () {},
      onNewNote: () {},
      onMaximized: heard.add,
    );

    for (final value in [true, false]) {
      await messenger.handlePlatformMessage(
        DesktopShell.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('windowMaximized', value),
        ),
        (_) {},
      );
    }
    expect(heard, [true, false]);
  });

  test("the tray icon's menu reaches the app", () async {
    final heard = <String>[];
    DesktopShell().listen(
      onNewTask: () => heard.add('task'),
      onNewNote: () => heard.add('note'),
    );

    for (final method in ['newTask', 'newNote']) {
      await messenger.handlePlatformMessage(
        DesktopShell.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
        (_) {},
      );
    }
    expect(heard, ['task', 'note']);
  });
}
