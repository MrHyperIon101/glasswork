import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import '../backdrop/mesh_backdrop.dart';
import 'glass_quality.dart';

export 'glass_quality.dart';

/// The only glass in the app. There is no ad-hoc [BackdropFilter] anywhere else.
///
/// Two modes, and they are not interchangeable:
///
/// * [GlassSurface.onBackdrop] reconstructs the mesh gradient at a refracted coordinate.
///   Cheap, and the one that reads as thick glass. It is only correct when the surface
///   sits directly on the backdrop — it does not know about content underneath it.
/// * [GlassSurface.overContent] blurs what is actually behind it. Use it for sheets and
///   modals that genuinely overlap a list.
class GlassSurface extends StatefulWidget {
  const GlassSurface.onBackdrop({
    required this.child,
    this.radius = AppRadius.surfaceValue,
    this.padding = EdgeInsets.zero,
    super.key,
  }) : overContent = false;

  const GlassSurface.overContent({
    required this.child,
    this.radius = AppRadius.surfaceValue,
    this.padding = EdgeInsets.zero,
    super.key,
  }) : overContent = true;

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool overContent;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  /// One shader instance per surface. Sharing a single [ui.FragmentShader] across
  /// surfaces would race: uniforms are mutable state on the object, not captured per draw.
  ui.FragmentShader? _shader;
  ui.FragmentProgram? _program;

  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final program = GlassRuntime.maybeOf(context)?.glassProgram;
    if (program != _program) {
      _shader?.dispose();
      _program = program;
      _shader = program?.fragmentShader();
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padded = Padding(padding: widget.padding, child: widget.child);
    final runtime = GlassRuntime.maybeOf(context);
    final quality = runtime?.quality ?? GlassQuality.flat;

    if (widget.overContent) {
      return _OverContentGlass(radius: widget.radius, child: padded);
    }

    final shader = _shader;
    if (shader == null || runtime == null || quality == GlassQuality.flat) {
      return _FlatGlass(radius: widget.radius, child: padded);
    }

    return MouseRegion(
      onHover: (event) => _pointer.value = event.localPosition,
      onExit: (_) => _pointer.value = null,
      child: _GlassPaint(
        shader: shader,
        clock: runtime.clock,
        pointer: _pointer,
        backdropSize: runtime.backdropSize,
        backdropOrigin: runtime.backdropOrigin,
        radius: widget.radius,
        refract: quality == GlassQuality.full ? 1 : 0,
        child: padded,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shader path
// ---------------------------------------------------------------------------

class _GlassPaint extends SingleChildRenderObjectWidget {
  const _GlassPaint({
    required this.shader,
    required this.clock,
    required this.pointer,
    required this.backdropSize,
    required this.backdropOrigin,
    required this.radius,
    required this.refract,
    required Widget super.child,
  });

  final ui.FragmentShader shader;
  final ValueListenable<double> clock;
  final ValueListenable<Offset?> pointer;
  final Size backdropSize;
  final Offset backdropOrigin;
  final double radius;
  final double refract;

  @override
  _RenderGlass createRenderObject(BuildContext context) => _RenderGlass(
    shader: shader,
    clock: clock,
    pointer: pointer,
    backdropSize: backdropSize,
    backdropOrigin: backdropOrigin,
    radius: radius,
    refract: refract,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderGlass renderObject) {
    renderObject
      ..shader = shader
      ..clock = clock
      ..pointer = pointer
      ..backdropSize = backdropSize
      ..backdropOrigin = backdropOrigin
      ..radius = radius
      ..refract = refract;
  }
}

class _RenderGlass extends RenderProxyBox {
  _RenderGlass({
    required ui.FragmentShader shader,
    required ValueListenable<double> clock,
    required ValueListenable<Offset?> pointer,
    required Size backdropSize,
    required Offset backdropOrigin,
    required double radius,
    required double refract,
  }) : _shader = shader,
       _clock = clock,
       _pointer = pointer,
       _backdropSize = backdropSize,
       _backdropOrigin = backdropOrigin,
       _radius = radius,
       _refract = refract;

  ui.FragmentShader _shader;
  set shader(ui.FragmentShader value) {
    if (_shader == value) return;
    _shader = value;
    markNeedsPaint();
  }

  ValueListenable<double> _clock;
  set clock(ValueListenable<double> value) {
    if (_clock == value) return;
    if (attached) _clock.removeListener(markNeedsPaint);
    _clock = value;
    if (attached) _clock.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  ValueListenable<Offset?> _pointer;
  set pointer(ValueListenable<Offset?> value) {
    if (_pointer == value) return;
    if (attached) _pointer.removeListener(markNeedsPaint);
    _pointer = value;
    if (attached) _pointer.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Size _backdropSize;
  set backdropSize(Size value) {
    if (_backdropSize == value) return;
    _backdropSize = value;
    markNeedsPaint();
  }

  Offset _backdropOrigin;
  set backdropOrigin(Offset value) {
    if (_backdropOrigin == value) return;
    _backdropOrigin = value;
    markNeedsPaint();
  }

  double _radius;
  set radius(double value) {
    if (_radius == value) return;
    _radius = value;
    markNeedsPaint();
  }

  double _refract;
  set refract(double value) {
    if (_refract == value) return;
    _refract = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clock.addListener(markNeedsPaint);
    _pointer.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _clock.removeListener(markNeedsPaint);
    _pointer.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Where this surface sits within the backdrop. The shader needs it to know which
    // part of the gradient to reconstruct — it cannot see what is behind it.
    final origin = localToGlobal(Offset.zero) - _backdropOrigin;
    final p = _pointer.value;

    _shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, origin.dx)
      ..setFloat(3, origin.dy)
      ..setFloat(4, _backdropSize.width)
      ..setFloat(5, _backdropSize.height)
      ..setFloat(6, _clock.value)
      ..setFloat(7, _radius)
      ..setFloat(8, p?.dx ?? -1)
      ..setFloat(9, p?.dy ?? -1)
      ..setFloat(10, _refract);

    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    // A plain rect: the shader derives its own rounded-rect coverage from an SDF, which
    // antialiases better than clipping would.
    canvas.drawRect(Offset.zero & size, Paint()..shader = _shader);
    canvas.restore();

    super.paint(context, offset);
  }
}

// ---------------------------------------------------------------------------
// Fallbacks
// ---------------------------------------------------------------------------

/// [GlassQuality.flat] — a tinted solid. Deliberate, not broken.
class _FlatGlass extends StatelessWidget {
  const _FlatGlass({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppGlass.flatFill,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      border: Border.all(color: AppGlass.edge),
    ),
    child: child,
  );
}

/// The one sanctioned [BackdropFilter] in the app, for surfaces that overlap real content
/// rather than the backdrop.
class _OverContentGlass extends StatelessWidget {
  const _OverContentGlass({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: AppGlass.blurSigma,
        sigmaY: AppGlass.blurSigma,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppGlass.flatFill,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          border: Border.all(color: AppGlass.edge),
        ),
        child: child,
      ),
    ),
  );
}
