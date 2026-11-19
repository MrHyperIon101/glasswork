import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'dev/frame_stats.dart';
import 'theme/tokens.dart';
import 'data/preferences.dart';
import 'ui/glass/ambient_backdrop.dart';
import 'ui/glass/liquid_glass.dart';
import 'ui/screens/app_shell.dart';

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
      // Clear: the ground is painted by _Ground, which may be laid over the desktop.
      home: const Scaffold(
        backgroundColor: Color(0x00000000),
        body: _Ground(child: SafeArea(child: AppShell())),
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
  Widget build(BuildContext context, WidgetRef ref) => AmbientBackdrop(
    moving: ref.watch(glassProvider) != Glass.solid,
    seeThrough: ref.watch(desktopGlassProvider) && ref.watch(glassProvider) != Glass.solid,
    child: BackdropGroup(child: child),
  );
}
