import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'glass/glass_surface.dart';

/// A card.
///
/// The default surface in the app, and the one to reach for first. It is glass — see
/// [GlassSurface] — over the ambient backdrop, or an opaque card in [colour] where Settings
/// asks for solid. Depth comes from the layered greys in [AppColour] and the light along
/// the rim, not from shadow, which barely registers on a dark ground.
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

  /// The card's colour: opaque in the solid look, the tint of the glass otherwise.
  final Color colour;

  /// A clear edge rather than a faint one. Worth it when two surfaces of similar lightness
  /// meet and the edge would otherwise be ambiguous; noise everywhere else.
  final bool border;

  @override
  Widget build(BuildContext context) => GlassSurface(
    radius: radius,
    padding: padding,
    solid: colour,
    tint: colour == AppColour.surface
        ? AppMaterial.cardTint
        : colour.withValues(alpha: AppMaterial.cardTint.a),
    hairline: border,
    child: child,
  );
}

/// A surface that floats over others, the way macOS does a sidebar or a sheet: more blur and
/// a heavier tint than a card, so what scrolls beneath never resolves into shapes.
///
/// A sheet takes a capture of its own, since it lies over cards that are glass themselves
/// and surfaces that overlap must not share one.
class VibrancyMaterial extends StatelessWidget {
  const VibrancyMaterial.sidebar({
    required this.child,
    this.radius = AppRadius.large,
    super.key,
  }) : _blur = AppMaterial.sidebarBlur,
       _tint = AppMaterial.sidebarTint,
       _solid = AppColour.base,
       _floats = false;

  const VibrancyMaterial.sheet({
    required this.child,
    this.radius = AppRadius.xlarge,
    super.key,
  }) : _blur = AppMaterial.sheetBlur,
       _tint = AppMaterial.sheetTint,
       _solid = AppColour.surface,
       _floats = true;

  final Widget child;
  final double radius;
  final double _blur;
  final Color _tint;
  final Color _solid;
  final bool _floats;

  @override
  Widget build(BuildContext context) {
    final surface = GlassSurface(
      radius: radius,
      blur: _blur,
      tint: _tint,
      solid: _solid,
      hairline: true,
      child: child,
    );
    return _floats ? BackdropGroup(child: surface) : surface;
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
