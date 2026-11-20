import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// For a render object whose painting depends on where it is on the screen, as liquid glass's
/// does: its shader is told the surface's place when it paints, and draws the glass there.
///
/// Most things that move a surface do not paint it again. A list lays its items out afresh
/// when one above them grows — a card's data arriving, a section opening — and only moves
/// their layers; an animation carries a page in by its transform. Either leaves the glass
/// drawn where the surface was, and the surface lit as if it were all rim. So after every
/// frame, each of these is looked over, and one that has moved since it last painted is
/// painted again in the next.
///
/// Call [paintedAt] from paint, with the rectangle it painted for.
mixin RepaintsWhenMoved on RenderBox {
  static final _all = <RepaintsWhenMoved>{};
  static bool _watching = false;

  Rect? _painted;

  /// Asked to paint again and not yet painted: asked once, so one that is never painted
  /// (offstage, say) cannot keep frames coming.
  bool _asked = false;

  /// Where this is on the screen now, in logical pixels.
  Rect get onScreen => MatrixUtils.transformRect(getTransformTo(null), Offset.zero & size);

  /// Where it was when it last painted.
  @visibleForTesting
  Rect? get paintedRect => _painted;

  /// Says it painted, for [rect] — where it is on screen as it paints.
  void paintedAt(Rect rect) {
    _painted = rect;
    _asked = false;
  }

  /// Whether it has moved since it painted, by more than a quarter of a pixel.
  bool get movedSincePaint {
    final painted = _painted;
    if (painted == null || !attached || !hasSize) return false;
    final now = onScreen;
    return (now.left - painted.left).abs() > 0.25 ||
        (now.top - painted.top).abs() > 0.25 ||
        (now.width - painted.width).abs() > 0.25 ||
        (now.height - painted.height).abs() > 0.25;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _all.add(this);
    if (!_watching) {
      _watching = true;
      SchedulerBinding.instance.addPersistentFrameCallback((_) => repaintMoved());
    }
  }

  @override
  void detach() {
    _all.remove(this);
    _painted = null;
    super.detach();
  }

  /// Marks each that has moved since it painted, and asks for the frame that paints them.
  /// Runs after every frame; returns how many it marked, for the tests.
  static int repaintMoved() {
    var marked = 0;
    for (final surface in _all) {
      if (surface._asked || !surface.movedSincePaint) continue;
      surface._asked = true;
      surface.markNeedsPaint();
      marked++;
    }
    // In the middle of a frame, marking alone asks for nothing: the frame is assumed to be
    // about to paint it. This one already has.
    if (marked > 0) SchedulerBinding.instance.scheduleFrame();
    return marked;
  }
}
