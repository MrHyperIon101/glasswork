import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/db/database.dart';
import '../../data/preferences.dart';
import '../../data/quick_add_parser.dart';
import '../../state/providers.dart';
import '../../state/reminders_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../motion.dart';
import '../sheet.dart';
import '../surface.dart';
import 'field_controls.dart';
import 'reminder_picker.dart';

/// The task creation flow.
///
/// Typing is still fast — the title field parses dates, priorities, labels, estimates and
/// reminders as you go — but what it understood lands in **visible controls** rather than
/// being applied invisibly. You can see every field it filled in and change any of them,
/// which is the difference between a parser you trust and one you fight.
///
/// Fields you set by hand are never overwritten by a later parse.
///
/// Several tasks can be added at once as well: a typed or pasted list becomes one task a
/// line, each line read the way a single title is.
class TaskComposer extends ConsumerWidget {
  const TaskComposer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() => ref.read(composerOpenProvider.notifier).close();

    return SheetPresence(
      open: ref.watch(composerOpenProvider),
      builder: (context) => ModalSheet(
        onClose: close,
        maxHeight: 700,
        child: _Form(onClose: close),
      ),
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
enum _Touched { due, priority, estimate, labels, reminder }

class _FormState extends ConsumerState<_Form> {
  final _title = TextEditingController();
  final _notes = TextEditingController();

  /// The list, when adding several.
  final _list = TextEditingController();

  final _touched = <_Touched>{};

  String? _projectId;
  String? _sectionId;
  DateTime? _dueAt;
  DateTime? _dueDate;
  DateTime? _remindAt;
  int _priority = 0;
  int? _estimateMin;
  final _labelNames = <String>{};
  final _fieldValues = <String, String?>{};
  bool _notesOpen = false;

  /// Adding a list, one task a line, rather than a single task.
  bool _several = false;

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
    _list.dispose();
    super.dispose();
  }

  /// When a reminder that names a day but no time is: the morning Settings has.
  int get _morningMin =>
      (ref.read(preferencesProvider).value ?? const Preferences()).morningMin;

  void _onTitleChanged() {
    final parsed = QuickAddParser.parse(
      _title.text,
      now: DateTime.now(),
      morningMin: _morningMin,
    );

    setState(() {
      _spans = parsed.spans;

      if (!_touched.contains(_Touched.due)) {
        _dueAt = parsed.dueAt;
        _dueDate = _isoToDate(parsed.dueDate);
      }
      if (!_touched.contains(_Touched.priority) && parsed.priority != 0) {
        _priority = parsed.priority;
      }
      if (!_touched.contains(_Touched.estimate) && parsed.estimateMin != null) {
        _estimateMin = parsed.estimateMin;
      }
      if (!_touched.contains(_Touched.labels) && parsed.labels.isNotEmpty) {
        _labelNames
          ..clear()
          ..addAll(parsed.labels);
      }
      if (!_touched.contains(_Touched.reminder)) {
        _remindAt = parsed.remindAt;
      }
    });
  }

  DateTime? get _effectiveDueDay {
    if (_dueAt case final at?) return DateTime(at.year, at.month, at.day);
    return _dueDate;
  }

  String get _cleanTitle => QuickAddParser.parse(
    _title.text,
    now: DateTime.now(),
    morningMin: _morningMin,
  ).title;

  bool get _canSubmit => _cleanTitle.isNotEmpty && _sectionId != null;

  /// The tasks in the list, one a line.
  List<String> get _lines => QuickAddParser.splitLines(_list.text);

  bool get _canSubmitSeveral => _lines.isNotEmpty && _sectionId != null;

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

  Future<void> _submit() => _several ? _submitSeveral() : _submitOne();

  Future<void> _submitOne() async {
    if (!_canSubmit) return;

    final scope = ref.read(appScopeProvider).value;
    final sectionId = _sectionId;
    if (scope == null || sectionId == null) return;
    // Taken before closing: a closed composer can no longer reach its providers.
    final container = ProviderScope.containerOf(context, listen: false);

    widget.onClose();

    final created = await scope.tasks.create(
      listId: sectionId,
      workspaceId: scope.workspace.id,
      title: _cleanTitle,
      dueAt: _dueAt,
      dueDate: _dueAt == null ? _isoOf(_dueDate) : null,
      priority: _priority,
      estimateMin: _estimateMin,
      remindAt: _remindAt,
    );

    if (_notes.text.trim().isNotEmpty) {
      await scope.tasks.setNotes(created.id, _notes.text.trim());
    }

    // Labels are created on demand: typing #uni should not require the label to exist.
    for (final name in _labelNames) {
      final label = await scope.labels.ensure(
        workspaceId: scope.workspace.id,
        name: name,
      );
      await scope.labels.attach(
        workspaceId: scope.workspace.id,
        taskId: created.id,
        labelId: label.id,
      );
    }

    for (final entry in _fieldValues.entries) {
      if (entry.value == null) continue;
      await scope.projects.setFieldValue(
        workspaceId: scope.workspace.id,
        taskId: created.id,
        fieldId: entry.key,
        value: entry.value,
      );
    }

    if (_remindAt != null) await _askToNotify(container);
  }

  /// Adds every line of the list, in order, each read for its own dates, priority,
  /// estimate, labels and reminder.
  Future<void> _submitSeveral() async {
    final lines = _lines;
    final scope = ref.read(appScopeProvider).value;
    final sectionId = _sectionId;
    if (lines.isEmpty || scope == null || sectionId == null) return;
    final container = ProviderScope.containerOf(context, listen: false);

    widget.onClose();

    var reminded = false;
    for (final line in lines) {
      final parsed = QuickAddParser.parse(
        line,
        now: DateTime.now(),
        morningMin: _morningMin,
      );
      if (parsed.title.isEmpty) continue;

      final created = await scope.tasks.create(
        listId: sectionId,
        workspaceId: scope.workspace.id,
        title: parsed.title,
        dueAt: parsed.dueAt,
        dueDate: parsed.dueDate,
        priority: parsed.priority,
        estimateMin: parsed.estimateMin,
        remindAt: parsed.remindAt,
      );
      reminded |= parsed.remindAt != null;

      for (final name in parsed.labels) {
        final label = await scope.labels.ensure(
          workspaceId: scope.workspace.id,
          name: name,
        );
        await scope.labels.attach(
          workspaceId: scope.workspace.id,
          taskId: created.id,
          labelId: label.id,
        );
      }
    }

    if (reminded) await _askToNotify(container);
  }

  /// Asks to show notifications the first time a reminder is set, which is when the
  /// question makes sense, rather than at launch.
  static Future<void> _askToNotify(ProviderContainer container) async {
    await container.read(reminderServiceProvider).requestPermission();
    container.invalidate(reminderPermissionProvider);
  }

  void _toggleSeveral() => setState(() {
    // A title already typed becomes the list's first line, rather than being lost.
    if (!_several &&
        _list.text.trim().isEmpty &&
        _title.text.trim().isNotEmpty) {
      _list.text = '${_title.text.trim()}\n';
      _list.selection = TextSelection.collapsed(offset: _list.text.length);
    }
    _several = !_several;
  });

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? const <Board>[];

    // Default to wherever you are, or else the project Settings names, or else the first.
    final projectId = _projectId ?? ref.watch(captureProjectIdProvider);

    final sections = projectId == null
        ? const <BoardList>[]
        : ref.watch(sectionsProvider(projectId)).value ?? const <BoardList>[];

    // Resolve the section once sections for the chosen project arrive.
    if (_sectionId == null && sections.isNotEmpty) {
      _sectionId = sections.first.id;
    } else if (_sectionId != null &&
        sections.isNotEmpty &&
        !sections.any((s) => s.id == _sectionId)) {
      // Project changed under us; the old section belongs to a different board.
      _sectionId = sections.first.id;
    }

    final fields = projectId == null
        ? const <FieldDef>[]
        : ref.watch(fieldsProvider(projectId)).value ?? const <FieldDef>[];

    // Where the new task or tasks go.
    final destination = <Widget>[
      if (projects.length > 1) ...[
        FieldRow(
          label: 'Project',
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final p in projects)
                ComposerChip(
                  label: '${p.icon ?? '○'}  ${p.name}',
                  selected: p.id == projectId,
                  tint: p.colour == null ? null : Color(p.colour!),
                  onTap: () => setState(() {
                    _projectId = p.id;
                    // Section belongs to the old project; clear so the
                    // resolver above picks the new project's first.
                    _sectionId = null;
                    _fieldValues.clear();
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
      ],

      if (sections.length > 1) ...[
        FieldRow(
          label: 'Section',
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final s in sections)
                ComposerChip(
                  label: s.name,
                  selected: s.id == _sectionId,
                  onTap: () => setState(() => _sectionId = s.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
      ],
    ];

    final preview = _several ? null : _preview;
    final lineCount = _several ? _lines.length : 0;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xxl,
              AppSpace.xl,
              AppSpace.xxl,
              AppSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_several)
                  TextField(
                    key: const ValueKey('composer-list'),
                    controller: _list,
                    autofocus: true,
                    style: AppText.body,
                    cursorColor: AppColour.accent,
                    cursorWidth: 1.5,
                    minLines: 4,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'One task a line. Type them, or paste a list.',
                      hintStyle: AppText.body.copyWith(
                        color: AppColour.labelTertiary,
                      ),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _title,
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
                      '${_spans.map((s) => s.label).join('  ·  ')}',
                      style: AppText.footnote.copyWith(
                        color: AppColour.labelTertiary,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpace.xs),
                _TextAction(
                  label: _several
                      ? 'Add one task instead'
                      : 'Add several at once',
                  onTap: _toggleSeveral,
                ),
              ],
            ),
          ),
          const AppDivider(),

          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xxl),
              children: [
                if (_several) ...[
                  FieldRow(
                    label: 'Tasks',
                    hint:
                        'Each line reads its own dates, !priority, ~estimate, #labels and '
                        '"remind tomorrow 9am", the same as a single task does.',
                    child: _ListPreview(lines: _lines, morningMin: _morningMin),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  ...destination,
                ] else ...[
                  ...destination,
                  FieldRow(
                    label: 'Due',
                    child: DueChips(
                      dueAt: _dueAt,
                      dueDate: _dueDate,
                      onChanged: (at, date) => setState(() {
                        _touched.add(_Touched.due);
                        _dueAt = at;
                        _dueDate = date;
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  FieldRow(
                    label: 'Remind me',
                    child: ReminderPicker(
                      remindAt: _remindAt,
                      dueAt: _dueAt,
                      dueDate: _dueDate,
                      permitted:
                          ref.watch(reminderPermissionProvider).value ?? true,
                      onChanged: (at) => setState(() {
                        _touched.add(_Touched.reminder);
                        _remindAt = at;
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  FieldRow(
                    label: 'Priority',
                    child: PriorityChips(
                      value: _priority,
                      onChanged: (p) => setState(() {
                        _touched.add(_Touched.priority);
                        _priority = p;
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  FieldRow(
                    label: 'Estimate',
                    hint: _estimateMin == null
                        ? 'Without one the planner assumes '
                              '${Format.estimate(CapacityScheduler.assumedEstimateMin)}'
                        : null,
                    child: EstimateChips(
                      value: _estimateMin,
                      onChanged: (m) => setState(() {
                        _touched.add(_Touched.estimate);
                        _estimateMin = m;
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  FieldRow(
                    label: 'Labels',
                    child: LabelPicker(
                      selectedNames: _labelNames,
                      onToggle: (name) => setState(() {
                        _touched.add(_Touched.labels);
                        _labelNames.contains(name)
                            ? _labelNames.remove(name)
                            : _labelNames.add(name);
                      }),
                    ),
                  ),

                  // The project's own vocabulary, if it has any.
                  for (final field in fields) ...[
                    const SizedBox(height: AppSpace.lg),
                    FieldRow(
                      label: field.name,
                      child: CustomFieldControl(
                        field: field,
                        value: _fieldValues[field.id],
                        onChanged: (v) =>
                            setState(() => _fieldValues[field.id] = v),
                      ),
                    ),
                  ],

                  AnimatedSize(
                    duration: AppMotion.medium,
                    curve: AppMotion.standard,
                    alignment: Alignment.topCenter,
                    child: _notesOpen
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpace.lg),
                            child: FieldRow(
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
                            child: GhostButton(
                              label: '+ Add notes',
                              onTap: () => setState(() => _notesOpen = true),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),

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
                // Keys a phone does not have, and room its buttons need.
                if (AppLayout.touch)
                  const Spacer()
                else
                  Expanded(
                    child: Text(
                      _several
                          ? 'Ctrl+Return to add them · Esc to cancel'
                          : 'Return to add · Esc to cancel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.numeric.copyWith(
                        color: AppColour.labelQuaternary,
                      ),
                    ),
                  ),
                GhostButton(label: 'Cancel', onTap: widget.onClose),
                const SizedBox(width: AppSpace.sm),
                PrimaryButton(
                  label: !_several
                      ? 'Add task'
                      : switch (lineCount) {
                          0 => 'Add tasks',
                          1 => 'Add 1 task',
                          _ => 'Add $lineCount tasks',
                        },
                  enabled: _several ? _canSubmitSeveral : _canSubmit,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

/// What each line of a list will become, before any of it is added.
class _ListPreview extends StatelessWidget {
  const _ListPreview({required this.lines, required this.morningMin});

  final List<String> lines;
  final int morningMin;

  /// Lines shown before the rest are counted instead.
  static const _shown = 8;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Text(
        'Nothing yet. Each line you type or paste above becomes a task.',
        style: AppText.footnote,
      );
    }

    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines.take(_shown))
          Builder(
            builder: (context) {
              final parsed = QuickAddParser.parse(
                line,
                now: now,
                morningMin: morningMin,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpace.xs),
                      child: Icon(
                        Icons.radio_button_unchecked_rounded,
                        size: 13,
                        color: AppColour.labelTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parsed.title.isEmpty ? line : parsed.title,
                            style: AppText.callout.copyWith(
                              color: AppColour.label,
                            ),
                          ),
                          if (parsed.spans.isNotEmpty)
                            Text(
                              parsed.spans.map((s) => s.label).join('  ·  '),
                              style: AppText.footnote.copyWith(
                                color: AppColour.labelTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (lines.length > _shown)
          Text('and ${lines.length - _shown} more', style: AppText.footnote),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

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
          vertical: AppLayout.touch ? AppSpace.sm : AppSpace.xs,
        ),
        child: Text(
          label,
          style: AppText.footnote.copyWith(color: AppColour.accent),
        ),
      ),
    ),
  );
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
        : 'it finishes on the day it is due, with nothing spare';

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
              impossible ? "This won't fit — $detail." : 'Tight — $detail.',
              style: AppText.callout.copyWith(color: AppColour.label),
            ),
          ),
        ],
      ),
    );
  }
}
