import 'package:flutter/material.dart';

import '../../capacity/block_check.dart';
import '../../capacity/ledger.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../time_entry.dart';
import 'field_controls.dart';
import 'value_stepper.dart';
import 'weekday_picker.dart';

/// A block as the dialog edits it.
class BlockDraft {
  const BlockDraft({
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

/// Adds or edits a fixed block, and will not put one where it cannot count.
///
/// Times are a start and an end, the way a timetable prints them; the length is worked out
/// and shown beside the end. Time already spoken for — asleep, or taken by another block on
/// a shared day — is checked as the times are typed. The dialog says what is in the way,
/// offers the nearest time that is free, and saves only once nothing is.
class BlockDialog extends StatefulWidget {
  const BlockDialog({
    required this.settings,
    required this.others,
    this.initial,
    this.timetableName,
    this.notInForce,
    super.key,
  });

  /// Where sleep falls.
  final CapacitySettings settings;

  /// The rest of the timetable the block belongs to, without the block itself.
  final List<FixedBlock> others;

  /// The block being edited, or null to add one.
  final BlockDraft? initial;

  final String? timetableName;

  /// Why blocks saved here will not count today, when they will not.
  final String? notInForce;

  @override
  State<BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<BlockDialog> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final Set<int> _weekdays = {...?widget.initial?.weekdays};
  late int _startMin = widget.initial?.startMin ?? 9 * 60;
  late int _durationMin = widget.initial?.durationMin ?? 60;

  /// Whether what is typed into each field can be used.
  bool _startReadable = true;
  bool _endReadable = true;

  /// What the steps move by.
  static const _step = 15;

  int get _endMin => _startMin + _durationMin;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _setDays(Iterable<int> days) => setState(
    () => _weekdays
      ..clear()
      ..addAll(days),
  );

  /// The length of a block from the start to an end at [endMin]: past midnight when the end
  /// is not after the start. Null when it would have no length at all.
  int? _lengthTo(int endMin) {
    final length = endMin > _startMin
        ? endMin - _startMin
        : endMin + minutesInDay - _startMin;
    return length <= 0 || length >= minutesInDay ? null : length;
  }

  @override
  Widget build(BuildContext context) {
    final readable = _startReadable && _endReadable;
    final problems = _weekdays.isEmpty || !readable
        ? const <BlockProblem>[]
        : BlockCheck.problems(
            startMin: _startMin,
            durationMin: _durationMin,
            weekdays: _weekdays,
            settings: widget.settings,
            others: widget.others,
          );
    final nearest = problems.isEmpty
        ? null
        : BlockCheck.nearestFreeStart(
            startMin: _startMin,
            durationMin: _durationMin,
            weekdays: _weekdays,
            settings: widget.settings,
            others: widget.others,
          );
    final canSave =
        _title.text.trim().isNotEmpty &&
        _weekdays.isNotEmpty &&
        readable &&
        problems.isEmpty;

    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Fixed block' : 'Edit block',
                style: AppText.title3,
              ),
              if (widget.timetableName case final name?)
                Text('In $name', style: AppText.footnote),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _title,
                // Straight to typing when adding. Editing is more often a time than a name,
                // and a keyboard would cover the times on a phone.
                autofocus: widget.initial == null,
                style: AppText.body,
                cursorColor: AppColour.accent,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColour.fill,
                  border: const OutlineInputBorder(
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
              Row(
                children: [
                  Expanded(child: Text('Repeats', style: AppText.caption)),
                  _Preset(
                    label: 'Weekdays',
                    onTap: () => _setDays(const [1, 2, 3, 4, 5]),
                  ),
                  _Preset(
                    label: 'Every day',
                    onTap: () => _setDays(const [1, 2, 3, 4, 5, 6, 7]),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              WeekdayPicker(
                selected: _weekdays,
                onToggle: (day) => setState(
                  () => _weekdays.contains(day)
                      ? _weekdays.remove(day)
                      : _weekdays.add(day),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              ValueStepper(
                key: const ValueKey('block-start'),
                label: 'Starts',
                text: Format.clock(_startMin),
                keyboardType: TextInputType.datetime,
                error: !_startReadable,
                // Moving the start keeps the length, so the end moves with it.
                onStep: (direction) => setState(() {
                  _startReadable = true;
                  _startMin = (_startMin + direction * _step).clamp(
                    0,
                    minutesInDay - _step,
                  );
                }),
                onEdit: (text) {
                  final value = TimeEntry.clock(text);
                  setState(() {
                    _startReadable = value != null;
                    if (value != null) _startMin = value;
                  });
                },
                onSubmit: (text) {
                  final value = TimeEntry.clock(text);
                  // Unreadable text is put back to the last time that was read.
                  setState(() {
                    _startReadable = true;
                    if (value != null) _startMin = value;
                  });
                  return value != null;
                },
              ),
              ValueStepper(
                key: const ValueKey('block-end'),
                label: 'Ends',
                detail: readable
                    ? '${Format.estimate(_durationMin)} long'
                          '${_endMin > minutesInDay ? ', past midnight' : ''}'
                    : null,
                text: Format.clock(_endMin),
                keyboardType: TextInputType.datetime,
                error: !_endReadable,
                onStep: (direction) => setState(() {
                  _endReadable = true;
                  _durationMin = (_durationMin + direction * _step).clamp(
                    _step,
                    minutesInDay - _step,
                  );
                }),
                onEdit: (text) {
                  final end = TimeEntry.clock(text);
                  final length = end == null ? null : _lengthTo(end);
                  setState(() {
                    _endReadable = length != null;
                    if (length != null) _durationMin = length;
                  });
                },
                onSubmit: (text) {
                  final end = TimeEntry.clock(text);
                  final length = end == null ? null : _lengthTo(end);
                  setState(() {
                    _endReadable = true;
                    if (length != null) _durationMin = length;
                  });
                  return length != null;
                },
              ),
              if (!readable) ...[
                const SizedBox(height: AppSpace.sm),
                _Notice(
                  lines: [
                    _startReadable
                        ? "Couldn't use that end. Try 10:30, 1030 or 10.30pm, and a "
                              'time other than the start.'
                        : "Couldn't read that start. Try 9:30, 930 or 9.30pm.",
                  ],
                ),
              ] else if (problems.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                _Notice(
                  lines: [
                    for (final problem in problems) _describe(problem),
                    if (nearest == null)
                      'Nothing ${Format.estimate(_durationMin)} long is free on '
                          'those days. Try fewer days, or a shorter block.',
                  ],
                  action: nearest == null
                      ? null
                      : _Fix(
                          label: 'Move to ${Format.clock(nearest)}',
                          onTap: () => setState(() => _startMin = nearest),
                        ),
                ),
              ],
              if (widget.notInForce case final note?) ...[
                const SizedBox(height: AppSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColour.labelTertiary,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text(note, style: AppText.footnote)),
                  ],
                ),
              ],
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
                    label: widget.initial == null ? 'Add' : 'Save',
                    enabled: canSave,
                    onTap: () {
                      if (!canSave) return;
                      Navigator.pop(
                        context,
                        BlockDraft(
                          title: _title.text.trim(),
                          weekdays: {..._weekdays},
                          startMin: _startMin,
                          durationMin: _durationMin,
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

  static String _describe(BlockProblem problem) => switch (problem) {
    DuringSleep(:final weekdays) =>
      'Falls while you sleep ${Format.onDays(weekdays)}, and sleep is never counted as '
          'time to spend. If you are up then, change your sleep under Profile.',
    PastMidnight() =>
      'Runs past midnight. End it by 00:00, and add what comes after as a block of '
          'its own.',
    Clash(:final title, :final weekdays, :final startMin, :final endMin) =>
      'Overlaps $title, ${Format.weekdays(weekdays)} '
          '${Format.clockRange(startMin, endMin)}.',
  };
}

class _Preset extends StatelessWidget {
  const _Preset({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppLayout.touch ? AppSpace.sm : AppSpace.xs,
        ),
        child: Text(
          label,
          style: AppText.numeric.copyWith(color: AppColour.accent),
        ),
      ),
    ),
  );
}

/// What is in the way, said plainly, with the fix beside it.
class _Notice extends StatelessWidget {
  const _Notice({required this.lines, this.action});

  final List<String> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: AppColour.orange.withValues(alpha: 0.12),
      borderRadius: AppRadius.mediumAll,
      border: Border.all(color: AppColour.orange.withValues(alpha: 0.35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColour.orange),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, line) in lines.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpace.xs),
                Text(
                  line,
                  style: AppText.callout.copyWith(color: AppColour.label),
                ),
              ],
              if (action case final fix?) ...[
                const SizedBox(height: AppSpace.sm),
                fix,
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _Fix extends StatelessWidget {
  const _Fix({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: AppLayout.touch ? AppSize.touch - AppSpace.sm : AppSize.chip,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          color: AppColour.accent.withValues(alpha: 0.18),
          borderRadius: AppRadius.smallAll,
        ),
        // As wide as its label, not the notice: a button, not a banner.
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: AppText.headline.copyWith(color: AppColour.accent),
          ),
        ),
      ),
    ),
  );
}
