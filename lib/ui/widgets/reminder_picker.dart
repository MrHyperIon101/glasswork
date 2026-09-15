import 'package:flutter/material.dart';

import '../../reminders/reminder_presets.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import 'field_controls.dart';

/// When to be reminded about a task: a quick choice, any date and time, or not at all.
class ReminderPicker extends StatelessWidget {
  const ReminderPicker({
    required this.remindAt,
    required this.onChanged,
    this.dueAt,
    this.dueDate,
    this.permitted = true,
    super.key,
  });

  final DateTime? remindAt;
  final DateTime? dueAt;
  final DateTime? dueDate;

  /// False when this device has been told not to show notifications, so a reminder set
  /// here would never appear on it.
  final bool permitted;

  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final at = remindAt?.toLocal();
    final presets = ReminderPresets.of(now, dueAt: dueAt, dueDate: dueDate);

    Future<void> pick() async {
      final suggested = at ?? presets.firstOrNull?.at ?? now.add(const Duration(hours: 1));
      final initial = suggested.isBefore(now) ? now : suggested;
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 5),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time == null) return;
      onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
    }

    String when(DateTime moment) {
      // A preset's name already says today or tomorrow, so its time says only the time.
      final days = DateTime.utc(moment.year, moment.month, moment.day)
          .difference(DateTime.utc(now.year, now.month, now.day))
          .inDays;
      return days <= 1
          ? Format.clock(moment.hour * 60 + moment.minute)
          : Format.reminderTime(moment, now);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final preset in presets)
              ComposerChip(
                label: '${preset.label} · ${when(preset.at)}',
                selected: at == preset.at,
                onTap: () => onChanged(preset.at),
              ),
            if (at != null && !presets.any((p) => p.at == at))
              ComposerChip(
                label: Format.reminderTime(at, now),
                selected: true,
                onTap: pick,
              ),
            ComposerChip(
              label: 'Pick a time',
              selected: false,
              tint: AppColour.labelTertiary,
              onTap: pick,
            ),
            if (at != null)
              ComposerChip(
                label: 'No reminder',
                selected: false,
                tint: AppColour.labelTertiary,
                onTap: () => onChanged(null),
              ),
          ],
        ),
        if (at != null && !at.isAfter(now)) ...[
          const SizedBox(height: AppSpace.sm),
          Text('That time has passed.', style: AppText.footnote),
        ] else if (at != null && !permitted) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            'Notifications are off for Glasswork on this device, so this reminder will '
            'not appear here. Turn them on in the system settings.',
            style: AppText.footnote.copyWith(color: AppColour.orange),
          ),
        ],
      ],
    );
  }
}
