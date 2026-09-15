import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../surface.dart';

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
          : AppSurface(
              key: ValueKey(offer),
              colour: AppColour.elevated,
              radius: AppRadius.round,
              border: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A long task title is cut short rather than pushing Undo off the edge,
                  // which is the one part of this that has to stay in reach.
                  Flexible(
                    child: Text(
                      offer.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.callout.copyWith(color: AppColour.label),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xl),
                  GestureDetector(
                    onTap: () => ref.read(undoProvider.notifier).undo(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.touch ? AppSpace.sm : 0,
                      ),
                      child: Text(
                        'Undo',
                        style: AppText.headline.copyWith(color: AppColour.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
