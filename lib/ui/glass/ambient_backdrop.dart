import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';

/// What the glass is laid over: a few large soft fields of colour on the app's ground,
/// drifting slowly enough that you notice it only when you look for it.
///
/// Glass over a flat colour shows nothing — there is nothing to bend or blur — so this is
/// what gives every surface something to catch. It is painted, not captured, so it costs
/// almost nothing of its own; what it does cost is that each repaint makes the glass over
/// it filter again, so it repaints at a gentle [_fps] rather than every frame, stops while
/// the window is in the background, and stands still when the system asks for less motion.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({
    required this.child,
    this.moving = true,
    this.seeThrough = false,
    super.key,
  });

  final Widget child;

  /// False to hold it still: under a solid look, where nothing shows it through the cards.
  final bool moving;

  /// Laid over the desktop rather than instead of it: the ground and its colour thinned, so
  /// the blur the shell draws behind the window shows through, still dark enough for text.
  final bool seeThrough;

  /// Steps a second. The fields move a fraction of a pixel a frame, so more would be
  /// invisible and only cost the glass a filter pass each.
  static const _fps = 15;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop> with WidgetsBindingObserver {
  // A timer rather than a ticker: a ticker asks for a frame on every vsync whether or not the
  // fields moved, which is a GPU kept awake for nothing between the steps.
  Timer? _timer;
  final _time = ValueNotifier<double>(0);
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(AmbientBackdrop old) {
    super.didUpdateWidget(old);
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _update();
  }

  void _update() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final run = widget.moving && _foreground && !still;
    if (run && _timer == null) {
      _timer = Timer.periodic(
        const Duration(microseconds: 1000000 ~/ AmbientBackdrop._fps),
        (_) => _time.value += 1 / AmbientBackdrop._fps,
      );
    } else if (!run) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _FieldsPainter(_time, seeThrough: widget.seeThrough),
    isComplex: true,
    child: widget.child,
  );
}

/// One field of colour and the slow loop it follows.
class _Field {
  const _Field(this.colour, this.radius, this.home, this.reach, this.period, this.phase);

  final Color colour;

  /// As a share of the longer side.
  final double radius;

  /// Where it wanders around, as shares of the width and height.
  final Offset home;

  /// How far it wanders from there, as shares.
  final Offset reach;

  /// Seconds for one loop.
  final double period;
  final double phase;

  Offset at(double seconds, Size size) {
    final t = 2 * math.pi * seconds / period + phase;
    return Offset(
      (home.dx + reach.dx * math.sin(t)) * size.width,
      (home.dy + reach.dy * math.cos(t * 0.8)) * size.height,
    );
  }
}

class _FieldsPainter extends CustomPainter {
  _FieldsPainter(this.time, {required this.seeThrough}) : super(repaint: time);

  final ValueListenable<double> time;
  final bool seeThrough;

  /// Apple's own hues, dim: enough for glass to have something to bend, never so much
  /// that text on a card has to fight it.
  static final _fields = [
    _Field(AppColour.accent.withValues(alpha: 0.42), 0.55, const Offset(0.18, 0.22),
        const Offset(0.10, 0.08), 70, 0),
    _Field(AppColour.indigo.withValues(alpha: 0.42), 0.60, const Offset(0.82, 0.30),
        const Offset(0.08, 0.10), 90, 1.3),
    _Field(AppColour.purple.withValues(alpha: 0.30), 0.50, const Offset(0.62, 0.88),
        const Offset(0.12, 0.06), 80, 2.6),
    _Field(AppColour.teal.withValues(alpha: 0.26), 0.45, const Offset(0.12, 0.85),
        const Offset(0.06, 0.08), 100, 4.1),
    _Field(AppColour.pink.withValues(alpha: 0.18), 0.35, const Offset(0.45, 0.45),
        const Offset(0.14, 0.12), 120, 5.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = seeThrough ? AppMaterial.desktopGround : AppColour.ground,
    );
    final longest = math.max(size.width, size.height);
    final strength = seeThrough ? AppMaterial.desktopFields : 1.0;
    for (final field in _fields) {
      final centre = field.at(time.value, size);
      final radius = field.radius * longest;
      final colour = field.colour.withValues(alpha: field.colour.a * strength);
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [colour, colour.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_FieldsPainter old) => old.time != time || old.seeThrough != seeThrough;
}
