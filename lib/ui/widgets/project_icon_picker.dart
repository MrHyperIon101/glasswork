import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';
import '../project_icon.dart';
import '../surface.dart';
import 'field_controls.dart';

/// Chooses a project's icon: one of the symbols, or any emoji or letters typed in.
///
/// Returns the icon as a project stores it, or null when closed without a choice.
Future<String?> pickProjectIcon(
  BuildContext context, {
  required String? current,
  required Color colour,
}) => showAppDialog<String>(
  context: context,
  builder: (context) => _ProjectIconPicker(current: current, colour: colour),
);

/// A project's icon, which opens the picker when pressed and reports what was chosen.
class ProjectIconButton extends StatefulWidget {
  const ProjectIconButton({
    required this.icon,
    required this.colour,
    required this.onChosen,
    super.key,
  });

  final String? icon;
  final Color colour;
  final ValueChanged<String> onChosen;

  @override
  State<ProjectIconButton> createState() => _ProjectIconButtonState();
}

class _ProjectIconButtonState extends State<ProjectIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Choose an icon',
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Pressable(
        onTap: () async {
          final chosen = await pickProjectIcon(
            context,
            current: widget.icon,
            colour: widget.colour,
          );
          if (chosen != null) widget.onChosen(chosen);
        },
        child: AnimatedContainer(
          key: const ValueKey('project-icon'),
          duration: AppMotion.of(context, AppMotion.quick),
          width: AppSize.touch,
          height: AppSize.touch,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.colour.withValues(alpha: _hovered ? 0.28 : 0.18),
            borderRadius: AppRadius.mediumAll,
          ),
          child: ProjectGlyph(icon: widget.icon, colour: widget.colour, size: 22),
        ),
      ),
    ),
  );
}

class _ProjectIconPicker extends StatefulWidget {
  const _ProjectIconPicker({required this.current, required this.colour});

  final String? current;
  final Color colour;

  @override
  State<_ProjectIconPicker> createState() => _ProjectIconPickerState();
}

class _ProjectIconPickerState extends State<_ProjectIconPicker> {
  final _typed = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _choose(String icon) => Navigator.pop(context, icon);

  @override
  Widget build(BuildContext context) {
    final typed = ProjectIcon.typed(_typed.text);

    Widget choices(Iterable<(String, Widget)> items) => Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: [
        for (final (icon, glyph) in items)
          _Choice(
            key: ValueKey('icon-$icon'),
            selected: widget.current == icon,
            colour: widget.colour,
            onTap: () => _choose(icon),
            child: glyph,
          ),
      ],
    );

    return Dialog(
      backgroundColor: AppColour.elevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.md),
              child: Row(
                children: [
                  Container(
                    width: AppSize.touch,
                    height: AppSize.touch,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.colour.withValues(alpha: 0.18),
                      borderRadius: AppRadius.mediumAll,
                    ),
                    child: ProjectGlyph(
                      icon: typed ?? widget.current,
                      colour: widget.colour,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Icon', style: AppText.title3),
                        Text(
                          'A symbol, or any emoji or two letters of your own.',
                          style: AppText.footnote,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Emoji or letters', style: AppText.caption),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: AppSize.control,
                            child: TextField(
                              key: const ValueKey('icon-typed'),
                              controller: _typed,
                              style: AppText.body,
                              cursorColor: widget.colour,
                              onSubmitted: (_) {
                                if (typed != null) _choose(typed);
                              },
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: AppColour.fill,
                                hintText: 'Type or paste one',
                                hintStyle: AppText.body.copyWith(color: AppColour.labelTertiary),
                                border: const OutlineInputBorder(
                                  borderRadius: AppRadius.mediumAll,
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.md,
                                  vertical: AppSpace.sm,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        PrimaryButton(
                          label: 'Use',
                          enabled: typed != null,
                          onTap: () {
                            if (typed != null) _choose(typed);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    choices([
                      for (final emoji in ProjectIcon.suggestedEmoji)
                        (emoji, Text(emoji, style: const TextStyle(fontSize: 18, height: 1))),
                    ]),
                    const SizedBox(height: AppSpace.lg),
                    Text('Symbols', style: AppText.caption),
                    const SizedBox(height: AppSpace.sm),
                    choices([
                      for (final MapEntry(key: name, value: symbol) in ProjectIcon.symbols.entries)
                        (
                          ProjectIcon.symbol(name),
                          Icon(symbol, size: 20, color: widget.colour),
                        ),
                    ]),
                    const SizedBox(height: AppSpace.lg),
                  ],
                ),
              ),
            ),
            const AppDivider(),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GhostButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One icon to choose, its own colour washed behind it once it is the one chosen.
class _Choice extends StatefulWidget {
  const _Choice({
    required this.selected,
    required this.colour,
    required this.onTap,
    required this.child,
    super.key,
  });

  final bool selected;
  final Color colour;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Choice> createState() => _ChoiceState();
}

class _ChoiceState extends State<_Choice> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // A finger's width on a touch screen; a little tighter under a mouse.
    final size = AppLayout.touch ? AppSize.touch : AppSize.control + AppSpace.xs;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Pressable(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.quick),
          curve: AppMotion.standard,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.colour.withValues(alpha: 0.22)
                : _hovered
                ? AppColour.fillStrong
                : AppColour.fill,
            borderRadius: AppRadius.mediumAll,
            border: Border.all(
              color: widget.selected
                  ? widget.colour.withValues(alpha: 0.6)
                  : widget.colour.withValues(alpha: 0),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
