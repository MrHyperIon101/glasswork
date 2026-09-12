import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Shared motion primitives.
///
/// Everything that moves in the app moves through one of these, so timing and feel stay
/// consistent instead of each screen inventing its own. Motion answers actions — it is
/// never decoration, and nothing animates just because it appeared.

/// Spring-driven entrance for overlays: scales up from slightly small while fading in.
///
/// Uses a real spring simulation rather than a curve, because Apple's panels settle
/// rather than ease — the difference is small on paper and obvious in the hand.
class SpringIn extends StatefulWidget {
  const SpringIn({
    required this.child,
    this.from = 0.96,
    this.slide = 8,
    super.key,
  });

  final Widget child;

  /// Starting scale. Close to 1: a panel that grows from nothing reads as a toy.
  final double from;

  /// Vertical travel in logical pixels.
  final double slide;

  @override
  State<SpringIn> createState() => _SpringInState();
}

class _SpringInState extends State<SpringIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _controller.animateWith(
      SpringSimulation(AppMotion.spring, 0, 1, 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value.clamp(0.0, 1.0);
        return Opacity(
          // Fade finishes well before the spring settles, so the panel is readable
          // while it is still arriving.
          opacity: (t * 1.6).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.slide * (1 - t)),
            child: Transform.scale(
              scale: widget.from + (1 - widget.from) * t,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Fade and rise. For list rows and screen bodies arriving.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 6,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Cross-fades between screens without the horizontal shove of a page route.
///
/// Destinations in a sidebar app are siblings, not a stack — sliding one over another
/// would imply a hierarchy that is not there.
class ScreenSwitcher extends StatelessWidget {
  const ScreenSwitcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      // Default is a cross-fade that briefly shows both; this keeps the outgoing screen
      // out of the way so text never doubles up mid-transition.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A pop on completion. Small, quick, and only on the transition into done — undoing
/// should feel like a correction, not a second celebration.
class CheckPop extends StatefulWidget {
  const CheckPop({required this.done, required this.child, super.key});

  final bool done;
  final Widget child;

  @override
  State<CheckPop> createState() => _CheckPopState();
}

class _CheckPopState extends State<CheckPop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didUpdateWidget(CheckPop old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Out and back: peaks at 1.18 halfway through.
        final t = _controller.value;
        final scale = 1 + 0.18 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
