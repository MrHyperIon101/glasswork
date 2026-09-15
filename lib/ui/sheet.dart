import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'layout.dart';
import 'motion.dart';
import 'surface.dart';

/// A sheet over the content: its scrim, its material, and where it sits.
///
/// Centred with a width cap on a desktop. On a phone it rises from the bottom and spans the
/// width: the thumb is down there, and the keyboard pushes it up from there anyway.
class ModalSheet extends StatelessWidget {
  const ModalSheet({
    required this.onClose,
    required this.child,
    this.maxWidth = 640,
    this.maxHeight = 720,
    this.alignment = const Alignment(0, -0.1),
    this.scrim = 0.62,
    super.key,
  });

  final VoidCallback onClose;
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  /// Where a centred sheet sits. Unused on a phone.
  final Alignment alignment;

  /// How dark the layer over the content gets.
  final double scrim;

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.compact(context);

    return Stack(
      children: [
        // Fades in on its own, so the sheet's spring is not muddied by it.
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.quick,
            builder: (context, t, _) => GestureDetector(
              onTap: onClose,
              child: ColoredBox(color: Color.fromRGBO(0, 0, 0, scrim * t)),
            ),
          ),
        ),
        if (compact)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.sm,
                AppSpace.huge,
                AppSpace.sm,
                AppSpace.sm,
              ),
              child: SpringIn(
                from: 1,
                slide: AppSpace.huge,
                child: VibrancyMaterial.sheet(
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          )
        else
          Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: SpringIn(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  ),
                  child: VibrancyMaterial.sheet(child: child),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
