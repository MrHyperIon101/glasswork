import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/ledger.dart';
import '../../capacity/slot_check.dart';
import '../../data/task_slots.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../motion.dart';
import '../task_time_text.dart';
import '../time_entry.dart';
import 'field_controls.dart';
import 'value_stepper.dart';

/// What the time dialog was closed with.
sealed class TaskTimeChoice {
  const TaskTimeChoice();
}

/// From [start], for [lengthMin].
final class TaskTimeSet extends TaskTimeChoice {
  const TaskTimeSet(this.start, this.lengthMin);

  final DateTime start;
  final int lengthMin;
}

/// No time any more.
final class TaskTimeRemoved extends TaskTimeChoice {
  const TaskTimeRemoved();
}

/// A task's time: when it is, with a way to change or remove it, or a button to give it one.
///
/// Giving a task a time is what puts it on the time budget: the day's timeline draws it, the
/// day's figures count it, and the home screen's day lists it, all from this one field.
class TaskTimePicker extends StatelessWidget {
  const TaskTimePicker({
    required this.title,
    required this.start,
    required this.lengthMin,
    required this.onChanged,
    this.taskId,
    super.key,
  });

  /// What the task is called, for the dialog to name it.
  final String title;

  /// Its time, if it has one.
  final DateTime? start;

  /// How long it takes: its estimate.
  final int? lengthMin;

  /// The task, when it exists already, so its own time is not a clash with itself.
  final String? taskId;

  /// A new time and length, or null for none.
  final void Function(DateTime? start, int? lengthMin) onChanged;

  @override
  Widget build(BuildContext context) {
    final start = this.start;

    Future<void> choose() async {
      final choice = await showAppDialog<TaskTimeChoice>(
        context: context,
        builder: (context) => TaskTimeDialog(
          title: title,
          start: start,
          lengthMin: lengthMin,
          taskId: taskId,
        ),
      );
      switch (choice) {
        case TaskTimeSet(:final start, :final lengthMin):
          onChanged(start, lengthMin);
        case TaskTimeRemoved():
          onChanged(null, null);
        case null:
      }
    }

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ComposerChip(
          key: const ValueKey('task-time'),
          label: start == null
              ? 'Give it a time'
              : Format.taskTime(start, lengthMin ?? TaskSlots.defaultLengthMin, DateTime.now()),
          selected: start != null,
          leading: Icon(
            Icons.schedule_rounded,
            size: 14,
            color: start == null ? AppColour.labelSecondary : AppColour.accent,
          ),
          onTap: choose,
        ),
        if (start != null)
          ComposerChip(
            label: 'Remove',
            selected: false,
            onTap: () => onChanged(null, null),
          ),
      ],
    );
  }
}

/// Choosing a task's time: a day this week, when it starts, and how long it takes, with a
/// line saying whether that time is free, and a way to move it to where it is.
class TaskTimeDialog extends ConsumerStatefulWidget {
  const TaskTimeDialog({
    required this.title,
    this.start,
    this.lengthMin,
    this.taskId,
    super.key,
  });

  final String title;
  final DateTime? start;
  final int? lengthMin;
  final String? taskId;

  @override
  ConsumerState<TaskTimeDialog> createState() => _TaskTimeDialogState();
}

class _TaskTimeDialogState extends ConsumerState<TaskTimeDialog> {
  late DateTime _day;
  late int _startMin;
  late int _lengthMin = widget.lengthMin ?? TaskSlots.defaultLengthMin;

  /// How far a step moves the start or the length.
  static const _step = 15;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.start?.toLocal() case final start?) {
      _day = DateTime(start.year, start.month, start.day);
      _startMin = start.hour * 60 + start.minute;
      return;
    }
    // Without a time yet: the next free stretch long enough today, from the next quarter
    // hour, or else the same tomorrow.
    final today = DateTime(now.year, now.month, now.day);
    final fromMin = ((now.hour * 60 + now.minute) ~/ _step + 1) * _step;
    final days = ref.read(dayCapacityProvider);
    final free = days.isEmpty
        ? null
        : SlotCheck.nextFree(days.first, lengthMin: _lengthMin, fromMin: fromMin);
    if (free != null) {
      _day = today;
      _startMin = free;
    } else {
      _day = DateTime(today.year, today.month, today.day + 1);
      _startMin = days.length < 2
          ? 9 * 60
          : SlotCheck.nextFree(days[1], lengthMin: _lengthMin) ?? 9 * 60;
    }
  }

  DayCapacity? _capacityOn(DateTime day) {
    for (final capacity in ref.watch(dayCapacityProvider)) {
      if (capacity.date == day) return capacity;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final capacity = _capacityOn(_day);
    final others = [
      for (final slot in ref.watch(taskSlotsProvider(_day)))
        if (slot.taskId != widget.taskId && !slot.done)
          (slot.title, slot.startMin, slot.endMin),
    ];
    final problems = capacity == null
        ? null
        : SlotCheck.problems(
            capacity,
            startMin: _startMin,
            lengthMin: _lengthMin,
            others: others,
          );
    final check = TaskTimeText.check(problems);
    final free = problems == null || problems.isEmpty || capacity == null
        ? null
        : SlotCheck.nextFree(capacity, lengthMin: _lengthMin, fromMin: _startMin, others: others) ??
              SlotCheck.nextFree(capacity, lengthMin: _lengthMin, others: others);

    final start = DateTime(_day.year, _day.month, _day.day, _startMin ~/ 60, _startMin % 60);
    final valid = _lengthMin > 0 && _startMin >= 0 && _startMin < minutesInDay;

    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A time for it', style: AppText.title3),
              const SizedBox(height: AppSpace.xs),
              Text(
                'Sets aside time to do "${widget.title}". It goes on your time budget '
                'for the day, and counts in its figures.',
                style: AppText.footnote,
              ),
              const SizedBox(height: AppSpace.lg),
              Text('Day', style: AppText.caption),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (var offset = 0; offset < 7; offset++)
                    if (DateTime(today.year, today.month, today.day + offset) case final day)
                      ComposerChip(
                        key: ValueKey('time-day-$offset'),
                        label: switch (offset) {
                          0 => 'Today',
                          1 => 'Tomorrow',
                          _ => _dayNames[day.weekday - 1],
                        },
                        selected: day == _day,
                        onTap: () => setState(() => _day = day),
                      ),
                  // A time set further ahead stays choosable.
                  if (_day.difference(today).inDays >= 7 || _day.isBefore(today))
                    ComposerChip(
                      label: Format.dayAndDate(_day),
                      selected: true,
                      onTap: () {},
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              ValueStepper(
                key: const ValueKey('time-start'),
                label: 'Starts',
                text: Format.clock(_startMin),
                keyboardType: TextInputType.datetime,
                onStep: (direction) => setState(
                  () => _startMin = (_startMin + direction * _step).clamp(0, minutesInDay - _step),
                ),
                onSubmit: (text) {
                  final minutes = TimeEntry.clock(text);
                  if (minutes == null) return false;
                  setState(() => _startMin = minutes);
                  return true;
                },
              ),
              ValueStepper(
                key: const ValueKey('time-length'),
                label: 'Takes',
                text: Format.estimate(_lengthMin),
                onStep: (direction) => setState(
                  () => _lengthMin = (_lengthMin + direction * _step).clamp(_step, 12 * 60),
                ),
                onSubmit: (text) {
                  final minutes = TimeEntry.duration(text, bareMinutes: true);
                  if (minutes == null || minutes <= 0) return false;
                  setState(() => _lengthMin = minutes);
                  return true;
                },
              ),
              const SizedBox(height: AppSpace.sm),
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.quick),
                child: Row(
                  key: ValueKey(check.text + (free?.toString() ?? '')),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        check.clear ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 15,
                        color: check.clear ? AppColour.green : AppColour.orange,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        '${Format.taskTime(start, _lengthMin, now)}. ${check.text}',
                        style: AppText.footnote.copyWith(
                          color: check.clear ? AppColour.labelSecondary : AppColour.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (free != null) ...[
                const SizedBox(height: AppSpace.sm),
                ComposerChip(
                  key: const ValueKey('time-move'),
                  label: TaskTimeText.moveTo(free),
                  selected: false,
                  onTap: () => setState(() => _startMin = free),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  if (widget.start != null)
                    Flexible(
                      child: GhostButton(
                        label: AppLayout.compact(context) ? 'Remove' : 'Remove the time',
                        onTap: () => Navigator.pop(context, const TaskTimeRemoved()),
                      ),
                    ),
                  const Spacer(),
                  GhostButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
                  const SizedBox(width: AppSpace.sm),
                  PrimaryButton(
                    label: 'Set',
                    enabled: valid,
                    onTap: () {
                      if (valid) Navigator.pop(context, TaskTimeSet(start, _lengthMin));
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
