import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/repository/project_repository.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';

/// Controls shared by the composer and the detail sheet.
///
/// One implementation each, so a field cannot behave differently depending on where you
/// happen to be editing it — which is exactly the kind of drift that makes an app feel
/// unfinished.

/// A labelled row: caption on the left, control on the right.
class FieldRow extends StatelessWidget {
  const FieldRow({
    required this.label,
    required this.child,
    this.hint,
    super.key,
  });

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 84,
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            label,
            style: AppText.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            if (hint case final h?) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                h,
                style: AppText.footnote.copyWith(
                  color: AppColour.labelQuaternary,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

/// Selectable pill.
class ComposerChip extends StatefulWidget {
  const ComposerChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tint,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  State<ComposerChip> createState() => _ComposerChipState();
}

class _ComposerChipState extends State<ComposerChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tint = widget.tint ?? AppColour.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm - 1,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? tint.withValues(alpha: 0.2)
                : _hovered
                ? AppColour.fillStrong
                : AppColour.fill,
            borderRadius: AppRadius.smallAll,
            border: Border.all(
              color: widget.selected
                  ? tint.withValues(alpha: 0.55)
                  : const Color(0x00000000),
            ),
          ),
          child: Text(
            widget.label,
            style: AppText.callout.copyWith(
              color: widget.selected ? tint : AppColour.labelSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Due-date quick picks plus a calendar.
class DueChips extends StatelessWidget {
  const DueChips({
    required this.dueAt,
    required this.dueDate,
    required this.onChanged,
    super.key,
  });

  final DateTime? dueAt;
  final DateTime? dueDate;

  /// (timedInstant, allDayDate) — at most one is ever non-null.
  final void Function(DateTime? at, DateTime? date) onChanged;

  @override
  Widget build(BuildContext context) {
    final today = _dayOf(DateTime.now());
    final due = dueAt == null ? dueDate : _dayOf(dueAt!);

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        ComposerChip(
          label: 'Today',
          selected: due != null && _same(due, today),
          onTap: () => onChanged(null, today),
        ),
        ComposerChip(
          label: 'Tomorrow',
          selected:
              due != null && _same(due, today.add(const Duration(days: 1))),
          onTap: () => onChanged(null, today.add(const Duration(days: 1))),
        ),
        ComposerChip(
          label: 'Next week',
          selected:
              due != null && _same(due, today.add(const Duration(days: 7))),
          onTap: () => onChanged(null, today.add(const Duration(days: 7))),
        ),
        ComposerChip(
          label: due == null
              ? 'Pick a day'
              : dueAt != null
              ? '${Format.shortDate(dueAt!)}, '
                    '${dueAt!.hour.toString().padLeft(2, '0')}:'
                    '${dueAt!.minute.toString().padLeft(2, '0')}'
              : Format.shortDate(due),
          selected: due != null && !_isQuick(due, today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: due ?? today,
              firstDate: DateTime(today.year - 1),
              lastDate: DateTime(today.year + 5),
            );
            if (picked != null) onChanged(null, _dayOf(picked));
          },
        ),
        // A time turns an all-day task into a timed one, which changes when it counts
        // as late — so it is a deliberate extra step, not a default.
        if (due != null)
          ComposerChip(
            label: dueAt == null ? '+ Add a time' : 'Clear time',
            selected: false,
            tint: AppColour.labelTertiary,
            onTap: () async {
              if (dueAt != null) {
                onChanged(null, _dayOf(dueAt!));
                return;
              }
              final t = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 17, minute: 0),
              );
              if (t != null) {
                onChanged(
                  DateTime(due.year, due.month, due.day, t.hour, t.minute),
                  null,
                );
              }
            },
          ),
        if (due != null)
          ComposerChip(
            label: 'Clear',
            selected: false,
            tint: AppColour.labelTertiary,
            onTap: () => onChanged(null, null),
          ),
      ],
    );
  }

  static bool _isQuick(DateTime due, DateTime today) =>
      _same(due, today) ||
      _same(due, today.add(const Duration(days: 1))) ||
      _same(due, today.add(const Duration(days: 7)));

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class PriorityChips extends StatelessWidget {
  const PriorityChips({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [
    (0, 'None', null),
    (1, 'Low', AppColour.grey),
    (2, 'Medium', AppColour.orange),
    (3, 'High', AppColour.red),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.sm,
    runSpacing: AppSpace.sm,
    children: [
      for (final (v, label, tint) in _options)
        ComposerChip(
          label: label,
          selected: value == v,
          tint: tint ?? AppColour.labelTertiary,
          onTap: () => onChanged(v),
        ),
    ],
  );
}

class EstimateChips extends StatelessWidget {
  const EstimateChips({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  /// Sizes, not a number field. One tap is the difference between estimating everything
  /// and estimating nothing, which is what the capacity engine depends on.
  static const _sizes = [15, 30, 60, 120, 240, 480];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.sm,
    runSpacing: AppSpace.sm,
    children: [
      for (final mins in _sizes)
        ComposerChip(
          label: Format.estimate(mins),
          selected: value == mins,
          onTap: () => onChanged(value == mins ? null : mins),
        ),
    ],
  );
}

/// Existing labels plus a field to invent one.
class LabelPicker extends ConsumerStatefulWidget {
  const LabelPicker({
    required this.selectedNames,
    required this.onToggle,
    super.key,
  });

  final Set<String> selectedNames;
  final ValueChanged<String> onToggle;

  @override
  ConsumerState<LabelPicker> createState() => _LabelPickerState();
}

class _LabelPickerState extends ConsumerState<LabelPicker> {
  final _controller = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(labelsProvider).value ?? const <Label>[];
    final names = {
      for (final l in existing) l.name,
      // A label typed into quick-add may not exist yet; show it anyway.
      ...widget.selectedNames,
    }.toList()..sort();

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final name in names)
          ComposerChip(
            label: '#$name',
            selected: widget.selectedNames.contains(name),
            tint: _tintFor(name, existing),
            onTap: () => widget.onToggle(name),
          ),
        if (_adding)
          SizedBox(
            width: 140,
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: AppText.callout.copyWith(color: AppColour.label),
              cursorColor: AppColour.accent,
              onSubmitted: (v) {
                final name = v.trim().replaceAll('#', '');
                if (name.isNotEmpty) widget.onToggle(name);
                _controller.clear();
                setState(() => _adding = false);
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColour.fill,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.smallAll,
                  borderSide: BorderSide.none,
                ),
                hintText: 'new label',
                hintStyle: AppText.callout.copyWith(
                  color: AppColour.labelTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
              ),
            ),
          )
        else
          ComposerChip(
            label: '+',
            selected: false,
            tint: AppColour.labelTertiary,
            onTap: () => setState(() => _adding = true),
          ),
      ],
    );
  }

  static Color? _tintFor(String name, List<Label> existing) {
    for (final l in existing) {
      if (l.name == name && l.colour != null) return Color(l.colour!);
    }
    return null;
  }
}

/// A control for one custom field, chosen by its type.
///
/// Values are stored as text and decoded per type. Encodings are deliberately boring:
/// ISO for dates, 'true'/'false' for checkboxes, the option label for a select, and a
/// JSON array for a multi-select.
class CustomFieldControl extends StatelessWidget {
  const CustomFieldControl({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final FieldDef field;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.checkbox:
        final on = value == 'true';
        return ComposerChip(
          label: on ? 'Yes' : 'No',
          selected: on,
          tint: AppColour.green,
          onTap: () => onChanged(on ? 'false' : 'true'),
        );

      case FieldType.select:
        final options = FieldOption.decode(field.optionsJson);
        return Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final o in options)
              ComposerChip(
                label: o.label,
                selected: value == o.label,
                tint: o.colour == null ? null : Color(o.colour!),
                onTap: () => onChanged(value == o.label ? null : o.label),
              ),
          ],
        );

      case FieldType.multiSelect:
        final options = FieldOption.decode(field.optionsJson);
        final chosen = _decodeList(value);
        return Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final o in options)
              ComposerChip(
                label: o.label,
                selected: chosen.contains(o.label),
                tint: o.colour == null ? null : Color(o.colour!),
                onTap: () {
                  final next = chosen.toSet();
                  next.contains(o.label)
                      ? next.remove(o.label)
                      : next.add(o.label);
                  onChanged(next.isEmpty ? null : jsonEncode(next.toList()));
                },
              ),
          ],
        );

      case FieldType.date:
        final parsed = value == null ? null : DateTime.tryParse(value!);
        return Wrap(
          spacing: AppSpace.sm,
          children: [
            ComposerChip(
              label: parsed == null ? 'Pick a day' : Format.shortDate(parsed),
              selected: parsed != null,
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: parsed ?? now,
                  firstDate: DateTime(now.year - 2),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) {
                  onChanged(picked.toIso8601String().split('T').first);
                }
              },
            ),
            if (parsed != null)
              ComposerChip(
                label: 'Clear',
                selected: false,
                tint: AppColour.labelTertiary,
                onTap: () => onChanged(null),
              ),
          ],
        );

      case FieldType.text:
      case FieldType.number:
      case FieldType.url:
        return _TextValue(
          field: field,
          value: value,
          onChanged: onChanged,
        );
    }
  }

  static List<String> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      return parsed is List ? parsed.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }
}

class _TextValue extends StatefulWidget {
  const _TextValue({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FieldDef field;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  State<_TextValue> createState() => _TextValueState();
}

class _TextValueState extends State<_TextValue> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numeric = widget.field.type == FieldType.number;

    return TextField(
      controller: _controller,
      style: AppText.body,
      cursorColor: AppColour.accent,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v.trim()),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColour.fill,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: BorderSide.none,
        ),
        hintText: switch (widget.field.type) {
          FieldType.url => 'https://…',
          FieldType.number => '0',
          _ => 'Anything',
        },
        hintStyle: AppText.body.copyWith(color: AppColour.labelTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
      ),
    );
  }
}

// --- buttons ---------------------------------------------------------------

class GhostButton extends StatefulWidget {
  const GhostButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: _hovered ? AppColour.fill : null,
          borderRadius: AppRadius.smallAll,
        ),
        child: Text(
          widget.label,
          style: AppText.callout.copyWith(color: AppColour.labelSecondary),
        ),
      ),
    ),
  );
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.enabled
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: !widget.enabled
              ? AppColour.fill
              : _hovered
              ? AppColour.accent
              : AppColour.accent.withValues(alpha: 0.9),
          borderRadius: AppRadius.mediumAll,
        ),
        child: Text(
          widget.label,
          style: AppText.headline.copyWith(
            color: widget.enabled ? Colors.white : AppColour.labelQuaternary,
          ),
        ),
      ),
    ),
  );
}
