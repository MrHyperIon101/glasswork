import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/day_agenda.dart';
import '../../capacity/day_now.dart';
import '../../capacity/ledger.dart';
import '../../capacity/task_slot.dart';
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

/// The Today dashboard: the few figures worth a glance, what is due today and coming up,
/// the day's timetable against now, the week's load, and a place to jot a note.
///
/// Every figure comes from a tested source — [TaskStats], the capacity ledger, [DayNow],
/// [DayAgenda] — and every sentence from [HomeText]. Nothing here is arithmetic of its own.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final wontFit = ref.watch(scheduleProvider).impossible.length;
    final now = DateTime.now();
    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);
    final bottom = compact ? AppSpace.xxl : AppSpace.xl;

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
                    builder: (context, constraints) {
                      // Larger text needs more room for the same shape, across and down.
                      final textScale = MediaQuery.textScalerOf(context).scale(100) / 100;
                      final shape = _Shape.at(constraints.maxWidth / textScale);
                      final fill =
                          constraints.maxHeight - bottom >= shape.fillFrom * textScale;

                      Widget dashboard(bool fill) => _Dashboard(
                        stats: stats,
                        shape: shape,
                        width: constraints.maxWidth,
                        fill: fill,
                      );

                      // A window tall enough is shared out between the cards, and whatever is
                      // longer than its card scrolls inside it. Otherwise the page scrolls.
                      return fill
                          ? Padding(
                              padding: EdgeInsets.only(bottom: bottom),
                              child: dashboard(true),
                            )
                          : ListView(
                              padding: EdgeInsets.only(bottom: bottom),
                              children: [dashboard(false)],
                            );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// How the dashboard is laid out at a width.
enum _Shape {
  /// One column, and the page scrolls.
  narrow(double.infinity),

  /// The figures in a row; under them today, and beside it the day above the week and notes.
  medium(720),

  /// The figures in a row; under them today across two of their widths, then the day, then
  /// the week above notes.
  wide(640);

  const _Shape(this.fillFrom);

  /// The least height in which the cards can share the window instead of scrolling it: room
  /// for every card's fixed part, a few rows of each list, and week bars tall enough to
  /// compare. Any shorter and the bars flatten into slivers.
  final double fillFrom;

  static _Shape at(double width) => width >= 1200
      ? wide
      : width >= 860
      ? medium
      : narrow;
}

/// Arrives a moment after the card before it.
Widget _staggered(int index, Widget child) =>
    FadeSlideIn(delay: Duration(milliseconds: 45 * index), offset: 12, child: child);

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.stats,
    required this.shape,
    required this.width,
    required this.fill,
  });

  final TaskStats stats;
  final _Shape shape;
  final double width;

  /// Whether the cards share a height of their own, rather than each being as tall as it
  /// needs.
  final bool fill;

  static const _gap = AppSpace.lg;

  @override
  Widget build(BuildContext context) {
    Widget grow(Widget child, {int flex = 1}) =>
        fill ? Expanded(flex: flex, child: child) : child;
    const gap = SizedBox.square(dimension: _gap);

    if (shape == _Shape.narrow) {
      const between = SizedBox(height: AppSpace.md);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _staggered(0, _TodayCard(stats: stats, fill: false)),
          between,
          _staggered(1, const _DayCard(fill: false)),
          between,
          _staggered(2, _Tiles(stats: stats, perRow: 2)),
          between,
          _staggered(3, const _NotesCard(fill: false)),
          between,
          _staggered(4, const _WeekCard(fill: false)),
        ],
      );
    }

    // Every column lines up with the edges of the four figures above it.
    final tile = (width - 3 * _gap) / 4;
    final today = SizedBox(
      width: 2 * tile + _gap,
      child: _staggered(1, _TodayCard(stats: stats, fill: fill)),
    );
    final day = _staggered(2, _DayCard(fill: fill));
    final week = _staggered(3, _WeekCard(fill: fill));
    final notes = _staggered(4, _NotesCard(fill: fill));

    final columns = switch (shape) {
      _Shape.medium => [
        today,
        gap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: fill
                ? [
                    Expanded(flex: 11, child: day),
                    gap,
                    // The week and notes side by side, each a figure wide.
                    Expanded(
                      flex: 6,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: tile, child: week),
                          gap,
                          Expanded(child: notes),
                        ],
                      ),
                    ),
                  ]
                : [day, gap, notes, gap, week],
          ),
        ),
      ],
      _ => [
        today,
        gap,
        SizedBox(width: tile, child: day),
        gap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [grow(week, flex: 2), gap, grow(notes, flex: 3)],
          ),
        ),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _staggered(0, _Tiles(stats: stats, perRow: 4)),
        gap,
        grow(
          Row(
            crossAxisAlignment: fill ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
            children: columns,
          ),
        ),
      ],
    );
  }
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

/// A card's heading: its badge and name, and whatever stands at the far end.
class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.icon,
    required this.colour,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final Color colour;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Badge(icon: icon, colour: colour),
      const SizedBox(width: AppSpace.sm),
      Expanded(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
      ),
      ?trailing,
    ],
  );
}

/// What a card holds, given the room the card has and scrolling within it once it is
/// longer. An edge with more beyond it fades out, which is how you can tell.
class _CardScroll extends StatefulWidget {
  const _CardScroll({required this.child});

  final Widget child;

  @override
  State<_CardScroll> createState() => _CardScrollState();
}

class _CardScrollState extends State<_CardScroll> {
  bool _above = false;
  bool _below = false;

  bool _measure(ViewportNotificationMixin notification, ScrollMetrics metrics) {
    // Only this scroll view's own edges; a row's chips scrolling sideways say nothing of them.
    if (notification.depth != 0) return false;
    final above = metrics.extentBefore > 0.5;
    final below = metrics.extentAfter > 0.5;
    if (above != _above || below != _below) {
      setState(() {
        _above = above;
        _below = below;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const solid = AppColour.label;
    final clear = AppColour.label.withValues(alpha: 0);

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) => _measure(notification, notification.metrics),
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) => _measure(notification, notification.metrics),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) {
            final fade = rect.height <= 0 ? 0.0 : (AppSpace.xxl / rect.height).clamp(0.0, 0.5);
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_above ? clear : solid, solid, solid, _below ? clear : solid],
              stops: [0, fade, 1 - fade, 1],
            ).createShader(rect);
          },
          child: ScrollConfiguration(
            // The fade says there is more; a scroll bar over the rows would only crowd them.
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(child: widget.child),
          ),
        ),
      ),
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
  const _TodayCard({required this.stats, required this.fill});

  final TaskStats stats;
  final bool fill;

  /// Tasks coming up shown on a card as tall as its content; "Next 7 days" has the rest.
  static const _comingUpShown = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final items = [...stats.overdue, ...stats.dueToday];
    final total = stats.todayTotal + stats.completedToday;
    final progress = total == 0 ? 0.0 : stats.completedToday / total;
    final comingUp = fill ? stats.comingUp : stats.comingUp.take(_comingUpShown).toList();

    Widget row(BuildContext context, Task task) => TaskRow(
      key: ValueKey(task.id),
      task: task,
      onToggle: () => scope?.tasks.setDone(task.id, done: task.status != TaskStatus.done),
      onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
      onDelete: () async {
        if (scope == null) return;
        await scope.tasks.softDelete(task.id);
        ref
            .read(undoProvider.notifier)
            .offer('Deleted "${task.title}"', () => scope.tasks.restore(task.id));
      },
    );

    final dueNow = AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.medium),
      child: items.isEmpty
          ? _ClearState(key: const ValueKey('clear'), completedToday: stats.completedToday)
          : AnimatedItems<Task>(
              key: const ValueKey('tasks'),
              items: items,
              keyOf: (task) => task.id,
              itemBuilder: row,
            ),
    );

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dueNow,
        if (comingUp.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppLayout.touch ? AppSpace.xs : AppSpace.md,
              AppSpace.lg,
              0,
              AppSpace.xs,
            ),
            child: Row(
              children: [
                Expanded(child: Text('Coming up', style: AppText.caption)),
                _TextLink(
                  label: 'Next 7 days',
                  onTap: () =>
                      ref.read(destinationProvider.notifier).go(const UpcomingDestination()),
                ),
              ],
            ),
          ),
          AnimatedItems<Task>(items: comingUp, keyOf: (task) => task.id, itemBuilder: row),
        ],
      ],
    );

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
          if (!fill)
            list
          else if (items.isEmpty && comingUp.isEmpty)
            // Nothing today and nothing coming: the card's room goes to saying so.
            Expanded(child: Center(child: dueNow))
          else
            Expanded(child: _CardScroll(child: list)),
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
      mainAxisSize: MainAxisSize.min,
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

// --- the day --------------------------------------------------------------------------

/// Where the day stands now, and the day itself: its blocks and the free time between.
class _DayCard extends ConsumerStatefulWidget {
  const _DayCard({required this.fill});

  final bool fill;

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  /// Keeps "now" true while nothing else changes.
  Timer? _clock;

  /// The stretch of the day happening now.
  final _now = GlobalKey();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    // A long day in a card of its own height opens where now is, a little of what has gone
    // still above it. Only once: after that, where it is scrolled to is the reader's.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = _now.currentContext;
      if (!mounted || !widget.fill || now == null) return;
      Scrollable.ensureVisible(now, alignment: 0.25);
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
    final tasksToday = ref.watch(taskSlotsProvider(today.date));
    final dayNow = DayNow.of(today, nowMin, tasks: tasksToday);
    final settings = CapacityMapping.settings(ref.watch(capacityProfileProvider).value);
    final text = HomeText.now(dayNow, bedtimeMin: settings.sleepOn(now.weekday).bedtimeMin);
    final colours = ref.watch(blockColoursProvider);
    final colour = switch (dayNow.current) {
      final busy? when busy.isTask => AppColour.label,
      final busy? => BlockStyle.colourIn(colours, busy.title),
      null when dayNow.dayDone || dayNow.beforeWaking => AppColour.indigo,
      null => AppColour.green,
    };
    void openBudget() => ref.read(destinationProvider.notifier).go(const CapacityDestination());
    void openTask(String id) => ref.read(openTaskProvider.notifier).open(id);
    // With a height of its own to fill, the card goes on to tomorrow's blocks.
    final tomorrow = widget.fill && days.length > 1 ? days[1] : null;
    final tasksTomorrow = tomorrow == null
        ? const <TaskSlot>[]
        : ref.watch(taskSlotsProvider(tomorrow.date));

    final entries = DayAgenda.of(today, nowMin, tasks: tasksToday);
    // Blocks that overlap can both be on now; the key goes to the first.
    final current = entries.where((e) => e.when == AgendaTime.now).firstOrNull;

    final agenda = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (today.blocks.isEmpty && tasksToday.isEmpty)
          _NothingFixed(day: today.date, onOpen: openBudget)
        else
          for (final entry in entries)
            _AgendaRow(
              key: identical(entry, current) ? _now : null,
              entry: entry,
              nowMin: nowMin,
              colours: colours,
              onOpenTask: openTask,
            ),
        if (tomorrow != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.lg, AppSpace.sm, AppSpace.xs),
            child: Text('Tomorrow', style: AppText.caption),
          ),
          if (tomorrow.blocks.isEmpty && tasksTomorrow.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              child: Text(HomeText.nothingFixed(tomorrow.date, now), style: AppText.footnote),
            )
          else
            // A minute before midnight, so nothing of tomorrow has started.
            for (final entry in DayAgenda.of(tomorrow, -1, tasks: tasksTomorrow))
              if (!entry.free)
                _AgendaRow(
                  entry: entry,
                  nowMin: -1,
                  colours: colours,
                  onOpenTask: openTask,
                ),
        ],
      ],
    );

    return _Card(
      glow: colour,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeading(
            icon: dayNow.current?.isTask ?? false
                ? Icons.schedule_rounded
                : dayNow.current != null
                ? Icons.event_available_rounded
                : dayNow.dayDone || dayNow.beforeWaking
                ? Icons.bedtime_rounded
                : Icons.self_improvement_rounded,
            colour: colour,
            label: 'Right now · ${Format.clock(nowMin)}',
            trailing: _TextLink(label: 'Timetable', onTap: openBudget),
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
          _DayStrip(day: today, nowMin: nowMin, colours: colours, tasks: tasksToday),
          const SizedBox(height: AppSpace.md),
          const AppDivider(),
          const SizedBox(height: AppSpace.sm),
          if (widget.fill) Expanded(child: _CardScroll(child: agenda)) else agenda,
        ],
      ),
    );
  }
}

/// The waking day as a strip: blocks in their colours, and a marker at now.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.day,
    required this.nowMin,
    required this.colours,
    required this.tasks,
  });

  final DayCapacity day;
  final int nowMin;
  final Map<String, Color> colours;

  /// Tasks given a time, white on the strip as on the time budget.
  final List<TaskSlot> tasks;

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
                  // A little inside the strip, so the marker at now still shows across one.
                  for (final task in tasks)
                    Positioned(
                      left: x(task.startMin),
                      width: math.max(3, x(task.endMin) - x(task.startMin)),
                      top: AppSpace.xs + 2,
                      height: _height - 4,
                      child: Tooltip(
                        message:
                            '${task.title} · ${Format.clockRange(task.startMin, task.endMin)}',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColour.label.withValues(
                              alpha: task.done || task.endMin <= nowMin ? 0.3 : 0.85,
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColour.label,
                          borderRadius: AppRadius.roundAll,
                          boxShadow: [
                            BoxShadow(color: AppColour.label.withValues(alpha: 0.4), blurRadius: 6),
                          ],
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

/// A stretch of the day, the way a calendar lists one: when it starts and ends, a bar in
/// its block's colour, and what it is. Free time is quieter, and what has gone is dimmed.
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.entry,
    required this.nowMin,
    required this.colours,
    required this.onOpenTask,
    super.key,
  });

  final AgendaEntry entry;
  final int nowMin;
  final Map<String, Color> colours;

  /// Opens a task given a time, from its row.
  final ValueChanged<String> onOpenTask;

  /// Room for "00:00" in the times column, before the text is scaled.
  static const _timesWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final block = entry.block;
    final task = entry.task;
    // A block or a task: something that takes the time, as against free time.
    final filled = !entry.free;
    final done = task?.done ?? false;
    final happening = entry.when == AgendaTime.now && !done;
    final colour = switch ((block, task)) {
      (final block?, _) => BlockStyle.colourIn(colours, block.title),
      // White, which no timetable block wears, as the time budget draws a task.
      (_, final task?) => task.done ? AppColour.grey : AppColour.label,
      _ => AppColour.labelTertiary,
    };
    final times = MediaQuery.textScalerOf(context).scale(_timesWidth);
    final detail = HomeText.agendaDetail(entry, nowMin);

    final row = Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: filled ? AppSpace.sm : AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: happening ? colour.withValues(alpha: 0.14) : null,
        borderRadius: AppRadius.mediumAll,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: times,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Format.clock(entry.startMin),
                    style: AppText.numeric.copyWith(
                      color: filled ? AppColour.label : AppColour.labelTertiary,
                    ),
                  ),
                  if (filled)
                    Text(
                      Format.clock(entry.endMin),
                      style: AppText.numeric.copyWith(color: AppColour.labelTertiary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: filled ? colour : AppColour.fill,
                borderRadius: AppRadius.roundAll,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: !filled
                  ? Row(
                      children: [
                        Text(HomeText.agendaTitle(entry), style: AppText.callout),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.numeric.copyWith(
                              color: entry.usable ? AppColour.labelSecondary : AppColour.labelTertiary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            if (task != null) ...[
                              Icon(
                                done ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                size: 13,
                                color: colour,
                              ),
                              const SizedBox(width: AppSpace.xs),
                            ],
                            Flexible(
                              child: Text(
                                HomeText.agendaTitle(entry),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.headline.copyWith(
                                  color: done ? AppColour.labelTertiary : null,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                  decorationColor: AppColour.labelTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.numeric),
                      ],
                    ),
            ),
            if (happening) ...[
              const SizedBox(width: AppSpace.sm),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: filled ? colour : AppColour.fillStrong,
                    borderRadius: AppRadius.roundAll,
                  ),
                  child: Text(
                    'Now',
                    style: AppText.caption.copyWith(
                      color: filled ? AppColour.base : AppColour.label,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final shown = AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.medium),
      opacity: entry.when == AgendaTime.past ? 0.45 : 1,
      child: row,
    );
    if (task == null) return shown;
    // A task opens from its row, as it does from any list.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Pressable(
        pressedScale: 0.98,
        onTap: () => onOpenTask(task.taskId),
        child: shown,
      ),
    );
  }
}

class _NothingFixed extends StatelessWidget {
  const _NothingFixed({required this.day, required this.onOpen});

  final DateTime day;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.event_available_rounded, size: 28, color: AppColour.labelTertiary),
        const SizedBox(height: AppSpace.sm),
        Text(
          HomeText.nothingFixed(day, DateTime.now()),
          style: AppText.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Classes and other fixed hours go in your timetable.',
          style: AppText.footnote,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.sm),
        _TextLink(label: 'Timetable', onTap: onOpen),
      ],
    ),
  );
}

// --- the week -------------------------------------------------------------------------

class _WeekCard extends ConsumerWidget {
  const _WeekCard({required this.fill});

  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Card(
    // The whole card opens the Time budget: a link in its heading took the width its name
    // needed, where the card is a figure wide.
    onTap: () => ref.read(destinationProvider.notifier).go(const CapacityDestination()),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CardHeading(
          icon: Icons.bar_chart_rounded,
          colour: AppColour.accent,
          label: 'This week',
          trailing: Icon(Icons.chevron_right_rounded, size: 16, color: AppColour.labelTertiary),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Planned against usable time',
          style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
        ),
        const SizedBox(height: AppSpace.sm),
        // Bars as tall as the card allows, where it has a height of its own.
        if (fill) const Expanded(child: WeekLoadBars()) else const WeekLoadBars(barHeight: 74),
      ],
    ),
  );
}

// --- figures --------------------------------------------------------------------------

class _Tiles extends ConsumerWidget {
  const _Tiles({required this.stats, required this.perRow});

  final TaskStats stats;

  /// Four in a row, or two rows of two.
  final int perRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final impossible = schedule.impossible;
    final now = DateTime.now();
    final inRow = perRow == 4;
    void go(Destination destination) => ref.read(destinationProvider.notifier).go(destination);

    final worst = stats.overdue.firstOrNull;
    final reminder = stats.nextReminder;

    final tiles = [
      _Tile(
        icon: Icons.error_outline_rounded,
        colour: worst == null ? AppColour.grey : AppColour.red,
        label: 'Overdue',
        labelBeside: inRow,
        count: stats.overdue.length,
        caption: worst == null ? 'Nothing late' : Format.due(worst, now)?.label ?? '',
        onTap: () => go(const AllDestination()),
      ),
      _Tile(
        icon: Icons.hourglass_bottom_rounded,
        colour: impossible.isEmpty ? AppColour.grey : AppColour.orange,
        label: "Won't fit",
        labelBeside: inRow,
        count: impossible.length,
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
        labelBeside: inRow,
        count: stats.completedThisWeek,
        trailing: _WeekBars(counts: stats.doneByDay),
        caption: stats.completedToday == 0 ? 'None yet today' : '${stats.completedToday} today',
        onTap: () => go(const DoneDestination()),
      ),
      _Tile(
        icon: Icons.notifications_active_rounded,
        colour: reminder == null ? AppColour.grey : AppColour.accent,
        label: 'Next reminder',
        labelBeside: inRow,
        words: reminder == null ? 'None' : Format.reminderTime(reminder.remindAt!, now),
        caption: reminder?.title ?? 'Nothing coming up',
        onTap: reminder == null
            ? null
            : () => ref.read(openTaskProvider.notifier).open(reminder.id),
      ),
    ];

    Widget row(List<Widget> tiles, double gap) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(child: tile),
          ],
        ],
      ),
    );

    if (inRow) return row(tiles, _Dashboard._gap);
    return Column(
      children: [
        row(tiles.sublist(0, 2), AppSpace.md),
        const SizedBox(height: AppSpace.md),
        row(tiles.sublist(2), AppSpace.md),
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
    required this.caption,
    this.count,
    this.words,
    this.labelBeside = false,
    this.trailing,
    this.onTap,
  }) : assert((count == null) != (words == null), 'A tile shows a count or words');

  final IconData icon;
  final Color colour;
  final String label;
  final String caption;

  /// The figure: a number, which counts to its new value, or else [words].
  final int? count;
  final String? words;

  /// The label beside the badge and the caption beside the figure, where a tile is wide,
  /// rather than each on a line of its own.
  final bool labelBeside;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.footnote.copyWith(color: AppColour.label),
    );
    final captionText = Text(
      caption,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.footnote,
    );
    final figureStyle = count == null ? AppText.title3 : AppText.metricSmall;

    // The figure, made by [line] from its text as it stands, counting where it is a number.
    Widget figure(Widget Function(String text) line) => switch (count) {
      final count? => AnimatedCount.builder(count, builder: (context, shown) => line(shown)),
      null => line(words!),
    };

    return _Card(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: labelBeside ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              _Badge(icon: icon, colour: colour),
              if (labelBeside) ...[
                const SizedBox(width: AppSpace.sm),
                Expanded(child: labelText),
              ] else
                const Spacer(),
              ?trailing,
            ],
          ),
          if (labelBeside) ...[
            const SizedBox(height: AppSpace.sm),
            // One line of text, so the caption gives way first and nothing runs past the edge.
            figure(
              (text) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: text, style: figureStyle),
                    const WidgetSpan(child: SizedBox(width: AppSpace.sm)),
                    TextSpan(text: caption, style: AppText.footnote),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpace.md),
            figure(
              (text) => Text(text, style: figureStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 2),
            labelText,
            captionText,
          ],
        ],
      ),
    );
  }
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
  const _NotesCard({required this.fill});

  final bool fill;

  /// Recent notes shown on a card as tall as its content; the rest are a tap away.
  static const _shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider).value ?? const <Note>[];
    final lines = AnimatedItems<Note>(
      items: fill ? notes : notes.take(_shown).toList(),
      keyOf: (note) => note.id,
      itemBuilder: (context, note) => _NoteLine(note: note),
    );
    final none = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
      child: Text(
        'What you jot down stays here, a line each.',
        textAlign: TextAlign.center,
        style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
      ),
    );

    return _Card(
      glow: AppColour.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeading(
            icon: Icons.sticky_note_2_rounded,
            colour: AppColour.yellow,
            label: 'Notes',
            trailing: _TextLink(
              label: notes.isEmpty ? 'Open' : 'All ${notes.length}',
              onTap: () => ref.read(destinationProvider.notifier).go(const NotesDestination()),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const QuickNoteField(),
          // The list stays put while the line saying there is nothing goes, so the first
          // note kept still animates in.
          if (fill)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CardScroll(child: lines),
                  IgnorePointer(
                    child: AnimatedOpacity(
                      duration: AppMotion.of(context, AppMotion.quick),
                      opacity: notes.isEmpty ? 1 : 0,
                      child: Center(child: none),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            lines,
            AnimatedSize(
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.standard,
              child: notes.isEmpty ? none : const SizedBox(width: double.infinity),
            ),
          ],
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
    final preview = NoteText.preview(note);
    final images = ref.watch(noteImagesProvider).value?[note.id]?.length ?? 0;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Level with the heading's first line.
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    note.pinned
                        ? Icons.push_pin_rounded
                        : images > 0
                        ? Icons.image_outlined
                        : Icons.notes_rounded,
                    size: 14,
                    color: note.pinned ? AppColour.yellow : AppColour.labelTertiary,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NoteText.heading(note, images: images),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.callout.copyWith(color: AppColour.label),
                      ),
                      if (preview.isNotEmpty)
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
                        ),
                    ],
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
