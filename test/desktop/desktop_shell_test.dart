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
