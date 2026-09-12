import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../glass/glass_surface.dart';

/// Shows the pending undo, if there is one.
///
/// Every destructive action in the app offers one of these for five seconds — that is a
/// rule in `docs/architecture.md`, and this widget is the only place it is rendered.
class UndoToast extends ConsumerWidget {
  const UndoToast({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(undoProvider);

    return AnimatedSwitcher(
      duration: AppMotion.quick,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: offer == null
          ? const SizedBox.shrink()
          : GlassSurface.onBackdrop(
              key: ValueKey(offer),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(offer.label, style: AppText.body),
                  const SizedBox(width: AppSpace.xl),
                  GestureDetector(
                    onTap: () => ref.read(undoProvider.notifier).undo(),
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Undo',
                      style: AppText.body.copyWith(
                        color: AppColour.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
