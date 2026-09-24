import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/completed.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../motion.dart';

/// The heading finished work folds under, and how much of it there is.
///
/// The same header in the project's list, on the board's completed column and under the
/// smart views, so "Completed · 12" behaves the same wherever it turns up — and stays
/// folded, on this device, until it is opened again.
class CompletedHeader extends ConsumerWidget {
  const CompletedHeader({
    required this.ownerId,
    required this.count,
    this.dense = false,
    super.key,
  });

  /// The project this belongs to, or [CollapsedCompleted.smartViews].
  final String ownerId;

  final int count;

  /// Tighter, for a board column where the width is the scarce thing.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(completedCollapsedProvider(ownerId));

    return Pressable(
      onTap: () {
        final scope = ref.read(appScopeProvider).value;
        scope?.preferences.setCompletedCollapsed(ownerId, collapsed: !collapsed);
      },
      pressedScale: 0.995,
      child: Tooltip(
        message: collapsed ? 'Show completed' : 'Hide completed',
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            dense ? AppSpace.sm : AppSpace.md,
            dense ? AppSpace.xs : AppSpace.lg,
            AppSpace.sm,
            AppSpace.sm,
          ),
          child: Row(
            children: [
              AnimatedRotation(
                key: const ValueKey('completed-chevron'),
                turns: collapsed ? -0.25 : 0,
                duration: AppMotion.of(context, AppMotion.quick),
                curve: AppMotion.standard,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColour.labelTertiary,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Text('Completed', style: AppText.caption),
              const SizedBox(width: AppSpace.sm),
              AnimatedCount.builder(
                count,
                builder: (context, text) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColour.fill,
                    borderRadius: AppRadius.smallAll,
                  ),
                  child: Text(
                    text,
                    style: AppText.numeric.copyWith(
                      color: AppColour.labelSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
