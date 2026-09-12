import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import '../glass/glass_quality.dart';

/// What a [GlassSurface] needs to reconstruct the backdrop behind itself.
///
/// The glass shader does not sample the backdrop — that API is Impeller-only and throws
/// on Skia, which is what Linux runs. Instead it re-evaluates the same gradient function,
/// so it needs the backdrop's geometry and the same clock the backdrop is using.
class GlassRuntime extends InheritedWidget {
  const GlassRuntime({
    required this.glassProgram,
    required this.clock,
    required this.backdropSize,
    required this.quality,
    required super.child,
    this.backdropOrigin = Offset.zero,
    super.key,
  });

  /// Null until the shader finishes loading. Surfaces fall back to [GlassQuality.flat]
  /// while it is.
  final ui.FragmentProgram? glassProgram;

  /// Seconds since start. Stops advancing when the window is unfocused or the platform
  /// asks for reduced motion.
  final ValueListenable<double> clock;

  final Size backdropSize;

  /// Where the backdrop sits in global coordinates. Zero while the backdrop is the root
  /// fullscreen widget, which it is today; kept explicit so an inset backdrop later does
  /// not silently misalign every glass surface.
  final Offset backdropOrigin;

  final GlassQuality quality;

  static GlassRuntime? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassRuntime>();

  @override
  bool updateShouldNotify(GlassRuntime old) =>
      glassProgram != old.glassProgram ||
      clock != old.clock ||
      backdropSize != old.backdropSize ||
      backdropOrigin != old.backdropOrigin ||
      quality != old.quality;
}

/// The slow-drifting mesh gradient everything else floats over.
///
/// The backdrop is load-bearing, not decoration: glass only reads as glass when there is
/// something worth refracting behind it.
class MeshBackdrop extends StatefulWidget {
  const MeshBackdrop({
    required this.child,
    this.quality = GlassQuality.full,
    super.key,
  });

  final Widget child;
  final GlassQuality quality;

  @override
  State<MeshBackdrop> createState() => _MeshBackdropState();
}

class _MeshBackdropState extends State<MeshBackdrop>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);

  late final Ticker _ticker = createTicker(_onTick);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: _onLifecycle,
  );

  ui.FragmentShader? _meshShader;
  ui.FragmentProgram? _glassProgram;

  bool _focused = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _lifecycle; // instantiate the listener
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _lifecycle.dispose();
    _meshShader?.dispose();
    _clock.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final mesh = await ui.FragmentProgram.fromAsset('shaders/mesh.frag');
    final glass = await ui.FragmentProgram.fromAsset('shaders/glass.frag');
    if (!mounted) {
      return;
    }
    setState(() {
      _meshShader = mesh.fragmentShader();
      _glassProgram = glass;
    });
    _syncTicker();
  }

  void _onTick(Duration elapsed) {
    _clock.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  void _onLifecycle(AppLifecycleState state) {
    debugPrint('BACKDROP lifecycle=$state');
    final focused = state == AppLifecycleState.resumed;
    if (focused != _focused) {
      _focused = focused;
      _syncTicker();
    }
  }

  /// The backdrop animates only when it is being looked at and motion is welcome.
  void _syncTicker() {
    final shouldRun = _focused && !_reduceMotion && _meshShader != null;
    debugPrint(
      'BACKDROP decide run=$shouldRun active=${_ticker.isActive} '
      '(focused=$_focused reduceMotion=$_reduceMotion '
      'shaderLoaded=${_meshShader != null})',
    );
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shader = _meshShader;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Solid base, so the window is never transparent for a frame while the
            // shader loads.
            const ColoredBox(color: AppColour.base),
            if (shader != null)
              RepaintBoundary(
                child: CustomPaint(
                  painter: _MeshPainter(shader: shader, clock: _clock),
                  size: size,
                ),
              ),
            GlassRuntime(
              glassProgram: _glassProgram,
              clock: _clock,
              backdropSize: size,
              quality: widget.quality,
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.shader, required this.clock})
    : super(repaint: clock);

  final ui.FragmentShader shader;
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, clock.value);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  // Repaint is driven by the clock passed to super, not by comparing painters.
  @override
  bool shouldRepaint(_MeshPainter old) =>
      old.shader != shader || old.clock != clock;
}
