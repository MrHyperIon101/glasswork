import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/db/database.dart';
import '../../data/quick_add_parser.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../motion.dart';
import '../surface.dart';

/// The task creation flow.
///
/// Typing is still fast — the title field parses dates, priorities, labels and estimates
/// as you go — but what it understood lands in **visible controls** rather than being
/// applied invisibly. You can see every field it filled in and change any of them, which
/// is the difference between a parser you trust and one you fight.
///
/// Fields you set by hand are never overwritten by a later parse.
class TaskComposer extends ConsumerWidget {
  const TaskComposer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(composerOpenProvider);
    if (!open) return const SizedBox.shrink();

    void close() => ref.read(composerOpenProvider.notifier).close();

    return Stack(
      children: [
        // Scrim fades in on its own so the panel's spring is not muddied by it.
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.quick,
            builder: (context, t, _) => GestureDetector(
              onTap: close,
              child: ColoredBox(
                color: Color.fromRGBO(0, 0, 0, 0.62 * t),
              ),
            ),
          ),
        ),
        Align(
          // Slightly above centre: the panel grows downward as fields appear, and
          // dead-centring would make it drift as it does.
          alignment: const Alignment(0, -0.25),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: SpringIn(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: VibrancyMaterial.sheet(child: _Form(onClose: close)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

/// Which fields the user has set by hand, so a later parse does not clobber them.
enum _Field { list, due, priority, estimate }

class _FormState extends ConsumerState<_Form> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _titleFocus = FocusNode();

  final _touched = <_Field>{};

  String? _listId;
  DateTime? _dueAt;
  DateTime? _dueDate;
  int _priority = 0;
  int? _estimateMin;
  bool _notesOpen = false;

  List<ParseSpan> _spans = const [];

  @override
  void initState() {
    super.initState();
    _title.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// Re-parses and seeds any field the user has not taken over.
  void _onTitleChanged() {
    final parsed = QuickAddParser.parse(_title.text, now: DateTime.now());

    setState(() {
      _spans = parsed.spans;

      if (!_touched.contains(_Field.due)) {
        _dueAt = parsed.dueAt;
        _dueDate = _isoToDate(parsed.dueDate);
      }
      if (!_touched.contains(_Field.priority) && parsed.priority != 0) {
        _priority = parsed.priority;
      }
      if (!_touched.contains(_Field.estimate) && parsed.estimateMin != null) {
        _estimateMin = parsed.estimateMin;
      }
    });
  }

  DateTime? get _effectiveDueDay {
    if (_dueAt case final at?) return DateTime(at.year, at.month, at.day);
    return _dueDate;
  }

  /// What the arithmetic makes of this task, live, before it exists.
  ScheduledTask? get _preview {
    final due = _effectiveDueDay;
    if (due == null) return null;
    return previewFeasibility(
      ref,
      PlannedTask(
        id: '__composing__',
        title: _cleanTitle,
        dueDay: due,
        estimateMin: _estimateMin ?? CapacityScheduler.assumedEstimateMin,
        priority: _priority,
        estimateAssumed: _estimateMin == null,
      ),
    );
  }

  String get _cleanTitle =>
      QuickAddParser.parse(_title.text, now: DateTime.now()).title;

  bool get _canSubmit => _cleanTitle.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final scope = ref.read(appScopeProvider).value;
    final listId = _listId ?? ref.read(captureListIdProvider);
    if (scope == null || listId == null) return;

    widget.onClose();

    final created = await scope.tasks.create(
      listId: listId,
      workspaceId: scope.workspace.id,
      title: _cleanTitle,
      dueAt: _dueAt,
      dueDate: _dueAt == null ? _isoOf(_dueDate) : null,
      priority: _priority,
      estimateMin: _estimateMin,
    );

    if (_notes.text.trim().isNotEmpty) {
      await scope.tasks.setNotes(created.id, _notes.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(listsProvider).value ?? const <BoardList>[];
    final fallbackListId = ref.watch(captureListIdProvider);
    final selectedList = _listId ?? fallbackListId;
    final preview = _preview;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- title ---
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xxl,
              AppSpace.xl,
              AppSpace.xxl,
              AppSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _title,
                  focusNode: _titleFocus,
                  autofocus: true,
                  style: AppText.title3,
                  cursorColor: AppColour.accent,
                  cursorWidth: 1.5,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'What needs doing?',
                    hintStyle: AppText.title3.copyWith(
                      color: AppColour.labelTertiary,
                    ),
                  ),
                ),
                if (_spans.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Read from what you typed: '
                    '${_spans.map((s) => s.label).join(' · ')}',
                    style: AppText.footnote.copyWith(
                      color: AppColour.labelTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const AppDivider(),

          // --- fields ---
          Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lists.length > 1) ...[
                  _FieldRow(
                    label: 'List',
                    child: Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final list in lists)
                          ComposerChip(
                            label: list.name,
                            selected: list.id == selectedList,
                            onTap: () => setState(() {
                              _listId = list.id;
                              _touched.add(_Field.list);
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],

                _FieldRow(label: 'Due', child: _dueControls()),
                const SizedBox(height: AppSpace.lg),

                _FieldRow(
                  label: 'Priority',
                  child: Wrap(
                    spacing: AppSpace.sm,
                    children: [
                      for (final (value, label) in const [
                        (0, 'None'),
                        (1, 'Low'),
                        (2, 'Medium'),
                        (3, 'High'),
                      ])
                        ComposerChip(
                          label: label,
                          selected: _priority == value,
                          tint: switch (value) {
                            3 => AppColour.red,
                            2 => AppColour.orange,
                            1 => AppColour.grey,
                            _ => null,
                          },
                          onTap: () => setState(() {
                            _priority = value;
                            _touched.add(_Field.priority);
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),

                _FieldRow(
                  label: 'Estimate',
                  hint: _estimateMin == null
                      ? 'Without one the planner assumes '
                            '${Format.estimate(CapacityScheduler.assumedEstimateMin)}'
                      : null,
                  child: Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      for (final mins in const [15, 30, 60, 120, 240])
                        ComposerChip(
                          label: Format.estimate(mins),
                          selected: _estimateMin == mins,
                          onTap: () => setState(() {
                            _estimateMin = _estimateMin == mins ? null : mins;
                            _touched.add(_Field.estimate);
                          }),
                        ),
                    ],
                  ),
                ),

                // Notes stay folded away: most tasks do not need them, and an empty
                // textarea makes every capture feel like paperwork.
                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.standard,
                  alignment: Alignment.topCenter,
                  child: _notesOpen
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpace.lg),
                          child: _FieldRow(
                            label: 'Notes',
                            child: TextField(
                              controller: _notes,
                              style: AppText.body,
                              maxLines: null,
                              minLines: 2,
                              cursorColor: AppColour.accent,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColour.fill,
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.mediumAll,
                                  borderSide: BorderSide.none,
                                ),
                                hintText: 'Anything worth remembering',
                                hintStyle: AppText.callout.copyWith(
                                  color: AppColour.labelTertiary,
                                ),
                                contentPadding: const EdgeInsets.all(
                                  AppSpace.md,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpace.md),
                          child: _TextAction(
                            label: '+ Add notes',
                            onTap: () => setState(() => _notesOpen = true),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // --- live feasibility ---
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: preview == null || preview.state == Feasibility.fine
                ? const SizedBox(width: double.infinity)
                : _FeasibilityNote(plan: preview),
          ),

          const AppDivider(),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                Text(
                  'Return to add · Esc to cancel',
                  style: AppText.numeric.copyWith(
                    color: AppColour.labelQuaternary,
                  ),
                ),
                const Spacer(),
                _TextAction(label: 'Cancel', onTap: widget.onClose),
                const SizedBox(width: AppSpace.sm),
                _PrimaryAction(
                  label: 'Add task',
                  enabled: _canSubmit,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueControls() {
    final today = DateTime.now();
    final due = _effectiveDueDay;

    void set(DateTime? d, {DateTime? at}) => setState(() {
      _touched.add(_Field.due);
      _dueAt = at;
      _dueDate = at == null ? d : null;
    });

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        ComposerChip(
          label: 'Today',
          selected: due != null && _sameDay(due, today),
          onTap: () => set(_dayOf(today)),
        ),
        ComposerChip(
          label: 'Tomorrow',
          selected:
              due != null &&
              _sameDay(due, today.add(const Duration(days: 1))),
          onTap: () => set(_dayOf(today.add(const Duration(days: 1)))),
        ),
        ComposerChip(
          label: 'Next week',
          selected:
              due != null &&
              _sameDay(due, today.add(const Duration(days: 7))),
          onTap: () => set(_dayOf(today.add(const Duration(days: 7)))),
        ),
        ComposerChip(
          label: due == null
              ? 'Pick…'
              : _dueAt != null
              ? '${Format.shortDate(_dueAt!)} '
                    '${_dueAt!.hour.toString().padLeft(2, '0')}:'
                    '${_dueAt!.minute.toString().padLeft(2, '0')}'
              : Format.shortDate(due),
          selected: due != null && !_isQuickPick(due, today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: due ?? today,
              firstDate: DateTime(today.year - 1),
              lastDate: DateTime(today.year + 5),
            );
            if (picked != null) set(_dayOf(picked));
          },
        ),
        if (due != null)
          ComposerChip(
            label: 'Clear',
            tint: AppColour.labelTertiary,
            selected: false,
            onTap: () => set(null),
          ),
      ],
    );
  }

  static bool _isQuickPick(DateTime due, DateTime today) =>
      _sameDay(due, today) ||
      _sameDay(due, today.add(const Duration(days: 1))) ||
      _sameDay(due, today.add(const Duration(days: 7)));

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String? _isoOf(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _isoToDate(String? iso) {
    if (iso == null) return null;
    final p = iso.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    return (y == null || m == null || d == null) ? null : DateTime(y, m, d);
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child, this.hint});

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 78,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(label, style: AppText.caption),
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

/// Selectable pill. Shared with the detail sheet's controls.
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

/// Live push-back while composing, rather than a report afterwards.
class _FeasibilityNote extends StatelessWidget {
  const _FeasibilityNote({required this.plan});

  final ScheduledTask plan;

  @override
  Widget build(BuildContext context) {
    final impossible = plan.state == Feasibility.impossible;
    final tint = impossible ? AppColour.red : AppColour.orange;

    final detail = impossible
        ? (plan.shortfallMin > 0
              ? '${Format.estimate(plan.shortfallMin)} more than you have before then'
              : '${-plan.slackDays} '
                    '${-plan.slackDays == 1 ? 'day' : 'days'} past the deadline')
        : 'It finishes on the day it is due, with nothing spare';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xxl,
        vertical: AppSpace.md,
      ),
      color: tint.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: tint),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              impossible
                  ? "This won't fit — $detail."
                  : 'Tight — $detail.',
              style: AppText.callout.copyWith(color: AppColour.label),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatefulWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_TextAction> createState() => _TextActionState();
}

class _TextActionState extends State<_TextAction> {
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

class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: !enabled
                ? AppColour.fill
                : _hovered
                ? AppColour.accent
                : AppColour.accent.withValues(alpha: 0.9),
            borderRadius: AppRadius.mediumAll,
          ),
          child: Text(
            widget.label,
            style: AppText.headline.copyWith(
              color: enabled ? Colors.white : AppColour.labelQuaternary,
            ),
          ),
        ),
      ),
    );
  }
}
