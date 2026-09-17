import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/ledger.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';

/// Load against capacity for the next week, a bar for each day.
///
/// The point of these bars is that you can see a bad Thursday on Monday. Over capacity a
/// bar does not merely turn red — it says by how much, because "you are over" is not
/// actionable and "you are two hours over" is.
class WeekLoadBars extends ConsumerWidget {
  const WeekLoadBars({this.days = 7, this.barHeight, super.key});

  final int days;

  /// The height of the tallest bar, or null for the bars to take whatever height they are
  /// given.
  final double? barHeight;

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

    return Row(
      crossAxisAlignment: barHeight == null ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
      children: [
        for (final day in window)
          Expanded(
            child: _DayColumn(
              day: day,
              allocatedMin: schedule.allocatedOn(day.date),
              peakMin: peak == 0 ? 1 : peak,
              barHeight: barHeight,
            ),
          ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.allocatedMin,
    required this.peakMin,
    required this.barHeight,
  });

  final DayCapacity day;
  final int allocatedMin;
  final int peakMin;
  final double? barHeight;

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

    // Scaled down, never wrapped, where a phone's seven columns are narrower than a figure.
    Widget figure(String text, Color colour) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, style: AppText.numeric.copyWith(color: colour)),
    );

    Widget bars(double height) => Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Usable capacity: the trough the load sits in.
        Container(
          height: (height * capacityHeight).clamp(2.0, height),
          decoration: const BoxDecoration(
            color: AppColour.fill,
            borderRadius: AppRadius.smallAll,
          ),
        ),
        AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.standard,
          height: (height * loadHeight).clamp(0.0, height),
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
    final fixed = barHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: fixed == null ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Overflow amount, above the bar, only when there is one.
          SizedBox(
            height: 14,
            child: over ? figure('+${Format.hoursShort(overflow)}', AppColour.red) : null,
          ),
          if (fixed == null)
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) => bars(constraints.maxHeight)),
            )
          else
            SizedBox(height: fixed, child: bars(fixed)),
          const SizedBox(height: AppSpace.xs),
          Text(
            _letters[day.date.weekday - 1],
            style: AppText.numeric.copyWith(
              color: isToday ? AppColour.label : AppColour.labelTertiary,
            ),
          ),
          // What is planned that day, so a tall bar can be read without the Time budget.
          figure(
            allocatedMin == 0 ? '–' : Format.hoursShort(allocatedMin),
            AppColour.labelTertiary,
          ),
        ],
      ),
    );
  }
}
