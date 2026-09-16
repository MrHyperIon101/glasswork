import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The desktop window's life outside Flutter: an icon in the tray, and whether closing the
/// window quits Glasswork or leaves it running there.
///
/// The Linux runner keeps both (`linux/runner/desktop_shell.cc`); this is its side of the
/// `dev.mrhyperion.glasswork/desktop` channel. Where there is no runner answering — Android,
/// tests — every call quietly does nothing.
class DesktopShell {
  DesktopShell([MethodChannel? channel]) : _channel = channel ?? const MethodChannel(name);

  static const name = 'dev.mrhyperion.glasswork/desktop';

  final MethodChannel _channel;

  /// Whether this desktop has a tray to keep the app in.
  Future<bool> trayAvailable() async => await _call<bool>('trayAvailable') ?? false;

  /// Shows or takes away the tray icon, and with it whether closing the window keeps the app
  /// running. Returns whether the icon is now shown.
  Future<bool> setKeepInTray(bool keep) async =>
      await _call<bool>('setKeepInTray', keep) ?? false;

  /// Answers the tray icon's menu.
  void listen({required VoidCallback onNewTask, required VoidCallback onNewNote}) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'newTask':
          onNewTask();
        case 'newNote':
          onNewNote();
      }
    });
  }

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('Desktop: $method failed: ${error.message}');
      return null;
    }
  }
}

final desktopShellProvider = Provider<DesktopShell>((ref) => DesktopShell());

/// Whether Glasswork can be kept in a tray here: a Linux desktop that has one.
final trayAvailableProvider = FutureProvider<bool>((ref) async {
  if (defaultTargetPlatform != TargetPlatform.linux) return false;
  return ref.watch(desktopShellProvider).trayAvailable();
});
