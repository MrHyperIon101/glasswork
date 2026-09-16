import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../format.dart';
import '../reminder_choice.dart';
import '../time_entry.dart';
import 'field_controls.dart';
import 'value_stepper.dart';

/// Choosing exactly when to be reminded: soon, or a day and a time.
///
/// Everything can be typed as well as tapped. The day is a chip or a date from the
/// calendar; the time is typed ("6pm", "18:30") or stepped; and a line above the buttons
/// says in words when that is and how long until it, so a reminder set for the wrong day
/// is caught here rather than when it fails to arrive.
class ReminderDialog extends StatefulWidget {
  const ReminderDialog({this.initial, super.key});

  /// The reminder already set, if any.
  final DateTime? initial;

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late DateTime _day;
  late int _minutes;
  bool _timeReadable = true;
  bool _calendarOpen = false;

  /// How far a step moves the time.
  static const _step = 15;
  static const _minutesInDay = 24 * 60;

  @override
  void initState() {
    super.initState();
    final start = ReminderChoice.initial(DateTime.now(), existing: widget.initial);
    _day = DateTime(start.year, start.month, start.day);
    _minutes = start.hour * 60 + start.minute;
  }

  DateTime get _at => ReminderChoice.at(_day, _minutes);

  void _choose(DateTime at) => setState(() {
    _day = DateTime(at.year, at.month, at.day);
    _minutes = at.hour * 60 + at.minute;
    _timeReadable = true;
    _calendarOpen = false;
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary = _timeReadable ? ReminderChoice.describe(_at, now) : null;
    final canSet = summary != null;
    final days = ReminderChoice.days(now);
    final onAChip = days.any((d) => d.at == _day);

    Widget chips(List<Widget> children) => Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: children,
    );

    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remind me', style: AppText.title3),
              const SizedBox(height: AppSpace.lg),
              Text('Soon', style: AppText.caption),
              const SizedBox(height: AppSpace.sm),
              chips([
                for (final choice in ReminderChoice.soon(now))
                  ComposerChip(
                    label: choice.label,
                    selected: _at == choice.at,
                    onTap: () => _choose(choice.at),
                  ),
              ]),
              const SizedBox(height: AppSpace.lg),
              Text('Day', style: AppText.caption),
              const SizedBox(height: AppSpace.sm),
              chips([
                for (final day in days)
                  ComposerChip(
                    label: day.label,
                    selected: _day == day.at,
                    onTap: () => setState(() {
                      _day = day.at;
                      _calendarOpen = false;
                    }),
                  ),
                ComposerChip(
                  label: onAChip ? 'Another day' : Format.dayAndDate(_day),
                  selected: !onAChip || _calendarOpen,
                  onTap: () => setState(() => _calendarOpen = !_calendarOpen),
                ),
              ]),
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: _calendarOpen
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpace.sm),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColour.accent,
                              onPrimary: AppColour.label,
                              surface: AppColour.elevated,
                              onSurface: AppColour.label,
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: _day,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: DateTime(now.year + 5, 12, 31),
                            onDateChanged: (date) => setState(() {
                              _day = DateTime(date.year, date.month, date.day);
                              _calendarOpen = false;
                            }),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: AppSpace.lg),
              ValueStepper(
                key: const ValueKey('reminder-time'),
                label: 'At',
                text: Format.clock(_minutes),
                keyboardType: TextInputType.datetime,
                error: !_timeReadable,
                onStep: (direction) => setState(() {
                  _timeReadable = true;
                  _minutes = (_minutes + direction * _step) % _minutesInDay;
                }),
                onEdit: (text) {
                  final minutes = TimeEntry.clock(text);
                  setState(() {
                    _timeReadable = minutes != null;
                    if (minutes != null) _minutes = minutes;
                  });
                },
                onSubmit: (text) {
                  final minutes = TimeEntry.clock(text);
                  // Unreadable text goes back to the last time that was read.
                  setState(() {
                    _timeReadable = true;
                    if (minutes != null) _minutes = minutes;
                  });
                  return minutes != null;
                },
              ),
              const SizedBox(height: AppSpace.xs),
              chips([
                for (final minutes in ReminderChoice.times)
                  ComposerChip(
                    label: Format.clock(minutes),
                    selected: _minutes == minutes,
                    onTap: () => setState(() {
                      _minutes = minutes;
                      _timeReadable = true;
                    }),
                  ),
              ]),
              const SizedBox(height: AppSpace.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    canSet ? Icons.notifications_active_outlined : Icons.error_outline,
                    size: 16,
                    color: canSet ? AppColour.accent : AppColour.red,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      !_timeReadable
                          ? "Couldn't read that time. Try 6pm, 18:30 or 9.15am."
                          : summary ?? 'That time has already passed.',
                      style: AppText.callout.copyWith(
                        color: canSet ? AppColour.label : AppColour.red,
                      ),
                    ),
                  ),
                ],
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
                    label: 'Set reminder',
                    enabled: canSet,
                    onTap: () {
                      if (canSet) Navigator.pop(context, _at);
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
