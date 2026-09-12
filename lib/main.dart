import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'dev/frame_stats.dart';
import 'theme/tokens.dart';
import 'ui/backdrop/mesh_backdrop.dart';
import 'ui/glass/glass_surface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FrameStats.start();
  runApp(const GlassworkApp());
}

class GlassworkApp extends StatefulWidget {
  const GlassworkApp({super.key});

  @override
  State<GlassworkApp> createState() => _GlassworkAppState();
}

class _GlassworkAppState extends State<GlassworkApp> {
  GlassQuality _quality = GlassQuality.full;

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
      home: MeshBackdrop(
        quality: _quality,
        child: _GateHarness(
          quality: _quality,
          onQuality: (q) => setState(() => _quality = q),
        ),
      ),
    );
  }
}

/// Phase 0 gate: four glass surfaces over the animated backdrop, with a switcher so all
/// three quality levels can be compared by eye. This screen is scaffolding — it goes away
/// in phase 1.
class _GateHarness extends StatelessWidget {
  const _GateHarness({required this.quality, required this.onQuality});

  final GlassQuality quality;
  final ValueChanged<GlassQuality> onQuality;

  static const _cards = <(String, String, Color)>[
    ('Submit DBMS lab', 'Today · 17:00', AppColour.soon),
    ('ML assignment 3', 'Overdue by 2 days', AppColour.overdue),
    ('NPTEL week 6 quiz', 'Thu · 4h estimated', AppColour.textDim),
    ('Ambassador report', 'Done', AppColour.done),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppConfig.name, style: AppText.display),
              const SizedBox(height: AppSpace.xs),
              Text(
                '${AppGlass.maxOnScreen} glass surfaces · ${quality.name}  ·  '
                'ImageFilter.shader: '
                '${ui.ImageFilter.isShaderFilterSupported ? "supported" : "unsupported"}',
                style: AppText.numeric,
              ),
              const SizedBox(height: AppSpace.xxxl),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppSpace.xl,
                    runSpacing: AppSpace.xl,
                    children: [
                      // Three of the four surfaces are pinned to a quality level so the
                      // whole ladder is visible at once. Exactly four glass surfaces
                      // total, which is what the gate measures.
                      for (final (i, (title, meta, colour)) in _cards.indexed)
                        _QualityOverride(
                          quality: i < GlassQuality.values.length
                              ? GlassQuality.values[i]
                              : quality,
                          child: _PreviewCard(
                            title: title,
                            meta: meta,
                            accent: colour,
                            label: i < GlassQuality.values.length
                                ? GlassQuality.values[i].name
                                : 'switcher: ${quality.name}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xxl),
              _QualitySwitch(value: quality, onChanged: onQuality),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pins its subtree to one [GlassQuality] by shadowing the inherited runtime. Costs no
/// API surface on [GlassSurface] itself.
class _QualityOverride extends StatelessWidget {
  const _QualityOverride({required this.quality, required this.child});

  final GlassQuality quality;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final runtime = GlassRuntime.maybeOf(context);
    if (runtime == null) {
      return child;
    }
    return GlassRuntime(
      glassProgram: runtime.glassProgram,
      clock: runtime.clock,
      backdropSize: runtime.backdropSize,
      backdropOrigin: runtime.backdropOrigin,
      quality: quality,
      child: child,
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.meta,
    required this.accent,
    required this.label,
  });

  final String title;
  final String meta;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: GlassSurface.onBackdrop(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppText.tiny),
            const SizedBox(height: AppSpace.xs),
            Text(title, style: AppText.heading),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Container(
                  width: AppSpace.sm,
                  height: AppSpace.sm,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: AppRadius.controlAll,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(meta, style: AppText.numeric),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QualitySwitch extends StatelessWidget {
  const _QualitySwitch({required this.value, required this.onChanged});

  final GlassQuality value;
  final ValueChanged<GlassQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.sm,
      children: [
        for (final q in GlassQuality.values)
          GestureDetector(
            onTap: () => onChanged(q),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: q == value ? AppColour.accent : AppGlass.flatFill,
                borderRadius: AppRadius.controlAll,
                border: Border.all(color: AppGlass.edge),
              ),
              child: Text(
                q.name,
                style: AppText.small.copyWith(
                  color: q == value ? AppColour.base : AppColour.text,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
