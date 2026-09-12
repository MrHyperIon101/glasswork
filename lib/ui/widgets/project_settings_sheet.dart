import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/repository/project_repository.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../motion.dart';
import '../surface.dart';
import 'confirm_dialog.dart';
import 'field_controls.dart';

/// Everything about a project that is not a task.
///
/// Also the only place several things could be deleted from — sections, custom fields,
/// labels, the project itself. A repository method with no way to reach it is not a
/// feature, and this app had four of them.
class ProjectSettingsSheet extends ConsumerWidget {
  const ProjectSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(projectSettingsOpenProvider);
    if (projectId == null) return const SizedBox.shrink();

    void close() => ref.read(projectSettingsOpenProvider.notifier).close();

    return Stack(
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.quick,
            builder: (context, t, _) => GestureDetector(
              onTap: close,
              child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.62 * t)),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.05),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: SpringIn(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
                child: VibrancyMaterial.sheet(
                  child: _Body(projectId: projectId, onClose: close),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.projectId, required this.onClose});

  final String projectId;
  final VoidCallback onClose;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  TextEditingController? _name;
  TextEditingController? _purpose;

  @override
  void dispose() {
    _name?.dispose();
    _purpose?.dispose();
    super.dispose();
  }

  AppScope? get _scope => ref.read(appScopeProvider).value;

  @override
  Widget build(BuildContext context) {
    final project = (ref.watch(projectsProvider).value ?? const <Board>[])
        .where((p) => p.id == widget.projectId)
        .firstOrNull;

    if (project == null) {
      // Deleted from under us — nothing left to configure.
      return Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Text('This project is gone.', style: AppText.body),
      );
    }

    _name ??= TextEditingController(text: project.name);
    _purpose ??= TextEditingController(text: project.purpose ?? '');

    final sections =
        ref.watch(sectionsProvider(widget.projectId)).value ?? const [];
    final fields =
        ref.watch(fieldsProvider(widget.projectId)).value ?? const [];
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xxl,
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Project settings', style: AppText.title),
                ),
                _IconAction(icon: Icons.close, onTap: widget.onClose),
              ],
            ),
          ),
          const AppDivider(),

          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xxl),
              children: [
                FieldRow(
                  label: 'Name',
                  child: TextField(
                    controller: _name,
                    style: AppText.body,
                    cursorColor: AppColour.accent,
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _scope?.projects.updateProject(
                          project.id,
                          name: v.trim(),
                        );
                      }
                    },
                    decoration: _input('Sem V — DBMS'),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                FieldRow(
                  label: 'Purpose',
                  hint: 'One line, so it still makes sense in six weeks',
                  child: TextField(
                    controller: _purpose,
                    style: AppText.body,
                    cursorColor: AppColour.accent,
                    onChanged: (v) => _scope?.projects.updateProject(
                      project.id,
                      purpose: v.trim(),
                    ),
                    decoration: _input('What this project is for'),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                FieldRow(
                  label: 'Colour',
                  child: Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      for (final colour in _palette)
                        _Swatch(
                          colour: Color(colour),
                          selected: project.colour == colour,
                          onTap: () => _scope?.projects.updateProject(
                            project.id,
                            colour: colour,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.xxl),
                _Heading(
                  'Sections',
                  action: 'Add',
                  onAction: () => _scope?.projects.addSection(
                    workspaceId: project.workspaceId,
                    boardId: project.id,
                    name: 'New section',
                  ),
                ),
                for (final section in sections)
                  _SectionRow(
                    section: section,
                    canDelete: sections.length > 1,
                    onDelete: () => _deleteSection(section),
                  ),

                const SizedBox(height: AppSpace.xxl),
                _Heading(
                  'Fields',
                  action: 'Add',
                  onAction: () => _addField(project),
                ),
                if (fields.isEmpty)
                  Text(
                    'No custom fields. Add ones this project actually needs — '
                    'they belong to it alone.',
                    style: AppText.footnote,
                  ),
                for (final field in fields)
                  _FieldDefRow(
                    field: field,
                    onDelete: () => _deleteField(field),
                  ),

                const SizedBox(height: AppSpace.xxl),
                _Heading('Labels'),
                Text(
                  'Shared across every project, unlike fields.',
                  style: AppText.footnote.copyWith(
                    color: AppColour.labelQuaternary,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                if (labels.isEmpty)
                  Text(
                    'None yet. Typing #something while adding a task creates one.',
                    style: AppText.footnote,
                  ),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final label in labels)
                      _DeletableLabel(
                        label: label,
                        onDelete: () => _deleteLabel(label),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpace.xxl),
                _Heading('Removing this project'),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    GhostButton(
                      label: 'Archive',
                      onTap: () async {
                        widget.onClose();
                        await _scope?.projects.archiveProject(project.id);
                        _offerUndo(
                          'Archived "${project.name}"',
                          () => _scope!.projects.unarchiveProject(project.id),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpace.sm),
                    _DangerButton(
                      label: 'Delete project',
                      onTap: () => _deleteProject(project),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Archiving keeps everything and just removes it from the sidebar. '
                  'A finished term is worth keeping — it is the only record of what '
                  'it actually involved.',
                  style: AppText.footnote.copyWith(
                    color: AppColour.labelQuaternary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _palette = [
    0xFF0A84FF,
    0xFFBF5AF2,
    0xFF30D158,
    0xFFFF9F0A,
    0xFFFF453A,
    0xFFFFD60A,
    0xFF64D2FF,
    0xFF8E8E93,
  ];

  InputDecoration _input(String hint) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColour.fill,
    border: OutlineInputBorder(
      borderRadius: AppRadius.mediumAll,
      borderSide: BorderSide.none,
    ),
    hintText: hint,
    hintStyle: AppText.body.copyWith(color: AppColour.labelTertiary),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: AppSpace.md,
    ),
  );

  void _offerUndo(String label, Future<void> Function() revert) =>
      ref.read(undoProvider.notifier).offer(label, revert);

  Future<void> _deleteSection(BoardList section) async {
    final scope = _scope;
    if (scope == null) return;

    final count = await scope.projects.taskCountIn(section.id);
    if (!mounted) return;

    // Tasks move rather than vanish, and the copy says so — a confirmation that hides
    // what it is about to do is worse than none.
    final ok = await confirm(
      context,
      title: 'Delete "${section.name}"?',
      detail: count == 0
          ? 'It has no tasks in it.'
          : '$count ${count == 1 ? 'task moves' : 'tasks move'} to the first '
                'remaining section. Nothing is lost.',
      confirmLabel: 'Delete section',
    );
    if (!ok) return;

    final moved = await scope.projects.deleteSection(section.id);
    if (!moved) return;
    _offerUndo(
      'Deleted "${section.name}"',
      () => scope.projects.restoreSection(section.id),
    );
  }

  Future<void> _deleteField(FieldDef field) async {
    final scope = _scope;
    if (scope == null) return;

    final ok = await confirm(
      context,
      title: 'Delete the "${field.name}" field?',
      detail: 'Values already recorded against it stop being shown.',
      confirmLabel: 'Delete field',
    );
    if (!ok) return;

    await scope.projects.deleteField(field.id);
    _offerUndo(
      'Deleted "${field.name}"',
      () => scope.projects.restoreField(field.id),
    );
  }

  Future<void> _deleteLabel(Label label) async {
    final scope = _scope;
    if (scope == null) return;

    final ok = await confirm(
      context,
      title: 'Delete #${label.name}?',
      detail: 'It is removed from every task that carries it, in every project.',
      confirmLabel: 'Delete label',
    );
    if (!ok) return;

    await scope.labels.delete(label.id);
    _offerUndo(
      'Deleted #${label.name}',
      () => scope.labels.restore(label.id),
    );
  }

  Future<void> _deleteProject(Board project) async {
    final scope = _scope;
    if (scope == null) return;

    final count = await scope.projects.projectTaskCount(project.id);
    if (!mounted) return;

    final ok = await confirm(
      context,
      title: 'Delete "${project.name}"?',
      detail: count == 0
          ? 'It has no tasks. Its sections and fields go with it.'
          : 'Its $count ${count == 1 ? 'task' : 'tasks'} go with it, along with '
                'its sections and fields. Archive instead if you might want '
                'them later.',
      confirmLabel: 'Delete project',
    );
    if (!ok) return;

    widget.onClose();
    ref.read(destinationProvider.notifier).go(const TodayDestination());
    await scope.projects.deleteProject(project.id);
    _offerUndo(
      'Deleted "${project.name}"',
      () => scope.projects.restoreProject(project.id),
    );
  }

  Future<void> _addField(Board project) async {
    final result = await showDialog<_NewField>(
      context: context,
      builder: (context) => const _AddFieldDialog(),
    );
    if (result == null) return;

    await _scope?.projects.addField(
      workspaceId: project.workspaceId,
      boardId: project.id,
      name: result.name,
      type: result.type,
      options: result.options,
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label, {this.action, this.onAction});

  final String label;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.sm),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppText.caption)),
        if (action case final a?)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                a,
                style: AppText.numeric.copyWith(color: AppColour.accent),
              ),
            ),
          ),
      ],
    ),
  );
}

class _SectionRow extends ConsumerStatefulWidget {
  const _SectionRow({
    required this.section,
    required this.canDelete,
    required this.onDelete,
  });

  final BoardList section;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  ConsumerState<_SectionRow> createState() => _SectionRowState();
}

class _SectionRowState extends ConsumerState<_SectionRow> {
  late final TextEditingController _name = TextEditingController(
    text: widget.section.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(appScopeProvider).value;
    final limit = widget.section.wipLimit;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              style: AppText.body,
              cursorColor: AppColour.accent,
              onChanged: (v) {
                if (v.trim().isNotEmpty) {
                  scope?.projects.renameSection(widget.section.id, v.trim());
                }
              },
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpace.sm),
              ),
            ),
          ),
          // WIP limits are the board's honest bit: a column over its limit tells you to
          // stop starting things.
          Text('limit', style: AppText.numeric),
          const SizedBox(width: AppSpace.sm),
          _Stepper(
            value: limit == null ? '—' : '$limit',
            onChange: (d) {
              final next = (limit ?? 0) + d;
              scope?.projects.setSectionWipLimit(
                widget.section.id,
                next <= 0 ? null : next,
              );
            },
          ),
          const SizedBox(width: AppSpace.sm),
          if (widget.canDelete)
            _IconAction(
              icon: Icons.delete_outline,
              tint: AppColour.red,
              onTap: widget.onDelete,
            )
          else
            // The last section cannot go: its tasks would have nowhere to live.
            Tooltip(
              message: 'A project needs at least one section',
              child: Icon(
                Icons.delete_outline,
                size: 16,
                color: AppColour.labelQuaternary,
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldDefRow extends StatelessWidget {
  const _FieldDefRow({required this.field, required this.onDelete});

  final FieldDef field;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xs),
    child: Row(
      children: [
        Expanded(child: Text(field.name, style: AppText.body)),
        Text(field.type.name, style: AppText.numeric),
        const SizedBox(width: AppSpace.md),
        _IconAction(
          icon: Icons.delete_outline,
          tint: AppColour.red,
          onTap: onDelete,
        ),
      ],
    ),
  );
}

class _DeletableLabel extends StatefulWidget {
  const _DeletableLabel({required this.label, required this.onDelete});

  final Label label;
  final VoidCallback onDelete;

  @override
  State<_DeletableLabel> createState() => _DeletableLabelState();
}

class _DeletableLabelState extends State<_DeletableLabel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tint = widget.label.colour == null
        ? AppColour.grey
        : Color(widget.label.colour!);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.16),
          borderRadius: AppRadius.smallAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${widget.label.name}',
              style: AppText.numeric.copyWith(color: tint),
            ),
            AnimatedSize(
              duration: AppMotion.quick,
              child: _hovered
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppSpace.sm),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onDelete,
                          child: const Icon(
                            Icons.close,
                            size: 13,
                            color: AppColour.red,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChange});

  final String value;
  final void Function(int delta) onChange;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _IconAction(icon: Icons.remove, onTap: () => onChange(-1)),
      SizedBox(
        width: 26,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: AppText.numeric.copyWith(color: AppColour.label),
        ),
      ),
      _IconAction(icon: Icons.add, onTap: () => onChange(1)),
    ],
  );
}

class _IconAction extends StatefulWidget {
  const _IconAction({required this.icon, required this.onTap, this.tint});

  final IconData icon;
  final VoidCallback onTap;
  final Color? tint;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
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
        padding: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: _hovered ? AppColour.fill : null,
          borderRadius: AppRadius.smallAll,
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: widget.tint ?? AppColour.labelSecondary,
        ),
      ),
    ),
  );
}

class _DangerButton extends StatefulWidget {
  const _DangerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<_DangerButton> {
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
          color: _hovered
              ? AppColour.red.withValues(alpha: 0.18)
              : AppColour.red.withValues(alpha: 0.1),
          borderRadius: AppRadius.mediumAll,
        ),
        child: Text(
          widget.label,
          style: AppText.callout.copyWith(color: AppColour.red),
        ),
      ),
    ),
  );
}

// --- adding a field -------------------------------------------------------

class _NewField {
  const _NewField({
    required this.name,
    required this.type,
    this.options = const [],
  });

  final String name;
  final FieldType type;
  final List<FieldOption> options;
}

class _AddFieldDialog extends StatefulWidget {
  const _AddFieldDialog();

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _name = TextEditingController();
  final _choices = TextEditingController();
  FieldType _type = FieldType.text;

  @override
  void dispose() {
    _name.dispose();
    _choices.dispose();
    super.dispose();
  }

  bool get _needsChoices =>
      _type == FieldType.select || _type == FieldType.multiSelect;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New field', style: AppText.title3),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _name,
                autofocus: true,
                style: AppText.body,
                cursorColor: AppColour.accent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColour.fill,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mediumAll,
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Area, Worth %, Figma link…',
                  hintStyle: AppText.body.copyWith(
                    color: AppColour.labelTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text('Holds', style: AppText.caption),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final type in FieldType.values)
                    ComposerChip(
                      label: _typeLabel(type),
                      selected: _type == type,
                      onTap: () => setState(() => _type = type),
                    ),
                ],
              ),
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: _needsChoices
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpace.lg),
                        child: TextField(
                          controller: _choices,
                          style: AppText.body,
                          cursorColor: AppColour.accent,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColour.fill,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mediumAll,
                              borderSide: BorderSide.none,
                            ),
                            labelText: 'Choices, comma separated',
                            labelStyle: AppText.footnote,
                            hintText: 'Frontend, Backend, Infra',
                            hintStyle: AppText.body.copyWith(
                              color: AppColour.labelTertiary,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
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
                    label: 'Add field',
                    enabled:
                        _name.text.trim().isNotEmpty &&
                        (!_needsChoices || _parsedChoices.isNotEmpty),
                    onTap: () => Navigator.pop(
                      context,
                      _NewField(
                        name: _name.text.trim(),
                        type: _type,
                        options: _parsedChoices,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FieldOption> get _parsedChoices => [
    for (final part in _choices.text.split(','))
      if (part.trim().isNotEmpty) FieldOption(label: part.trim()),
  ];

  static String _typeLabel(FieldType t) => switch (t) {
    FieldType.text => 'Text',
    FieldType.number => 'Number',
    FieldType.select => 'One choice',
    FieldType.multiSelect => 'Several choices',
    FieldType.date => 'Date',
    FieldType.checkbox => 'Yes / no',
    FieldType.url => 'Link',
  };
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: colour,
          borderRadius: AppRadius.smallAll,
          border: Border.all(
            color: selected ? AppColour.label : const Color(0x00000000),
            width: 2,
          ),
        ),
      ),
    ),
  );
}
