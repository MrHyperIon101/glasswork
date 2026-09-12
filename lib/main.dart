import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'dev/frame_stats.dart';
import 'theme/tokens.dart';
import 'ui/screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FrameStats.start();
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
      home: const Scaffold(
        backgroundColor: AppColour.base,
        body: SafeArea(child: AppShell()),
      ),
    );
  }
}
