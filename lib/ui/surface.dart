import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// An opaque card.
///
/// This is the default surface in the app and should be reached for first. Depth comes
/// from the layered greys in [AppColour] — a lighter surface reads as nearer — not from
/// shadow, which barely registers on a dark ground and tends to look like grime.
class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.xl),
    this.radius = AppRadius.large,
    this.colour = AppColour.surface,
    this.border = false,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color colour;

  /// A hairline. Worth it when two surfaces of similar lightness meet and the edge would
  /// otherwise be ambiguous; noise everywhere else.
  final bool border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        // Always a faint edge, which lifts a card off the ground the way light catches the
        // rim of a panel; a clear one where two surfaces of similar lightness meet.
        border: Border.all(
          color: border ? AppColour.separator : AppColour.separator.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Blurred vibrancy, the way macOS does a sidebar or a sheet.
///
/// This is the **only** translucency in the app and the only `BackdropFilter`. It is
/// expensive — each one forces the compositor to capture and blur what is behind it — so
/// it is reserved for surfaces that genuinely float above scrolling content. A card in a
/// grid is not one of those; use [AppSurface].
class VibrancyMaterial extends StatelessWidget {
  const VibrancyMaterial.sidebar({
    required this.child,
    this.radius = AppRadius.large,
    super.key,
  }) : _blur = AppMaterial.sidebarBlur,
       _tint = AppMaterial.sidebarTint;

  const VibrancyMaterial.sheet({
    required this.child,
    this.radius = AppRadius.xlarge,
    super.key,
  }) : _blur = AppMaterial.sheetBlur,
       _tint = AppMaterial.sheetTint;

  final Widget child;
  final double radius;
  final double _blur;
  final Color _tint;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.all(Radius.circular(radius));

    return ClipRRect(
      borderRadius: corners,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // The tint is not decoration. Without it the blur still resolves into
            // recognisable shapes when something high-contrast scrolls behind.
            color: _tint,
            borderRadius: corners,
            border: Border.all(color: AppColour.separator, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A hairline divider at the standard inset.
class AppDivider extends StatelessWidget {
  const AppDivider({this.indent = 0, super.key});

  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent),
    child: const SizedBox(
      height: 0.5,
      width: double.infinity,
      child: ColoredBox(color: AppColour.separator),
    ),
  );
}
