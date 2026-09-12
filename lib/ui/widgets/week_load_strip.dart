import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/ledger.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../surface.dart';

/// Load against capacity for the next week.
///
/// The point of this strip is that you can see a bad Thursday on Monday. Over capacity it
/// does not merely turn red — it says by how much, because "you are over" is not
/// actionable and "you are two hours over" is.
class WeekLoadStrip extends ConsumerWidget {
  const WeekLoadStrip({this.days = 7, super.key});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacity = ref.watch(dayCapacityProvider);
    final schedule = ref.watch(scheduleProvider);
    if (capacity.isEmpty) return const SizedBox.shrink();

    final window = capacity.take(days).toList();
    final peak = window.fold<int>(0, (best, day) {
      final load = schedule.allocatedOn(day.date);
      final ceiling = day.usableMin > load ? day.usableMin : load;
      return ceiling > best ? ceiling : best;
    });

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Load', style: AppText.caption),
              const SizedBox(width: AppSpace.sm),
              Text(
                'planned against usable time',
                style: AppText.footnote.copyWith(
                  color: AppColour.labelTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in window)
                  Expanded(
                    child: _DayColumn(
                      day: day,
                      allocatedMin: schedule.allocatedOn(day.date),
                      peakMin: peak == 0 ? 1 : peak,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.allocatedMin,
    required this.peakMin,
  });

  final DayCapacity day;
  final int allocatedMin;
  final int peakMin;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final over = allocatedMin > day.usableMin;
    final overflow = allocatedMin - day.usableMin;

    final capacityHeight = day.usableMin / peakMin;
    final loadHeight = allocatedMin / peakMin;

    final today = DateTime.now();
    final isToday =
        day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Overflow amount, above the bar, only when there is one.
          SizedBox(
            height: 14,
            child: over
                ? FittedBox(
                    child: Text(
                      '+${Format.estimate(overflow)}',
                      style: AppText.numeric.copyWith(color: AppColour.red),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Usable capacity: the trough the load sits in.
                    Container(
                      height: (h * capacityHeight).clamp(2.0, h),
                      decoration: const BoxDecoration(
                        color: AppColour.fill,
                        borderRadius: AppRadius.smallAll,
                      ),
                    ),
                    AnimatedContainer(
                      duration: AppMotion.medium,
                      curve: AppMotion.standard,
                      height: (h * loadHeight).clamp(0.0, h),
                      decoration: BoxDecoration(
                        color: over
                            ? AppColour.red
                            : allocatedMin == 0
                            ? Colors.transparent
                            : AppColour.accent,
                        borderRadius: AppRadius.smallAll,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            _letters[day.date.weekday - 1],
            style: AppText.numeric.copyWith(
              color: isToday ? AppColour.label : AppColour.labelTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
