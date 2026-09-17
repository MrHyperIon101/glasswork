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
import '../widgets/day_timeline.dart';
import '../widgets/field_controls.dart';
import '../widgets/typed_value.dart';
import '../widgets/value_stepper.dart';
import '../widgets/weekday_picker.dart';
import '../motion.dart';

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
          ),
          SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
          Expanded(
            child: ListView(
              // On a phone the list runs to the bottom edge, so its end needs room to clear it.
              padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : 0),
              children: [
                if (rejected.isNotEmpty) ...[
                  _RejectedRules(rejected: rejected),
                  const SizedBox(height: AppSpace.lg),
                ],
                if (uncounted.isNotEmpty) ...[
                  _UncountedBlocks(blocks: uncounted, settings: settings),
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
                _ScheduleSets(),
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
    final planned = ref.watch(scheduleProvider).allocatedOn(day.date);
    final spare = day.spareAfter(planned);

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
                : spare < 0
                ? "You have ${Format.estimate(day.usableMin)} to spend and "
                      "${Format.estimate(planned)} planned. "
                      "That's ${Format.estimate(-spare)} more than fits."
                : 'You have ${Format.estimate(day.usableMin)} to spend and '
                      '${Format.estimate(planned)} planned, '
                      '${spare == 0 ? 'with nothing to spare' : '${Format.estimate(spare)} spare'}.',
            style: AppText.title3.copyWith(
              color: spare < 0 ? AppColour.red : AppColour.label,
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          DayTimeline(
            day: day,
            allocatedMin: planned,
            tasks: ref.watch(taskSlotsProvider(day.date)),
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
                    _showWorking ? Icons.expand_less_rounded : Icons.expand_more_rounded,
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
    final schedule = ref.watch(scheduleProvider);
    final compact = AppLayout.compact(context);

    Widget timeline(DayCapacity day) => DayTimeline(
      day: day,
      allocatedMin: schedule.allocatedOn(day.date),
      tasks: ref.watch(taskSlotsProvider(day.date)),
      showHours: false,
      // Seven full legends down a phone make a wall of figures.
      dense: compact,
    );

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The week ahead', style: AppText.caption),
          const SizedBox(height: AppSpace.md),
          for (final day in days)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: compact
                  // The day named above its bar, so the bar has the phone's whole width.
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: AppText.numeric,
                            children: [
                              TextSpan(
                                text: _names[day.date.weekday - 1],
                                style: const TextStyle(color: AppColour.label),
                              ),
                              TextSpan(
                                text: '  ${day.date.day}/${day.date.month}',
                                style: const TextStyle(
                                  color: AppColour.labelQuaternary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        timeline(day),
                      ],
                    )
                  : Row(
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
                        Expanded(child: timeline(day)),
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
    final effects = ref.watch(settingEffectsProvider);
    final focusPercent = (profile.focusFactor * 100).round();

    // A length, stepped or typed, kept inside [min, max].
    Widget length({
      required String label,
      required int value,
      required int step,
      required int min,
      required int max,
      required void Function(int minutes) save,
      required String explanation,
      required String effect,
      bool bareMinutes = false,
    }) => ValueStepper(
      label: label,
      text: Format.estimate(value),
      keyboardType: TextInputType.datetime,
      explanation: explanation,
      effect: effect,
      onStep: (direction) => save((value + direction * step).clamp(min, max)),
      onSubmit: (text) {
        final typed = TimeEntry.duration(text, bareMinutes: bareMinutes);
        if (typed == null) return false;
        save(typed.clamp(min, max));
        return true;
      },
    );

    // What one step more does to an average day's time to spend.
    String stepEffect(String step, int change) => change == 0
        ? '$step more would change nothing this week.'
        : change < 0
        ? '$step more leaves about ${Format.estimate(-change)} less a day to spend.'
        : '$step more adds about ${Format.estimate(change)} a day to spend.';

    final shortNights = [
      for (final day in effects.shortNights.keys) _SleepWeek.names[day - 1],
    ];

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: AppText.caption),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Every figure on this screen is worked out from these. Under each is what it '
            'means, and what changing it would do to an average day this week.',
            style: AppText.footnote,
          ),
          const SizedBox(height: AppSpace.lg),
          _SleepWeek(profile: profile),
          const SizedBox(height: AppSpace.md),
          const AppDivider(),
          const SizedBox(height: AppSpace.sm),
          length(
            label: 'Sleep at least',
            value: profile.sleepTargetMin,
            step: 15,
            min: 240,
            max: 720,
            save: (v) => repo?.updateProfile(profile.id, sleepTargetMin: v),
            explanation:
                'The least sleep you want in a night. Nothing is planned into sleep '
                'either way: this only marks the nights above that fall short of it.',
            effect: shortNights.isEmpty
                ? 'Every night this week gets at least this.'
                : '${shortNights.length == 1 ? 'The night after ${shortNights.single} '
                          'falls' : '${shortNights.length} nights fall'} short of it.',
          ),
          length(
            label: 'Meals',
            value: profile.mealsMin,
            step: SettingEffects.mealsStepMin,
            min: 0,
            max: 300,
            save: (v) => repo?.updateProfile(profile.id, mealsMin: v),
            explanation:
                "Time for eating, taken out of each day's free time before anything is "
                'planned, spread across the day.',
            effect: stepEffect(
              Format.estimate(SettingEffects.mealsStepMin),
              effects.mealsStep,
            ),
          ),
          length(
            label: 'Buffer',
            value: profile.bufferMin,
            step: SettingEffects.bufferStepMin,
            min: 0,
            max: 300,
            save: (v) => repo?.updateProfile(profile.id, bufferMin: v),
            explanation:
                'Getting around, admin, and the small things every day loses. Taken out '
                'of free time the same way as meals.',
            effect: stepEffect(
              Format.estimate(SettingEffects.bufferStepMin),
              effects.bufferStep,
            ),
          ),
          ValueStepper(
            label: 'Focus factor',
            text: '$focusPercent%',
            keyboardType: TextInputType.number,
            explanation:
                'How much of your free time turns into real work. At $focusPercent%, a '
                'free hour counts as ${Format.estimate((60 * profile.focusFactor).round())}.',
            effect: profile.focusFactor >= 1
                ? 'Already all of it: every free minute counts.'
                : stepEffect(
                    '${SettingEffects.focusStepPercent}%',
                    effects.focusStep,
                  ),
            onStep: (direction) => repo?.updateProfile(
              profile.id,
              focusFactor:
                  (profile.focusFactor +
                          direction * SettingEffects.focusStepPercent / 100)
                      .clamp(0.3, 1.0),
            ),
            onSubmit: (text) {
              final typed = TimeEntry.percent(text);
              if (typed == null) return false;
              repo?.updateProfile(
                profile.id,
                focusFactor: (typed / 100).clamp(0.3, 1.0),
              );
              return true;
            },
          ),
          length(
            label: 'Shortest usable gap',
            value: profile.minGapMin,
            step: SettingEffects.minGapStepMin,
            min: 5,
            max: 120,
            bareMinutes: true,
            save: (v) => repo?.updateProfile(profile.id, minGapMin: v),
            explanation:
                'Free stretches shorter than this are ignored, because real work does not '
                'get started in them.',
            effect:
                '${effects.discardedPerDay == 0 ? 'No free time this week comes in '
                          'stretches that short. ' : 'This week that sets aside about '
                          '${Format.estimate(effects.discardedPerDay)} of free time a day. '}'
                '${stepEffect(Format.estimate(SettingEffects.minGapStepMin), effects.minGapStep)}',
          ),
        ],
      ),
    );
  }
}

/// Sleep, day by day: when you get up, and when you go to bed that night.
class _SleepWeek extends ConsumerWidget {
  const _SleepWeek({required this.profile});

  final CapacityProfile profile;

  static const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Room for the arrow between going to bed and getting up.
  static const arrowWidth = AppSpace.xl;

  /// Shares of the width for a night's name, each of its times, and how long it is. The
  /// heading and the rows use the same shares, so the columns line up at any width and any
  /// text size: fixed widths cut the lengths short on a phone, and wrapped the day names
  /// with larger text.
  static const nameFlex = 4;
  static const timeFlex = 5;
  static const lengthFlex = 5;

  /// Wide enough for every column and no wider. Stretched across a desktop, each night's
  /// length ended up far from its times.
  static const maxWidth = 460.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appScopeProvider).value?.capacity;
    final settings = CapacityMapping.settings(profile);

    // Only the days that actually change are written.
    void save(Map<int, DaySleep> days) {
      final changed = {
        for (final MapEntry(key: day, value: sleep) in days.entries)
          if (settings.sleepOn(day) != sleep) day: sleep,
      };
      if (changed.isNotEmpty) repo?.setSleep(profile.id, changed);
    }

    Widget heading(String text, {TextAlign align = TextAlign.center}) =>
        Text(text, style: AppText.caption, textAlign: align);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Sleep', style: AppText.headline)),
            _SmallAction(
              label: 'Set several nights',
              onTap: () => _setSeveral(context, settings, save),
            ),
          ],
        ),
        Text(
          'When you go to bed each night, and when you get up the next morning. A bedtime '
          'earlier than you got up that day is after midnight. Nothing is ever planned '
          'into sleep, and blocks that fall in it do not count.',
          style: AppText.footnote,
        ),
        const SizedBox(height: AppSpace.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: nameFlex,
                    child: heading('Night', align: TextAlign.start),
                  ),
                  Expanded(flex: timeFlex, child: heading('To bed')),
                  const SizedBox(width: arrowWidth),
                  Expanded(flex: timeFlex, child: heading('Up at')),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    flex: lengthFlex,
                    child: heading('Asleep', align: TextAlign.end),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              // A row a night, the way a night is lived: to bed on the day it is named for,
              // then up the next morning. Rows of days, getting up first, read as sleeping
              // from morning until night.
              for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                _SleepNightRow(
                  name: names[day - 1],
                  nextName: names[CapacitySettings.dayAfter(day) - 1],
                  bedtimeMin: settings.sleepOn(day).bedtimeMin,
                  wakeMin: settings.sleepOn(CapacitySettings.dayAfter(day)).wakeMin,
                  night: settings.nightAfter(day),
                  target: settings.sleepTargetMin,
                  onBedtime: (minutes) {
                    final sleep = settings.sleepOn(day);
                    // Getting up and going to bed at the same minute is a day of no length.
                    if (minutes == sleep.wakeMin) return false;
                    save({day: DaySleep(wakeMin: sleep.wakeMin, bedtimeMin: minutes)});
                    return true;
                  },
                  onWake: (minutes) {
                    final next = CapacitySettings.dayAfter(day);
                    final sleep = settings.sleepOn(next);
                    if (minutes == sleep.bedtimeMin) return false;
                    save({next: DaySleep(wakeMin: minutes, bedtimeMin: sleep.bedtimeMin)});
                    return true;
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _setSeveral(
    BuildContext context,
    CapacitySettings settings,
    void Function(Map<int, DaySleep> days) save,
  ) async {
    final result = await showAppDialog<(Set<int>, int, int)>(
      context: context,
      builder: (context) => _SleepDialog(
        bedtimeMin: settings.sleepOn(DateTime.monday).bedtimeMin,
        wakeMin: settings.sleepOn(DateTime.tuesday).wakeMin,
      ),
    );
    if (result == null) return;
    final (nights, bedtime, wake) = result;

    // Each night sets the bedtime of the day it starts on and getting up on the next, so
    // two nights in a row share the day between them.
    final days = <int, DaySleep>{};
    DaySleep current(int day) => days[day] ?? settings.sleepOn(day);
    for (final night in nights) {
      days[night] = DaySleep(wakeMin: current(night).wakeMin, bedtimeMin: bedtime);
      final next = CapacitySettings.dayAfter(night);
      days[next] = DaySleep(wakeMin: wake, bedtimeMin: current(next).bedtimeMin);
    }
    // Never a day of no length, which only a clash with an untouched time could make.
    save({
      for (final MapEntry(key: day, value: sleep) in days.entries)
        if (sleep.wakeMin != sleep.bedtimeMin) day: sleep,
    });
  }
}

class _SleepNightRow extends StatelessWidget {
  const _SleepNightRow({
    required this.name,
    required this.nextName,
    required this.bedtimeMin,
    required this.wakeMin,
    required this.night,
    required this.target,
    required this.onBedtime,
    required this.onWake,
  });

  /// The day the night starts on.
  final String name;

  /// The day after it, when getting up ends the night.
  final String nextName;

  final int bedtimeMin;
  final int wakeMin;

  /// How long the night is.
  final int night;

  /// The least sleep wanted in a night.
  final int target;

  /// Each takes a typed time, and says whether it could be used.
  final bool Function(int minutes) onBedtime;
  final bool Function(int minutes) onWake;

  @override
  Widget build(BuildContext context) {
    bool submit(String text, bool Function(int minutes) apply) {
      final minutes = TimeEntry.clock(text);
      return minutes != null && apply(minutes);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: _SleepWeek.nameFlex,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body,
                ),
              ),
              Expanded(
                flex: _SleepWeek.timeFlex,
                child: TypedValue(
                  key: ValueKey('bedtime-$name'),
                  fill: true,
                  text: Format.clock(bedtimeMin),
                  keyboardType: TextInputType.datetime,
                  onSubmit: (text) => submit(text, onBedtime),
                ),
              ),
              const SizedBox(
                width: _SleepWeek.arrowWidth,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: AppColour.labelTertiary,
                ),
              ),
              Expanded(
                flex: _SleepWeek.timeFlex,
                child: TypedValue(
                  // Named for the day it sets: getting up ends the night on the next day.
                  key: ValueKey('wake-$nextName'),
                  fill: true,
                  text: Format.clock(wakeMin),
                  keyboardType: TextInputType.datetime,
                  onSubmit: (text) => submit(text, onWake),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                flex: _SleepWeek.lengthFlex,
                child: Text(
                  Format.estimate(night),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.numeric.copyWith(
                    color: night < target ? AppColour.orange : null,
                  ),
                ),
              ),
            ],
          ),
          if (night < target)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: AppSpace.xs),
              child: Text(
                night == 0
                    ? 'No sleep at all before $nextName'
                    : 'Only ${Format.estimate(night)} of sleep before $nextName',
                style: AppText.footnote.copyWith(color: AppColour.orange),
              ),
            ),
        ],
      ),
    );
  }
}

/// The same sleep for several nights at once.
class _SleepDialog extends StatefulWidget {
  const _SleepDialog({required this.bedtimeMin, required this.wakeMin});

  final int bedtimeMin;
  final int wakeMin;

  @override
  State<_SleepDialog> createState() => _SleepDialogState();
}

class _SleepDialogState extends State<_SleepDialog> {
  /// Nights, by the day each starts on.
  final _nights = <int>{};
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
              Text('Sleep for several nights', style: AppText.title3),
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

class _CommitmentsCard extends ConsumerWidget {
  const _CommitmentsCard({required this.commitments});

  final List<Commitment> commitments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the set being edited, so a semester's blocks are never mixed with another's.
    final editingId = ref.watch(editingScheduleIdProvider);
    final visible = commitments
        .where((c) => c.scheduleId == editingId)
        .toList();
    final settings = CapacityMapping.settings(
      ref.watch(capacityProfileProvider).value,
    );

    final name = (ref.watch(schedulesProvider).value ?? const <TimetableSet>[])
        .where((s) => s.id == editingId)
        .map((s) => s.name)
        .firstOrNull;
    // A set not in force takes blocks that count nowhere above, which is baffling unless
    // it says so.
    final notInForce = editingId == null
        ? null
        : _notInForce(ref.watch(timetableProvider), editingId, name);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name == null ? 'Blocks' : 'Blocks in $name',
                  style: AppText.caption,
                ),
              ),
              _AddCommitmentButton(),
            ],
          ),
          if (notInForce != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              notInForce,
              style: AppText.footnote.copyWith(color: AppColour.orange),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          if (visible.isEmpty)
            Text(
              'No fixed blocks yet. Add your classes and labs — until then every day '
              'looks completely free, and the load figures will flatter you.',
              style: AppText.callout,
            )
          else
            for (final c in visible)
              _BlockRow(
                commitment: c,
                problems: _problemsOf(
                  c,
                  settings,
                  others: CapacityMapping.blocksOf([
                    for (final other in visible)
                      if (other.id != c.id) other,
                  ]).$1,
                ),
                onTap: () => _editBlock(context, ref, existing: c),
                onDelete: () => _deleteBlock(ref, c),
              ),
        ],
      ),
    );
  }

  Future<void> _deleteBlock(WidgetRef ref, Commitment c) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    await scope.capacity.deleteCommitment(c.id);
    ref
        .read(undoProvider.notifier)
        .offer(
          'Deleted "${c.title}"',
          () => scope.capacity.restoreCommitment(c.id),
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
          'are up then, change your sleep under Profile.',
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

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Timetables', style: AppText.caption)),
              _SmallAction(
                label: 'New',
                onTap: () => _edit(context, ref, null),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            active == null
                ? 'No timetable covers today, so nothing is being subtracted.'
                : 'In force today: ${active.name}',
            style: AppText.footnote.copyWith(
              color: active == null
                  ? AppColour.orange
                  : AppColour.labelTertiary,
            ),
          ),
          const SizedBox(height: AppSpace.md),

          for (final set in sets)
            _ScheduleRow(
              set: set,
              editing: set.id == editingId,
              inForce: active?.id == set.id,
              onSelect: () =>
                  ref.read(editingScheduleProvider.notifier).select(set.id),
              onEdit: () => _edit(context, ref, set),
              onDuplicate: () => _duplicate(context, ref, set),
              onDelete: () => _delete(ref, set),
            ),
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

class _ScheduleRow extends StatefulWidget {
  const _ScheduleRow({
    required this.set,
    required this.editing,
    required this.inForce,
    required this.onSelect,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final TimetableSet set;
  final bool editing;
  final bool inForce;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  State<_ScheduleRow> createState() => _ScheduleRowState();
}

class _ScheduleRowState extends State<_ScheduleRow> {
  bool _hovered = false;

  /// Narrower than this, a row's actions go on a line under its name instead of beside it.
  static const _actionsBesideFrom = 420.0;

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    // Shown for the row under the pointer, and for the selected row, which is how a touch
    // screen, where nothing hovers, reaches them.
    final showActions = _hovered || widget.editing;

    final dates = set.isFallback
        ? 'Any day no other timetable covers'
        : (set.startsOn == null && set.endsOn == null)
        ? 'Every day'
        : '${_readableDate(set.startsOn)}  →  ${_readableDate(set.endsOn)}';

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                set.name,
                style: AppText.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.inForce) ...[
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: AppColour.green.withValues(alpha: 0.18),
                  borderRadius: AppRadius.smallAll,
                ),
                child: Text(
                  'in force',
                  style: AppText.numeric.copyWith(color: AppColour.green),
                ),
              ),
            ],
          ],
        ),
        Text(dates, style: AppText.numeric),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallAction(label: 'Duplicate', onTap: widget.onDuplicate),
        _SmallAction(label: 'Edit', onTap: widget.onEdit),
        if (!set.isFallback)
          _SmallAction(
            label: 'Delete',
            tint: AppColour.red,
            onTap: widget.onDelete,
          ),
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          margin: const EdgeInsets.only(bottom: AppSpace.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: widget.editing
                ? AppColour.fillStrong
                : _hovered
                ? AppColour.fill
                : null,
            borderRadius: AppRadius.mediumAll,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _actionsBesideFrom) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    AnimatedSize(
                      duration: AppMotion.quick,
                      curve: AppMotion.standard,
                      alignment: Alignment.topLeft,
                      child: showActions
                          ? Align(
                              alignment: Alignment.centerLeft,
                              // Level with the name above, past the first action's padding.
                              child: Transform.translate(
                                offset: const Offset(-AppSpace.sm, 0),
                                child: actions,
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: details),
                  // Invisible actions must not still take taps.
                  IgnorePointer(
                    ignoring: !showActions,
                    child: AnimatedOpacity(
                      duration: AppMotion.quick,
                      opacity: showActions ? 1 : 0,
                      child: actions,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
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
