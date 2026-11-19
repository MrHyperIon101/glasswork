import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'desktop/desktop_shell.dart';
import 'dev/frame_stats.dart';
import 'theme/tokens.dart';
import 'data/preferences.dart';
import 'ui/glass/ambient_backdrop.dart';
import 'ui/glass/liquid_glass.dart';
import 'ui/screens/app_shell.dart';
import 'ui/widgets/window_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FrameStats.start();
  // Before the first frame, so every glass surface is liquid from it rather than changing.
  await LiquidGlass.load();
  runApp(const ProviderScope(child: GlassworkApp()));
}

class GlassworkApp extends StatelessWidget {
  const GlassworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColour.base,
        fontFamily: AppFont.ui,
        // The app draws its own surfaces; Material's defaults would fight the palette.
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      // Everything, sheets and dialogs too, inside the window's rounded shape.
      builder: (context, child) => _WindowShape(child: child!),
      // Clear: the ground is painted by _Ground, which may be laid over the desktop.
      home: const Scaffold(
        backgroundColor: Color(0x00000000),
        body: _Ground(child: SafeArea(child: AppShell())),
      ),
    );
  }
}

/// The desktop window's shape: its corners rounded as a Mac's are, with a faint edge, and
/// square while it fills the screen. Outside the corners the window is clear, so the desktop
/// shows there — the runner gives it an alpha channel — and the GNOME Shell extension rounds
/// the frost behind it to the same radius (CORNER_RADIUS in its window_glass.js).
class _WindowShape extends ConsumerWidget {
  const _WindowShape({required this.child});

  final Widget child;

  static const _edge = Color(0x24FFFFFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!WindowControls.available || ref.watch(windowMaximizedProvider)) return child;
    return ClipRRect(
      borderRadius: AppRadius.xlargeAll,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlargeAll,
          border: Border.all(color: _edge),
        ),
        child: child,
      ),
    );
  }
}

/// What every screen is laid on: the ambient backdrop, and the one capture of it that all
/// the glass above shares. It holds still under the solid look, where nothing shows it.
class _Ground extends ConsumerWidget {
  const _Ground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seeThrough = ref.watch(desktopGlassProvider) && ref.watch(glassProvider) != Glass.solid;
    return AmbientBackdrop(
      // Over the desktop there are no fields to move: the desktop's own colour shows.
      moving: ref.watch(glassProvider) != Glass.solid && !seeThrough,
      seeThrough: seeThrough,
      child: BackdropGroup(child: child),
    );
  }
}
