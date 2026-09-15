import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Seven day squares, Monday first, any of which can be on.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({required this.selected, required this.onToggle, super.key});

  /// `DateTime.monday` to `DateTime.sunday`.
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // Squares sharing the width, so all seven fit a phone's dialog, and no bigger than a
    // finger needs where there is more room than that.
    constraints: const BoxConstraints(
      maxWidth: 7 * AppSize.touch + 6 * AppSpace.xs,
    ),
    child: Row(
      children: [
        for (var day = 1; day <= 7; day++) ...[
          // Gaps between squares rather than padding on each, so all seven are one size.
          if (day > 1) const SizedBox(width: AppSpace.xs),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onToggle(day),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: AppMotion.quick,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected.contains(day)
                          ? AppColour.accent
                          : AppColour.fill,
                      borderRadius: AppRadius.smallAll,
                    ),
                    child: Text(
                      _letters[day - 1],
                      style: AppText.numeric.copyWith(
                        color: selected.contains(day)
                            ? AppColour.label
                            : AppColour.labelSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
