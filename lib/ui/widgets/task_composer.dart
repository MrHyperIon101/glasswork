import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/db/database.dart';
import '../../data/quick_add_parser.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../sheet.dart';
import '../surface.dart';
import 'field_controls.dart';

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
    if (!ref.watch(composerOpenProvider)) return const SizedBox.shrink();

    void close() => ref.read(composerOpenProvider.notifier).close();

    return ModalSheet(
      onClose: close,
      maxHeight: 700,
      child: _Form(onClose: close),
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
enum _Touched { due, priority, estimate, labels }

class _FormState extends ConsumerState<_Form> {
  final _title = TextEditingController();
  final _notes = TextEditingController();

  final _touched = <_Touched>{};

  String? _projectId;
  String? _sectionId;
  DateTime? _dueAt;
  DateTime? _dueDate;
  int _priority = 0;
  int? _estimateMin;
  final _labelNames = <String>{};
  final _fieldValues = <String, String?>{};
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
    super.dispose();
  }

  void _onTitleChanged() {
    final parsed = QuickAddParser.parse(_title.text, now: DateTime.now());

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
    });
  }

  DateTime? get _effectiveDueDay {
    if (_dueAt case final at?) return DateTime(at.year, at.month, at.day);
    return _dueDate;
  }

  String get _cleanTitle =>
      QuickAddParser.parse(_title.text, now: DateTime.now()).title;

  bool get _canSubmit => _cleanTitle.isNotEmpty && _sectionId != null;

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

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final scope = ref.read(appScopeProvider).value;
    final sectionId = _sectionId;
    if (scope == null || sectionId == null) return;

    widget.onClose();

    final created = await scope.tasks.create(
      listId: sectionId,
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
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? const <Board>[];

    // Default to wherever you are, falling back to the first project.
    final projectId =
        _projectId ??
        ref.watch(currentProjectIdProvider) ??
        projects.firstOrNull?.id;

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
            ),
          ),
          const AppDivider(),

          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xxl),
              children: [
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
                      'Return to add · Esc to cancel',
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
