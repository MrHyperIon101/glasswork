import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/block_check.dart';
import '../../capacity/ledger.dart';
import '../../capacity/recurrence.dart';
import '../../capacity/setting_effects.dart';
import '../../capacity/timetable.dart' as tt;
import '../../data/db/database.dart';
import '../../data/repository/capacity_repository.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../block_style.dart';
import '../format.dart';
import '../layout.dart';
import '../surface.dart';
import '../time_entry.dart';
import '../widgets/block_dialog.dart';
import '../widgets/content_header.dart';
import '../../capacity/task_slot.dart';
import '../widgets/field_controls.dart';
import '../widgets/typed_value.dart';
import '../widgets/value_stepper.dart';
import '../widgets/weekday_picker.dart';
import '../motion.dart';

part 'capacity_tabs.dart';

/// The capacity ledger, and the timetable it is computed from.
///
/// This screen shows its working. Every number the app uses to tell you something will not
/// fit is derived here, and if you cannot trace *why* it said a thing, the feature is
/// broken — so the arithmetic is printed, not just the result.
class CapacityScreen extends ConsumerWidget {
  const CapacityScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(capacityProfileProvider).value;
    final commitments = ref.watch(commitmentsProvider).value ?? const [];
    final rejected = ref.watch(rejectedCommitmentsProvider);
    final capacity = ref.watch(dayCapacityProvider);
    final settings = CapacityMapping.settings(profile);
    // Blocks the ledger leaves out, because they fall where nothing is counted.
    final uncounted = [
      for (final c in commitments)
        if (_problemsOf(c, settings).isNotEmpty) c,
    ];

    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);

    final tab = ref.watch(_budgetTabProvider);
    final page = switch (tab) {
      _BudgetTab.overview => capacity.isEmpty
          ? const SizedBox()
          : _OverviewTab(days: capacity, notCounted: uncounted.length + rejected.length),
      _BudgetTab.timetable => _TimetableTab(
        commitments: commitments,
        uncounted: uncounted,
        rejected: rejected,
        settings: settings,
      ),
      _BudgetTab.sleep => profile == null ? const SizedBox() : _SleepTab(profile: profile),
      _BudgetTab.rules => profile == null
          ? const SizedBox()
          : _RulesTab(profile: profile, today: capacity.firstOrNull),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpace.sm : AppSpace.xl,
        gutter,
        compact ? 0 : AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            // The same name the sidebar gives it.
            title: 'Time budget',
            subtitle: 'What your days actually have room for',
            onMenu: onMenu,
            showNewTask: false,
            accessory: const _Segments(),
          ),
          SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.quick),
              child: KeyedSubtree(key: ValueKey(tab), child: page),
            ),
          ),
        ],
      ),
    );
  }
}

/// One night's sleep, or the same sleep for several nights at once.
class _SleepDialog extends StatefulWidget {
  const _SleepDialog({required this.bedtimeMin, required this.wakeMin, this.nights = const {}});

  final int bedtimeMin;
  final int wakeMin;

  /// The nights chosen when it opens: the one tapped, or none.
  final Set<int> nights;

  @override
  State<_SleepDialog> createState() => _SleepDialogState();
}

class _SleepDialogState extends State<_SleepDialog> {
  /// Nights, by the day each starts on.
  late final _nights = <int>{...widget.nights};
  late int _bedtime = widget.bedtimeMin;
  late int _wake = widget.wakeMin;

  void _setNights(Iterable<int> nights) => setState(
    () => _nights
      ..clear()
      ..addAll(nights),
  );

  @override
  Widget build(BuildContext context) {
    final length = CapacitySettings.nightBetween(_bedtime, _wake);
    final valid = _nights.isNotEmpty && length > 0;

    ValueStepper time(String label, int value, void Function(int minutes) set) =>
        ValueStepper(
          label: label,
          text: Format.clock(value),
          keyboardType: TextInputType.datetime,
          onStep: (direction) =>
              setState(() => set((value + direction * 15) % minutesInDay)),
          onSubmit: (text) {
            final minutes = TimeEntry.clock(text);
            if (minutes == null) return false;
            setState(() => set(minutes));
            return true;
          },
        );

    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      insetPadding: _dialogInsets,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.nights.length == 1
                    ? '${_dayNames[widget.nights.single - 1]} night'
                    : 'Sleep for several nights',
                style: AppText.title3,
              ),
              const SizedBox(height: AppSpace.lg),
              Text('Nights, by the day they start', style: AppText.caption),
              const SizedBox(height: AppSpace.sm),
              WeekdayPicker(
                selected: _nights,
                onToggle: (day) => setState(
                  () => _nights.contains(day) ? _nights.remove(day) : _nights.add(day),
                ),
              ),
              // Under the days, not beside the heading: on a phone with larger text, three
              // of them there left the heading a column one letter wide.
              Transform.translate(
                // Level with the squares, past the first choice's own padding.
                offset: const Offset(-AppSpace.sm, 0),
                child: Wrap(
                  children: [
                    // Named for the morning after, which is what a bedtime is chosen for.
                    _SmallAction(
                      label: 'Before weekdays',
                      onTap: () => _setNights(const [7, 1, 2, 3, 4]),
                    ),
                    _SmallAction(
                      label: 'Before weekends',
                      onTap: () => _setNights(const [5, 6]),
                    ),
                    _SmallAction(
                      label: 'Every night',
                      onTap: () => _setNights(const [1, 2, 3, 4, 5, 6, 7]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              time('To bed', _bedtime, (m) => _bedtime = m),
              time('Up at', _wake, (m) => _wake = m),
              const SizedBox(height: AppSpace.sm),
              Text(
                length == 0
                    ? 'Going to bed and getting up at the same time leaves no sleep at all.'
                    : '${Format.estimate(length)} of sleep.',
                style: AppText.footnote,
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  PrimaryButton(
                    label: 'Set',
                    enabled: valid,
                    onTap: () {
                      if (valid) Navigator.pop(context, ({..._nights}, _bedtime, _wake));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCommitmentButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _editBlock(context, ref),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppLayout.touch ? AppSpace.sm : AppSpace.xs,
          ),
          decoration: const BoxDecoration(
            color: AppColour.fill,
            borderRadius: AppRadius.smallAll,
          ),
          child: Text(
            'Add block',
            style: AppText.numeric.copyWith(color: AppColour.accent),
          ),
        ),
      ),
    );
  }
}

/// Opens [existing] for editing, or a new block when there is none, and saves what comes
/// back.
Future<void> _editBlock(
  BuildContext context,
  WidgetRef ref, {
  Commitment? existing,
  BlockDraft? prefill,
}) async {
  final scope = ref.read(appScopeProvider).value;
  final scheduleId =
      existing?.scheduleId ?? ref.read(editingScheduleIdProvider);
  if (scope == null || scheduleId == null) return;

  final commitments =
      ref.read(commitmentsProvider).value ?? const <Commitment>[];
  final (others, _) = CapacityMapping.blocksOf([
    for (final c in commitments)
      if (c.scheduleId == scheduleId && c.id != existing?.id) c,
  ]);
  final name = (ref.read(schedulesProvider).value ?? const <TimetableSet>[])
      .where((s) => s.id == scheduleId)
      .map((s) => s.name)
      .firstOrNull;
  final initial = existing == null
      ? null
      : BlockDraft(
          title: existing.title,
          weekdays: _weekdaysOf(existing) ?? const {},
          startMin: existing.startMin,
          durationMin: existing.durationMin,
        );

  final draft = await showAppDialog<BlockDraft>(
    context: context,
    builder: (context) => BlockDialog(
      settings: CapacityMapping.settings(
        ref.read(capacityProfileProvider).value,
      ),
      others: others,
      initial: initial,
      prefill: prefill,
      timetableName: name,
      notInForce: _notInForce(ref.read(timetableProvider), scheduleId, name),
    ),
  );
  if (draft == null) return;

  if (existing == null || initial == null) {
    await scope.capacity.addCommitment(
      workspaceId: scope.workspace.id,
      scheduleId: scheduleId,
      title: draft.title,
      weekdays: draft.weekdays,
      startMin: draft.startMin,
      durationMin: draft.durationMin,
    );
    return;
  }

  // Only what changed, so an edit here does not overwrite a change another device made to
  // a field this one never touched.
  await scope.capacity.updateCommitment(
    existing.id,
    title: draft.title == initial.title ? null : draft.title,
    weekdays: setEquals(draft.weekdays, initial.weekdays)
        ? null
        : draft.weekdays,
    startMin: draft.startMin == initial.startMin ? null : draft.startMin,
    durationMin: draft.durationMin == initial.durationMin
        ? null
        : draft.durationMin,
  );
}

/// Why blocks in the set [scheduleId] do not count today, or null when they do.
String? _notInForce(tt.Timetable timetable, String scheduleId, String? name) {
  final today = DateTime.now();
  final governing = timetable.windowFor(today);
  if (governing?.id == scheduleId) return null;

  final label = name ?? 'This timetable';
  final from = timetable.firstDayGovernedBy(
    scheduleId,
    today,
    capacityHorizonDays,
  );
  if (from != null) {
    return "$label isn't in force today. Its blocks count from "
        '${Format.dayAndDate(from)}.';
  }
  return governing == null
      ? "$label isn't in force in the next four weeks, so its blocks don't count "
            'in the figures above.'
      : '${governing.name} is in force instead, so blocks in $label '
            "don't count in the figures above.";
}

/// A stored block's weekdays, or null when its rule cannot be read.
Set<int>? _weekdaysOf(Commitment c) {
  try {
    return Recurrence.parse(c.rrule).weekdays;
  } on RecurrenceError {
    return null;
  }
}

/// What keeps [c] from counting in full: sleep and midnight, and given [others], the rest of
/// its timetable, clashes.
List<BlockProblem> _problemsOf(
  Commitment c,
  CapacitySettings settings, {
  List<FixedBlock> others = const [],
}) {
  final weekdays = _weekdaysOf(c);
  if (weekdays == null) return const [];
  return BlockCheck.problems(
    startMin: c.startMin,
    durationMin: c.durationMin,
    weekdays: weekdays,
    settings: settings,
    others: others,
  );
}

String _shortProblem(BlockProblem problem) => switch (problem) {
  DuringSleep() => 'Falls while you sleep, so it is not counted',
  PastMidnight() => 'Runs past midnight, and the rest is not counted',
  Clash(:final title) => 'Overlaps $title',
};

/// Blocks the ledger leaves out, whole or in part, because they fall while you sleep or
/// run past midnight. They used to be left out silently, and simply never appeared.
class _UncountedBlocks extends ConsumerWidget {
  const _UncountedBlocks({required this.blocks, required this.settings});

  final List<Commitment> blocks;
  final CapacitySettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppSurface(
    colour: AppColour.elevated,
    border: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bedtime_outlined,
              size: 15,
              color: AppColour.orange,
            ),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                '${blocks.length} block${blocks.length == 1 ? '' : 's'} not counted',
                style: AppText.headline.copyWith(color: AppColour.orange),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        for (final c in blocks)
          _BlockRow(
            commitment: c,
            problems: _problemsOf(c, settings),
            onTap: () => _editBlock(context, ref, existing: c),
          ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Sleep is never counted as time to spend. Tap a block to move it, or if you '
          'are up then, change your sleep under Sleep.',
          style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
        ),
      ],
    ),
  );
}

/// A block in a list: what it is and when, and anything keeping it from counting. Tapped,
/// it opens for editing.
class _BlockRow extends StatefulWidget {
  const _BlockRow({
    required this.commitment,
    required this.problems,
    required this.onTap,
    this.onDelete,
  });

  final Commitment commitment;
  final List<BlockProblem> problems;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.commitment;
    final weekdays = _weekdaysOf(c);
    final when =
        '${weekdays == null ? c.rrule : Format.weekdays(weekdays)} · '
        '${Format.clockSpan(c.startMin, c.durationMin)}';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.fill : null,
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            children: [
              // The colour and short name the block wears on every timeline.
              Consumer(
                builder: (context, ref, _) {
                  final colour = BlockStyle.colourIn(
                    ref.watch(blockColoursProvider),
                    c.title,
                  );
                  return Container(
                width: AppSize.touch - AppSpace.sm,
                height: AppSize.touch - AppSpace.sm,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.22),
                  borderRadius: AppRadius.mediumAll,
                  border: Border.all(color: colour.withValues(alpha: 0.5), width: 0.5),
                ),
                padding: const EdgeInsets.all(AppSpace.xs),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    BlockStyle.abbreviate(c.title),
                    maxLines: 1,
                    style: AppText.numeric.copyWith(
                      color: AppColour.label,
                      fontSize: 10,
                      fontVariations: const [FontVariation('wght', 650)],
                    ),
                  ),
                ),
              );
                },
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body,
                    ),
                    Text(when, style: AppText.numeric),
                    for (final problem in widget.problems)
                      Text(
                        _shortProblem(problem),
                        style: AppText.footnote.copyWith(
                          color: AppColour.orange,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onDelete case final delete?)
                Tooltip(
                  message: 'Delete block',
                  child: GestureDetector(
                    onTap: delete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(
                        AppLayout.touch ? AppSpace.md : AppSpace.xs,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppColour.labelTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rules the engine could not read. Never swallowed — a missing block silently inflates
/// every capacity figure.
class _RejectedRules extends StatelessWidget {
  const _RejectedRules({required this.rejected});

  final List<String> rejected;

  @override
  Widget build(BuildContext context) => AppSurface(
    colour: AppColour.elevated,
    border: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 15,
              color: AppColour.orange,
            ),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                '${rejected.length} block${rejected.length == 1 ? '' : 's'} '
                'could not be read',
                style: AppText.headline.copyWith(color: AppColour.orange),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        for (final r in rejected)
          Text(r, style: AppText.footnote),
        const SizedBox(height: AppSpace.sm),
        Text(
          'These are not counted against your day, so the figures above are optimistic '
          'until they are fixed.',
          style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
        ),
      ],
    ),
  );
}

/// Named timetable sets, and the tools to stop rebuilding them by hand.
///
/// Each set carries its own dates, so the ledger picks whichever governs a given day.
/// That is what makes this more than a switch: the horizon runs four weeks out, and on
/// the last week of a semester a manual switch would still be subtracting classes that
/// have finished.
class _ScheduleSets extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(schedulesProvider).value ?? const <TimetableSet>[];
    final active = ref.watch(activeScheduleProvider);
    final editingId = ref.watch(editingScheduleIdProvider);
    final editing = sets.where((s) => s.id == editingId).firstOrNull;
    // A set not in force takes blocks that count nowhere, which is baffling unless it says so.
    final notInForce = editing == null
        ? null
        : _notInForce(ref.watch(timetableProvider), editing.id, editing.name);

    final dates = editing == null
        ? null
        : editing.isFallback
        ? 'Any day no other timetable covers'
        : (editing.startsOn == null && editing.endsOn == null)
        ? 'Every day'
        : '${_readableDate(editing.startsOn)} – ${_readableDate(editing.endsOn)}';

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.md, AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // The sets, as a row of choices; the one being edited is raised.
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  for (final set in sets)
                    _SetChoice(
                      name: set.name,
                      selected: set.id == editingId,
                      inForce: active?.id == set.id,
                      onTap: () => ref.read(editingScheduleProvider.notifier).select(set.id),
                    ),
                  _SetChoice(
                    name: 'New',
                    icon: Icons.add_rounded,
                    selected: false,
                    inForce: false,
                    onTap: () => _edit(context, ref, null),
                  ),
                ],
              ),
              if (editing != null)
                // Level with the choices above, past the first action's own padding.
                Transform.translate(
                  offset: Offset(AppLayout.compact(context) ? -AppSpace.sm : 0, 0),
                  child: Wrap(
                  children: [
                    _SmallAction(label: 'Duplicate', onTap: () => _duplicate(context, ref, editing)),
                    _SmallAction(label: 'Rename and dates', onTap: () => _edit(context, ref, editing)),
                    if (!editing.isFallback)
                      _SmallAction(label: 'Delete', tint: AppColour.red, onTap: () => _delete(ref, editing)),
                  ],
                  ),
                ),
            ],
          ),
          if (dates != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text.rich(
              TextSpan(
                style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
                children: [
                  TextSpan(text: dates),
                  if (notInForce == null)
                    TextSpan(text: '  ·  In force today', style: TextStyle(color: AppColour.green))
                  else
                    TextSpan(text: '  ·  $notInForce', style: TextStyle(color: AppColour.orange)),
                ],
              ),
            ),
          ] else if (active == null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'No timetable covers today, so nothing is being subtracted.',
              style: AppText.footnote.copyWith(color: AppColour.orange),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    TimetableSet? existing,
  ) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    final result = await showAppDialog<_ScheduleDraft>(
      context: context,
      builder: (context) => _ScheduleDialog(existing: existing),
    );
    if (result == null) return;

    if (existing == null) {
      final created = await scope.capacity.addSchedule(
        workspaceId: scope.workspace.id,
        name: result.name,
        startsOn: result.startsOn,
        endsOn: result.endsOn,
      );
      ref.read(editingScheduleProvider.notifier).select(created.id);
    } else {
      await scope.capacity.updateSchedule(
        existing.id,
        name: result.name,
        startsOn: result.startsOn,
        endsOn: result.endsOn,
        clearDates: result.startsOn == null && result.endsOn == null,
      );
    }
  }

  /// The time-saver. Next term usually rhymes with this one.
  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    TimetableSet source,
  ) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    final result = await showAppDialog<_ScheduleDraft>(
      context: context,
      builder: (context) => _ScheduleDialog(
        existing: null,
        suggestedName: _nextName(source.name),
        title: 'Duplicate ${source.name}',
      ),
    );
    if (result == null) return;

    final created = await scope.capacity.duplicateSchedule(
      workspaceId: scope.workspace.id,
      sourceId: source.id,
      name: result.name,
      startsOn: result.startsOn,
      endsOn: result.endsOn,
    );
    ref.read(editingScheduleProvider.notifier).select(created.id);
  }

  Future<void> _delete(WidgetRef ref, TimetableSet set) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;
    if (!await scope.capacity.deleteSchedule(set.id)) return;
    ref
        .read(undoProvider.notifier)
        .offer(
          'Deleted "${set.name}"',
          () => scope.capacity.restoreSchedule(set.id),
        );
  }

  /// "Sem V" -> "Sem VI" is beyond a regex, but numbers are the common case.
  static String _nextName(String name) {
    final match = RegExp(r'(\d+)\s*$').firstMatch(name);
    if (match == null) return '$name copy';
    final n = int.parse(match.group(1)!);
    return name.replaceRange(match.start, match.end, '${n + 1}');
  }
}

/// A timetable to choose, as a pill: raised when chosen, a green dot when it is in force.
class _SetChoice extends StatefulWidget {
  const _SetChoice({
    required this.name,
    required this.selected,
    required this.inForce,
    required this.onTap,
    this.icon,
  });

  final String name;
  final bool selected;
  final bool inForce;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_SetChoice> createState() => _SetChoiceState();
}

class _SetChoiceState extends State<_SetChoice> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: widget.selected,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppLayout.touch ? AppSpace.sm : 5,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColour.fillStrong
                : _hovered
                ? AppColour.fill
                : null,
            borderRadius: AppRadius.roundAll,
            border: Border.all(
              color: widget.selected ? AppColour.separator : AppColour.fill,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon case final icon?) ...[
                Icon(icon, size: 14, color: AppColour.accent),
                const SizedBox(width: 4),
              ],
              if (widget.inForce) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppColour.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.name,
                style: AppText.footnote.copyWith(
                  color: widget.icon != null
                      ? AppColour.accent
                      : widget.selected
                      ? AppColour.label
                      : AppColour.labelSecondary,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.label, required this.onTap, this.tint});

  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppLayout.touch ? AppSpace.md : AppSpace.xs,
        ),
        child: Text(
          label,
          style: AppText.numeric.copyWith(color: tint ?? AppColour.accent),
        ),
      ),
    ),
  );
}

/// Room around a dialog. Material's default takes 80 points off a phone's width.
const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const _dialogInsets = EdgeInsets.symmetric(
  horizontal: AppSpace.lg,
  vertical: AppSpace.xxl,
);

/// "15 Aug 2026" from a stored date, or an ellipsis for an open end.
String _readableDate(String? iso) {
  final date = iso == null ? null : DateTime.tryParse(iso);
  return date == null ? '…' : '${Format.shortDate(date)} ${date.year}';
}

class _ScheduleDraft {
  const _ScheduleDraft({required this.name, this.startsOn, this.endsOn});

  final String name;
  final DateTime? startsOn;
  final DateTime? endsOn;
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({
    required this.existing,
    this.suggestedName,
    this.title,
  });

  final TimetableSet? existing;
  final String? suggestedName;
  final String? title;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.suggestedName ?? widget.existing?.name ?? '',
  );
  DateTime? _startsOn;
  DateTime? _endsOn;

  @override
  void initState() {
    super.initState();
    _startsOn = _parse(widget.existing?.startsOn);
    _endsOn = _parse(widget.existing?.endsOn);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  static DateTime? _parse(String? iso) =>
      iso == null || iso.isEmpty ? null : DateTime.tryParse(iso);

  /// Dates that would never cover a single day.
  bool get _backwards =>
      _startsOn != null && _endsOn != null && _endsOn!.isBefore(_startsOn!);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      insetPadding: _dialogInsets,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ??
                    (widget.existing == null ? 'New timetable' : 'Edit timetable'),
                style: AppText.title3,
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _name,
                autofocus: true,
                style: AppText.body,
                cursorColor: AppColour.accent,
                // Create is enabled by what is typed, so each keystroke has to rebuild it.
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColour.fill,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mediumAll,
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Sem V',
                  hintStyle: AppText.body.copyWith(
                    color: AppColour.labelTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text('In force between', style: AppText.caption),
              const SizedBox(height: AppSpace.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final from = _DateButton(
                    label: 'From',
                    value: _startsOn,
                    onPick: (d) => setState(() => _startsOn = d),
                  );
                  final until = _DateButton(
                    label: 'Until',
                    value: _endsOn,
                    onPick: (d) => setState(() => _endsOn = d),
                  );

                  // Side by side on a phone, each date would get a few characters of room.
                  if (constraints.maxWidth < 360) {
                    return Column(
                      children: [from, const SizedBox(height: AppSpace.sm), until],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: from),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(child: until),
                    ],
                  );
                },
              ),
              if (_backwards) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  'It ends before it starts, so it would never be in force.',
                  style: AppText.footnote.copyWith(color: AppColour.red),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              Text(
                'Leave both blank for a timetable that always applies. With dates, the '
                'planner uses it only on the days it covers — so a semester ending does '
                'not need you to remember anything.',
                style: AppText.footnote.copyWith(
                  color: AppColour.labelTertiary,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  PrimaryButton(
                    label: widget.existing == null ? 'Create' : 'Save',
                    enabled: _name.text.trim().isNotEmpty && !_backwards,
                    onTap: () {
                      if (_name.text.trim().isEmpty || _backwards) return;
                      Navigator.pop(
                        context,
                        _ScheduleDraft(
                          name: _name.text.trim(),
                          startsOn: _startsOn,
                          endsOn: _endsOn,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final initial = value ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          // Wide enough to include the date already set, which the picker will not
          // open on otherwise.
          firstDate: DateTime(
            (initial.year < now.year ? initial.year : now.year) - 2,
          ),
          lastDate: DateTime(
            (initial.year > now.year ? initial.year : now.year) + 6,
          ),
        );
        if (picked != null) onPick(picked);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.md,
        ),
        decoration: const BoxDecoration(
          color: AppColour.fill,
          borderRadius: AppRadius.mediumAll,
        ),
        child: Row(
          children: [
            Text('$label  ', style: AppText.numeric),
            Expanded(
              child: Text(
                value == null ? '—' : Format.shortDate(value!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  color: value == null
                      ? AppColour.labelTertiary
                      : AppColour.label,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onPick(null),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColour.labelTertiary,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
