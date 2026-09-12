import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../theme/tokens.dart';

/// Title, subtitle and search, shared by every content screen.
class ContentHeader extends ConsumerWidget {
  const ContentHeader({
    required this.title,
    this.subtitle,
    this.onMenu,
    this.trailing,
    this.showNewTask = true,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Present only on narrow layouts, where the sidebar is a drawer.
  final VoidCallback? onMenu;

  final Widget? trailing;

  /// False on screens with no composer to focus — Done and Capacity.
  final bool showNewTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (onMenu != null) ...[
          _IconButton(icon: Icons.menu, onTap: onMenu!),
          const SizedBox(width: AppSpace.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.largeTitle),
              if (subtitle case final s?) ...[
                const SizedBox(height: 2),
                Text(s, style: AppText.callout),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpace.lg),
        if (trailing case final t?) ...[t, const SizedBox(width: AppSpace.md)],
        const SizedBox(
          width: 220,
          height: AppSize.control,
          child: SearchField(),
        ),
        if (showNewTask) ...[
          const SizedBox(width: AppSpace.md),
          const NewTaskButton(),
        ],
      ],
    );
  }
}

class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cleared from elsewhere (navigating away), so mirror it back into the field.
    ref.listen(searchQueryProvider, (_, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) _controller.clear();
    });

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColour.fill,
        borderRadius: AppRadius.mediumAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 15,
              color: AppColour.labelTertiary,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                style: AppText.callout.copyWith(color: AppColour.label),
                cursorColor: AppColour.accent,
                cursorWidth: 1.5,
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).set(v),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  // Vertically centred in the fixed-height box rather than adding its
                  // own padding, which is what made it shorter than the buttons.
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Search',
                  hintStyle: AppText.callout.copyWith(
                    color: AppColour.labelTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.fill : null,
            borderRadius: AppRadius.smallAll,
          ),
          child: Icon(widget.icon, size: 18, color: AppColour.labelSecondary),
        ),
      ),
    );
  }
}

/// The primary action, filled and in the corner the eye already goes to.
///
/// This is the only filled accent button in the app. An inline field at the foot of a
/// panel is easy to read as a status bar rather than an input, so the obvious affordance
/// lives up here and the composer below is where the typing happens — the button just
/// puts the cursor there.
class NewTaskButton extends ConsumerStatefulWidget {
  const NewTaskButton({super.key});

  @override
  ConsumerState<NewTaskButton> createState() => _NewTaskButtonState();
}

class _NewTaskButtonState extends ConsumerState<NewTaskButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => ref.read(composerOpenProvider.notifier).open(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          height: AppSize.control,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColour.accent
                : AppColour.accent.withValues(alpha: 0.9),
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: Colors.white),
              const SizedBox(width: AppSpace.xs),
              Text(
                'New task',
                style: AppText.headline.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
