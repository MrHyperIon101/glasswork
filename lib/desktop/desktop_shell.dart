import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The desktop window's life outside Flutter: an icon in the tray, whether closing the
/// window quits Glasswork or leaves it running there, and the window's own buttons.
///
/// The Linux window has no title bar of its own, so minimising it, maximising it, closing
/// it and dragging it about are asked for from the app's own header — see
/// `lib/ui/widgets/window_controls.dart`.
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

  /// Puts the window out of the way, in the taskbar.
  Future<void> minimize() => _call<void>('windowMinimize');

  /// Maximises the window, or puts it back. Returns whether it is now maximised.
  Future<bool> toggleMaximize() async =>
      await _call<bool>('windowToggleMaximize') ?? false;

  /// Closes the window — which, with "Keep in the tray" on, leaves the app running there,
  /// exactly as the window's own close button did.
  Future<void> closeWindow() => _call<void>('windowClose');

  /// Hands the drag to the window manager, which moves the window from here on. Asked for
  /// as a drag begins on the app's header, since there is no title bar to drag.
  Future<void> startDrag() => _call<void>('windowDrag');

  Future<bool> maximized() async => await _call<bool>('windowMaximized') ?? false;

  /// Answers the tray icon's menu, and hears when the window is maximised or restored —
  /// which the desktop can do without the app being asked.
  void listen({
    required VoidCallback onNewTask,
    required VoidCallback onNewNote,
    ValueChanged<bool>? onMaximized,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'newTask':
          onNewTask();
        case 'newNote':
          onNewNote();
        case 'windowMaximized':
          onMaximized?.call(call.arguments == true);
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

/// Whether the window is maximised, as the runner last said — which decides only which
/// glyph the zoom button draws.
class WindowMaximized extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final windowMaximizedProvider = NotifierProvider<WindowMaximized, bool>(
  WindowMaximized.new,
);

/// Whether Glasswork can be kept in a tray here: a Linux desktop that has one.
final trayAvailableProvider = FutureProvider<bool>((ref) async {
  if (defaultTargetPlatform != TargetPlatform.linux) return false;
  return ref.watch(desktopShellProvider).trayAvailable();
});
