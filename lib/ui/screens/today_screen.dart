import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/day_now.dart';
import '../../capacity/ledger.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/note_text.dart';
import '../../data/repository/capacity_repository.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../block_style.dart';
import '../format.dart';
import '../home_text.dart';
import '../layout.dart';
import '../motion.dart';
import '../surface.dart';
import '../widgets/content_header.dart';
import '../widgets/note_widgets.dart';
import '../widgets/task_row.dart';
import '../widgets/week_load_strip.dart';

/// The Today dashboard: what is on today and how far through it you are, where the day
/// stands right now, the few figures worth a glance, and a place to jot a note.
///
/// Every figure comes from a tested source — [TaskStats], the capacity ledger, [DayNow] —
/// and every sentence from [HomeText]. Nothing here is arithmetic of its own.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  /// Room for the dashboard's two columns.
  static const _twoColumnsFrom = 860.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final wontFit = ref.watch(scheduleProvider).impossible.length;
    final now = DateTime.now();
    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpace.sm : AppSpace.xl,
        gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: HomeText.greeting(now),
            subtitle: stats == null
                ? HomeText.longDate(now)
                : '${HomeText.longDate(now)} · ${HomeText.summary(stats, wontFit: wontFit)}',
            onMenu: onMenu,
          ),
          SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
          Expanded(
            child: stats == null
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.xl),
                      children: [
                        if (constraints.maxWidth >= _twoColumnsFrom)
                          _Wide(stats: stats)
                        else
                          _Narrow(stats: stats),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Arrives a moment after the card before it.
Widget _staggered(int index, Widget child) =>
    FadeSlideIn(delay: Duration(milliseconds: 45 * index), offset: 12, child: child);

class _Wide extends StatelessWidget {
  const _Wide({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _staggered(0, _TodayCard(stats: stats)),
            const SizedBox(height: AppSpace.lg),
            _staggered(3, const WeekLoadStrip()),
          ],
        ),
      ),
      const SizedBox(width: AppSpace.lg),
      Expanded(
        flex: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _staggered(1, const _NowCard()),
            const SizedBox(height: AppSpace.lg),
            _staggered(2, _Tiles(stats: stats)),
            const SizedBox(height: AppSpace.lg),
            _staggered(3, const _NotesCard()),
          ],
        ),
      ),
    ],
  );
}

class _Narrow extends StatelessWidget {
  const _Narrow({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _staggered(0, _TodayCard(stats: stats)),
      const SizedBox(height: AppSpace.md),
      _staggered(1, const _NowCard()),
      const SizedBox(height: AppSpace.md),
      _staggered(2, _Tiles(stats: stats)),
      const SizedBox(height: AppSpace.md),
      _staggered(3, const _NotesCard()),
      const SizedBox(height: AppSpace.md),
      _staggered(4, const WeekLoadStrip()),
    ],
  );
}

/// A dashboard card: the surface, a faint wash of [glow] from its corner, and, where it
/// leads somewhere, a response to being hovered and pressed.
class _Card extends StatefulWidget {
  const _Card({required this.child, this.glow, this.onTap});

  final Widget child;
  final Color? glow;
  final VoidCallback? onTap;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.glow;
    final card = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.quick),
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: _hovered ? AppColour.elevated : AppColour.surface,
        borderRadius: AppRadius.largeAll,
        border: Border.all(color: AppColour.separator.withValues(alpha: 0.4), width: 0.5),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.largeAll,
          // A hint of the card's colour, gathered in its top corner and gone by the middle.
          gradient: glow == null
              ? null
              : RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.1,
                  colors: [glow.withValues(alpha: 0.075), glow.withValues(alpha: 0)],
                ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppLayout.compact(context) ? AppSpace.lg : AppSpace.xl),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Pressable(onTap: widget.onTap, pressedScale: 0.985, child: card),
    );
  }
}

/// An icon on a tinted disc, the way a settings row or a widget heading shows one.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.colour});

  final IconData icon;
  final Color colour;

  static const _size = 28.0;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.of(context, AppMotion.medium),
    width: _size,
    height: _size,
    decoration: BoxDecoration(color: colour.withValues(alpha: 0.18), shape: BoxShape.circle),
    child: Icon(icon, size: 16, color: colour),
  );
}

// --- today ----------------------------------------------------------------------------

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final items = [...stats.overdue, ...stats.dueToday];
    final total = stats.todayTotal + stats.completedToday;
    final progress = total == 0 ? 0.0 : stats.completedToday / total;

    return _Card(
      glow: AppColour.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Ring(
                progress: progress,
                size: _Ring.large,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCount(stats.todayTotal, style: AppText.metricSmall),
                    Text('to do', style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today', style: AppText.title),
                    const SizedBox(height: 2),
                    Text(HomeText.progress(stats), style: AppText.callout),
                    if (stats.estimatedMinutesToday > 0 || stats.untimedToday > 0) ...[
                      const SizedBox(height: AppSpace.sm),
                      _EstimatePill(stats: stats),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const AppDivider(),
          const SizedBox(height: AppSpace.xs),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            child: items.isEmpty
                ? _ClearState(key: const ValueKey('clear'), completedToday: stats.completedToday)
                : AnimatedItems<Task>(
                    key: const ValueKey('tasks'),
                    items: items,
                    keyOf: (task) => task.id,
                    itemBuilder: (context, task) => TaskRow(
                      key: ValueKey(task.id),
                      task: task,
                      onToggle: () => scope?.tasks.setDone(
                        task.id,
                        done: task.status != TaskStatus.done,
                      ),
                      onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
                      onDelete: () async {
                        if (scope == null) return;
                        await scope.tasks.softDelete(task.id);
                        ref
                            .read(undoProvider.notifier)
                            .offer('Deleted "${task.title}"', () => scope.tasks.restore(task.id));
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A ring that fills as today's work is done, the way an activity ring closes.
class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.size, required this.child});

  final double progress;
  final double size;
  final Widget child;

  static const large = 84.0;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: progress.clamp(0, 1)),
    duration: AppMotion.of(context, AppMotion.slow * 2),
    curve: AppMotion.standard,
    builder: (context, t, child) => CustomPaint(
      painter: _RingPainter(t),
      child: SizedBox.square(dimension: size, child: Center(child: child)),
    ),
    child: child,
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColour.green.withValues(alpha: 0.16),
    );
    if (t <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColour.green, AppColour.mint, AppColour.green],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

class _EstimatePill extends StatelessWidget {
  const _EstimatePill({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
    decoration: const BoxDecoration(color: AppColour.fill, borderRadius: AppRadius.roundAll),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, size: 12, color: AppColour.labelSecondary),
        const SizedBox(width: AppSpace.xs),
        Text(
          Format.estimate(stats.estimatedMinutesToday),
          style: AppText.numeric.copyWith(color: AppColour.label),
        ),
        // A total that silently ignores unestimated work would be a lie, so it says so.
        if (stats.untimedToday > 0)
          Text(
            '  + ${stats.untimedToday} untimed',
            style: AppText.numeric.copyWith(color: AppColour.labelTertiary),
          ),
      ],
    ),
  );
}

class _ClearState extends StatelessWidget {
  const _ClearState({required this.completedToday, super.key});

  final int completedToday;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
    child: Column(
      children: [
        const AnimatedCheck(done: true, size: 34),
        const SizedBox(height: AppSpace.md),
        Text(
          completedToday > 0 ? 'Today is clear. $completedToday done.' : 'Nothing due today.',
          style: AppText.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Add something, or take the afternoon.',
          style: AppText.footnote,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// --- right now ------------------------------------------------------------------------

class _NowCard extends ConsumerStatefulWidget {
  const _NowCard();

  @override
  ConsumerState<_NowCard> createState() => _NowCardState();
}

class _NowCardState extends ConsumerState<_NowCard> {
  /// Keeps "now" true while nothing else changes.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(dayCapacityProvider);
    if (days.isEmpty) return const SizedBox.shrink();

    final today = days.first;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final dayNow = DayNow.of(today, nowMin);
    final settings = CapacityMapping.settings(ref.watch(capacityProfileProvider).value);
    final text = HomeText.now(dayNow, bedtimeMin: settings.sleepOn(now.weekday).bedtimeMin);
    final colours = ref.watch(blockColoursProvider);
    final colour = switch (dayNow.current) {
      final block? => BlockStyle.colourIn(colours, block.title),
      null when dayNow.dayDone || dayNow.beforeWaking => AppColour.indigo,
      null => AppColour.green,
    };

    return _Card(
      glow: colour,
      onTap: () => ref.read(destinationProvider.notifier).go(const CapacityDestination()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Badge(
                icon: dayNow.current != null
                    ? Icons.event_available_rounded
                    : dayNow.dayDone || dayNow.beforeWaking
                    ? Icons.bedtime_rounded
                    : Icons.self_improvement_rounded,
                colour: colour,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text('Right now', style: AppText.caption)),
              Text(Format.clock(nowMin), style: AppText.numeric),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey(text),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.title, style: AppText.title3, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(text.detail, style: AppText.callout, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _DayStrip(day: today, nowMin: nowMin, colours: colours),
        ],
      ),
    );
  }
}

/// The waking day as a strip: blocks in their colours, and a marker at now.
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.day, required this.nowMin, required this.colours});

  final DayCapacity day;
  final int nowMin;
  final Map<String, Color> colours;

  static const _height = 12.0;

  @override
  Widget build(BuildContext context) {
    final start = day.awake.isEmpty ? 0 : day.awake.first.$1;
    final end = day.awake.isEmpty ? minutesInDay : day.awake.last.$2;
    final span = math.max(1, end - start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double x(int minute) => ((minute - start) / span * width).clamp(0.0, width);

            return SizedBox(
              height: _height + AppSpace.xs * 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: AppSpace.xs,
                    height: _height,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: AppColour.fill, borderRadius: AppRadius.roundAll),
                    ),
                  ),
                  // Time already gone this day, dimmed.
                  Positioned(
                    left: 0,
                    top: AppSpace.xs,
                    height: _height,
                    width: x(nowMin),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: AppColour.fill, borderRadius: AppRadius.roundAll),
                    ),
                  ),
                  for (final block in day.blocks)
                    Positioned(
                      left: x(block.startMin),
                      width: math.max(3, x(block.endMin) - x(block.startMin)),
                      top: AppSpace.xs,
                      height: _height,
                      child: Tooltip(
                        message:
                            '${block.title} · ${Format.clockRange(block.startMin, block.endMin)}',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: BlockStyle.colourIn(colours, block.title).withValues(
                              alpha: block.endMin <= nowMin ? 0.35 : 0.85,
                            ),
                            borderRadius: AppRadius.roundAll,
                          ),
                        ),
                      ),
                    ),
                  if (nowMin >= start && nowMin <= end)
                    Positioned(
                      left: x(nowMin) - 1,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColour.label,
                          borderRadius: AppRadius.roundAll,
                          boxShadow: [BoxShadow(color: Color(0x66FFFFFF), blurRadius: 6)],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpace.xs),
        Row(
          children: [
            Text(Format.clock(start), style: AppText.numeric.copyWith(color: AppColour.labelTertiary)),
            const Spacer(),
            Text(Format.clock(end), style: AppText.numeric.copyWith(color: AppColour.labelTertiary)),
          ],
        ),
      ],
    );
  }
}

// --- figures --------------------------------------------------------------------------

class _Tiles extends ConsumerWidget {
  const _Tiles({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final impossible = schedule.impossible;
    final now = DateTime.now();
    void go(Destination destination) => ref.read(destinationProvider.notifier).go(destination);

    final worst = stats.overdue.firstOrNull;
    final reminder = stats.nextReminder;

    final tiles = [
      _Tile(
        icon: Icons.error_outline_rounded,
        colour: worst == null ? AppColour.grey : AppColour.red,
        label: 'Overdue',
        value: AnimatedCount(stats.overdue.length, style: AppText.metricSmall),
        caption: worst == null ? 'Nothing late' : Format.due(worst, now)?.label ?? '',
        onTap: () => go(const AllDestination()),
      ),
      _Tile(
        icon: Icons.hourglass_bottom_rounded,
        colour: impossible.isEmpty ? AppColour.grey : AppColour.orange,
        label: "Won't fit",
        value: AnimatedCount(impossible.length, style: AppText.metricSmall),
        caption: switch ((impossible.length, schedule.tight.length)) {
          (0, 0) => 'Everything fits',
          (0, final t) => '$t with no slack',
          _ => impossible.first.task.title,
        },
        onTap: () => go(const CapacityDestination()),
      ),
      _Tile(
        icon: Icons.task_alt_rounded,
        colour: AppColour.green,
        label: 'Done this week',
        value: AnimatedCount(stats.completedThisWeek, style: AppText.metricSmall),
        trailing: _WeekBars(counts: stats.doneByDay),
        caption: stats.completedToday == 0 ? 'None yet today' : '${stats.completedToday} today',
        onTap: () => go(const DoneDestination()),
      ),
      _Tile(
        icon: Icons.notifications_active_rounded,
        colour: reminder == null ? AppColour.grey : AppColour.accent,
        label: 'Next reminder',
        value: Text(
          reminder == null ? 'None' : Format.reminderTime(reminder.remindAt!, now),
          style: AppText.title3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        caption: reminder?.title ?? 'Nothing coming up',
        onTap: reminder == null
            ? null
            : () => ref.read(openTaskProvider.notifier).open(reminder.id),
      ),
    ];

    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpace.md),
          Expanded(child: b),
        ],
      ),
    );

    return Column(
      children: [
        row(tiles[0], tiles[1]),
        const SizedBox(height: AppSpace.md),
        row(tiles[2], tiles[3]),
      ],
    );
  }
}

/// One figure worth a glance: what it is, the figure, and a line of what it means.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.colour,
    required this.label,
    required this.value,
    required this.caption,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color colour;
  final String label;
  final Widget value;
  final String caption;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Card(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Badge(icon: icon, colour: colour),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpace.md),
        value,
        const SizedBox(height: 2),
        Text(label, style: AppText.footnote.copyWith(color: AppColour.label)),
        Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.footnote),
      ],
    ),
  );
}

/// A week of completions as seven small bars, today's the brightest.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.counts});

  final List<int> counts;

  static const _barWidth = 4.0;
  static const _tallest = 24.0;
  static const _shortest = 3.0;

  @override
  Widget build(BuildContext context) {
    final peak = counts.fold<int>(1, math.max);
    return SizedBox(
      height: _tallest,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, count) in counts.indexed) ...[
            if (i > 0) const SizedBox(width: 3),
            TweenAnimationBuilder<double>(
              tween: Tween(end: count == 0 ? _shortest : math.max(_shortest, _tallest * count / peak)),
              duration: AppMotion.of(context, AppMotion.slow),
              curve: AppMotion.enter,
              builder: (context, height, _) => Container(
                width: _barWidth,
                height: height,
                decoration: BoxDecoration(
                  color: count == 0
                      ? AppColour.fill
                      : AppColour.green.withValues(alpha: i == counts.length - 1 ? 1 : 0.45),
                  borderRadius: AppRadius.roundAll,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- notes ----------------------------------------------------------------------------

class _NotesCard extends ConsumerWidget {
  const _NotesCard();

  /// Recent notes shown under the field; the rest are a tap away.
  static const _shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider).value ?? const <Note>[];

    return _Card(
      glow: AppColour.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _Badge(icon: Icons.sticky_note_2_rounded, colour: AppColour.yellow),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text('Notes', style: AppText.caption)),
              _TextLink(
                label: notes.isEmpty ? 'Open' : 'All ${notes.length}',
                onTap: () => ref.read(destinationProvider.notifier).go(const NotesDestination()),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          const QuickNoteField(),
          AnimatedItems<Note>(
            items: notes.take(_shown).toList(),
            keyOf: (note) => note.id,
            itemBuilder: (context, note) => _NoteLine(note: note),
          ),
        ],
      ),
    );
  }
}

class _NoteLine extends ConsumerStatefulWidget {
  const _NoteLine({required this.note});

  final Note note;

  @override
  ConsumerState<_NoteLine> createState() => _NoteLineState();
}

class _NoteLineState extends ConsumerState<_NoteLine> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Pressable(
          pressedScale: 0.98,
          onTap: () => ref.read(openNoteProvider.notifier).edit(note),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.quick),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
            decoration: BoxDecoration(
              color: _hovered ? AppColour.fill : null,
              borderRadius: AppRadius.mediumAll,
            ),
            child: Row(
              children: [
                Icon(
                  note.pinned ? Icons.push_pin_rounded : Icons.notes_rounded,
                  size: 14,
                  color: note.pinned ? AppColour.yellow : AppColour.labelTertiary,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    NoteText.heading(note),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.callout.copyWith(color: AppColour.label),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  NoteText.when(NoteText.editedAt(note), DateTime.now()),
                  style: AppText.numeric.copyWith(color: AppColour.labelTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Pressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppLayout.touch ? AppSpace.sm : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppText.footnote.copyWith(color: AppColour.accent)),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColour.accent),
          ],
        ),
      ),
    ),
  );
}
