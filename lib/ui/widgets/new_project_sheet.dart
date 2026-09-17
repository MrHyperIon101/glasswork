import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/project_templates.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';
import '../sheet.dart';
import 'project_icon_picker.dart';
import '../surface.dart';

/// Creating a project, starting from what kind of work it is.
///
/// Picking a shape first is the whole point: a project that arrives with the right
/// sections and the right fields is usable immediately, where an empty one is a
/// configuration chore you do badly and then live with.
class NewProjectSheet extends ConsumerWidget {
  const NewProjectSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() => ref.read(newProjectOpenProvider.notifier).close();

    return SheetPresence(
      open: ref.watch(newProjectOpenProvider),
      builder: (context) => ModalSheet(
        onClose: close,
        maxWidth: 660,
        maxHeight: 660,
        alignment: const Alignment(0, -0.2),
        child: _Body(onClose: close),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _name = TextEditingController();
  final _purpose = TextEditingController();
  ProjectTemplate _template = ProjectTemplate.all.first;
  bool _nameTouched = false;

  /// An icon chosen here, which outlasts changing the template.
  String? _icon;

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    super.dispose();
  }

  void _pick(ProjectTemplate template) {
    setState(() {
      _template = template;
      // Seed the purpose from the template until you write your own.
      if (!_nameTouched && template.suggestedPurpose != null) {
        _purpose.text = template.suggestedPurpose!;
      }
    });
  }

  Future<void> _create() async {
    final scope = ref.read(appScopeProvider).value;
    final name = _name.text.trim();
    if (scope == null || name.isEmpty) return;

    widget.onClose();

    final project = await scope.projects.createProject(
      workspaceId: scope.workspace.id,
      name: name,
      purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
      icon: _icon ?? _template.icon,
      colour: _template.colour,
      sections: _template.sections,
      fields: _template.fields,
    );

    ref.read(destinationProvider.notifier).go(ProjectDestination(project.id));
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _create,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _create,
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
              AppSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New project', style: AppText.title),
                const SizedBox(height: 2),
                Text(
                  'Pick the kind of work. You can change everything afterwards.',
                  style: AppText.callout,
                ),
              ],
            ),
          ),
          const AppDivider(),

          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xxl),
              children: [
                Text('Shape', style: AppText.caption),
                const SizedBox(height: AppSpace.sm),
                for (final template in ProjectTemplate.all)
                  _TemplateRow(
                    template: template,
                    selected: template.id == _template.id,
                    onTap: () => _pick(template),
                  ),

                const SizedBox(height: AppSpace.xl),
                Text('Name', style: AppText.caption),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    ProjectIconButton(
                      icon: _icon ?? _template.icon,
                      colour: Color(_template.colour),
                      onChosen: (icon) => setState(() => _icon = icon),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        autofocus: true,
                        style: AppText.body,
                        cursorColor: AppColour.accent,
                        onChanged: (_) => setState(() => _nameTouched = true),
                        onSubmitted: (_) => _create(),
                        decoration: _fieldDecoration('Sem V — DBMS'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpace.lg),
                Text('What it is for', style: AppText.caption),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  controller: _purpose,
                  style: AppText.body,
                  cursorColor: AppColour.accent,
                  onSubmitted: (_) => _create(),
                  decoration: _fieldDecoration(
                    'One line, so it still makes sense in six weeks',
                  ),
                ),

                const SizedBox(height: AppSpace.xl),
                _Preview(template: _template),
              ],
            ),
          ),

          const AppDivider(),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                // A key a phone does not have, and room its buttons need.
                if (AppLayout.touch)
                  const Spacer()
                else
                  Expanded(
                    child: Text(
                      'Esc to cancel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.numeric.copyWith(
                        color: AppColour.labelQuaternary,
                      ),
                    ),
                  ),
                _Ghost(label: 'Cancel', onTap: widget.onClose),
                const SizedBox(width: AppSpace.sm),
                _Primary(
                  label: 'Create project',
                  enabled: _name.text.trim().isNotEmpty,
                  onTap: _create,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
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
}

class _TemplateRow extends StatefulWidget {
  const _TemplateRow({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final ProjectTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TemplateRow> createState() => _TemplateRowState();
}

class _TemplateRowState extends State<_TemplateRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    final tint = Color(t.colour);

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
          margin: const EdgeInsets.only(bottom: AppSpace.xs),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: widget.selected
                ? tint.withValues(alpha: 0.16)
                : _hovered
                ? AppColour.fill
                : null,
            borderRadius: AppRadius.mediumAll,
            border: Border.all(
              color: widget.selected
                  ? tint.withValues(alpha: 0.5)
                  : const Color(0x00000000),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  borderRadius: AppRadius.smallAll,
                ),
                child: Text(t.icon, style: TextStyle(fontSize: 15, color: tint)),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: AppText.headline),
                    Text(
                      t.summary,
                      style: AppText.footnote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_circle_rounded, size: 17, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows exactly what the template will produce, so nothing is a surprise after the fact.
class _Preview extends StatelessWidget {
  const _Preview({required this.template});

  final ProjectTemplate template;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AppSurface(
        colour: AppColour.fill,
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('It will start with', style: AppText.caption),
            const SizedBox(height: AppSpace.sm),
            _Line(
              label: 'Sections',
              value: template.sections.join('  ·  '),
            ),
            _Line(
              label: 'Fields',
              value: template.fields.isEmpty
                  ? 'None — add your own later'
                  : template.fields.map((f) => f.name).join('  ·  '),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 74, child: Text(label, style: AppText.footnote)),
        Expanded(
          child: Text(
            value,
            style: AppText.numeric.copyWith(color: AppColour.label),
          ),
        ),
      ],
    ),
  );
}

class _Ghost extends StatelessWidget {
  const _Ghost({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        child: Text(
          label,
          style: AppText.callout.copyWith(color: AppColour.labelSecondary),
        ),
      ),
    ),
  );
}

class _Primary extends StatefulWidget {
  const _Primary({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_Primary> createState() => _PrimaryState();
}

class _PrimaryState extends State<_Primary> {
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
