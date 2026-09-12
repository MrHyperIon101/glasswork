import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'dev/frame_stats.dart';
import 'theme/tokens.dart';
import 'ui/backdrop/mesh_backdrop.dart';
import 'ui/screens/home_screen.dart';

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
      ),
      home: const MeshBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: HomeScreen()),
        ),
      ),
    );
  }
}
