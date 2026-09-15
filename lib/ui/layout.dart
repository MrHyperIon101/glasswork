import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The two questions layout code keeps asking: how much room is there, and is there a
/// mouse.
abstract final class AppLayout {
  /// A phone-width window.
  static bool compact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoint.compact;

  /// A touch screen. Nothing hovers there, so nothing may be reachable only by hovering,
  /// and whatever a finger has to hit is at least [AppSize.touch] across.
  static bool get touch => switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => true,
    TargetPlatform.linux || TargetPlatform.macOS || TargetPlatform.windows => false,
  };

  /// Space between a screen's content and the edge of the window.
  static double gutter(BuildContext context) =>
      compact(context) ? AppSpace.lg : AppSpace.xxl;
}

/// Picked up at once with a mouse; on a touch screen only after a long press, because there
/// a plain drag has to stay free to scroll whatever the item sits in.
class AdaptiveDraggable<T extends Object> extends StatelessWidget {
  const AdaptiveDraggable({
    required this.data,
    required this.feedback,
    required this.child,
    this.childWhenDragging,
    super.key,
  });

  final T data;
  final Widget feedback;
  final Widget child;
  final Widget? childWhenDragging;

  @override
  Widget build(BuildContext context) => AppLayout.touch
      ? LongPressDraggable<T>(
          data: data,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: feedback,
          childWhenDragging: childWhenDragging,
          child: child,
        )
      : Draggable<T>(
          data: data,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: feedback,
          childWhenDragging: childWhenDragging,
          child: child,
        );
}
