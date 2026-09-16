import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/project_filter.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import 'field_controls.dart';
import '../motion.dart';

/// Named ways of looking at a project.
///
/// A saved view is a name, a render kind, and a filter — nothing more. It is not a new
/// screen and not a new table per view, which is the same rule the smart views follow:
/// adding one must never mean adding a widget class.
class SavedViewsBar extends ConsumerWidget {
  const SavedViewsBar({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(projectViewsProvider(projectId)).value ?? const [];
    final current = ref.watch(matchingSavedViewProvider(projectId));
    final filter = ref.watch(effectiveProjectFilterProvider);

    // Nothing saved and nothing to save: stay out of the way entirely.
    if (views.isEmpty && filter.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final view in views)
            _ViewChip(
              view: view,
              selected: current?.id == view.id,
              onTap: () => _apply(ref, view),
              onDelete: () => _delete(context, ref, view),
            ),

          // Offered only when the current shape is not already saved — otherwise it
          // invites you to make duplicates of what you are looking at.
          if (!filter.isEmpty && current == null)
            _SaveButton(
              onTap: () => _save(context, ref),
            ),
        ],
      ),
    );
  }

  void _apply(WidgetRef ref, ProjectView view) {
    ref
        .read(projectFilterProvider.notifier)
        .replace(ProjectFilter.decode(view.filterJson));
    ref
        .read(projectViewModeProvider.notifier)
        .set(projectId, boardViewOf(view.kind));
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    final name = await _askName(context);
    if (name == null || name.isEmpty) return;

    final kind =
        ref.read(projectViewModeProvider)[projectId] ?? BoardView.board;

    await scope.projects.addView(
      workspaceId: scope.workspace.id,
      boardId: projectId,
      name: name,
      kind: viewKindOf(kind),
      filter: ref.read(effectiveProjectFilterProvider),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProjectView view,
  ) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;

    // No confirmation: a view holds no work, so losing one costs a few taps to rebuild.
    // Undo is enough, and a dialog here would just be ceremony.
    await scope.projects.deleteView(view.id);
    ref
        .read(undoProvider.notifier)
        .offer(
          'Removed the "${view.name}" view',
          () => scope.projects.restoreView(view.id),
        );
  }

  static Future<String?> _askName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showAppDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColour.elevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Save this view', style: AppText.title3),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'The current filter and layout, under a name you can come back to.',
                  style: AppText.callout.copyWith(
                    color: AppColour.labelSecondary,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppText.body,
                  cursorColor: AppColour.accent,
                  onSubmitted: (v) => Navigator.pop(context, v.trim()),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColour.fill,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mediumAll,
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'What I owe this week',
                    hintStyle: AppText.body.copyWith(
                      color: AppColour.labelTertiary,
                    ),
                  ),
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
                      label: 'Save view',
                      enabled: true,
                      onTap: () =>
                          Navigator.pop(context, controller.text.trim()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    return name;
  }
}

class _ViewChip extends StatefulWidget {
  const _ViewChip({
    required this.view,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final ProjectView view;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_ViewChip> createState() => _ViewChipState();
}

class _ViewChipState extends State<_ViewChip> {
  bool _hovered = false;

  static const _icons = {
    ViewKind.board: Icons.view_kanban_outlined,
    ViewKind.list: Icons.format_list_bulleted_rounded,
    ViewKind.calendar: Icons.calendar_month_outlined,
    ViewKind.timeline: Icons.timeline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

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
          padding: const EdgeInsets.only(
            left: AppSpace.md,
            right: AppSpace.sm,
            top: AppSpace.xs + 1,
            bottom: AppSpace.xs + 1,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColour.accent.withValues(alpha: 0.2)
                : _hovered
                ? AppColour.fillStrong
                : AppColour.fill,
            borderRadius: AppRadius.smallAll,
            border: Border.all(
              color: selected
                  ? AppColour.accent.withValues(alpha: 0.55)
                  : const Color(0x00000000),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icons[widget.view.kind] ?? Icons.filter_list_rounded,
                size: 13,
                color: selected ? AppColour.accent : AppColour.labelTertiary,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                widget.view.name,
                style: AppText.numeric.copyWith(
                  color: selected ? AppColour.accent : AppColour.labelSecondary,
                ),
              ),
              // Revealed on hover, so the bar reads as names rather than a row of
              // close buttons. A touch screen has no hover, so there it is always shown.
              AnimatedSize(
                duration: AppMotion.quick,
                child: _hovered || AppLayout.touch
                    ? GestureDetector(
                        onTap: widget.onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: AppSpace.xs,
                            right: AppLayout.touch ? AppSpace.xs : 0,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: AppColour.labelTertiary,
                          ),
                        ),
                      )
                    : const SizedBox(width: AppSpace.xs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
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
          vertical: AppSpace.xs + 1,
        ),
        decoration: BoxDecoration(
          color: _hovered ? AppColour.fillStrong : null,
          borderRadius: AppRadius.smallAll,
          border: Border.all(color: AppColour.separator),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_add_outlined, size: 13, color: AppColour.accent),
            const SizedBox(width: AppSpace.xs),
            Text(
              'Save this view',
              style: AppText.numeric.copyWith(color: AppColour.accent),
            ),
          ],
        ),
      ),
    ),
  );
}
