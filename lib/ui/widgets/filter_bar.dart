import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../surface.dart';

/// Filters for the open project.
///
/// Collapsed to a single button until used, because a permanent row of controls above
/// every board is clutter for the common case of not filtering at all. Once something is
/// active the button says how many and the bar stays open — a filter you cannot see is a
/// filter that quietly hides your work.
class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(projectFilterProvider);
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final notifier = ref.read(projectFilterProvider.notifier);

    final showing = _open || !filter.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FilterToggle(
              count: filter.activeCount,
              onTap: () => setState(() => _open = !_open),
            ),
            if (!filter.isEmpty) ...[
              const SizedBox(width: AppSpace.sm),
              _Plain(
                label: 'Clear',
                onTap: () {
                  notifier.clear();
                  setState(() => _open = false);
                },
              ),
              const SizedBox(width: AppSpace.sm),
              // Says what the filter is doing to the list, not just that one exists.
              Text(
                '${ref.watch(filteredProjectTasksProvider).length} of '
                '${ref.watch(visibleTasksProvider).length} shown',
                style: AppText.numeric,
              ),
            ],
          ],
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: !showing
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: AppSurface(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Pill(
                          label: 'Hide completed',
                          selected: filter.hideCompleted,
                          onTap: () =>
                              notifier.setHideCompleted(!filter.hideCompleted),
                        ),
                        _Pill(
                          label: "Only what won't fit",
                          tint: AppColour.red,
                          selected: filter.onlyAtRisk,
                          onTap: () => notifier.setOnlyAtRisk(!filter.onlyAtRisk),
                        ),
                        _Sep(),
                        for (final (value, label, tint) in const [
                          (3, 'High', AppColour.red),
                          (2, 'Medium', AppColour.orange),
                          (1, 'Low', AppColour.grey),
                        ])
                          _Pill(
                            label: label,
                            tint: tint,
                            selected: filter.priorities.contains(value),
                            onTap: () => notifier.togglePriority(value),
                          ),
                        if (labels.isNotEmpty) _Sep(),
                        for (final label in labels)
                          _Pill(
                            label: '#${label.name}',
                            tint: label.colour == null
                                ? AppColour.purple
                                : Color(label.colour!),
                            selected: filter.labelIds.contains(label.id),
                            onTap: () => notifier.toggleLabel(label.id),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterToggle extends StatefulWidget {
  const _FilterToggle({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  State<_FilterToggle> createState() => _FilterToggleState();
}

class _FilterToggleState extends State<_FilterToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.count > 0;

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
          height: AppSize.control,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: active
                ? AppColour.accent.withValues(alpha: 0.18)
                : _hovered
                ? AppColour.fillStrong
                : AppColour.fill,
            borderRadius: AppRadius.mediumAll,
            border: Border.all(
              color: active
                  ? AppColour.accent.withValues(alpha: 0.5)
                  : const Color(0x00000000),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list,
                size: 15,
                color: active ? AppColour.accent : AppColour.labelSecondary,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                active ? 'Filtered · ${widget.count}' : 'Filter',
                style: AppText.callout.copyWith(
                  color: active ? AppColour.accent : AppColour.labelSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatefulWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs + 1,
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
            style: AppText.numeric.copyWith(
              color: widget.selected ? tint : AppColour.labelSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5,
    height: 20,
    color: AppColour.separator,
  );
}

class _Plain extends StatelessWidget {
  const _Plain({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: AppText.numeric.copyWith(color: AppColour.accent),
      ),
    ),
  );
}
