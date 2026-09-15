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
class DayTimeline extends StatelessWidget {
  const DayTimeline({
    required this.day,
    required this.settings,
    required this.blocks,
    this.allocatedMin = 0,
    this.showHours = true,
    this.dense = false,
    super.key,
  });

  final DayCapacity day;
  final CapacitySettings settings;
  final List<FixedBlock> blocks;

  /// Minutes of task work the planner has put on this day.
  final int allocatedMin;

  final bool showHours;

  /// Only the two figures a row in a list of days needs: what is free, and what is
  /// planned. The bar itself shows the blocks and the fragments.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (windowStart, windowEnd) = settings.wakingWindow;
    final span = (windowEnd - windowStart).clamp(1, 1440);

    // Commitments actually occurring on this day, clipped to the waking window.
    final today = <({int start, int end, String title})>[];
    for (final b in blocks) {
      if (!b.recurrence.occursOn(day.date)) continue;
      final start = b.startMin.clamp(windowStart, windowEnd);
      final end = b.endMin.clamp(windowStart, windowEnd);
      if (end > start) today.add((start: start, end: end, title: b.title));
    }
    today.sort((a, b) => a.start.compareTo(b.start));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHours) ...[
          _HourRuler(windowStart: windowStart, windowEnd: windowEnd),
          const SizedBox(height: AppSpace.xs),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double x(int minute) =>
                ((minute - windowStart) / span * width).clamp(0.0, width);

            return SizedBox(
              height: 46,
              child: Stack(
                children: [
                  // The free ground. Everything else is drawn on top of it.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColour.fill,
                        borderRadius: AppRadius.smallAll,
                      ),
                    ),
                  ),

                  // Gaps too short to use. Shown explicitly, because a day with six
                  // free hours in ten-minute slivers is not a day with six hours free,
                  // and the bar would otherwise flatter it.
                  for (final gap in day.gaps)
                    if (gap.lengthMin < settings.minGapMin)
                      Positioned(
                        left: x(gap.startMin),
                        width: (x(gap.endMin) - x(gap.startMin)).clamp(1.0, width),
                        top: 0,
                        bottom: 0,
                        child: const _Hatched(),
                      ),

                  // Commitments.
                  for (final block in today)
                    Positioned(
                      left: x(block.start),
                      width: (x(block.end) - x(block.start)).clamp(2.0, width),
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
  const _HourRuler({required this.windowStart, required this.windowEnd});

  final int windowStart;
  final int windowEnd;

  @override
  Widget build(BuildContext context) {
    final firstHour = (windowStart / 60).ceil();
    final lastHour = (windowEnd / 60).floor();
    final span = windowEnd - windowStart;

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
                  left: ((h * 60 - windowStart) / span * width).clamp(
                    0.0,
                    width - 24,
                  ),
                  child: Text(
                    '${h.toString().padLeft(2, '0')}:00',
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
    final over = allocatedMin > day.usableMin;

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
            colour: over ? AppColour.red : AppColour.accent,
            label: over ? 'Planned — over by' : 'Planned',
            value: over
                ? Format.estimate(allocatedMin - day.usableMin)
                : Format.estimate(allocatedMin),
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
