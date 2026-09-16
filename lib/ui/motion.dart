import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/tokens.dart';

/// Shared motion primitives.
///
/// Everything that moves in the app moves through one of these, so timing and feel stay
/// consistent instead of each screen inventing its own. Motion answers something that
/// happened — a sheet opening, a task finished, a screen changed — and every piece of it
/// honours the system's request for less motion.

/// Keeps what [builder] makes on screen while [visible], animating it in, and a moment
/// longer once not, animating it out. Without this, closing something was instant while
/// opening it was animated, which is most of what made the motion feel unfinished.
class Presence extends StatefulWidget {
  const Presence({
    required this.visible,
    required this.builder,
    this.duration = AppMotion.slow,
    this.reverseDuration = AppMotion.quick,
    this.curve = AppMotion.enter,
    this.reverseCurve = AppMotion.exit,
    super.key,
  });

  final bool visible;
  final Widget Function(BuildContext context, Animation<double> animation) builder;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve reverseCurve;

  @override
  State<Presence> createState() => _PresenceState();
}

class _PresenceState extends State<Presence> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
    value: widget.visible ? 1 : 0,
  )..addStatusListener(_statusChanged);

  late final _curved = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
    reverseCurve: widget.reverseCurve,
  );

  void _statusChanged(AnimationStatus status) {
    // Gone once it has finished leaving.
    if (status == AnimationStatus.dismissed && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(Presence old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    _controller
      ..duration = AppMotion.of(context, widget.duration)
      ..reverseDuration = AppMotion.of(context, widget.reverseDuration);
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.isDismissed) return const SizedBox.shrink();
    // Something on its way out can no longer be tapped.
    return IgnorePointer(
      ignoring: !widget.visible,
      child: widget.builder(context, _curved),
    );
  }
}

/// A sheet while [open], animating in, and out again once closed.
///
/// While it leaves it goes on showing what it last showed. By then what it showed has
/// usually gone — a closed task sheet's task is no longer open — and a sheet that emptied
/// as it faded would flicker.
class SheetPresence extends StatefulWidget {
  const SheetPresence({required this.open, required this.builder, super.key});

  final bool open;

  /// Makes the sheet. Called only while [open].
  final WidgetBuilder builder;

  @override
  State<SheetPresence> createState() => _SheetPresenceState();
}

class _SheetPresenceState extends State<SheetPresence> {
  Widget? _shown;

  /// Counts openings, so a sheet opened again while the last one is still leaving starts
  /// afresh rather than inheriting what was typed into it.
  int _opening = 0;

  @override
  void didUpdateWidget(SheetPresence old) {
    super.didUpdateWidget(old);
    if (widget.open && !old.open) _opening++;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.open) {
      _shown = KeyedSubtree(key: ValueKey(_opening), child: widget.builder(context));
    }
    return Presence(
      visible: widget.open,
      builder: (context, animation) {
        final shown = _shown;
        if (shown == null) return const SizedBox.shrink();
        return SheetAnimation(
          animation: animation,
          closing: !widget.open,
          child: shown,
        );
      },
    );
  }
}

/// How far a sheet has arrived, for the sheet to draw itself by.
class SheetAnimation extends InheritedWidget {
  const SheetAnimation({
    required this.animation,
    required this.closing,
    required super.child,
    super.key,
  });

  /// 0 before it arrives, 1 once it has.
  final Animation<double> animation;

  /// Whether it is on its way out.
  final bool closing;

  static SheetAnimation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetAnimation>();

  @override
  bool updateShouldNotify(SheetAnimation old) =>
      animation != old.animation || closing != old.closing;
}

/// Opens a dialog that arrives and leaves the way sheets do: a quick fade, and a slight
/// grow into place.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: dismissible,
  barrierLabel: 'Close',
  barrierColor: const Color(0x8C000000),
  transitionDuration: AppMotion.of(context, AppMotion.medium),
  pageBuilder: (context, _, _) => builder(context),
  transitionBuilder: (context, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(curved),
        child: child,
      ),
    );
  },
);

/// Fade and rise into place, after [delay]. For content arriving: a screen's cards, one
/// after another, or a row that was just added.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 8,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium + delay);
    if (duration == Duration.zero) return child;
    final start = delay.inMicroseconds / duration.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Interval(start, 1, curve: AppMotion.enter),
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

/// Changes between screens by fading through: the old one goes quickly, then the new one
/// settles in. The two are never both legible at once, which is what made the old
/// cross-fade look like a double exposure.
///
/// Destinations in a sidebar app are siblings, not a stack — sliding one over another
/// would imply a hierarchy that is not there.
class ScreenSwitcher extends StatelessWidget {
  const ScreenSwitcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.medium),
      reverseDuration: AppMotion.of(context, AppMotion.instant),
      switchInCurve: const Interval(0.3, 1, curve: AppMotion.enter),
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.985, end: 1.0).animate(animation),
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Something to press: it gives slightly under a finger or a click, and springs back.
///
/// Hover is left to what it wraps, which knows what hovering should look like there.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.onLongPress,
    super.key,
  });

  final Widget child;

  /// Null leaves it unpressable, and still.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _press(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _press(true) : null,
      onTapUp: enabled ? (_) => _press(false) : null,
      onTapCancel: enabled ? () => _press(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: AppMotion.of(context, _down ? AppMotion.instant : AppMotion.medium),
        curve: _down ? Curves.easeOut : AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// A whole number that counts to its new value rather than jumping to it.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(this.value, {required this.style, this.suffix = '', super.key});

  final int value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: AppMotion.of(context, AppMotion.slow),
    curve: AppMotion.standard,
    builder: (context, shown, _) => Text('${shown.round()}$suffix', style: style),
  );
}

/// A column of keyed items that animate in as they arrive and out as they go, the rest
/// closing up smoothly behind them.
///
/// Built all at once, so for short lists: today's tasks, a handful of notes.
class AnimatedItems<T> extends StatefulWidget {
  const AnimatedItems({
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    super.key,
  });

  final List<T> items;
  final Object Function(T item) keyOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<AnimatedItems<T>> createState() => _AnimatedItemsState<T>();
}

class _Entry<T> {
  _Entry(this.key, this.item, this.controller);

  final Object key;
  T item;
  final AnimationController controller;
  bool leaving = false;
}

class _AnimatedItemsState<T> extends State<AnimatedItems<T>> with TickerProviderStateMixin {
  final _entries = <_Entry<T>>[];

  AnimationController _controller({required double value}) => AnimationController(
    vsync: this,
    duration: AppMotion.of(context, AppMotion.medium),
    reverseDuration: AppMotion.of(context, AppMotion.quick),
    value: value,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The first items are simply there: only later arrivals animate in.
    if (_entries.isEmpty) {
      for (final item in widget.items) {
        _entries.add(_Entry(widget.keyOf(item), item, _controller(value: 1)));
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedItems<T> old) {
    super.didUpdateWidget(old);
    final incoming = {for (final item in widget.items) widget.keyOf(item): item};
    final byKey = {for (final entry in _entries) entry.key: entry};

    // Whatever has gone leaves from where it was.
    for (final entry in _entries) {
      if (entry.leaving || incoming.containsKey(entry.key)) continue;
      entry.leaving = true;
      entry.controller.reverse().whenCompleteOrCancel(() {
        if (!mounted || !entry.leaving || !entry.controller.isDismissed) return;
        setState(() => _entries.remove(entry));
        entry.controller.dispose();
      });
    }

    // The new order, with anything leaving kept just after what it used to follow.
    final merged = <_Entry<T>>[];
    final placed = <Object>{};
    void carryLeavingAfter(int index) {
      for (var i = index; i < _entries.length && _entries[i].leaving; i++) {
        if (placed.add(_entries[i].key)) merged.add(_entries[i]);
      }
    }

    carryLeavingAfter(0);
    for (final item in widget.items) {
      final key = widget.keyOf(item);
      final existing = byKey[key];
      if (existing == null) {
        merged.add(_Entry(key, item, _controller(value: 0))..controller.forward());
      } else {
        if (existing.leaving) {
          // Back before it had finished going.
          existing.leaving = false;
          existing.controller.forward();
        }
        existing.item = item;
        merged.add(existing);
        carryLeavingAfter(_entries.indexOf(existing) + 1);
      }
      placed.add(key);
    }
    for (final entry in _entries) {
      if (entry.leaving && placed.add(entry.key)) merged.add(entry);
    }

    _entries
      ..clear()
      ..addAll(merged);
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in _entries)
        SizeTransition(
          key: ValueKey(entry.key),
          sizeFactor: CurvedAnimation(parent: entry.controller, curve: AppMotion.standard),
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: entry.controller,
            child: widget.itemBuilder(context, entry.item),
          ),
        ),
    ],
  );
}

/// A circle that fills and draws its tick when [done], and empties when not.
class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck({
    required this.done,
    required this.size,
    this.ring = AppColour.labelQuaternary,
    this.fill = AppColour.green,
    super.key,
  });

  final bool done;
  final double size;
  final Color ring;
  final Color fill;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: done ? 1 : 0),
    duration: AppMotion.of(context, done ? AppMotion.medium : AppMotion.quick),
    curve: done ? AppMotion.enter : AppMotion.exit,
    builder: (context, t, _) => CustomPaint(
      size: Size.square(size),
      painter: _CheckPainter(t: t, ring: ring, fill: fill),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.t, required this.ring, required this.fill});

  final double t;
  final Color ring;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2;

    // The ring, giving way to the fill as it grows from the middle.
    canvas.drawCircle(
      centre,
      radius - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(ring, fill, t.clamp(0, 1))!,
    );
    if (t <= 0) return;
    canvas.drawCircle(centre, radius * t.clamp(0, 1), Paint()..color = fill);

    // The tick draws itself over the second half.
    final stroke = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    if (stroke <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.67)
      ..lineTo(size.width * 0.73, size.height * 0.36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * stroke),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColour.base,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.ring != ring || old.fill != fill;
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
  late final AnimationController _controller = AnimationController.unbounded(vsync: this);

  @override
  void didUpdateWidget(CheckPop old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done && AppMotion.of(context, AppMotion.quick) != Duration.zero) {
      // Kicked outwards, then settles back on a spring.
      _controller.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 500, damping: 18),
          0,
          0,
          3.2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) =>
        Transform.scale(scale: 1 + _controller.value.clamp(-0.2, 0.3), child: child),
    child: widget.child,
  );
}
