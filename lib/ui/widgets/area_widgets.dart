import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/db/database.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';
import '../project_icon.dart';
import 'field_controls.dart';

/// What the area dialog was closed with.
sealed class AreaChoice {
  const AreaChoice();
}

/// Keep the area, under this name.
final class AreaNamed extends AreaChoice {
  const AreaNamed(this.name);

  final String name;
}

/// Delete the area.
final class AreaDeleted extends AreaChoice {
  const AreaDeleted();
}

/// Names a new area, or renames or deletes [area]. Null when closed without a choice.
Future<AreaChoice?> showAreaDialog(BuildContext context, {Area? area}) =>
    showAppDialog<AreaChoice>(
      context: context,
      builder: (context) => _AreaDialog(area: area),
    );

class _AreaDialog extends StatefulWidget {
  const _AreaDialog({this.area});

  final Area? area;

  @override
  State<_AreaDialog> createState() => _AreaDialogState();
}

class _AreaDialogState extends State<_AreaDialog> {
  late final _name = TextEditingController(text: widget.area?.name ?? '');

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, AreaNamed(name));
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(area == null ? 'New area' : 'Area', style: AppText.title3),
              const SizedBox(height: AppSpace.xs),
              Text(
                'A group of projects in the sidebar: a course, a job, a part of life.',
                style: AppText.footnote,
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                key: const ValueKey('area-name'),
                controller: _name,
                autofocus: true,
                style: AppText.body,
                cursorColor: AppColour.accent,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColour.fill,
                  hintText: 'University',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mediumAll,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(AppSpace.md),
                ),
              ),
              if (area != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Deleting an area keeps its projects: they move to Projects.',
                  style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  if (area != null)
                    GhostButton(
                      label: 'Delete area',
                      onTap: () => Navigator.pop(context, const AreaDeleted()),
                    ),
                  const Spacer(),
                  GhostButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
                  const SizedBox(width: AppSpace.sm),
                  PrimaryButton(
                    label: area == null ? 'Create' : 'Save',
                    enabled: _name.text.trim().isNotEmpty,
                    onTap: _save,
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

/// A project that can be picked up in the sidebar and dropped under another area.
class ProjectDragSource extends StatelessWidget {
  const ProjectDragSource({required this.project, required this.child, super.key});

  final Board project;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colour = project.colour == null ? AppColour.purple : Color(project.colour!);
    return AdaptiveDraggable<String>(
      data: project.id,
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      feedback: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: AppColour.elevated,
            borderRadius: AppRadius.mediumAll,
            border: Border.all(color: AppColour.separator),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProjectGlyph(icon: project.icon, colour: colour),
              const SizedBox(width: AppSpace.sm),
              Text(project.name, style: AppText.body),
            ],
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Somewhere a project dragged in the sidebar can be dropped, lit while one is over it.
class ProjectDropTarget extends StatelessWidget {
  const ProjectDropTarget({required this.onDrop, required this.child, super.key});

  final ValueChanged<String> onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onAcceptWithDetails: (details) {
      HapticFeedback.selectionClick();
      onDrop(details.data);
    },
    builder: (context, candidates, _) => AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.quick),
      decoration: BoxDecoration(
        color: candidates.isEmpty ? null : AppColour.accent.withValues(alpha: 0.18),
        borderRadius: AppRadius.mediumAll,
        border: Border.all(
          color: AppColour.accent.withValues(alpha: candidates.isEmpty ? 0 : 0.6),
        ),
      ),
      child: child,
    ),
  );
}

/// An area in the sidebar: its name, opening and closing the projects under it, and a way
/// to rename or delete it.
class AreaHeader extends StatefulWidget {
  const AreaHeader({
    required this.area,
    required this.count,
    required this.collapsed,
    required this.onToggle,
    required this.onEdit,
    super.key,
  });

  final Area area;

  /// Projects in it.
  final int count;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  State<AreaHeader> createState() => _AreaHeaderState();
}

class _AreaHeaderState extends State<AreaHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final touch = AppLayout.touch;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        onLongPress: widget.onEdit,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.quick),
          margin: const EdgeInsets.only(top: AppSpace.sm, bottom: 2),
          padding: EdgeInsets.fromLTRB(
            AppSpace.xs,
            touch ? AppSpace.sm : AppSpace.xs,
            AppSpace.xs,
            touch ? AppSpace.sm : AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.fill : null,
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            children: [
              AnimatedRotation(
                turns: widget.collapsed ? 0 : 0.25,
                duration: AppMotion.of(context, AppMotion.quick),
                curve: AppMotion.standard,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColour.labelTertiary,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  widget.area.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.footnote.copyWith(
                    color: AppColour.labelSecondary,
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation('wght', 600)],
                  ),
                ),
              ),
              if (widget.collapsed && widget.count > 0) ...[
                const SizedBox(width: AppSpace.sm),
                Text('${widget.count}', style: AppText.numeric),
              ],
              // Always there to a finger; to a mouse, once it is over the row.
              AnimatedOpacity(
                duration: AppMotion.of(context, AppMotion.quick),
                opacity: touch || _hovered ? 1 : 0,
                child: Tooltip(
                  message: 'Rename or delete ${widget.area.name}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onEdit,
                    child: const SizedBox.square(
                      dimension: AppSize.chip,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: AppColour.labelTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
