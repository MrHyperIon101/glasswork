import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/ledger.dart';
import '../../data/db/database.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../surface.dart';
import '../../data/repository/capacity_repository.dart';
import '../widgets/content_header.dart';
import '../widgets/day_timeline.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: 'Capacity',
            subtitle: 'What the day actually has room for',
            onMenu: onMenu,
            showNewTask: false,
          ),
          const SizedBox(height: AppSpace.xl),
          Expanded(
            child: ListView(
              children: [
                if (rejected.isNotEmpty) ...[
                  _RejectedRules(rejected: rejected),
                  const SizedBox(height: AppSpace.lg),
                ],
                if (capacity.isNotEmpty) ...[
                  _TodayCard(day: capacity.first),
                  const SizedBox(height: AppSpace.lg),
                  _WeekCard(days: capacity.take(7).toList()),
                  const SizedBox(height: AppSpace.lg),
                ],
                if (profile != null) _ProfileCard(profile: profile),
                const SizedBox(height: AppSpace.lg),
                _CommitmentsCard(commitments: commitments),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Today, led by the answer rather than the working.
class _TodayCard extends ConsumerStatefulWidget {
  const _TodayCard({required this.day});

  final DayCapacity day;

  @override
  ConsumerState<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends ConsumerState<_TodayCard> {
  bool _showWorking = false;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final profile = ref.watch(capacityProfileProvider).value;
    final settings = CapacityMapping.settings(profile);
    final commitments = ref.watch(commitmentsProvider).value ?? const [];
    final (blocks, _) = CapacityMapping.blocks(commitments);
    final planned = ref.watch(scheduleProvider).allocatedOn(day.date);

    final over = planned - day.usableMin;

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today', style: AppText.caption),
          const SizedBox(height: AppSpace.sm),

          // One sentence, in words, before any chart or number grid.
          Text(
            planned == 0
                ? 'You have ${Format.estimate(day.usableMin)} to spend and '
                      'nothing planned into it yet.'
                : over > 0
                ? "You have ${Format.estimate(day.usableMin)} to spend and "
                      "${Format.estimate(planned)} planned. "
                      "That's ${Format.estimate(over)} more than fits."
                : 'You have ${Format.estimate(day.usableMin)} to spend and '
                      '${Format.estimate(planned)} planned. '
                      '${Format.estimate(-over)} spare.',
            style: AppText.title3.copyWith(
              color: over > 0 ? AppColour.red : AppColour.label,
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          DayTimeline(
            day: day,
            settings: settings,
            blocks: blocks,
            allocatedMin: planned,
          ),

          const SizedBox(height: AppSpace.md),
          const AppDivider(),
          const SizedBox(height: AppSpace.sm),

          // The derivation is still available, just no longer the first thing you meet.
          GestureDetector(
            onTap: () => setState(() => _showWorking = !_showWorking),
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Icon(
                    _showWorking ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColour.labelTertiary,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    _showWorking ? 'Hide the arithmetic' : 'Show the arithmetic',
                    style: AppText.footnote,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: _showWorking
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Line(
                          label: 'Awake',
                          value: Format.estimate(day.wakingMin),
                        ),
                        _Line(
                          label: 'Classes and fixed blocks',
                          value: '− ${Format.estimate(day.committedMin)}',
                        ),
                        _Line(
                          label: 'Meals and buffer',
                          value: '− ${Format.estimate(day.overheadMin)}',
                        ),
                        if (day.discardedGapMin > 0)
                          _Line(
                            label: 'Gaps too short to use',
                            value: '− ${Format.estimate(day.discardedGapMin)}',
                            tint: AppColour.orange,
                          ),
                        _Line(
                          label: 'Focus factor, applied per gap',
                          value:
                              '× ${(CapacityMapping.settings(profile).focusFactor * 100).round()}%',
                          tint: AppColour.labelTertiary,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
                          child: AppDivider(),
                        ),
                        _Line(
                          label: 'Yours to spend',
                          value: Format.estimate(day.usableMin),
                          tint: AppColour.accent,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          'Sleep (${Format.estimate(day.sleepMin)}) is a floor, not '
                          'spare time. Nothing is ever scheduled into it.',
                          style: AppText.footnote.copyWith(
                            color: AppColour.labelTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The week, so a bad Thursday is visible on Monday.
class _WeekCard extends ConsumerWidget {
  const _WeekCard({required this.days});

  final List<DayCapacity> days;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(capacityProfileProvider).value;
    final settings = CapacityMapping.settings(profile);
    final commitments = ref.watch(commitmentsProvider).value ?? const [];
    final (blocks, _) = CapacityMapping.blocks(commitments);
    final schedule = ref.watch(scheduleProvider);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The week ahead', style: AppText.caption),
          const SizedBox(height: AppSpace.md),
          for (final day in days)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpace.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _names[day.date.weekday - 1],
                            style: AppText.numeric.copyWith(
                              color: AppColour.label,
                            ),
                          ),
                          Text(
                            '${day.date.day}/${day.date.month}',
                            style: AppText.numeric.copyWith(
                              fontSize: 10,
                              color: AppColour.labelQuaternary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: DayTimeline(
                      day: day,
                      settings: settings,
                      blocks: blocks,
                      allocatedMin: schedule.allocatedOn(day.date),
                      showHours: false,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.tint});

  final String label;
  final String value;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppText.callout)),
        Text(
          value,
          style: AppText.numeric.copyWith(color: tint ?? AppColour.label),
        ),
      ],
    ),
  );
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile});

  final CapacityProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appScopeProvider).value?.capacity;

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: AppText.caption),
          const SizedBox(height: AppSpace.md),
          _Stepper(
            label: 'Sleep target',
            value: Format.estimate(profile.sleepTargetMin),
            onChange: (delta) => repo?.updateProfile(
              profile.id,
              sleepTargetMin: (profile.sleepTargetMin + delta * 15).clamp(
                240,
                720,
              ),
            ),
          ),
          _Stepper(
            label: 'Meals',
            value: Format.estimate(profile.mealsMin),
            onChange: (delta) => repo?.updateProfile(
              profile.id,
              mealsMin: (profile.mealsMin + delta * 15).clamp(0, 300),
            ),
          ),
          _Stepper(
            label: 'Buffer — transit, admin, life',
            value: Format.estimate(profile.bufferMin),
            onChange: (delta) => repo?.updateProfile(
              profile.id,
              bufferMin: (profile.bufferMin + delta * 15).clamp(0, 300),
            ),
          ),
          _Stepper(
            label: 'Focus factor',
            value: '${(profile.focusFactor * 100).round()}%',
            onChange: (delta) => repo?.updateProfile(
              profile.id,
              focusFactor: (profile.focusFactor + delta * 0.05).clamp(0.3, 1.0),
            ),
          ),
          _Stepper(
            label: 'Shortest usable gap',
            value: Format.estimate(profile.minGapMin),
            onChange: (delta) => repo?.updateProfile(
              profile.id,
              minGapMin: (profile.minGapMin + delta * 5).clamp(5, 120),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Six free hours is not six hours of assignment. The focus factor is the '
            'honest correction, and it will be tuned from your own completion data later.',
            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChange,
  });

  final String label;
  final String value;
  final void Function(int delta) onChange;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppText.body)),
        _Step(icon: Icons.remove, onTap: () => onChange(-1)),
        SizedBox(
          width: 68,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.numeric.copyWith(color: AppColour.label),
          ),
        ),
        _Step(icon: Icons.add, onTap: () => onChange(1)),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColour.fill,
          borderRadius: AppRadius.smallAll,
        ),
        child: Icon(icon, size: 14, color: AppColour.labelSecondary),
      ),
    ),
  );
}

class _CommitmentsCard extends ConsumerWidget {
  const _CommitmentsCard({required this.commitments});

  final List<Commitment> commitments;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Timetable', style: AppText.caption)),
              _AddCommitmentButton(),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (commitments.isEmpty)
            Text(
              'No fixed blocks yet. Add your classes and labs — until then every day '
              'looks completely free, and the load figures will flatter you.',
              style: AppText.callout,
            )
          else
            for (final c in commitments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: AppText.body),
                          Text(
                            '${_days(c.rrule)} · ${_time(c.startMin)}'
                            '–${_time(c.startMin + c.durationMin)}',
                            style: AppText.numeric,
                          ),
                        ],
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(appScopeProvider)
                            .value
                            ?.capacity
                            .deleteCommitment(c.id),
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpace.xs),
                          child: Icon(
                            Icons.close,
                            size: 15,
                            color: AppColour.labelTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static String _time(int min) =>
      '${(min ~/ 60).toString().padLeft(2, '0')}:'
      '${(min % 60).toString().padLeft(2, '0')}';

  static String _days(String rrule) {
    const codes = {
      'MO': 0,
      'TU': 1,
      'WE': 2,
      'TH': 3,
      'FR': 4,
      'SA': 5,
      'SU': 6,
    };
    final match = RegExp('BYDAY=([A-Z,]+)').firstMatch(rrule.toUpperCase());
    if (match == null) return rrule;
    return match
        .group(1)!
        .split(',')
        .map((c) => codes[c] == null ? c : _dayNames[codes[c]!])
        .join(' ');
  }
}

class _AddCommitmentButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showAddDialog(context, ref),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    final result = await showDialog<_NewCommitment>(
      context: context,
      builder: (context) => const _AddCommitmentDialog(),
    );
    if (result == null) return;

    await scope.capacity.addCommitment(
      workspaceId: scope.workspace.id,
      title: result.title,
      weekdays: result.weekdays,
      startMin: result.startMin,
      durationMin: result.durationMin,
    );
  }
}

class _NewCommitment {
  const _NewCommitment({
    required this.title,
    required this.weekdays,
    required this.startMin,
    required this.durationMin,
  });

  final String title;
  final Set<int> weekdays;
  final int startMin;
  final int durationMin;
}

class _AddCommitmentDialog extends StatefulWidget {
  const _AddCommitmentDialog();

  @override
  State<_AddCommitmentDialog> createState() => _AddCommitmentDialogState();
}

class _AddCommitmentDialogState extends State<_AddCommitmentDialog> {
  final _title = TextEditingController();
  final _weekdays = <int>{};
  int _startMin = 9 * 60;
  int _durationMin = 60;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fixed block', style: AppText.title3),
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: _title,
              autofocus: true,
              style: AppText.body,
              cursorColor: AppColour.accent,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColour.fill,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mediumAll,
                  borderSide: BorderSide.none,
                ),
                hintText: 'DBMS lecture',
                hintStyle: AppText.body.copyWith(
                  color: AppColour.labelTertiary,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Repeats', style: AppText.caption),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                for (var d = 1; d <= 7; d++)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _weekdays.contains(d)
                            ? _weekdays.remove(d)
                            : _weekdays.add(d);
                      }),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _weekdays.contains(d)
                              ? AppColour.accent
                              : AppColour.fill,
                          borderRadius: AppRadius.smallAll,
                        ),
                        child: Text(
                          _letters[d - 1],
                          style: AppText.numeric.copyWith(
                            color: _weekdays.contains(d)
                                ? AppColour.label
                                : AppColour.labelSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            _Stepper(
              label: 'Starts',
              value:
                  '${(_startMin ~/ 60).toString().padLeft(2, '0')}:'
                  '${(_startMin % 60).toString().padLeft(2, '0')}',
              onChange: (d) =>
                  setState(() => _startMin = (_startMin + d * 15).clamp(0, 1380)),
            ),
            _Stepper(
              label: 'Lasts',
              value: Format.estimate(_durationMin),
              onChange: (d) => setState(
                () => _durationMin = (_durationMin + d * 15).clamp(15, 600),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppText.body.copyWith(
                      color: AppColour.labelSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                TextButton(
                  onPressed:
                      _title.text.trim().isEmpty || _weekdays.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          _NewCommitment(
                            title: _title.text.trim(),
                            weekdays: _weekdays,
                            startMin: _startMin,
                            durationMin: _durationMin,
                          ),
                        ),
                  child: Text(
                    'Add',
                    style: AppText.headline.copyWith(color: AppColour.accent),
                  ),
                ),
              ],
            ),
          ],
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
            Text(
              '${rejected.length} block${rejected.length == 1 ? '' : 's'} '
              'could not be read',
              style: AppText.headline.copyWith(color: AppColour.orange),
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
