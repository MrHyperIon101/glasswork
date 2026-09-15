import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../layout.dart';

/// Title, subtitle, search and the primary action, shared by every content screen.
///
/// Takes one of three shapes, chosen by the width it actually has:
///
/// - **Wide:** everything on one line.
/// - **Medium:** the [accessory] moves to a line of its own, so the title keeps its room.
/// - **Compact**, a phone: a toolbar across the top — menu, [actions], search, New task —
///   with the title under it. Search is a button there that opens the field in the
///   toolbar's place, because a field that is always open costs a phone a whole line.
class ContentHeader extends ConsumerStatefulWidget {
  const ContentHeader({
    required this.title,
    this.subtitle,
    this.onMenu,
    this.accessory,
    this.actions = const [],
    this.showNewTask = true,
    this.dense = false,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Present only where the sidebar is a drawer.
  final VoidCallback? onMenu;

  /// A control that belongs with the title, such as a project's view switcher.
  final Widget? accessory;

  /// Icon buttons that sit beside search.
  final List<Widget> actions;

  /// False on screens with nothing to add — Completed and Time budget.
  final bool showNewTask;

  /// A smaller title on a phone, for names that run long and screens that need the height
  /// for their content.
  final bool dense;

  @override
  ConsumerState<ContentHeader> createState() => _ContentHeaderState();
}

class _ContentHeaderState extends ConsumerState<ContentHeader> {
  /// Search opened from the compact toolbar, before anything has been typed into it.
  bool _searchOpen = false;

  /// Narrower than this, the header takes its phone shape.
  static const _compactBelow = 560.0;

  /// Narrower than this, an accessory no longer fits on the title's line.
  static const _oneLineFrom = 960.0;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < _compactBelow) {
          return _compact(searching: _searchOpen || query.isNotEmpty);
        }
        if (widget.accessory != null && width < _oneLineFrom) return _medium();
        return _wide();
      },
    );
  }

  Widget _wide() => Row(
    children: [
      ..._menu(),
      Expanded(child: _titles(lines: 1)),
      const SizedBox(width: AppSpace.lg),
      if (widget.accessory case final accessory?) ...[
        accessory,
        const SizedBox(width: AppSpace.md),
      ],
      ..._toolbar(),
    ],
  );

  Widget _medium() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          ..._menu(),
          Expanded(child: _titles(lines: 1)),
          const SizedBox(width: AppSpace.lg),
          ..._toolbar(),
        ],
      ),
      const SizedBox(height: AppSpace.md),
      widget.accessory!,
    ],
  );

  Widget _compact({required bool searching}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: AppSize.touch,
        child: searching
            ? Row(
                children: [
                  const Expanded(
                    child: SizedBox(
                      height: AppSize.control,
                      child: SearchField(autofocus: true),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _TextAction(
                    label: 'Cancel',
                    onTap: () {
                      ref.read(searchQueryProvider.notifier).clear();
                      setState(() => _searchOpen = false);
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  if (widget.onMenu case final onMenu?)
                    _IconButton(
                      icon: Icons.menu,
                      tooltip: 'Show the sidebar',
                      onTap: onMenu,
                    ),
                  const Spacer(),
                  ...widget.actions,
                  _IconButton(
                    icon: Icons.search,
                    tooltip: 'Search',
                    onTap: () => setState(() => _searchOpen = true),
                  ),
                  if (widget.showNewTask) ...[
                    const SizedBox(width: AppSpace.xs),
                    const NewTaskButton(),
                  ],
                ],
              ),
      ),
      const SizedBox(height: AppSpace.sm),
      _titles(lines: 2, dense: widget.dense),
      if (widget.accessory case final accessory?) ...[
        const SizedBox(height: AppSpace.md),
        accessory,
      ],
    ],
  );

  List<Widget> _menu() => [
    if (widget.onMenu case final onMenu?) ...[
      _IconButton(icon: Icons.menu, tooltip: 'Show the sidebar', onTap: onMenu),
      const SizedBox(width: AppSpace.md),
    ],
  ];

  List<Widget> _toolbar() => [
    for (final action in widget.actions) ...[
      action,
      const SizedBox(width: AppSpace.sm),
    ],
    const SizedBox(width: 220, height: AppSize.control, child: SearchField()),
    if (widget.showNewTask) ...[
      const SizedBox(width: AppSpace.md),
      const NewTaskButton(),
    ],
  ];

  Widget _titles({required int lines, bool dense = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        widget.title,
        style: dense ? AppText.title : AppText.largeTitle,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
      ),
      if (widget.subtitle case final subtitle?) ...[
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppText.callout,
          maxLines: dense ? 1 : lines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ],
  );
}

class SearchField extends ConsumerStatefulWidget {
  const SearchField({this.autofocus = false, super.key});

  /// Take focus as soon as it appears, for search opened on purpose from a toolbar.
  final bool autofocus;

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  // Starts from the query, not empty. The first keystroke replaces the screen with its
  // results, and this field with a new one, which would otherwise open blank and
  // unfocused while showing results for text it no longer holds.
  late final _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );
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
                autofocus: widget.autofocus || _controller.text.isNotEmpty,
                textInputAction: TextInputAction.search,
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
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final touch = AppLayout.touch;
    final size = touch ? AppSize.touch : AppSize.control;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppMotion.quick,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColour.fill : null,
              borderRadius: AppRadius.mediumAll,
            ),
            child: Icon(
              widget.icon,
              size: touch ? 22 : 18,
              color: AppColour.labelSecondary,
            ),
          ),
        ),
      ),
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
      child: Container(
        height: AppSize.touch,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        child: Text(
          label,
          style: AppText.body.copyWith(color: AppColour.accent),
        ),
      ),
    ),
  );
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
        child: Padding(
          // Taller to a finger than to the eye, so it still lines up with the controls
          // beside it.
          padding: EdgeInsets.symmetric(
            vertical: AppLayout.touch ? (AppSize.touch - AppSize.control) / 2 : 0,
          ),
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
      ),
    );
  }
}
