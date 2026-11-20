part of 'today_screen.dart';

// Plan my day, Focus, the Deadline radar and the Daily review, each a page of its own in the
// sidebar. The home page shows each as a card; these are the same engines' figures with the
// room to show all of them, and to act on them where they are shown.

/// A page under Planning: its header, then its content, scrolling under it.
class _PlanningPage extends StatelessWidget {
  const _PlanningPage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.onMenu,
    this.accessory,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onMenu;
  final Widget? accessory;

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, compact ? AppSpace.sm : AppSpace.xl, gutter, compact ? 0 : AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(title: title, subtitle: subtitle, onMenu: onMenu, accessory: accessory),
          SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.lg),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A figure: what it is, the number, and a line on what it means.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.detail, this.tint});

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
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(color: AppColour.labelTertiary),
        ),
      ],
    ),
  );
}

/// Figures in a row, or two to a line on a phone.
class _Stats extends StatelessWidget {
  const _Stats(this.stats);

  final List<Widget> stats;

  @override
  Widget build(BuildContext context) {
    if (AppLayout.compact(context)) {
      return LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          children: [
            for (final s in stats) SizedBox(width: (constraints.maxWidth - AppSpace.md) / 2, child: s),
          ],
        ),
      );
    }
    return Row(
      children: [
        for (final (i, s) in stats.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpace.lg),
          Expanded(child: s),
        ],
      ],
    );
  }
}

/// A titled card on a planning page.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.compact(context);
    return AppSurface(
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
              Expanded(child: Text(title, style: AppText.headline)),
              ?trailing,
            ],
          ),
          if (subtitle case final subtitle?)
            Text(subtitle, style: AppText.footnote.copyWith(color: AppColour.labelTertiary)),
          const SizedBox(height: AppSpace.md),
          child,
        ],
      ),
    );
  }
}

/// Two cards side by side where there is room, one above the other where there is not.
class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second, this.firstFlex = 3, this.secondFlex = 2});

  final Widget first;
  final Widget second;
  final int firstFlex;
  final int secondFlex;

  static const _sideBySideFrom = 1000.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < _sideBySideFrom) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: AppSpace.lg), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: firstFlex, child: first),
          const SizedBox(width: AppSpace.lg),
          Expanded(flex: secondFlex, child: second),
        ],
      );
    },
  );
}

/// Choices in a tray, the chosen one raised: a segmented control.
class _Choice<T> extends StatelessWidget {
  const _Choice({required this.values, required this.labels, required this.selected, required this.onSelect});

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelect;

  static const _segment = 96.0;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected);
    return Container(
      height: 30,
      width: _segment * values.length + 4,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: AppColour.fill, borderRadius: AppRadius.mediumAll),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: AppMotion.of(context, AppMotion.medium),
            curve: AppMotion.standard,
            left: _segment * index,
            top: 0,
            bottom: 0,
            width: _segment,
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
              for (final (i, value) in values.indexed)
                SizedBox(
                  width: _segment,
                  child: Semantics(
                    button: true,
                    selected: value == selected,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(value),
                        child: Center(
                          child: Text(
                            labels[i],
                            style: AppText.footnote.copyWith(
                              color: value == selected ? AppColour.label : AppColour.labelSecondary,
                              fontWeight: value == selected ? FontWeight.w600 : FontWeight.w500,
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
  }
}

// --- Plan my day ------------------------------------------------------------------------

class _PlanOffsetNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void show(int offset) => state = offset;
}

/// Today's plan, or tomorrow's.
final _planOffsetProvider = NotifierProvider<_PlanOffsetNotifier, int>(_PlanOffsetNotifier.new);

/// Gives each task in [plan] its time on [day], as one change that one Undo takes back.
Future<void> _acceptPlan(WidgetRef ref, DayPlan plan, DateTime day, String dayName) async {
  final scope = ref.read(appScopeProvider).value;
  if (scope == null) return;
  final tasks = {for (final t in ref.read(allTasksProvider).value ?? const <Task>[]) t.id: t};
  for (final slot in plan.slots) {
    await scope.tasks.setTime(
      slot.taskId,
      DateTime(day.year, day.month, day.day).add(Duration(minutes: slot.startMin)),
      // A task with no estimate takes the length it was planned for as one.
      lengthMin: tasks[slot.taskId]?.estimateMin == null ? slot.lengthMin : null,
    );
  }
  final n = plan.slots.length;
  ref.read(undoProvider.notifier).offer('Planned $n ${n == 1 ? 'task' : 'tasks'} into $dayName', () async {
    for (final slot in plan.slots) {
      await scope.tasks.setTime(slot.taskId, null);
    }
  });
}

/// Plan my day: the day's open work laid into its free time around its classes, shown before
/// anything changes, and accepted at once.
class PlanDayScreen extends ConsumerWidget {
  const PlanDayScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(_planOffsetProvider);
    final plan = ref.watch(planForProvider(offset));
    final days = ref.watch(dayCapacityProvider);
    final day = days.length > offset ? days[offset] : null;
    final dayName = offset == 0 ? 'today' : 'tomorrow';
    final n = plan.slots.length;

    final choice = _Choice<int>(
      values: const [0, 1],
      labels: const ['Today', 'Tomorrow'],
      selected: offset,
      onSelect: (o) => ref.read(_planOffsetProvider.notifier).show(o),
    );

    return _PlanningPage(
      title: 'Plan my day',
      subtitle: 'Your open work, laid into the free time you have',
      onMenu: onMenu,
      accessory: choice,
      children: [
        _Stats([
          _Stat(
            label: offset == 0 ? 'Free today' : 'Free tomorrow',
            value: Format.estimate(day?.usableMin ?? 0),
            detail: 'after classes, meals and buffer',
          ),
          _Stat(
            label: 'In this plan',
            value: Format.estimate(plan.plannedMin),
            detail: '$n ${n == 1 ? 'task' : 'tasks'} given a time',
            tint: AppColour.accent,
          ),
          _Stat(
            label: "Doesn't fit",
            value: '${plan.unplaced.length}',
            detail: plan.unplaced.isEmpty ? 'everything fits' : 'too long for any gap left',
            tint: plan.unplaced.isEmpty ? AppColour.green : AppColour.orange,
          ),
        ]),
        const SizedBox(height: AppSpace.lg),
        if (day != null)
          _Panel(
            title: offset == 0 ? 'Today' : 'Tomorrow',
            subtitle: n == 0
                ? null
                : 'Planned tasks are dashed until you accept them. Nothing changes before then, '
                      'and one Undo takes it all back.',
            trailing: PrimaryButton(
              label: n == 0 ? 'Nothing to plan' : 'Accept plan',
              enabled: n > 0,
              onTap: () => _acceptPlan(ref, plan, day.date, dayName),
            ),
            child: _DayAgendaWithPlan(day: day, plan: plan, isToday: offset == 0),
          ),
      ],
    );
  }
}

/// The day as an agenda: its classes, the tasks already at a time, and the plan's tasks
/// between them, dashed, all in the order they happen.
class _DayAgendaWithPlan extends ConsumerWidget {
  const _DayAgendaWithPlan({required this.day, required this.plan, required this.isToday});

  final DayCapacity day;
  final DayPlan plan;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = ref.watch(blockColoursProvider);
    final timed = ref.watch(taskSlotsProvider(day.date));
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    final entries = <(int, int, Widget)>[
      for (final b in day.blocks)
        (b.startMin, b.endMin, _AgendaEntry(
          start: b.startMin,
          end: b.endMin,
          title: b.title,
          colour: BlockStyle.colourIn(colours, b.title),
          kind: 'Class',
        )),
      for (final t in timed)
        (t.startMin, t.endMin, _AgendaEntry(
          start: t.startMin,
          end: t.endMin,
          title: t.title,
          colour: AppColour.label,
          kind: t.done ? 'Done' : 'At its time',
          onTap: () => ref.read(openTaskProvider.notifier).open(t.taskId),
        )),
      for (final s in plan.slots)
        (s.startMin, s.endMin, _AgendaEntry(
          start: s.startMin,
          end: s.endMin,
          title: s.title,
          colour: AppColour.accent,
          kind: 'Planned',
          dashed: true,
          onTap: () => ref.read(openTaskProvider.notifier).open(s.taskId),
        )),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Text(
              'Nothing on this day yet: no classes, and no open work to plan into it.',
              style: AppText.callout.copyWith(color: AppColour.labelSecondary),
            ),
          ),
        for (final (i, (start, _, entry)) in entries.indexed) ...[
          // Now, between what is over and what is still to come.
          if (isToday && start > nowMin && (i == 0 || entries[i - 1].$1 <= nowMin))
            const _NowLine(),
          entry,
        ],
        if (plan.unplaced.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          Text("Doesn't fit whole", style: AppText.caption),
          const SizedBox(height: AppSpace.xs),
          for (final task in plan.unplaced)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 15, color: AppColour.orange),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.callout)),
                  Text(Format.estimate(task.minutes), style: AppText.numeric.copyWith(color: AppColour.orange)),
                ],
              ),
            ),
          Text(
            'No gap left is long enough for these. Split one into smaller tasks, or give it a '
            'time by hand.',
            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
          ),
        ],
      ],
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppColour.red, shape: BoxShape.circle),
        ),
        Expanded(child: Container(height: 1.5, color: AppColour.red)),
      ],
    ),
  );
}

class _AgendaEntry extends StatefulWidget {
  const _AgendaEntry({
    required this.start,
    required this.end,
    required this.title,
    required this.colour,
    required this.kind,
    this.dashed = false,
    this.onTap,
  });

  final int start;
  final int end;
  final String title;
  final Color colour;
  final String kind;
  final bool dashed;
  final VoidCallback? onTap;

  @override
  State<_AgendaEntry> createState() => _AgendaEntryState();
}

class _AgendaEntryState extends State<_AgendaEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = AnimatedContainer(
      duration: AppMotion.quick,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mediumAll,
        color: widget.colour.withValues(alpha: _hovered ? 0.16 : (widget.dashed ? 0.07 : 0.11)),
        border: widget.dashed
            ? Border.all(color: widget.colour.withValues(alpha: 0.55))
            : Border(left: BorderSide(color: widget.colour, width: 3)),
      ),
      // On a phone the time goes above the name, so the name keeps the width.
      child: AppLayout.compact(context)
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Format.clockRange(widget.start, widget.end)} · ${widget.kind}',
                        style: AppText.caption.copyWith(
                          color: widget.dashed ? AppColour.accent : AppColour.labelSecondary,
                        ),
                      ),
                      Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.callout),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(Format.estimate(widget.end - widget.start), style: AppText.caption),
              ],
            )
          : Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              Format.clockRange(widget.start, widget.end),
              style: AppText.numeric.copyWith(color: AppColour.labelSecondary),
            ),
          ),
          Expanded(
            child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.callout),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(Format.estimate(widget.end - widget.start), style: AppText.caption),
          const SizedBox(width: AppSpace.md),
          SizedBox(
            width: 76,
            child: Text(
              widget.kind,
              textAlign: TextAlign.right,
              style: AppText.caption.copyWith(color: widget.dashed ? AppColour.accent : AppColour.labelTertiary),
            ),
          ),
        ],
      ),
    );
    if (widget.onTap == null) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: row),
    );
  }
}

// --- Focus ------------------------------------------------------------------------------

/// Focus: the timer, what to start it on, and where the week's focus went.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  /// Ticks only while a session runs, so an idle page wakes nothing.
  Timer? _tick;

  void _ticking(bool on) {
    if (on && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!on && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(focusStatsProvider);
    final running = ref.watch(runningFocusProvider);
    final upNext = ref.watch(upNextProvider);
    final controller = ref.read(focusControllerProvider);
    final preferences = ref.watch(preferencesProvider).value ?? const Preferences();
    final tasks = {for (final t in ref.watch(allTasksProvider).value ?? const <Task>[]) t.id: t};
    final now = DateTime.now();
    _ticking(running != null);

    final Widget timer;
    if (running != null) {
      final total = Duration(minutes: running.plannedMin);
      final left = running.startedAt.add(total).difference(now);
      final shown = left.isNegative ? Duration.zero : left;
      final progress = total.inSeconds == 0 ? 1.0 : 1 - shown.inSeconds / total.inSeconds;
      final isBreak = running.kind == 'break';
      final colour = isBreak ? AppColour.green : AppColour.accent;
      timer = Row(
        children: [
          SizedBox(
            width: 148,
            height: 148,
            child: CustomPaint(
              painter: _SessionRing(progress: progress.clamp(0, 1).toDouble(), colour: colour),
              child: Center(
                child: Text(
                  '${shown.inMinutes.toString().padLeft(2, '0')}:${(shown.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: AppText.metric.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isBreak ? 'On a break' : 'Focusing on', style: AppText.footnote),
                const SizedBox(height: 2),
                Text(
                  isBreak ? 'Back to it soon' : tasks[running.taskId]?.title ?? 'Nothing in particular',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title3,
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    PrimaryButton(label: isBreak ? 'Skip the break' : 'Stop', enabled: true, onTap: controller.stop),
                    if (!isBreak)
                      GhostButton(
                        label: 'Stop and take a break · ${Format.estimate(preferences.breakMin)}',
                        onTap: () async {
                          await controller.stop();
                          await controller.startBreak();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      timer = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(upNext == null ? 'Nothing is due today' : 'Up next', style: AppText.footnote),
          const SizedBox(height: 2),
          if (upNext != null) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => ref.read(openTaskProvider.notifier).open(upNext.id),
                child: Text(upNext.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.title3),
              ),
            ),
            Text(
              [
                if (upNext.dueDay case final due?) Format.dueDay(due, now),
                Format.estimate(upNext.minutes),
              ].join(' · '),
              style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
            ),
          ] else
            Text('Focus on anything, or take the time back.', style: AppText.title3),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              PrimaryButton(
                label: 'Start focus · ${Format.estimate(preferences.focusMin)}',
                enabled: true,
                onTap: () => controller.start(taskId: upNext?.id),
              ),
              if (upNext != null) GhostButton(label: 'On nothing in particular', onTap: controller.start),
              GhostButton(label: 'Take a break · ${Format.estimate(preferences.breakMin)}', onTap: controller.startBreak),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'The lengths are in Settings. Focus is kept with the task, and shows on it beside its '
            'estimate.',
            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
          ),
        ],
      );
    }

    final byTask = stats.byTask.entries.where((e) => tasks.containsKey(e.key)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final most = byTask.isEmpty ? 1 : byTask.first.value;

    return _PlanningPage(
      title: 'Focus',
      subtitle: 'One thing at a time, and where the time went',
      onMenu: widget.onMenu,
      children: [
        _Stats([
          _Stat(label: 'Today', value: Format.estimate(stats.todayMin), detail: 'focused', tint: AppColour.accent),
          _Stat(label: 'Last seven days', value: Format.estimate(stats.weekMin), detail: 'focused'),
          _Stat(
            label: 'Streak',
            value: '${stats.streakDays} ${stats.streakDays == 1 ? 'day' : 'days'}',
            detail: 'in a row with some focus',
            tint: stats.streakDays > 1 ? AppColour.orange : null,
          ),
        ]),
        const SizedBox(height: AppSpace.lg),
        _Pair(
          first: _Panel(title: running == null ? 'Start' : 'Now', child: timer),
          second: _Panel(
            title: 'Last seven days',
            child: _FocusWeek(byDay: stats.byDay, today: now),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        _Panel(
          title: 'Where the time went',
          subtitle: 'Focus on each task in the last seven days',
          child: byTask.isEmpty
              ? Text(
                  'Nothing yet. Start a session on a task and it shows here.',
                  style: AppText.callout.copyWith(color: AppColour.labelSecondary),
                )
              : Column(
                  children: [
                    for (final e in byTask.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(tasks[e.key]!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.callout),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: (e.value / most).clamp(0.02, 1).toDouble(),
                                  child: Container(
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColour.accent,
                                      borderRadius: AppRadius.roundAll,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            SizedBox(
                              width: 64,
                              child: Text(Format.estimate(e.value), textAlign: TextAlign.right, style: AppText.numeric),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// A ring that fills as the session runs.
class _SessionRing extends CustomPainter {
  _SessionRing({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(7);
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
      ..color = AppColour.fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10);
  }

  @override
  bool shouldRepaint(_SessionRing old) => old.progress != progress || old.colour != colour;
}

/// Seven bars, a day each, today last.
class _FocusWeek extends StatelessWidget {
  const _FocusWeek({required this.byDay, required this.today});

  final List<int> byDay;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final most = math.max(60, byDay.fold(0, math.max));
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, minutes) in byDay.indexed)
            Expanded(
              child: Tooltip(
                message: Format.estimate(minutes),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      minutes == 0 ? '' : Format.estimate(minutes),
                      maxLines: 1,
                      style: AppText.caption.copyWith(color: AppColour.labelSecondary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 4 + 116 * minutes / most,
                      decoration: BoxDecoration(
                        color: i == byDay.length - 1 ? AppColour.accent : AppColour.accent.withValues(alpha: 0.45),
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Format.weekdayShort(today.subtract(Duration(days: byDay.length - 1 - i))),
                      style: AppText.caption.copyWith(
                        color: i == byDay.length - 1 ? AppColour.label : AppColour.labelTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Deadline radar ---------------------------------------------------------------------

/// The next fortnight: each day's work against its time, its deadlines, and every task that
/// will not fit, or only just.
class RadarScreen extends ConsumerWidget {
  const RadarScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radar = ref.watch(radarProvider);
    final tasks = {for (final t in ref.watch(allTasksProvider).value ?? const <Task>[]) t.id: t};
    final now = DateTime.now();
    final impossible = radar.risks.where((r) => r.state == Feasibility.impossible).length;
    final tight = radar.risks.length - impossible;
    final due = radar.days.fold(0, (sum, d) => sum + d.due.length);
    final busiest = radar.days.isEmpty
        ? null
        : radar.days.reduce((a, b) => b.fill > a.fill ? b : a);

    return _PlanningPage(
      title: 'Deadline radar',
      subtitle: 'The next two weeks, and what will not fit in them',
      onMenu: onMenu,
      children: [
        _Stats([
          _Stat(
            label: "Won't fit",
            value: '$impossible',
            detail: impossible == 0 ? 'nothing is late on paper' : 'short of time before they are due',
            tint: impossible == 0 ? AppColour.green : AppColour.red,
          ),
          _Stat(
            label: 'Tight',
            value: '$tight',
            detail: 'fit, with little to spare',
            tint: tight == 0 ? null : AppColour.orange,
          ),
          _Stat(label: 'Due', value: '$due', detail: 'in the next 14 days'),
          _Stat(
            label: 'Busiest day',
            value: busiest == null || busiest.loadMin == 0 ? '—' : Format.dueDay(busiest.date, now),
            detail: busiest == null || busiest.loadMin == 0
                ? 'nothing planned yet'
                : '${Format.estimate(busiest.loadMin)} of ${Format.estimate(busiest.capacityMin)}',
          ),
        ]),
        const SizedBox(height: AppSpace.lg),
        _Panel(
          title: 'Each day',
          subtitle: 'The bar is the time a day has; the fill is the work planned into it. A dot is a deadline.',
          child: _RadarChart(radar: radar, now: now),
        ),
        const SizedBox(height: AppSpace.lg),
        _Panel(
          title: radar.risks.isEmpty ? 'Nothing at risk' : 'At risk',
          child: radar.risks.isEmpty
              ? Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColour.green),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        'Everything due in the next two weeks fits in the time you have.',
                        style: AppText.callout,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (final (i, risk) in radar.risks.indexed)
                      if (tasks[risk.taskId] case final task?) ...[
                        if (i > 0) const AppDivider(),
                        _RiskRow(task: task, risk: risk, now: now),
                      ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _RadarChart extends StatelessWidget {
  const _RadarChart({required this.radar, required this.now});

  final Radar radar;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final most = radar.days.fold(60, (m, d) => math.max(m, math.max(d.capacityMin, d.loadMin)));
    final height = AppLayout.compact(context) ? 110.0 : 150.0;
    // As tall as its labels need at any text size, rather than a height that cuts them off.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in radar.days)
            Expanded(
              child: Tooltip(
                message: '${Format.dueDay(day.date, now)}: ${Format.estimate(day.loadMin)} planned of '
                    '${Format.estimate(day.capacityMin)}${day.due.isEmpty ? '' : ', ${day.due.length} due'}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A deadline as a dot, red when what is due then will not fit.
                      SizedBox(
                        height: 12,
                        child: day.due.isEmpty
                            ? null
                            : Center(
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: day.due.any((id) => radar.risks.any((r) => r.taskId == id))
                                        ? AppColour.red
                                        : AppColour.label,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      // The day's time as a track, and the work planned into it as its fill.
                      SizedBox(
                        height: height,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: math.max(4, height * math.max(day.capacityMin, day.loadMin) / most),
                            decoration: const BoxDecoration(
                              color: AppColour.fill,
                              borderRadius: AppRadius.smallAll,
                            ),
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: day.capacityMin <= 0 && day.loadMin <= 0
                                  ? 0
                                  : (day.loadMin / math.max(day.capacityMin, day.loadMin)).clamp(0, 1).toDouble(),
                              widthFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.smallAll,
                                  color: day.over
                                      ? AppColour.red
                                      : day.fill > 0.85
                                      ? AppColour.orange
                                      : AppColour.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Format.weekdayShort(day.date).substring(0, 1),
                        style: AppText.caption.copyWith(
                          color: DateUtils.isSameDay(day.date, now) ? AppColour.accent : AppColour.labelTertiary,
                        ),
                      ),
                      Text(
                        '${day.date.day}',
                        style: AppText.caption.copyWith(
                          color: DateUtils.isSameDay(day.date, now) ? AppColour.accent : AppColour.labelSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiskRow extends ConsumerWidget {
  const _RiskRow({required this.task, required this.risk, required this.now});

  final Task task;
  final RadarRisk risk;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impossible = risk.state == Feasibility.impossible;
    final colour = impossible ? AppColour.red : AppColour.orange;
    final plan = risk.plan;
    final verdict = impossible
        ? (plan.shortfallMin > 0 ? '${Format.estimate(plan.shortfallMin)} short' : "Won't fit")
        : 'Tight';
    final detail = [
      if (plan.task.dueDay case final due?) Format.dueSentence(due, now),
      Format.estimate(plan.task.estimateMin),
      if (plan.startDay case final start? when !impossible) 'start by ${_lowerDay(Format.dueDay(start, now))}',
      if (impossible) 'start today and still short',
    ].join(' · ');
    return InkWell(
      onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
      borderRadius: AppRadius.mediumAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: colour, shape: BoxShape.circle)),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
                  Text(detail, style: AppText.footnote.copyWith(color: AppColour.labelTertiary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
              decoration: BoxDecoration(color: colour.withValues(alpha: 0.16), borderRadius: AppRadius.roundAll),
              child: Text(verdict, style: AppText.caption.copyWith(color: colour, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Daily review -----------------------------------------------------------------------

/// The day looked back on: what got done, what slipped and what to do with each, and
/// tomorrow planned before it starts.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(dailyReviewProvider);
    final scope = ref.watch(appScopeProvider).value;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final slipped = _Panel(
      title: 'Still open',
      subtitle: review.slipped.isEmpty ? null : 'Due today or earlier, and not done. Decide on each.',
      child: review.slipped.isEmpty
          ? Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColour.green),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text('Nothing left over from today.', style: AppText.callout)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, task) in review.slipped.indexed) ...[
                  if (i > 0) const AppDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body),
                        if (task.dueDay case final due?)
                          Text(
                            Format.dueSentence(due, now).replaceFirst('Due ', 'Was due '),
                            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
                          ),
                        const SizedBox(height: AppSpace.xs),
                        Transform.translate(
                          offset: const Offset(-AppSpace.sm, 0),
                          child: Wrap(
                            children: [
                              _ReviewAction(
                                label: 'Tomorrow',
                                onTap: () => scope?.tasks.setDue(task.id, dueDate: iso(tomorrow)),
                              ),
                              _ReviewAction(
                                label: 'Pick a day',
                                onTap: () async {
                                  final day = await showDatePicker(
                                    context: context,
                                    initialDate: tomorrow,
                                    firstDate: DateTime(now.year, now.month, now.day),
                                    lastDate: DateTime(now.year + 1, now.month, now.day),
                                  );
                                  if (day != null) await scope?.tasks.setDue(task.id, dueDate: iso(day));
                                },
                              ),
                              _ReviewAction(
                                label: 'Done',
                                tint: AppColour.green,
                                onTap: () => scope?.tasks.setDone(task.id, done: true),
                              ),
                              _ReviewAction(
                                label: 'Drop',
                                tint: AppColour.red,
                                onTap: () async {
                                  await scope?.tasks.softDelete(task.id);
                                  ref.read(undoProvider.notifier).offer(
                                    'Dropped "${task.title}"',
                                    () async => scope?.tasks.restore(task.id),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );

    final done = _Panel(
      title: 'Done today',
      child: review.done.isEmpty
          ? Text('Nothing finished today — tomorrow is another one.',
              style: AppText.callout.copyWith(color: AppColour.labelSecondary))
          : Column(
              children: [
                for (final task in review.done)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_rounded, size: 16, color: AppColour.green),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.callout),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );

    return _PlanningPage(
      title: 'Daily review',
      subtitle: 'The day, looked back on, and tomorrow set up',
      onMenu: onMenu,
      children: [
        _Stats([
          _Stat(
            label: 'Done today',
            value: '${review.done.length}',
            detail: review.done.length == 1 ? 'task finished' : 'tasks finished',
            tint: review.done.isEmpty ? null : AppColour.green,
          ),
          _Stat(
            label: 'Still open',
            value: '${review.slipped.length}',
            detail: 'to decide about',
            tint: review.slipped.isEmpty ? null : AppColour.orange,
          ),
          _Stat(
            label: 'Focused',
            value: Format.estimate(review.focusMin),
            detail: review.plannedMin > 0 ? 'of ${Format.estimate(review.plannedMin)} planned' : 'nothing was planned',
            tint: AppColour.accent,
          ),
        ]),
        const SizedBox(height: AppSpace.lg),
        _Pair(
          first: slipped,
          second: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Panel(title: 'Tomorrow', child: _PlanTomorrow(heading: false)),
              const SizedBox(height: AppSpace.lg),
              done,
            ],
          ),
          firstFlex: 1,
          secondFlex: 1,
        ),
      ],
    );
  }
}

class _ReviewAction extends StatelessWidget {
  const _ReviewAction({required this.label, required this.onTap, this.tint});

  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppLayout.touch ? AppSpace.md : AppSpace.xs),
        child: Text(label, style: AppText.footnote.copyWith(color: tint ?? AppColour.accent, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

/// "today" and "tomorrow" in the middle of a sentence; a weekday keeps its capital.
String _lowerDay(String day) => day == 'Today' || day == 'Tomorrow' ? day.toLowerCase() : day;
