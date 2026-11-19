import 'package:flutter/services.dart';

import 'spotlight_service.dart';

/// The runner's side of Spotlight, over `dev.mrhyperion.glasswork/spotlight`.
///
/// The runner serves `dev.mrhyperion.glasswork.Spotlight` on the session bus
/// (`linux/runner/spotlight_service.cc`) and hands each call here. Calls that arrive before
/// Glasswork can answer — the OS Spotlight woke it, and it is still starting — wait in the
/// runner until [listen] says it is ready, rather than failing.
abstract final class SpotlightChannel {
  static const name = 'dev.mrhyperion.glasswork/spotlight';
  static const _channel = MethodChannel(name);

  /// Answers the runner's calls with [service]. [onActivated] runs once something has been
  /// opened, so the window can come forward to show it.
  static Future<void> listen(
    SpotlightService service, {
    VoidCallback? onActivated,
    ValueChanged<bool>? onDesktopGlass,
  }) async {
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map ? call.arguments as Map : const {};
      String text() => '${args['text'] ?? ''}';
      int limit(int fallback) => args['limit'] is int ? args['limit'] as int : fallback;

      switch (call.method) {
        case 'query':
          return await service.query(text(), limit: limit(20));
        case 'recents':
          return await service.recents(limit: limit(8));
        case 'previewAdd':
          return await service.previewAdd(text());
        case 'addTask':
          return await service.addTask(text()) ?? '';
        case 'desktopGlass':
          onDesktopGlass?.call(args['on'] == true);
          return null;
        case 'activate':
          final opened = await service.activate('${args['id'] ?? ''}');
          if (opened) onActivated?.call();
          return opened;
      }
      throw MissingPluginException('No ${call.method} on $name');
    });
    try {
      await _channel.invokeMethod<void>('ready');
    } on MissingPluginException {
      // No runner serving Spotlight here: Android, a test.
    }
  }
}
