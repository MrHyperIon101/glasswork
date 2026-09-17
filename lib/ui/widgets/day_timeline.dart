import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/ledger.dart';
import '../../capacity/task_slot.dart';
import '../../theme/tokens.dart';
import '../block_style.dart';
import '../format.dart';
import '../layout.dart';

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
    this.allocatedMin = 0,
    this.tasks = const [],
    this.showHours = true,
    this.dense = false,
    super.key,
  });

  final DayCapacity day;

  /// Tasks given a time on this day, drawn where they fall.
  final List<TaskSlot> tasks;

  /// Minutes of task work the planner has put on this day.
  final int allocatedMin;

  final bool showHours;

  /// Only the two figures a row in a list of days needs: what is free, and what is
  /// planned. The bar itself shows the blocks and the fragments.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final awake = day.awake;
    // From the first waking minute to the last. With bedtime after midnight that is the
    // whole day, and the sleep inside it is drawn where it falls.
    final axisStart = awake.isEmpty ? 0 : awake.first.$1;
    final axisEnd = awake.isEmpty ? minutesInDay : awake.last.$2;
    final span = axisEnd - axisStart;

    final asleep = [
      for (final (start, end) in day.asleep)
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

                  // Commitments, each in its own colour.
                  for (final block in day.blocks)
                    Positioned(
                      left: x(block.startMin),
                      width: (x(block.endMin) - x(block.startMin)).clamp(2.0, width),
                      top: 0,
                      bottom: 0,
                      child: _Block(block: block),
                    ),

                  // Tasks given a time, over whatever they were put on, so a clash shows.
                  for (final task in tasks)
                    Positioned(
                      left: x(task.startMin),
                      width: (x(task.endMin) - x(task.startMin)).clamp(2.0, width),
                      top: AppSpace.xs,
                      bottom: AppSpace.xs,
                      child: _TaskBlock(task: task),
                    ),
                ],
              ),
            );
          },
        ),
        // A phone's bar is too narrow for names, so the blocks are named beneath it, each
        // with the colour and short name it wears in the bar.
        if (AppLayout.compact(context) && (day.blocks.isNotEmpty || tasks.isNotEmpty)) ...[
          const SizedBox(height: AppSpace.sm),
          _BlockKey(blocks: day.blocks, tasks: tasks, dense: dense),
        ],
        const SizedBox(height: AppSpace.sm),
        _Legend(day: day, allocatedMin: allocatedMin, dense: dense),
      ],
    );
  }
}

/// The day's blocks by name: colour, short name, full name and when.
class _BlockKey extends ConsumerWidget {
  const _BlockKey({required this.blocks, required this.tasks, required this.dense});

  final List<BlockSpan> blocks;
  final List<TaskSlot> tasks;

  /// A row in a week: short names and times only, which is enough to match the bar.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = ref.watch(blockColoursProvider);
    // The same block can reach two waking stretches; it is named once.
    final seen = <String>{};
    final unique = [
      for (final block in blocks)
        if (seen.add('${block.title}|${block.startMin}')) block,
    ];

    if (dense) {
      return Wrap(
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        children: [
          for (final block in unique)
            _Tag(
              colour: BlockStyle.colourIn(colours, block.title),
              text: '${BlockStyle.abbreviate(block.title)} ${Format.clock(block.startMin)}',
            ),
          for (final task in tasks)
            _Tag(
              colour: AppColour.label,
              text: '${BlockStyle.abbreviate(task.title)} ${Format.clock(task.startMin)}',
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in unique)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Row(
              children: [
                _Tag(
                  colour: BlockStyle.colourIn(colours, block.title),
                  text: BlockStyle.abbreviate(block.title),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.callout.copyWith(color: AppColour.label),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  Format.clockRange(block.startMin, block.endMin),
                  style: AppText.numeric,
                ),
              ],
            ),
          ),
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Row(
              children: [
                _Tag(colour: AppColour.label, text: BlockStyle.abbreviate(task.title)),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.callout.copyWith(
                      color: task.done ? AppColour.labelTertiary : AppColour.label,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(Format.clockRange(task.startMin, task.endMin), style: AppText.numeric),
              ],
            ),
          ),
      ],
    );
  }
}

/// A short name on its block's colour.
class _Tag extends StatelessWidget {
  const _Tag({required this.colour, required this.text});

  final Color colour;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.24),
      borderRadius: AppRadius.smallAll,
      border: Border.all(color: colour.withValues(alpha: 0.55), width: 0.5),
    ),
    child: Text(
      text,
      style: AppText.numeric.copyWith(color: AppColour.label, fontSize: 11),
    ),
  );
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

class _Block extends ConsumerWidget {
  const _Block({required this.block});

  final BlockSpan block;

  /// Wide enough for its whole name, and for its short name. Narrower than that, a block
  /// is only its colour, and the key beneath the bar or the tooltip names it.
  static const _namedFrom = 64.0;
  static const _shortNamedFrom = 26.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colour = BlockStyle.colourIn(ref.watch(blockColoursProvider), block.title);
    return Tooltip(
      message: '${block.title} · ${Format.clockRange(block.startMin, block.endMin)}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final label = width >= _namedFrom
              ? block.title
              : width >= _shortNamedFrom
              ? BlockStyle.abbreviate(block.title)
              : null;

          return Container(
            margin: const EdgeInsets.all(1),
            padding: EdgeInsets.symmetric(horizontal: width >= _namedFrom ? AppSpace.sm : 2),
            alignment: width >= _namedFrom ? Alignment.centerLeft : Alignment.center,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.4),
              borderRadius: AppRadius.smallAll,
              border: Border.all(color: colour.withValues(alpha: 0.65)),
            ),
            child: label == null
                ? null
                // A short name gives a little rather than losing its last letters.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: AppText.numeric.copyWith(
                        color: AppColour.label,
                        fontSize: 10,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// A task given a time: a white pill, a colour no timetable block wears, so it reads as
/// something you put there rather than something fixed; faded once it is done.
class _TaskBlock extends StatelessWidget {
  const _TaskBlock({required this.task});

  final TaskSlot task;

  static const _namedFrom = 64.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${task.title} · ${Format.clockRange(task.startMin, task.endMin)}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final named = constraints.maxWidth >= _namedFrom;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: EdgeInsets.symmetric(horizontal: named ? AppSpace.xs : 0),
            alignment: named ? Alignment.centerLeft : Alignment.center,
            decoration: BoxDecoration(
              color: AppColour.label.withValues(alpha: task.done ? 0.3 : 0.9),
              borderRadius: AppRadius.smallAll,
            ),
            child: constraints.maxWidth < AppSize.chip
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.done ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        size: 10,
                        color: AppColour.base,
                      ),
                      if (named) ...[
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppText.numeric.copyWith(
                              color: AppColour.base,
                              fontSize: 10,
                              fontVariations: const [FontVariation('wght', 600)],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
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
            colour: AppColour.labelSecondary,
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
