import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/preferences.dart';
import '../../theme/tokens.dart';
import 'liquid_glass.dart';
import 'repaints_when_moved.dart';

/// The app's one surface: a card, a sidebar, a sheet, a toast — drawn in glass, or in its
/// plainer forms, as Settings → Appearance says ([glassProvider]).
///
/// - **Liquid** blurs what is behind, bends it inside a band along the edge and lights the
///   rim, through `shaders/liquid_glass.frag`.
/// - **Frosted** only blurs it, and draws the rim.
/// - **Solid** is an opaque card in [solid], with nothing behind showing through.
///
/// Every glass surface reads the one capture of the screen its [BackdropGroup] takes,
/// rather than each taking its own, which is what makes a screen of them affordable. This
/// is the only place in the app a backdrop is filtered.
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    required this.child,
    this.radius = AppRadius.large,
    this.tint = AppMaterial.cardTint,
    this.solid = AppColour.surface,
    this.blur = AppMaterial.cardBlur,
    this.padding = EdgeInsets.zero,
    this.hairline = false,
    super.key,
  });

  final Widget child;
  final double radius;

  /// Laid over the glass: how much of what is behind still shows, and in what colour.
  final Color tint;

  /// The opaque colour the solid look uses instead.
  final Color solid;

  final double blur;
  final EdgeInsets padding;

  /// A clear edge rather than a faint one, where two surfaces of similar lightness meet.
  final bool hairline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corners = BorderRadius.all(Radius.circular(radius));
    final content = Padding(padding: padding, child: child);
    final glass = ref.watch(glassProvider);

    if (glass == Glass.solid) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: solid,
          borderRadius: corners,
          border: Border.all(
            color: hairline ? AppColour.separator : AppColour.separator.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: content,
      );
    }

    final rim = CustomPaint(
      foregroundPainter: _RimPainter(radius: radius, strong: hairline),
      child: content,
    );
    final backdropKey = BackdropGroup.of(context)?.backdropKey;
    final blurFilter = blur == 0
        ? null
        : ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.mirror);

    return ClipRRect(
      borderRadius: corners,
      child: glass == Glass.liquid
          ? _Liquid(
              radius: radius,
              tint: tint,
              blur: blurFilter,
              backdropKey: backdropKey,
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
              moving: _scrollPositions(context),
              child: rim,
            )
          : blurFilter == null
          ? DecoratedBox(decoration: BoxDecoration(color: tint), child: rim)
          : BackdropFilter.grouped(
              filter: blurFilter,
              child: DecoratedBox(decoration: BoxDecoration(color: tint), child: rim),
            ),
    );
  }

  /// Everything that can move this surface without repainting it: the scroll views it is in.
  /// The liquid shader is told where the surface is each time it paints, so a scroll has to
  /// paint it again or the bend would stay where the surface used to be.
  static Listenable? _scrollPositions(BuildContext context) {
    final positions = <Listenable>[];
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      positions.add(scrollable.position);
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    return positions.isEmpty ? null : Listenable.merge(positions);
  }
}

/// The light along a glass edge: brighter where it faces the top left, faint elsewhere.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.radius, required this.strong});

  final double radius;
  final bool strong;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColour.label.withValues(alpha: strong ? 0.34 : 0.24),
            AppColour.label.withValues(alpha: strong ? 0.12 : 0.05),
            AppColour.label.withValues(alpha: strong ? 0.16 : 0.08),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.radius != radius || old.strong != strong;
}

/// The liquid look: a backdrop filter whose shader knows where this surface is.
class _Liquid extends SingleChildRenderObjectWidget {
  const _Liquid({
    required this.radius,
    required this.tint,
    required this.blur,
    required this.backdropKey,
    required this.devicePixelRatio,
    required this.moving,
    required super.child,
  });

  final double radius;
  final Color tint;
  final ui.ImageFilter? blur;
  final BackdropKey? backdropKey;
  final double devicePixelRatio;
  final Listenable? moving;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLiquid(
    LiquidGlass.program!.fragmentShader(),
    radius: radius,
    tint: tint,
    blur: blur,
    backdropKey: backdropKey,
    devicePixelRatio: devicePixelRatio,
    moving: moving,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderLiquid renderObject) {
    renderObject
      ..radius = radius
      ..tint = tint
      ..blur = blur
      ..backdropKey = backdropKey
      ..devicePixelRatio = devicePixelRatio
      ..moving = moving;
  }
}

class _RenderLiquid extends RenderProxyBox with RepaintsWhenMoved {
  _RenderLiquid(
    this._shader, {
    required double radius,
    required Color tint,
    required ui.ImageFilter? blur,
    required BackdropKey? backdropKey,
    required double devicePixelRatio,
    required Listenable? moving,
  }) : _radius = radius,
       _tint = tint,
       _blur = blur,
       _backdropKey = backdropKey,
       _devicePixelRatio = devicePixelRatio,
       _moving = moving;

  final ui.FragmentShader _shader;

  double _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  Color _tint;
  set tint(Color value) {
    if (value == _tint) return;
    _tint = value;
    markNeedsPaint();
  }

  ui.ImageFilter? _blur;
  set blur(ui.ImageFilter? value) {
    if (value == _blur) return;
    _blur = value;
    markNeedsPaint();
  }

  BackdropKey? _backdropKey;
  set backdropKey(BackdropKey? value) {
    if (value == _backdropKey) return;
    _backdropKey = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  Listenable? _moving;
  set moving(Listenable? value) {
    if (value == _moving) return;
    if (attached) _moving?.removeListener(markNeedsPaint);
    _moving = value;
    if (attached) _moving?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _moving?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _moving?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    // Where this surface is on the screen, in the backdrop's own pixels. Painted again
    // whenever it moves (RepaintsWhenMoved), so this is never where it used to be.
    final onScreen = this.onScreen;
    paintedAt(onScreen);
    final scale = size.width == 0 ? 1.0 : onScreen.width / size.width;
    final px = _devicePixelRatio;
    final tint = _tint;

    var i = 2; // 0 and 1 are the backdrop's size, which the engine sets.
    void put(double value) => _shader.setFloat(i++, value);
    put(onScreen.left * px);
    put(onScreen.top * px);
    put(onScreen.width * px);
    put(onScreen.height * px);
    put(_radius * scale * px);
    put(AppMaterial.liquidRim * scale * px);
    put(AppMaterial.liquidRefraction * scale * px);
    put(AppMaterial.liquidLight);
    put(tint.r * tint.a);
    put(tint.g * tint.a);
    put(tint.b * tint.a);
    put(tint.a);

    final shader = ui.ImageFilter.shader(_shader);
    final blur = _blur;
    final filter = blur == null ? shader : ui.ImageFilter.compose(outer: shader, inner: blur);
    final layer = (this.layer ??= BackdropFilterLayer())
      ..filter = filter
      ..backdropKey = _backdropKey;
    context.pushLayer(layer, super.paint, offset);
  }
}
