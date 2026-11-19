import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/preferences.dart';
import '../../state/providers.dart';

/// The liquid glass shader, loaded once as the app starts so every surface can use it from
/// its first frame.
///
/// `shaders/liquid_glass.frag` is run as a backdrop filter, which only Impeller can do. Where
/// it cannot — Skia, a test, a renderer without shader filters — [program] stays null, and
/// Liquid is drawn as Frosted.
abstract final class LiquidGlass {
  static ui.FragmentProgram? _program;

  static ui.FragmentProgram? get program => _program;

  /// Whether this device can draw [Glass.liquid] at all.
  static bool get runs => _program != null;

  static Future<void> load() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
    } on Exception catch (error) {
      debugPrint('Liquid glass: no shader ($error); drawing frosted instead.');
    }
  }
}

/// How surfaces are drawn on this device: the choice in Settings, Liquid until one is made,
/// and never Liquid where the shader cannot run.
final glassProvider = Provider<Glass>((ref) {
  final wanted = ref.watch(preferencesProvider).value?.glass ?? Glass.liquid;
  return wanted == Glass.liquid && !LiquidGlass.runs ? Glass.frosted : wanted;
});

/// Whether the desktop itself is the glass behind the window: the GNOME Shell extension blurs
/// what is behind Glasswork's window and says so over D-Bus, and the ground turns translucent
/// over that blur. Off until then, and always off where nothing can blur the desktop — a
/// window cannot see what is behind it on Wayland, only the compositor can.
class DesktopGlass extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

final desktopGlassProvider = NotifierProvider<DesktopGlass, bool>(DesktopGlass.new);
