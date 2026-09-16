import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'field_controls.dart';
import '../motion.dart';

/// Confirmation for a destructive action that undo cannot fully cover.
///
/// Deliberately rare. Most destructive things in this app just happen and offer undo for
/// five seconds, which is less friction and more forgiving. A dialog is only worth it
/// when the action cascades — deleting a project takes its tasks — because there the
/// cost of a mistaken tap is high enough to be worth a sentence first.
///
/// The [detail] must say what will actually happen, including counts. A confirmation
/// that hides its consequences is worse than none: it trains you to click through.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String detail,
  required String confirmLabel,
}) async {
  final result = await showAppDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title3),
              const SizedBox(height: AppSpace.sm),
              Text(
                detail,
                style: AppText.callout.copyWith(
                  color: AppColour.labelSecondary,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GhostButton(
                    label: 'Keep it',
                    onTap: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _Destructive(
                    label: confirmLabel,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

class _Destructive extends StatefulWidget {
  const _Destructive({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_Destructive> createState() => _DestructiveState();
}

class _DestructiveState extends State<_Destructive> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColour.red
              : AppColour.red.withValues(alpha: 0.88),
          borderRadius: AppRadius.mediumAll,
        ),
        child: Text(
          widget.label,
          style: AppText.headline.copyWith(color: Colors.white),
        ),
      ),
    ),
  );
}
