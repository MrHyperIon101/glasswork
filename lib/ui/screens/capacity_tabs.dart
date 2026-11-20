part of 'capacity_screen.dart';

// The Time budget, in four parts, one at a time: what your days have room for (Overview),
// the classes and fixed blocks that take it (Timetable), the nights around it (Sleep), and
// how free time is counted (Rules). Each shows its subject as a picture first — a week on
// one clock, a week of classes in a grid, a week of nights against the goal — and is edited
// where it is shown.

enum _BudgetTab {
  overview('Overview'),
  timetable('Timetable'),
  sleep('Sleep'),
  rules('Rules');

  const _BudgetTab(this.label);

  final String label;
}

class _BudgetTabNotifier extends Notifier<_BudgetTab> {
  @override
  _BudgetTab build() => _BudgetTab.overview;

  void show(_BudgetTab tab) => state = tab;
}

/// Which part of the Time budget is showing; kept while you go elsewhere and come back.
final _budgetTabProvider = NotifierProvider<_BudgetTabNotifier, _BudgetTab>(_BudgetTabNotifier.new);

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// --- the segmented control ----------------------------------------------------------------

/// A segmented control as macOS draws one: the choices in a tray, the chosen one raised on a
/// thumb that slides to it.
class _Segments extends ConsumerWidget {
  const _Segments();

  /// Each choice's width, unless the line is too narrow for four of them: then they share it.
  static const _widest = 96.0;
  static const _height = 30.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_budgetTabProvider);
    const tabs = _BudgetTab.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final segment = math.min(_widest, (constraints.maxWidth - 4) / tabs.length);
        return Container(
          height: _height,
          width: segment * tabs.length + 4,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: AppColour.fill, borderRadius: AppRadius.mediumAll),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.of(context, AppMotion.medium),
                curve: AppMotion.standard,
                left: segment * tab.index,
                top: 0,
                bottom: 0,
                width: segment,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColour.fillStrong,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium - 2)),
                    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in tabs)
                    SizedBox(
                      width: segment,
                      child: Semantics(
                        selected: t == tab,
                        button: true,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => ref.read(_budgetTabProvider.notifier).show(t),
                            child: Center(
                              child: Text(
                                t.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.footnote.copyWith(
                                  color: t == tab ? AppColour.label : AppColour.labelSecondary,
                                  fontWeight: t == tab ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Overview -----------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.days, required this.notCounted});

  final List<DayCapacity> days;

  /// Blocks the figures leave out, whole or in part: shown here too, so a too-rosy number
  /// is never read without knowing why.
  final int notCounted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final today = days.first;
    final planned = schedule.allocatedOn(today.date);
    final spare = today.spareAfter(planned);
    final week = days.take(7).toList();
    final weekFree = week.fold(0, (sum, d) => sum + d.usableMin);
    final weekPlanned = week.fold(0, (sum, d) => sum + schedule.allocatedOn(d.date));
    final compact = AppLayout.compact(context);

    final figures = [
      _Figure(label: 'Free today', value: Format.estimate(today.usableMin), detail: 'after classes, meals and buffer'),
      _Figure(label: 'Planned today', value: Format.estimate(planned), detail: 'of your tasks, by the plan'),
      _Figure(
        label: spare < 0 ? 'Over today' : 'Spare today',
        value: Format.estimate(spare.abs()),
        detail: spare < 0 ? 'more planned than fits' : 'left once the plan is done',
        tint: spare < 0 ? AppColour.red : AppColour.green,
      ),
      _Figure(
        label: 'Next seven days',
        value: Format.estimate(weekFree),
        detail: '${Format.estimate(weekPlanned)} of it planned',
      ),
    ];

    return ListView(
      padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.lg),
      children: [
        if (notCounted > 0) ...[
          _Notice(
            text: '$notCounted ${notCounted == 1 ? 'block is' : 'blocks are'} not counted in these figures',
            action: 'Review',
            onTap: () => ref.read(_budgetTabProvider.notifier).show(_BudgetTab.timetable),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        if (compact)
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                for (final f in figures) SizedBox(width: (constraints.maxWidth - AppSpace.md) / 2, child: f),
              ],
            ),
          )
        else
          Row(
            children: [
              for (final (i, f) in figures.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.lg),
                Expanded(child: f),
              ],
            ],
          ),
        const SizedBox(height: AppSpace.lg),
        AppSurface(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpace.lg : AppSpace.xl,
            AppSpace.lg,
            compact ? AppSpace.lg : AppSpace.xl,
            AppSpace.lg,
          ),
          child: _WeekOnOneClock(days: week),
        ),
        const SizedBox(height: AppSpace.lg),
        _DayBreakdown(day: today),
      ],
    );
  }
}

/// A line that something needs a look, and where to look.
class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.sm),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: AppColour.orange),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(text, style: AppText.callout)),
        _SmallAction(label: action, onTap: onTap),
      ],
    ),
  );
}

/// A figure as Screen Time shows one: what it is, the number, and a line on what it means.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.detail, this.tint});

  final String label;
  final String value;
  final String detail;
  final Color? tint;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.footnote),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.metric.copyWith(color: tint ?? AppColour.label)),
        ),
        Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: AppColour.labelTertiary)),
      ],
    ),
  );
}

/// The week on one clock: every day across the same hours, so a late class on Tuesday sits
/// under a late class on Monday, one legend for all of them, and each day's free and planned
/// time in two columns at its end.
class _WeekOnOneClock extends ConsumerWidget {
  const _WeekOnOneClock({required this.days});

  final List<DayCapacity> days;

  static const _rowHeight = 32.0;
  static const _labelWidth = 76.0;
  static const _figureWidth = 76.0;

  /// The clock the week is drawn on: from an hour before the earliest anyone is up to
  /// midnight. The small hours are asleep on almost every day, and a third of each row
  /// spent showing it pushed the classes into a corner.
  static (int, int) _clock(List<DayCapacity> days) {
    var first = 8 * 60;
    for (final day in days) {
      // The longest waking stretch is the day; a sliver after midnight is the night before.
      final main = day.awake.fold<(int, int)?>(
        null,
        (best, w) => best == null || w.$2 - w.$1 > best.$2 - best.$1 ? w : best,
      );
      if (main != null) first = math.min(first, main.$1);
    }
    for (final day in days) {
      for (final b in day.blocks) {
        first = math.min(first, b.startMin);
      }
    }
    return (math.max(0, (first ~/ 60 - 1) * 60), minutesInDay);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final colours = ref.watch(blockColoursProvider);
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final compact = AppLayout.compact(context);
    final (from, to) = _clock(days);
    final hourStep = compact ? 6 : (to - from) > 16 * 60 ? 3 : 2;

    Widget legend(Color colour, String label, {bool hatched = false, bool ring = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: hatched || ring ? null : colour,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            border: hatched || ring ? Border.all(color: colour) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.caption),
      ],
    );

    Widget figure(String text, {Color? colour, FontWeight weight = FontWeight.w500}) => SizedBox(
      width: _figureWidth,
      child: Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 1,
        style: AppText.numeric.copyWith(color: colour ?? AppColour.label, fontWeight: weight),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpace.sm,
          spacing: AppSpace.lg,
          children: [
            Text('Next seven days', style: AppText.headline),
            Wrap(
              spacing: AppSpace.lg,
              runSpacing: AppSpace.xs,
              children: [
                legend(AppColour.accent, 'Classes'),
                legend(_freeColour, 'Free'),
                legend(AppColour.labelTertiary, 'Too short to use', hatched: true),
                legend(AppColour.label, 'Planned tasks'),
                legend(_sleepColour, 'Asleep'),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        // The hours, once, over every day; and over the figures, what they are.
        Row(
          children: [
            const SizedBox(width: _labelWidth),
            Expanded(
              child: SizedBox(
                height: 16,
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var m = (from + 59) ~/ 60 * 60; m <= to; m += hourStep * 60)
                        Positioned(
                          left: (c.maxWidth * (m - from) / (to - from) - 20).clamp(0, c.maxWidth - 40),
                          width: 40,
                          child: Text(
                            Format.clock(m % minutesInDay),
                            textAlign: TextAlign.center,
                            style: AppText.caption.copyWith(color: AppColour.labelTertiary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppSpace.md),
              figure('Free', colour: AppColour.labelTertiary),
              figure('Planned', colour: AppColour.labelTertiary),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        for (final (i, day) in days.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: i == 0 ? 'Today' : _weekdayNames[day.date.weekday - 1],
                        style: AppText.callout.copyWith(
                          color: i == 0 ? AppColour.accent : AppColour.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '  ${day.date.day}',
                        style: AppText.callout.copyWith(color: AppColour.labelTertiary),
                      ),
                    ]),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: _rowHeight,
                    child: CustomPaint(
                      painter: _DayOnClockPainter(
                        day: day,
                        from: from,
                        to: to,
                        tasks: ref.watch(taskSlotsProvider(day.date)),
                        colours: colours,
                        nowMin: i == 0 ? nowMin : null,
                      ),
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpace.md),
                  figure(Format.estimate(day.usableMin), weight: FontWeight.w600),
                  Builder(builder: (context) {
                    final planned = schedule.allocatedOn(day.date);
                    return figure(
                      planned == 0 ? '—' : Format.estimate(planned),
                      colour: planned == 0
                          ? AppColour.labelQuaternary
                          : planned > day.usableMin
                          ? AppColour.red
                          : AppColour.accent,
                    );
                  }),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

const _freeColour = Color(0x3378788C);
const _sleepColour = Color(0x66090912);

/// One day on the clock, from [from] to [to]: asleep, free, the stretches too short to use,
/// the blocks in their colours, the tasks given a time, and now.
class _DayOnClockPainter extends CustomPainter {
  _DayOnClockPainter({
    required this.day,
    required this.from,
    required this.to,
    required this.tasks,
    required this.colours,
    this.nowMin,
  });

  final DayCapacity day;
  final int from;
  final int to;
  final List<TaskSlot> tasks;
  final Map<String, Color> colours;
  final int? nowMin;

  @override
  void paint(Canvas canvas, Size size) {
    double x(int min) => size.width * (min.clamp(from, to) - from) / (to - from);
    final full = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    canvas.save();
    canvas.clipRRect(full);
    canvas.drawRect(Offset.zero & size, Paint()..color = _freeColour);
    for (final (start, end) in day.asleep) {
      canvas.drawRect(Rect.fromLTRB(x(start), 0, x(end), size.height), Paint()..color = _sleepColour);
    }
    final hatch = Paint()
      ..color = AppColour.labelQuaternary
      ..strokeWidth = 1;
    for (final gap in day.discardedGaps) {
      final r = Rect.fromLTRB(x(gap.startMin), 0, x(gap.endMin), size.height);
      canvas.save();
      canvas.clipRect(r);
      for (var dx = r.left - size.height; dx < r.right; dx += 5) {
        canvas.drawLine(Offset(dx, size.height), Offset(dx + size.height, 0), hatch);
      }
      canvas.restore();
    }
    for (final block in day.blocks) {
      if (block.endMin <= from) continue;
      final r = Rect.fromLTRB(x(block.startMin) + 1, 3, x(block.endMin) - 1, size.height - 3);
      final colour = BlockStyle.colourIn(colours, block.title);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()..color = colour.withValues(alpha: 0.92));
      _label(canvas, r, block.title);
    }
    for (final task in tasks) {
      final r = Rect.fromLTRB(x(task.startMin) + 1, 8, x(task.endMin) - 1, size.height - 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..color = AppColour.label.withValues(alpha: task.done ? 0.4 : 0.85),
      );
    }
    canvas.restore();
    if (nowMin case final now? when now >= from) {
      final nx = x(now);
      canvas.drawLine(Offset(nx, -3), Offset(nx, size.height + 3), Paint()
        ..color = AppColour.red
        ..strokeWidth = 2);
      canvas.drawCircle(Offset(nx, -3), 3, Paint()..color = AppColour.red);
    }
  }

  /// The block's name if it fits, its short name if that does, and nothing if neither does.
  void _label(Canvas canvas, Rect r, String text) {
    final room = r.width - 10;
    if (room < 14) return;
    final style = AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    var painter = TextPainter(text: TextSpan(text: text, style: style), maxLines: 1, textDirection: TextDirection.ltr)
      ..layout();
    if (painter.width > room) {
      painter = TextPainter(
        text: TextSpan(text: BlockStyle.abbreviate(text), style: style),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: room);
    }
    painter.paint(canvas, Offset(r.left + 5, r.center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_DayOnClockPainter old) =>
      old.day != day ||
      old.from != from ||
      old.to != to ||
      old.tasks != tasks ||
      old.colours != colours ||
      old.nowMin != nowMin;
}

/// Where a day's twenty-four hours go, as macOS shows where a disk's space goes: one bar cut
/// into its parts, and under it each part with its length. The parts add up to the day, so
/// the time to spend is never a number without its working.
class _DayBreakdown extends ConsumerWidget {
  const _DayBreakdown({required this.day, this.title = 'Where today goes'});

  final DayCapacity day;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(capacityProfileProvider).value;
    final focus = CapacityMapping.settings(profile).focusFactor;
    final drift = math.max(
      0,
      day.wakingMin - day.committedMin - day.overheadMin - day.discardedGapMin - day.usableMin,
    );
    final parts = <(String, int, Color)>[
      ('Yours to spend', day.usableMin, AppColour.accent),
      ('Classes and blocks', day.committedMin, AppColour.purple),
      ('Meals and buffer', day.overheadMin, AppColour.orange),
      ('Breaks and drift', drift, AppColour.teal),
      ('Too short to use', day.discardedGapMin, AppColour.yellow),
      ('Asleep', day.sleepMin, AppColour.grey),
    ];

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpace.lg,
            children: [
              Text(title, style: AppText.headline),
              Text(
                '${Format.estimate(day.usableMin)} of 24h is yours',
                style: AppText.footnote,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: AppRadius.smallAll,
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  for (final (i, (_, minutes, colour)) in parts.indexed)
                    if (minutes > 0)
                      Expanded(
                        flex: minutes,
                        child: Container(
                          margin: EdgeInsets.only(left: i == 0 ? 0 : 1.5),
                          color: colour.withValues(alpha: i == parts.length - 1 ? 0.35 : 0.9),
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.xl,
            runSpacing: AppSpace.sm,
            children: [
              for (final (i, (label, minutes, colour)) in parts.indexed)
                if (minutes > 0 || i == 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colour.withValues(alpha: i == parts.length - 1 ? 0.5 : 1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(label, style: AppText.footnote),
                      const SizedBox(width: 6),
                      Text(
                        Format.estimate(minutes),
                        style: AppText.numeric.copyWith(color: AppColour.label, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            focus >= 1
                ? 'Every free minute counts as work: nothing is kept back for breaks.'
                : 'Of every free hour, ${Format.estimate((60 * focus).round())} counts as work; '
                      'the rest is kept for breaks and drift. Nothing is ever planned into sleep.',
            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
          ),
        ],
      ),
    );
  }
}

// --- Timetable ----------------------------------------------------------------------------

class _TimetableTab extends ConsumerWidget {
  const _TimetableTab({required this.commitments, required this.uncounted, required this.rejected, required this.settings});

  final List<Commitment> commitments;
  final List<Commitment> uncounted;
  final List<String> rejected;
  final CapacitySettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editingId = ref.watch(editingScheduleIdProvider);
    final blocks = [for (final c in commitments) if (c.scheduleId == editingId) c];
    final compact = AppLayout.compact(context);
    return ListView(
      padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.lg),
      children: [
        if (rejected.isNotEmpty) ...[
          _RejectedRules(rejected: rejected),
          const SizedBox(height: AppSpace.md),
        ],
        if (uncounted.isNotEmpty) ...[
          _UncountedBlocks(blocks: uncounted, settings: settings),
          const SizedBox(height: AppSpace.md),
        ],
        _ScheduleSets(),
        const SizedBox(height: AppSpace.lg),
        AppSurface(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(compact ? 'Blocks' : 'The week', style: AppText.headline)),
                  if (!compact) ...[
                    Text(
                      blocks.isEmpty ? 'Click an hour to add a block' : 'Click a block to change it, or an hour to add one',
                      style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
                    ),
                    const SizedBox(width: AppSpace.md),
                  ],
                  _AddCommitmentButton(),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              if (!compact)
                _WeekGrid(blocks: blocks)
              else if (blocks.isEmpty)
                Text(
                  'No fixed blocks yet. Add your classes and labs — until then every day looks '
                  'completely free.',
                  style: AppText.callout,
                )
              else
                // Seven columns on a phone leave each class a sliver: a list reads better.
                for (final c in blocks)
                  _BlockRow(
                    commitment: c,
                    problems: _problemsOf(
                      c,
                      settings,
                      others: CapacityMapping.blocksOf([
                        for (final other in blocks)
                          if (other.id != c.id) other,
                      ]).$1,
                    ),
                    onTap: () => _editBlock(context, ref, existing: c),
                    onDelete: () => _deleteBlock(ref, c),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A week of classes as a calendar's week view draws one: the days across, the hours down,
/// each block where and as long as it is, in its colour. A tap on a block changes it; a tap
/// on an empty hour adds one there.
class _WeekGrid extends ConsumerStatefulWidget {
  const _WeekGrid({required this.blocks});

  final List<Commitment> blocks;

  @override
  ConsumerState<_WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends ConsumerState<_WeekGrid> {
  String? _hovered;

  static const _hour = 44.0;
  static const _gutter = 48.0;
  static const _header = 28.0;

  /// The hours worth showing: from the first block's start to the last one's end, an hour
  /// either side, and never less than the working day.
  (int, int) _range(List<(int day, int start, int end, Commitment c)> placed) {
    var first = 8;
    var last = 18;
    for (final (_, start, end, _) in placed) {
      first = math.min(first, start ~/ 60);
      last = math.max(last, (end + 59) ~/ 60);
    }
    return (math.max(0, first), math.min(24, last));
  }

  @override
  Widget build(BuildContext context) {
    final colours = ref.watch(blockColoursProvider);
    final placed = <(int, int, int, Commitment)>[
      for (final c in widget.blocks)
        for (final day in _weekdaysOf(c) ?? const <int>{})
          (day, c.startMin, math.min(c.startMin + c.durationMin, minutesInDay), c),
    ];
    final (first, last) = _range(placed);
    final hours = last - first;
    final today = DateTime.now().weekday;
    final settings = CapacityMapping.settings(ref.watch(capacityProfileProvider).value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final column = (constraints.maxWidth - _gutter) / 7;
        double y(int min) => _header + (min - first * 60) / 60 * _hour;

        // Blocks on the same day that overlap share its width, side by side.
        final lanes = <(int, int, int, Commitment), (int, int)>{};
        for (var day = 1; day <= 7; day++) {
          final onDay = placed.where((p) => p.$1 == day).toList()..sort((a, b) => a.$2.compareTo(b.$2));
          final ends = <int>[];
          final assigned = <(int, int, int, Commitment), int>{};
          for (final p in onDay) {
            var lane = ends.indexWhere((end) => end <= p.$2);
            if (lane < 0) {
              lane = ends.length;
              ends.add(p.$3);
            } else {
              ends[lane] = p.$3;
            }
            assigned[p] = lane;
          }
          for (final p in onDay) {
            lanes[p] = (assigned[p]!, ends.length);
          }
        }

        return SizedBox(
          height: _header + hours * _hour + AppSpace.md,
          child: Stack(
            children: [
              // The hours, and a line under each.
              for (var h = 0; h <= hours; h++) ...[
                Positioned(
                  left: 0,
                  top: _header + h * _hour - 7,
                  width: _gutter - 8,
                  child: Text(
                    Format.clock((first + h) * 60 % minutesInDay),
                    textAlign: TextAlign.right,
                    style: AppText.caption,
                  ),
                ),
                Positioned(
                  left: _gutter,
                  right: 0,
                  top: _header + h * _hour,
                  child: Container(height: 1, color: AppColour.separator),
                ),
              ],
              // Asleep, shaded, so a block that falls there shows why it is not counted.
              for (var day = 1; day <= 7; day++)
                for (final (start, end) in settings.sleepIntervalsOn(day))
                  if (end > first * 60 && start < last * 60)
                    Positioned(
                      left: _gutter + (day - 1) * column + 1,
                      width: column - 1,
                      top: y(math.max(start, first * 60)),
                      height: y(math.min(end, last * 60)) - y(math.max(start, first * 60)),
                      child: const IgnorePointer(child: ColoredBox(color: Color(0x2E000000))),
                    ),
              // The days, today marked.
              for (var day = 1; day <= 7; day++) ...[
                Positioned(
                  left: _gutter + (day - 1) * column,
                  width: column,
                  top: 0,
                  height: _header - 6,
                  child: Center(
                    child: Text(
                      _weekdayNames[day - 1],
                      style: AppText.footnote.copyWith(
                        color: day == today ? AppColour.accent : AppColour.labelSecondary,
                        fontWeight: day == today ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (day > 1)
                  Positioned(
                    left: _gutter + (day - 1) * column,
                    top: _header,
                    bottom: 0,
                    child: Container(width: 1, color: AppColour.separator),
                  ),
                // An empty hour, to add a block to.
                for (var h = 0; h < hours; h++)
                  Positioned(
                    left: _gutter + (day - 1) * column,
                    width: column,
                    top: _header + h * _hour,
                    height: _hour,
                    child: _EmptyHour(
                      key: ValueKey('hour-$day-${first + h}'),
                      onTap: () => _editBlock(
                        context,
                        ref,
                        prefill: BlockDraft(title: '', weekdays: {day}, startMin: (first + h) * 60, durationMin: 60),
                      ),
                    ),
                  ),
              ],
              for (final p in placed)
                Builder(builder: (context) {
                  final (day, start, end, c) = p;
                  final (lane, of) = lanes[p] ?? (0, 1);
                  final width = column / of;
                  final key = '${c.id}-$day';
                  final colour = BlockStyle.colourIn(colours, c.title);
                  final hovered = _hovered == key;
                  return Positioned(
                    left: _gutter + (day - 1) * column + lane * width + 2,
                    width: width - 4,
                    top: y(start) + 1,
                    height: math.max(y(end) - y(start) - 2, 16),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hovered = key),
                      onExit: (_) => setState(() => _hovered = null),
                      child: GestureDetector(
                        onTap: () => _editBlock(context, ref, existing: c),
                        child: AnimatedContainer(
                          duration: AppMotion.of(context, AppMotion.quick),
                          padding: const EdgeInsets.fromLTRB(6, 3, 4, 3),
                          decoration: BoxDecoration(
                            color: colour.withValues(alpha: hovered ? 0.55 : 0.35),
                            borderRadius: AppRadius.smallAll,
                            border: Border(left: BorderSide(color: colour, width: 3)),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title,
                                      maxLines: end - start >= 90 ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.caption.copyWith(color: AppColour.label, fontWeight: FontWeight.w600)),
                                  if (end - start >= 45)
                                    Text(Format.clockSpan(c.startMin, c.durationMin),
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                        style: AppText.caption.copyWith(color: AppColour.labelSecondary)),
                                ],
                              ),
                              if (hovered)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Tooltip(
                                    message: 'Delete ${c.title}',
                                    child: GestureDetector(
                                      onTap: () => _deleteBlock(ref, c),
                                      child: const Icon(Icons.close_rounded, size: 14, color: AppColour.labelSecondary),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyHour extends StatefulWidget {
  const _EmptyHour({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<_EmptyHour> createState() => _EmptyHourState();
}

class _EmptyHourState extends State<_EmptyHour> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _hovered ? 1 : 0,
        duration: AppMotion.of(context, AppMotion.quick),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: AppColour.fill, borderRadius: AppRadius.smallAll),
          child: const Icon(Icons.add_rounded, size: 16, color: AppColour.labelSecondary),
        ),
      ),
    ),
  );
}

Future<void> _deleteBlock(WidgetRef ref, Commitment c) async {
  final scope = ref.read(appScopeProvider).value;
  if (scope == null) return;
  await scope.capacity.deleteCommitment(c.id);
  ref.read(undoProvider.notifier).offer('Deleted "${c.title}"', () => scope.capacity.restoreCommitment(c.id));
}

// --- Sleep --------------------------------------------------------------------------------

class _SleepTab extends ConsumerWidget {
  const _SleepTab({required this.profile});

  final CapacityProfile profile;

  /// Wide enough for the chart and a column beside it.
  static const _sideBySideFrom = 1080.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = CapacityMapping.settings(profile);
    final repo = ref.watch(appScopeProvider).value?.capacity;
    final goal = profile.sleepTargetMin;
    final nights = [for (var d = 1; d <= 7; d++) settings.nightAfter(d)];
    final short = nights.where((n) => n < goal).length;
    final average = nights.fold(0, (a, b) => a + b) ~/ 7;
    final compact = AppLayout.compact(context);

    final chart = AppSurface(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpace.lg : AppSpace.xl,
        AppSpace.lg,
        compact ? AppSpace.lg : AppSpace.xl,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Each night', style: AppText.headline)),
              _SmallAction(label: 'Set several nights', onTap: () => _editNights(context, ref, profile)),
            ],
          ),
          Text(
            '${AppLayout.touch ? 'Tap' : 'Click'} a night to change when you go to bed and get up.',
            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
          ),
          const SizedBox(height: AppSpace.lg),
          _SleepChart(profile: profile, settings: settings, goal: goal),
        ],
      ),
    );

    final averageFigure = _Figure(label: 'Average night', value: Format.estimate(average), detail: 'across the week');
    final shortFigure = _Figure(
      label: 'Short of the goal',
      value: short == 0 ? 'None' : '$short ${short == 1 ? 'night' : 'nights'}',
      detail: 'under ${Format.estimate(goal)}',
      tint: short == 0 ? AppColour.green : AppColour.orange,
    );
    final goalGroup = _Group(
      rows: [
        _RuleRow(
          title: 'Sleep at least',
          value: Format.estimate(goal),
          onStep: (d) => repo?.updateProfile(profile.id, sleepTargetMin: (goal + d * 15).clamp(240, 720)),
          onSubmit: (text) {
            final typed = TimeEntry.duration(text);
            if (typed == null) return false;
            repo?.updateProfile(profile.id, sleepTargetMin: typed.clamp(240, 720));
            return true;
          },
        ),
      ],
      footer: 'Nights shorter than this show in orange. It never moves anything: nothing is '
          'ever planned into sleep, and blocks that fall in it do not count.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _sideBySideFrom) {
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpace.lg),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: AppSpace.lg),
                  SizedBox(
                    width: 360,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        averageFigure,
                        const SizedBox(height: AppSpace.lg),
                        shortFigure,
                        const SizedBox(height: AppSpace.lg),
                        goalGroup,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return ListView(
          padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.lg),
          children: [
            Row(
              children: [
                Expanded(child: averageFigure),
                SizedBox(width: compact ? AppSpace.md : AppSpace.lg),
                Expanded(child: shortFigure),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            chart,
            const SizedBox(height: AppSpace.lg),
            goalGroup,
          ],
        );
      },
    );
  }
}

/// A week of nights as Health draws a sleep schedule: each night a bar from going to bed to
/// getting up, on one clock that runs from a little before the earliest bedtime to a little
/// after the latest morning, with each night's length under its name and the nights that fall
/// short of the goal in orange.
class _SleepChart extends StatelessWidget {
  const _SleepChart({required this.profile, required this.settings, required this.goal});

  final CapacityProfile profile;
  final CapacitySettings settings;
  final int goal;

  static const _height = 300.0;
  static const _gutter = 44.0;
  static const _head = 44.0;

  /// The night's clock starts at noon, so a bedtime after midnight is later than one before.
  static int _fromNoon(int clock) => (clock - 12 * 60 + minutesInDay) % minutesInDay;

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      final nights = [
        for (var d = 1; d <= 7; d++)
          (
            day: d,
            bedtime: settings.sleepOn(d).bedtimeMin,
            wake: settings.sleepOn(CapacitySettings.dayAfter(d)).wakeMin,
            length: settings.nightAfter(d),
          ),
      ];
      var first = minutesInDay;
      var last = 0;
      for (final n in nights) {
        final start = _fromNoon(n.bedtime);
        first = math.min(first, start);
        last = math.max(last, start + n.length);
      }
      // An hour either side, on whole hours.
      final from = math.max(0, (first ~/ 60 - 1) * 60);
      final to = math.min(2 * minutesInDay, ((last + 59) ~/ 60 + 1) * 60);
      final span = math.max(60, to - from);
      final step = span > 12 * 60 ? 2 : 1;

      return LayoutBuilder(
        builder: (context, constraints) {
          final column = (constraints.maxWidth - _gutter) / 7;
          final bar = math.min(34.0, column * 0.42);
          double y(int fromNoon) => _head + _height * (fromNoon - from) / span;
          return SizedBox(
            height: _head + _height + 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var m = from; m <= to; m += step * 60) ...[
                  Positioned(
                    left: 0,
                    width: _gutter - 10,
                    top: y(m) - 7,
                    child: Text(
                      Format.clock((m + 12 * 60) % minutesInDay),
                      textAlign: TextAlign.right,
                      style: AppText.caption.copyWith(color: AppColour.labelTertiary),
                    ),
                  ),
                  Positioned(
                    left: _gutter,
                    right: 0,
                    top: y(m),
                    child: Container(height: 1, color: AppColour.separator),
                  ),
                ],
                for (final n in nights)
                  Positioned(
                    left: _gutter + (n.day - 1) * column,
                    width: column,
                    top: 0,
                    bottom: 0,
                    child: _Night(
                      name: _weekdayNames[n.day - 1],
                      length: n.length,
                      bedtime: n.bedtime,
                      wake: n.wake,
                      short: n.length < goal,
                      barWidth: bar,
                      top: y(_fromNoon(n.bedtime)),
                      bottom: y(_fromNoon(n.bedtime) + n.length),
                      onTap: () => _editNights(context, ref, profile, nights: {n.day}),
                      labelled: column >= 64,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// One night in the chart: its name and length at the top, and its bar, lit when pointed at.
class _Night extends StatefulWidget {
  const _Night({
    required this.name,
    required this.length,
    required this.bedtime,
    required this.wake,
    required this.short,
    required this.barWidth,
    required this.top,
    required this.bottom,
    required this.onTap,
    required this.labelled,
  });

  /// Whether there is room for the times beside the bar.
  final bool labelled;
  final String name;
  final int length;
  final int bedtime;
  final int wake;
  final bool short;
  final double barWidth;
  final double top;
  final double bottom;
  final VoidCallback onTap;

  @override
  State<_Night> createState() => _NightState();
}

class _NightState extends State<_Night> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colour = widget.short ? AppColour.orange : AppColour.indigo;
    final tint = widget.short ? AppColour.orange : AppColour.label;
    return Semantics(
      button: true,
      label: '${widget.name} night, ${Format.clock(widget.bedtime)} to ${Format.clock(widget.wake)}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: AppMotion.quick,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _hovered ? AppColour.fill : null,
                    borderRadius: AppRadius.mediumAll,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Column(
                  children: [
                    Text(widget.name, style: AppText.footnote),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Format.estimate(widget.length),
                        maxLines: 1,
                        style: AppText.numeric.copyWith(color: tint, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: widget.top,
                height: math.max(widget.bottom - widget.top, 6),
                child: Center(
                  child: AnimatedContainer(
                    duration: AppMotion.quick,
                    width: widget.barWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colour.withValues(alpha: _hovered ? 1 : 0.9),
                          colour.withValues(alpha: _hovered ? 0.85 : 0.65),
                        ],
                      ),
                      borderRadius: AppRadius.roundAll,
                    ),
                  ),
                ),
              ),
              // Going to bed above the bar, getting up below it, where there is room.
              if (widget.labelled) Positioned(
                left: 0,
                right: 0,
                top: widget.top - 17,
                child: Text(
                  Format.clock(widget.bedtime),
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: AppColour.labelSecondary),
                ),
              ),
              if (widget.labelled) Positioned(
                left: 0,
                right: 0,
                top: widget.bottom + 3,
                child: Text(
                  Format.clock(widget.wake),
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: AppColour.labelSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sets [nights] — or, with none given, whichever the dialog is told — to one bedtime and
/// one time to get up.
Future<void> _editNights(BuildContext context, WidgetRef ref, CapacityProfile profile, {Set<int> nights = const {}}) async {
  final settings = CapacityMapping.settings(profile);
  final repo = ref.read(appScopeProvider).value?.capacity;
  final first = nights.isEmpty ? DateTime.monday : nights.first;
  final result = await showAppDialog<(Set<int>, int, int)>(
    context: context,
    builder: (context) => _SleepDialog(
      bedtimeMin: settings.sleepOn(first).bedtimeMin,
      wakeMin: settings.sleepOn(CapacitySettings.dayAfter(first)).wakeMin,
      nights: nights,
    ),
  );
  if (result == null || repo == null) return;
  final (chosen, bedtime, wake) = result;
  // Each night sets the bedtime of the day it starts on and getting up on the next, so two
  // nights in a row share the day between them.
  final days = <int, DaySleep>{};
  DaySleep current(int day) => days[day] ?? settings.sleepOn(day);
  for (final night in chosen) {
    days[night] = DaySleep(wakeMin: current(night).wakeMin, bedtimeMin: bedtime);
    final next = CapacitySettings.dayAfter(night);
    days[next] = DaySleep(wakeMin: wake, bedtimeMin: current(next).bedtimeMin);
  }
  final changed = {
    for (final MapEntry(key: day, value: sleep) in days.entries)
      if (sleep.wakeMin != sleep.bedtimeMin && settings.sleepOn(day) != sleep) day: sleep,
  };
  if (changed.isNotEmpty) await repo.setSleep(profile.id, changed);
}

// --- Rules --------------------------------------------------------------------------------

class _RulesTab extends ConsumerWidget {
  const _RulesTab({required this.profile, this.today});

  final CapacityProfile profile;

  /// Today as these rules make it, shown above them so a change shows its effect at once.
  final DayCapacity? today;

  static const _sideBySideFrom = 1080.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appScopeProvider).value?.capacity;
    final effects = ref.watch(settingEffectsProvider);
    final focusPercent = (profile.focusFactor * 100).round();
    final compact = AppLayout.compact(context);

    String step(String step, int change) => change == 0
        ? '$step more would change nothing this week.'
        : change < 0
        ? '$step more leaves about ${Format.estimate(-change)} less a day.'
        : '$step more adds about ${Format.estimate(change)} a day.';

    _RuleRow length({
      required String title,
      required String subtitle,
      required int value,
      required int stepMin,
      required int min,
      required int max,
      required void Function(int) save,
      bool bareMinutes = false,
    }) => _RuleRow(
      title: title,
      subtitle: subtitle,
      value: Format.estimate(value),
      onStep: (d) => save((value + d * stepMin).clamp(min, max)),
      onSubmit: (text) {
        final typed = TimeEntry.duration(text, bareMinutes: bareMinutes);
        if (typed == null) return false;
        save(typed.clamp(min, max));
        return true;
      },
    );

    final meals = _Group(
                  title: 'Taken out of each day',
                  rows: [
                    length(
                      title: 'Meals',
                      subtitle: step(Format.estimate(SettingEffects.mealsStepMin), effects.mealsStep),
                      value: profile.mealsMin,
                      stepMin: SettingEffects.mealsStepMin,
                      min: 0,
                      max: 300,
                      save: (v) => repo?.updateProfile(profile.id, mealsMin: v),
                    ),
                    length(
                      title: 'Buffer',
                      subtitle: step(Format.estimate(SettingEffects.bufferStepMin), effects.bufferStep),
                      value: profile.bufferMin,
                      stepMin: SettingEffects.bufferStepMin,
                      min: 0,
                      max: 300,
                      save: (v) => repo?.updateProfile(profile.id, bufferMin: v),
                    ),
                  ],
                  footer: 'Eating, getting around and the small things every day loses, taken out of '
                      'its free time before anything is planned.',
                );
    final focus = _Group(
                  title: 'Turning free time into work',
                  rows: [
                    _RuleRow(
                      title: 'Focus factor',
                      subtitle: profile.focusFactor >= 1
                          ? 'Every free minute counts.'
                          : 'A free hour counts as ${Format.estimate((60 * profile.focusFactor).round())}. '
                                '${step('${SettingEffects.focusStepPercent}%', effects.focusStep)}',
                      value: '$focusPercent%',
                      keyboardType: TextInputType.number,
                      onStep: (d) => repo?.updateProfile(
                        profile.id,
                        focusFactor: (profile.focusFactor + d * SettingEffects.focusStepPercent / 100).clamp(0.3, 1.0),
                      ),
                      onSubmit: (text) {
                        final typed = TimeEntry.percent(text);
                        if (typed == null) return false;
                        repo?.updateProfile(profile.id, focusFactor: (typed / 100).clamp(0.3, 1.0));
                        return true;
                      },
                    ),
                    length(
                      title: 'Shortest usable gap',
                      subtitle: effects.discardedPerDay == 0
                          ? 'No free time this week comes in stretches that short.'
                          : 'Sets aside about ${Format.estimate(effects.discardedPerDay)} of free time a day this week.',
                      value: profile.minGapMin,
                      stepMin: SettingEffects.minGapStepMin,
                      min: 5,
                      max: 120,
                      bareMinutes: true,
                      save: (v) => repo?.updateProfile(profile.id, minGapMin: v),
                    ),
                  ],
                  footer: 'How much of your free time becomes real work, and how short a stretch is '
                      'too short to start anything in.',
                );

    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.lg),
        children: [
          if (today case final day?) ...[
            _DayBreakdown(day: day, title: 'Today, by these rules'),
            const SizedBox(height: AppSpace.xl),
          ],
          if (constraints.maxWidth >= _sideBySideFrom)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: meals),
                const SizedBox(width: AppSpace.xl),
                Expanded(child: focus),
              ],
            )
          else ...[
            meals,
            const SizedBox(height: AppSpace.xl),
            focus,
          ],
        ],
      ),
    );
  }
}

/// A group of settings as macOS lays them out: rows on one rounded surface, a hairline
/// between them, a title above and a line of explanation below.
class _Group extends StatelessWidget {
  const _Group({required this.rows, this.title, this.footer});

  final String? title;
  final List<Widget> rows;
  final String? footer;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title case final title?)
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.md, bottom: AppSpace.sm),
          child: Text(title, style: AppText.headline),
        ),
      AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) const Padding(padding: EdgeInsets.only(left: AppSpace.lg), child: AppDivider()),
              row,
            ],
          ],
        ),
      ),
      if (footer case final footer?)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, 0),
          child: Text(footer, style: AppText.footnote.copyWith(color: AppColour.labelTertiary)),
        ),
    ],
  );
}

/// One setting: its name and what it does now, and its value, stepped or typed.
class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.title,
    required this.value,
    required this.onStep,
    required this.onSubmit,
    this.subtitle,
    this.keyboardType = TextInputType.datetime,
  });

  final String title;
  final String? subtitle;
  final String value;
  final void Function(int direction) onStep;
  final bool Function(String text) onSubmit;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body),
              if (subtitle case final subtitle?)
                Text(subtitle, style: AppText.footnote.copyWith(color: AppColour.labelSecondary)),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.lg),
        TypedValue(text: value, keyboardType: keyboardType, onSubmit: onSubmit),
        const SizedBox(width: AppSpace.sm),
        _Stepper(onStep: onStep),
      ],
    ),
  );
}

/// A stepper as iOS draws one: minus and plus in one capsule, a hairline between them.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.onStep});

  final void Function(int direction) onStep;

  @override
  Widget build(BuildContext context) {
    final height = AppLayout.touch ? AppSize.touch - AppSpace.sm : AppSize.chip;
    Widget half(IconData icon, int direction, String label) => Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Ends any typing first, so the field shows the stepped value afterwards.
            FocusManager.instance.primaryFocus?.unfocus();
            onStep(direction);
          },
          child: SizedBox(
            width: height + 6,
            height: height,
            child: Icon(icon, size: 14, color: AppColour.labelSecondary),
          ),
        ),
      ),
    );
    return Container(
      decoration: const BoxDecoration(color: AppColour.fill, borderRadius: AppRadius.smallAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          half(Icons.remove_rounded, -1, 'Less'),
          Container(width: 1, height: height * 0.5, color: AppColour.separator),
          half(Icons.add_rounded, 1, 'More'),
        ],
      ),
    );
  }
}
