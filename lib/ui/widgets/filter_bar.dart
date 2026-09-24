import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/task_order.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../surface.dart';

/// Filters for the open project.
///
/// Collapsed to a single button until used, because a permanent row of controls above
/// every board is clutter for the common case of not filtering at all. Once something is
/// active the button says how many and the bar stays open — a filter you cannot see is a
/// filter that quietly hides your work.
///
/// Sharing a phone's line with another control, an open bar would cost a third of the
/// screen for as long as a filter is on. There it closes to a single line saying what the
/// filter is hiding, which keeps the same promise in a fraction of the height.
class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({this.leading, super.key});

  /// A control sharing the toggle's line, such as a phone's view switcher. With one, the
  /// toggle shrinks to its icon, and Clear and the count move under it, where there is
  /// room for them.
  final Widget? leading;

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(effectiveProjectFilterProvider);
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final notifier = ref.read(projectFilterProvider.notifier);
    final leading = widget.leading;
    final shared = leading != null;

    final clear = _Plain(
      label: 'Clear',
      onTap: () {
        notifier.clear();
        setState(() => _open = false);
      },
    );
    // Says what the filter is doing to the list, not just that one exists — and how the
    // list is ordered, which is otherwise invisible once the panel is shut.
    final ordered = filter.sort == TaskSort.manual
        ? ''
        : ', by ${filter.sort.label.toLowerCase()}';
    final count = Text(
      '${ref.watch(filteredProjectTasksProvider).length} of '
      '${ref.watch(visibleTasksProvider).length} shown$ordered',
      style: AppText.numeric,
    );
    final summary = Row(children: [Expanded(child: count), clear]);

    final status = [
      _Pill(
        label: 'Hide completed',
        selected: filter.hideCompleted,
        onTap: () => notifier.setHideCompleted(!filter.hideCompleted),
      ),
      _Pill(
        label: "Only what won't fit",
        tint: AppColour.red,
        selected: filter.onlyAtRisk,
        onTap: () => notifier.setOnlyAtRisk(!filter.onlyAtRisk),
      ),
    ];
    final priorities = [
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
    ];
    // Sorting is not filtering — it hides nothing — but it is the other half of "show me
    // this project like this", and a saved view keeps both. Manual is the order the cards
    // are actually in, which is why it leads.
    //
    // Narrow, four pills would cost a line of their own on a panel that is already most
    // of a phone screen, so there it is one pill that names the order and steps through
    // them. It says where it is either way; only the number of taps differs.
    final sorts = shared
        ? [
            _Pill(
              label: 'Order: ${filter.sort.label.toLowerCase()}',
              tint: AppColour.accent,
              selected: filter.sort != TaskSort.manual,
              onTap: () => notifier.setSort(
                TaskSort.values[(filter.sort.index + 1) % TaskSort.values.length],
              ),
            ),
          ]
        : [
            for (final sort in TaskSort.values)
              _Pill(
                label: sort == TaskSort.manual
                    ? 'Manual order'
                    : 'By ${sort.label.toLowerCase()}',
                tint: AppColour.accent,
                selected: filter.sort == sort,
                onTap: () => notifier.setSort(sort),
              ),
          ];
    final tags = [
      for (final label in labels)
        _Pill(
          label: '#${label.name}',
          tint: label.colour == null ? AppColour.purple : Color(label.colour!),
          selected: filter.labelIds.contains(label.id),
          onTap: () => notifier.toggleLabel(label.id),
        ),
    ];

    Widget pills(List<Widget> children) => Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );

    // A panel is not allowed to push the work it is filtering off the screen. Past about
    // a third of the height it scrolls inside itself instead — which is what a phone at
    // the largest text size does once every group of pills is open.
    Widget bounded(Widget child) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.32,
      ),
      child: SingleChildScrollView(child: child),
    );

    final panel = AppSurface(
      padding: const EdgeInsets.all(AppSpace.md),
      child: shared
          // Narrow, the pills wrap, and a separator between groups ends up hanging at the
          // end of a line. Each group starts a line of its own instead.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!filter.isEmpty || filter.sort != TaskSort.manual) ...[
                  summary,
                  const SizedBox(height: AppSpace.md),
                ],
                // The order joins the status pills rather than starting a line: it
                // wraps onto one only where there is no room beside them.
                pills([...status, ...sorts]),
                const SizedBox(height: AppSpace.sm),
                pills(priorities),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  pills(tags),
                ],
              ],
            )
          : pills([
              ...status,
              _Sep(),
              ...priorities,
              if (tags.isNotEmpty) _Sep(),
              ...tags,
              _Sep(),
              ...sorts,
            ]),
    );

    final plain = filter.isEmpty && filter.sort == TaskSort.manual;

    final Widget below;
    if (_open || (!shared && !plain)) {
      below = Padding(
        padding: const EdgeInsets.only(top: AppSpace.sm),
        child: bounded(panel),
      );
    } else if (!plain) {
      below = Padding(
        padding: const EdgeInsets.only(top: AppSpace.sm),
        child: summary,
      );
    } else {
      below = const SizedBox(width: double.infinity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leading != null) ...[
              Expanded(child: leading),
              const SizedBox(width: AppSpace.sm),
            ],
            _FilterToggle(
              count: filter.activeCount,
              iconOnly: shared,
              onTap: () => setState(() => _open = !_open),
            ),
            if (!shared && !plain) ...[
              const SizedBox(width: AppSpace.sm),
              clear,
              const SizedBox(width: AppSpace.sm),
              count,
            ],
          ],
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: below,
        ),
      ],
    );
  }
}

class _FilterToggle extends StatefulWidget {
  const _FilterToggle({
    required this.count,
    required this.onTap,
    this.iconOnly = false,
  });

  final int count;
  final VoidCallback onTap;

  /// Just the icon, and the count when there is one.
  final bool iconOnly;

  @override
  State<_FilterToggle> createState() => _FilterToggleState();
}

class _FilterToggleState extends State<_FilterToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.count > 0;
    final colour = active ? AppColour.accent : AppColour.labelSecondary;

    return Tooltip(
      message: widget.iconOnly ? 'Filter' : '',
      child: MouseRegion(
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
            constraints: const BoxConstraints(minWidth: AppSize.control),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: widget.iconOnly ? AppSpace.sm : AppSpace.md,
            ),
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
                Icon(Icons.filter_list_rounded, size: 15, color: colour),
                if (!widget.iconOnly) ...[
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    active ? 'Filtered · ${widget.count}' : 'Filter',
                    style: AppText.callout.copyWith(color: colour),
                  ),
                ] else if (active) ...[
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    '${widget.count}',
                    style: AppText.callout.copyWith(color: colour),
                  ),
                ],
              ],
            ),
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
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            // Taller for a finger, which has no pointer's precision.
            vertical: AppLayout.touch ? AppSpace.sm : AppSpace.xs + 1,
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
      child: Padding(
        // Room around the word to hit on a touch screen, none to throw off alignment
        // under a pointer.
        padding: AppLayout.touch
            ? const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, 0, AppSpace.sm)
            : EdgeInsets.zero,
        child: Text(
          label,
          style: AppText.numeric.copyWith(color: AppColour.accent),
        ),
      ),
    ),
  );
}
