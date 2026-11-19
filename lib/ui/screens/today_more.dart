part of 'today_screen.dart';

// The home page's newer cards: focus and what is up next, the deadline radar, where to jump
// back in, and the evening's review. Each is a view of a pure engine's figures — FocusStats,
// UpNext, DeadlineRadar, DailyReviewer — through its provider.

/// Focus today, the streak, and the one task to start now.
class _FocusCard extends ConsumerWidget {
  const _FocusCard({required this.fill});

  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(focusStatsProvider);
    final running = ref.watch(runningFocusProvider);
    final upNext = ref.watch(upNextProvider);
    final controller = ref.read(focusControllerProvider);
    final preferences = ref.watch(preferencesProvider).value ?? const Preferences();
    final now = DateTime.now();
    final evening = now.hour * 60 + now.minute >= preferences.eveningMin;
    final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
    String? titleOf(String? id) => tasks.where((t) => t.id == id).firstOrNull?.title;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stats.todayMin == 0 ? 'No focus yet today' : '${Format.estimate(stats.todayMin)} focused today',
          style: AppText.title3,
        ),
        const SizedBox(height: 2),
        Text(
          stats.weekMin == 0
              ? 'Start a session on something below, or from any task.'
              : '${Format.estimate(stats.weekMin)} this week',
          style: AppText.footnote.copyWith(color: AppColour.labelSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        if (running != null) ...[
          Text(running.kind == 'break' ? 'On a break' : 'Focusing now', style: AppText.caption),
          const SizedBox(height: 2),
          Text(
            running.kind == 'break' ? 'Back to it soon' : titleOf(running.taskId) ?? 'On nothing in particular',
            style: AppText.callout.copyWith(color: AppColour.label),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.sm),
          GhostButton(label: running.kind == 'break' ? 'Skip the break' : 'Stop', onTap: controller.stop),
        ] else if (upNext != null) ...[
          Text('Up next', style: AppText.caption),
          const SizedBox(height: 2),
          InkWell(
            onTap: () => ref.read(openTaskProvider.notifier).open(upNext.id),
            child: Text(
              upNext.title,
              style: AppText.callout.copyWith(color: AppColour.label),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            [
              if (upNext.dueDay case final due?) Format.dueDay(due, now),
              Format.estimate(upNext.minutes),
            ].join(' · '),
            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
          ),
          const SizedBox(height: AppSpace.sm),
          GhostButton(
            label: 'Start focus · ${Format.estimate(preferences.focusMin)}',
            onTap: () => controller.start(taskId: upNext.id),
          ),
        ] else ...[
          Text('Nothing is due today.', style: AppText.callout),
          const SizedBox(height: AppSpace.sm),
          GhostButton(label: 'Start focus anyway', onTap: controller.start),
        ],
        if (stats.streakDays > 1) ...[
          const SizedBox(height: AppSpace.md),
          Text('${stats.streakDays} days in a row with focus',
              style: AppText.footnote.copyWith(color: AppColour.orange)),
        ],
      ],
    );

    return _Card(
      glow: AppColour.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeading(
            icon: Icons.timer_outlined,
            colour: AppColour.accent,
            label: 'Focus',
            // In the evening, the day's review, where it is always in view.
            trailing: evening ? _TextLink(label: 'Review the day', onTap: () => _showReview(context)) : null,
          ),
          const SizedBox(height: AppSpace.md),
          if (fill) Expanded(child: _CardScroll(child: body)) else body,
        ],
      ),
    );
  }
}

/// The next fortnight: each day's load against its time, its deadlines as marks, and the
/// tasks at risk.
class _RadarCard extends ConsumerWidget {
  const _RadarCard({required this.fill});

  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radar = ref.watch(radarProvider);
    final tasks = {for (final t in ref.watch(allTasksProvider).value ?? const <Task>[]) t.id: t};
    final now = DateTime.now();
    final atRisk = radar.risks.take(fill ? 6 : 3).toList();

    // Room for the tallest bar — a day planned past its time — with its deadline mark and day.
    final strip = SizedBox(
      height: 92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in radar.days)
            Expanded(
              child: Tooltip(
                message: '${Format.dueDay(day.date, now)}: ${Format.estimate(day.loadMin)} planned of '
                    '${Format.estimate(day.capacityMin)}'
                    '${day.due.isEmpty ? '' : ', ${day.due.length} due'}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (day.due.isNotEmpty)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: day.due.any((id) => radar.risks.any((r) => r.taskId == id))
                                ? AppColour.red
                                : AppColour.label,
                          ),
                        ),
                      Container(
                        height: 4 + 44 * day.fill.clamp(0, 1.2).toDouble(),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.smallAll,
                          color: day.over
                              ? AppColour.red
                              : day.fill > 0.85
                              ? AppColour.orange
                              : AppColour.accent.withValues(alpha: day.loadMin == 0 ? 0.25 : 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MTWTFSS'[day.date.weekday - 1],
                        style: AppText.caption.copyWith(
                          color: day.date.day == now.day && day.date.month == now.month
                              ? AppColour.label
                              : AppColour.labelTertiary,
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

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (atRisk.isEmpty)
          Text('Nothing at risk in the next two weeks.',
              style: AppText.footnote.copyWith(color: AppColour.labelSecondary))
        else
          for (final risk in atRisk)
            if (tasks[risk.taskId] case final task?)
              InkWell(
                onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
                borderRadius: AppRadius.mediumAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: risk.state == Feasibility.impossible ? AppColour.red : AppColour.orange,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(task.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.callout),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        risk.state == Feasibility.impossible
                            ? (risk.plan.shortfallMin > 0
                                ? '${Format.estimate(risk.plan.shortfallMin)} short'
                                : "Won't fit")
                            : 'Tight',
                        style: AppText.caption.copyWith(
                          color: risk.state == Feasibility.impossible ? AppColour.red : AppColour.orange,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(Format.dueDay(risk.plan.task.dueDay!, now),
                          style: AppText.caption.copyWith(color: AppColour.labelTertiary)),
                    ],
                  ),
                ),
              ),
      ],
    );

    return _Card(
      glow: radar.risks.isEmpty ? AppColour.green : AppColour.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeading(
            icon: Icons.radar_rounded,
            colour: radar.risks.isEmpty ? AppColour.green : AppColour.red,
            label: 'Deadline radar · next 14 days',
          ),
          const SizedBox(height: AppSpace.md),
          strip,
          const SizedBox(height: AppSpace.md),
          const AppDivider(),
          const SizedBox(height: AppSpace.sm),
          if (fill) Expanded(child: _CardScroll(child: list)) else list,
        ],
      ),
    );
  }
}

/// What was open lately, to go back to, and each project's pulse.
class _JumpBackCard extends ConsumerWidget {
  const _JumpBackCard({required this.fill});

  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentsProvider).value ?? const <Recent>[];
    final tasks = {for (final t in ref.watch(allTasksProvider).value ?? const <Task>[]) t.id: t};
    final notes = {for (final n in ref.watch(notesProvider).value ?? const <Note>[]) n.id: n};
    final projects = {for (final p in ref.watch(projectsProvider).value ?? const <Board>[]) p.id: p};
    final pulse = ref.watch(projectPulseProvider);
    final destinations = ref.read(destinationProvider.notifier);

    Widget row({required IconData icon, required String title, String? detail, required VoidCallback onTap, Color? colour}) =>
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mediumAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Row(
              children: [
                Icon(icon, size: 15, color: colour ?? AppColour.labelSecondary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.callout),
                ),
                if (detail != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  Text(detail, style: AppText.caption.copyWith(color: AppColour.labelTertiary)),
                ],
              ],
            ),
          ),
        );

    final recentRows = <Widget>[
      for (final r in recents.take(5))
        switch (r.kind) {
          RecentKind.task when tasks[r.id] != null => row(
            icon: Icons.check_circle_outline_rounded,
            title: tasks[r.id]!.title,
            onTap: () => ref.read(openTaskProvider.notifier).open(r.id),
          ),
          RecentKind.note when notes[r.id] != null => row(
            icon: Icons.sticky_note_2_outlined,
            title: NoteText.heading(notes[r.id]!),
            onTap: () {
              destinations.go(const NotesDestination());
              ref.read(openNoteProvider.notifier).edit(notes[r.id]!);
            },
          ),
          RecentKind.project when projects[r.id] != null => row(
            icon: Icons.folder_outlined,
            title: projects[r.id]!.name,
            onTap: () => destinations.go(ProjectDestination(r.id)),
          ),
          _ => const SizedBox.shrink(),
        },
    ];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recentRows.isEmpty)
          Text('What you open shows here, to come back to.',
              style: AppText.footnote.copyWith(color: AppColour.labelSecondary))
        else
          ...recentRows,
        if (pulse.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          Text('Projects at a glance', style: AppText.caption),
          const SizedBox(height: AppSpace.xs),
          for (final p in pulse)
            row(
              icon: Icons.circle,
              colour: p.project.colour == null ? AppColour.accent : Color(p.project.colour!),
              title: p.project.name,
              detail: [
                '${p.open} open',
                if (p.open + p.done > 0) '${(100 * p.done / (p.open + p.done)).round()}% done',
                if (p.atRisk > 0) '${p.atRisk} at risk',
              ].join(' · '),
              onTap: () => destinations.go(ProjectDestination(p.project.id)),
            ),
        ],
      ],
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeading(icon: Icons.history_rounded, colour: AppColour.indigo, label: 'Jump back in'),
          const SizedBox(height: AppSpace.md),
          if (fill) Expanded(child: _CardScroll(child: body)) else body,
        ],
      ),
    );
  }
}

// --- the evening's review ---------------------------------------------------------------

void _showReview(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _DailyReviewDialog());

/// The day looked back on: what got done, what slipped — each to move to tomorrow, give up on,
/// or mark done — and focus against what was planned.
class _DailyReviewDialog extends ConsumerWidget {
  const _DailyReviewDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(dailyReviewProvider);
    final scope = ref.watch(appScopeProvider).value;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: GlassSurface(
          radius: AppRadius.xlarge,
          tint: AppMaterial.sheetTint,
          blur: AppMaterial.sheetBlur,
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('The day, looked back on', style: AppText.title3),
                const SizedBox(height: AppSpace.xs),
                Text(
                  [
                    '${review.done.length} done',
                    if (review.slipped.isNotEmpty) '${review.slipped.length} to decide about',
                    '${Format.estimate(review.focusMin)} focused'
                        '${review.plannedMin > 0 ? ' of ${Format.estimate(review.plannedMin)} planned' : ''}',
                  ].join(' · '),
                  style: AppText.callout.copyWith(color: AppColour.labelSecondary),
                ),
                const SizedBox(height: AppSpace.lg),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (review.slipped.isNotEmpty) ...[
                        Text('Still open', style: AppText.caption),
                        const SizedBox(height: AppSpace.xs),
                        for (final task in review.slipped)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(task.title,
                                      maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.callout),
                                ),
                                GhostButton(
                                  label: 'Tomorrow',
                                  onTap: () => scope?.tasks.setDue(task.id, dueDate: iso(tomorrow)),
                                ),
                                GhostButton(
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
                                GhostButton(
                                  label: 'Done',
                                  onTap: () => scope?.tasks.setDone(task.id, done: true),
                                ),
                                GhostButton(
                                  label: 'Drop',
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
                        const SizedBox(height: AppSpace.lg),
                      ],
                      const _PlanTomorrow(),
                      const SizedBox(height: AppSpace.lg),
                      Text('Done today', style: AppText.caption),
                      const SizedBox(height: AppSpace.xs),
                      if (review.done.isEmpty)
                        Text('Nothing finished today — tomorrow is another one.', style: AppText.footnote)
                      else
                        for (final task in review.done)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.check_rounded, size: 15, color: AppColour.green),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(child: Text(task.title, style: AppText.callout)),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: GhostButton(label: 'Close', onTap: () => Navigator.of(context).pop()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plan tomorrow, at the end of the day's review: tomorrow's work laid into tomorrow's free
/// time, shown before anything changes, and accepted as one change that one Undo takes back.
class _PlanTomorrow extends ConsumerWidget {
  const _PlanTomorrow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planForProvider(1));
    final days = ref.watch(dayCapacityProvider);
    if (days.length < 2) return const SizedBox.shrink();
    final tomorrow = days[1].date;
    final n = plan.slots.length;

    Future<void> accept() async {
      final scope = ref.read(appScopeProvider).value;
      if (scope == null) return;
      final tasks = {for (final t in ref.read(allTasksProvider).value ?? const <Task>[]) t.id: t};
      final day = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      for (final slot in plan.slots) {
        await scope.tasks.setTime(
          slot.taskId,
          day.add(Duration(minutes: slot.startMin)),
          lengthMin: tasks[slot.taskId]?.estimateMin == null ? slot.lengthMin : null,
        );
      }
      ref.read(undoProvider.notifier).offer('Planned $n ${n == 1 ? 'task' : 'tasks'} into tomorrow', () async {
        for (final slot in plan.slots) {
          await scope.tasks.setTime(slot.taskId, null);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tomorrow', style: AppText.caption),
        const SizedBox(height: AppSpace.xs),
        if (plan.isEmpty)
          Text('Nothing to plan into tomorrow yet.', style: AppText.footnote)
        else ...[
          for (final slot in plan.slots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(Format.clockRange(slot.startMin, slot.endMin),
                        style: AppText.footnote.copyWith(color: AppColour.accent)),
                  ),
                  Expanded(child: Text(slot.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.callout)),
                ],
              ),
            ),
          for (final task in plan.unplaced)
            Text("Doesn't fit tomorrow whole: ${task.title} (${Format.estimate(task.minutes)})",
                style: AppText.footnote.copyWith(color: AppColour.orange)),
          if (n > 0) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: GhostButton(
                label: 'Plan tomorrow · $n ${n == 1 ? 'task' : 'tasks'}, ${Format.estimate(plan.plannedMin)}',
                onTap: accept,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
