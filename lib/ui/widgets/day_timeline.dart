import 'package:flutter/material.dart';

import '../../capacity/ledger.dart';
import '../../theme/tokens.dart';
import '../format.dart';

/// A day drawn as a bar, so where the time goes is visible rather than inferred.
///
/// The arithmetic was already correct and already explained in words, and words were not
/// enough: "990 awake, minus 240 committed, minus 150 overhead, times 0.65" is a
/// derivation you have to follow. A day you can look at is a day you understand at a
/// glance, which is the actual goal.
///
/// It draws what the ledger counted — blocks as clipped to waking hours, the gaps it threw
/// away — rather than working the day out again for itself. It used to, and the two
/// versions drifted: a block the ledger could not place was dropped without a trace.
class DayTimeline extends StatelessWidget {
  const DayTimeline({
    required this.day,
    required this.settings,
    this.allocatedMin = 0,
    this.showHours = true,
    this.dense = false,
    super.key,
  });

  final DayCapacity day;

  /// The settings [day] was computed with, for where sleep falls.
  final CapacitySettings settings;

  /// Minutes of task work the planner has put on this day.
  final int allocatedMin;

  final bool showHours;

  /// Only the two figures a row in a list of days needs: what is free, and what is
  /// planned. The bar itself shows the blocks and the fragments.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final awake = settings.wakingIntervals;
    // From the first waking minute to the last. With bedtime after midnight that is the
    // whole day, and the sleep inside it is drawn where it falls.
    final axisStart = awake.isEmpty ? 0 : awake.first.$1;
    final axisEnd = awake.isEmpty ? minutesInDay : awake.last.$2;
    final span = axisEnd - axisStart;

    final asleep = [
      for (final (start, end) in settings.sleepIntervals)
        if (start < axisEnd && end > axisStart)
          (start < axisStart ? axisStart : start, end > axisEnd ? axisEnd : end),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHours) ...[
          _HourRuler(axisStart: axisStart, axisEnd: axisEnd),
          const SizedBox(height: AppSpace.xs),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double x(int minute) =>
                ((minute - axisStart) / span * width).clamp(0.0, width);

            return SizedBox(
              height: 46,
              child: Stack(
                children: [
                  // The free ground. Everything else is drawn on top of it.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColour.fill,
                        borderRadius: AppRadius.smallAll,
                      ),
                    ),
                  ),

                  for (final (start, end) in asleep)
                    Positioned(
                      left: x(start),
                      width: (x(end) - x(start)).clamp(1.0, width),
                      top: 0,
                      bottom: 0,
                      child: _Asleep(fromMin: start, toMin: end),
                    ),

                  // Gaps too short to use. Shown explicitly, because a day with six
                  // free hours in ten-minute slivers is not a day with six hours free,
                  // and the bar would otherwise flatter it.
                  for (final gap in day.discardedGaps)
                    Positioned(
                      left: x(gap.startMin),
                      width: (x(gap.endMin) - x(gap.startMin)).clamp(1.0, width),
                      top: 0,
                      bottom: 0,
                      child: const _Hatched(),
                    ),

                  // Commitments.
                  for (final block in day.blocks)
                    Positioned(
                      left: x(block.startMin),
                      width: (x(block.endMin) - x(block.startMin)).clamp(2.0, width),
                      top: 0,
                      bottom: 0,
                      child: _Block(title: block.title),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpace.sm),
        _Legend(day: day, allocatedMin: allocatedMin, dense: dense),
      ],
    );
  }
}

class _HourRuler extends StatelessWidget {
  const _HourRuler({required this.axisStart, required this.axisEnd});

  final int axisStart;
  final int axisEnd;

  @override
  Widget build(BuildContext context) {
    final firstHour = (axisStart / 60).ceil();
    final lastHour = (axisEnd / 60).floor();
    final span = axisEnd - axisStart;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Every third hour: any denser and the labels collide on a narrow window.
        final step = span > 720 ? 3 : 2;

        return SizedBox(
          height: 12,
          child: Stack(
            children: [
              for (var h = firstHour; h <= lastHour; h += step)
                Positioned(
                  left: ((h * 60 - axisStart) / span * width).clamp(
                    0.0,
                    width - 24,
                  ),
                  child: Text(
                    Format.clock(h * 60),
                    style: AppText.numeric.copyWith(
                      fontSize: 9,
                      color: AppColour.labelQuaternary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Sleep inside the drawn day: kept, so the bar keeps its proportions, and dark, because
/// none of it is time to spend.
class _Asleep extends StatelessWidget {
  const _Asleep({required this.fromMin, required this.toMin});

  final int fromMin;
  final int toMin;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Asleep ${Format.clockRange(fromMin, toMin)}',
    child: Container(
      margin: const EdgeInsets.all(1),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColour.base,
        borderRadius: AppRadius.smallAll,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < AppSize.chip
            ? const SizedBox.shrink()
            : const Icon(
                Icons.bedtime_outlined,
                size: 13,
                color: AppColour.labelQuaternary,
              ),
      ),
    ),
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.title});

  final String title;

  /// Narrower than this, a label shows a letter or two, which reads as a glitch rather
  /// than a name. Such a block goes unlabelled, and its name is in the tooltip.
  static const _labelledFrom = 56.0;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: title,
    child: LayoutBuilder(
      builder: (context, constraints) => Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColour.purple.withValues(alpha: 0.38),
          borderRadius: AppRadius.smallAll,
          border: Border.all(color: AppColour.purple.withValues(alpha: 0.5)),
        ),
        child: constraints.maxWidth < _labelledFrom
            ? null
            : Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppText.numeric.copyWith(
                  color: AppColour.label,
                  fontSize: 10,
                ),
              ),
      ),
    ),
  );
}

/// Diagonal hatching for time that exists but cannot be used.
class _Hatched extends StatelessWidget {
  const _Hatched();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HatchPainter(), child: const SizedBox.expand());
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColour.labelQuaternary
      ..strokeWidth = 1;

    // Each stroke leans a bar's height to the right, so unclipped the last ones ran on into
    // the block beside the gap and showed through it.
    canvas.clipRect(Offset.zero & size);

    for (var x = -size.height; x < size.width; x += 5) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => false;
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.day,
    required this.allocatedMin,
    required this.dense,
  });

  final DayCapacity day;
  final int allocatedMin;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spare = day.spareAfter(allocatedMin);

    return Wrap(
      spacing: AppSpace.lg,
      runSpacing: AppSpace.xs,
      children: [
        if (!dense)
          _Swatch(
            colour: AppColour.purple.withValues(alpha: 0.38),
            label: 'Classes and fixed blocks',
            value: Format.estimate(day.committedMin),
          ),
        _Swatch(
          colour: AppColour.fill,
          label: 'Yours to spend',
          value: Format.estimate(day.usableMin),
        ),
        if (!dense && day.discardedGapMin > 0)
          _Swatch(
            colour: AppColour.labelQuaternary,
            label: 'Too fragmented to use',
            value: Format.estimate(day.discardedGapMin),
          ),
        if (allocatedMin > 0)
          _Swatch(
            colour: spare < 0 ? AppColour.red : AppColour.accent,
            label: spare < 0 ? 'Planned — over by' : 'Planned',
            value: Format.estimate(spare < 0 ? -spare : allocatedMin),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colour,
    required this.label,
    required this.value,
  });

  final Color colour;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: colour,
          borderRadius: AppRadius.smallAll,
        ),
      ),
      const SizedBox(width: AppSpace.sm),
      Text(label, style: AppText.footnote),
      const SizedBox(width: AppSpace.xs),
      Text(
        value,
        style: AppText.numeric.copyWith(color: AppColour.label),
      ),
    ],
  );
}
