import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../layout.dart';
import 'typed_value.dart';

/// A labelled value with a step either side, which can also be typed.
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    required this.label,
    required this.text,
    required this.onStep,
    required this.onSubmit,
    this.onEdit,
    this.detail,
    this.explanation,
    this.effect,
    this.error = false,
    this.keyboardType = TextInputType.text,
    super.key,
  });

  final String label;

  /// A short line under the label, such as how long a block is.
  final String? detail;

  /// What the value means, under the whole row.
  final String? explanation;

  /// What changing it would do, under the explanation.
  final String? effect;

  /// The value as it reads.
  final String text;

  /// Called with -1 or 1.
  final void Function(int direction) onStep;

  /// See [TypedValue.onSubmit].
  final bool Function(String text) onSubmit;

  /// See [TypedValue.onEdit].
  final ValueChanged<String>? onEdit;

  final bool error;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppText.body),
                  if (detail case final d?) Text(d, style: AppText.footnote),
                ],
              ),
            ),
            _Step(icon: Icons.remove_rounded, onTap: () => onStep(-1)),
            const SizedBox(width: AppSpace.xs),
            TypedValue(
              text: text,
              onSubmit: onSubmit,
              onEdit: onEdit,
              error: error,
              keyboardType: keyboardType,
            ),
            const SizedBox(width: AppSpace.xs),
            _Step(icon: Icons.add_rounded, onTap: () => onStep(1)),
          ],
        ),
        if (explanation case final text?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(text, style: AppText.footnote),
          ),
        if (effect case final text?)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: AppText.footnote.copyWith(color: AppColour.label),
            ),
          ),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A finger gets a bigger target than a pointer needs, level with the typed value.
    final size = AppLayout.touch ? AppSize.touch - AppSpace.sm : AppSize.chip;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Ends any typing first, so the field shows the stepped value afterwards.
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColour.fill,
            borderRadius: AppRadius.smallAll,
          ),
          child: Icon(icon, size: 14, color: AppColour.labelSecondary),
        ),
      ),
    );
  }
}
