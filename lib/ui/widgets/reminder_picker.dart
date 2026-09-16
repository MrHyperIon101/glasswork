import 'package:flutter/material.dart';

import '../../reminders/reminder_presets.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../reminder_choice.dart';
import 'field_controls.dart';
import 'reminder_dialog.dart';

/// When to be reminded about a task, used wherever a task is made or edited.
///
/// What is set, said in words with how long until it; quick choices that suit the task;
/// and any other moment, chosen in [ReminderDialog].
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
    final summary = at == null ? null : ReminderChoice.describe(at, now);

    Future<void> choose() async {
      final chosen = await showDialog<DateTime>(
        context: context,
        builder: (_) => ReminderDialog(initial: at),
      );
      if (chosen != null) onChanged(chosen);
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
        if (at != null) ...[
          _SetReminder(
            text: summary ?? '${Format.reminderTime(at, now)}, which has passed',
            passed: summary == null,
            onChange: choose,
            onRemove: () => onChanged(null),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
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
            ComposerChip(
              key: const ValueKey('reminder-choose'),
              label: at == null ? 'Choose a time…' : 'Another time…',
              selected: false,
              tint: AppColour.labelTertiary,
              onTap: choose,
            ),
          ],
        ),
        if (at != null && summary != null && !permitted) ...[
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

/// The reminder that is set: when, how long until, and ways to change or remove it.
class _SetReminder extends StatelessWidget {
  const _SetReminder({
    required this.text,
    required this.passed,
    required this.onChange,
    required this.onRemove,
  });

  final String text;
  final bool passed;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tint = passed ? AppColour.red : AppColour.accent;

    return Container(
      padding: const EdgeInsets.only(left: AppSpace.md),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: AppRadius.mediumAll,
      ),
      child: Row(
        children: [
          Icon(
            passed
                ? Icons.notifications_off_outlined
                : Icons.notifications_active_outlined,
            size: 16,
            color: tint,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onChange,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Text(
                    text,
                    style: AppText.callout.copyWith(color: AppColour.label),
                  ),
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'No reminder',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(
                    AppLayout.touch ? AppSpace.md : AppSpace.sm,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 15,
                    color: AppColour.labelSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
