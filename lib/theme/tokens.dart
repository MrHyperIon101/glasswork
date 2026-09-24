import 'package:flutter/widgets.dart';

/// Design tokens. Every colour, radius, space and duration in the app comes from here —
/// no literal hex and no magic padding in widget files.
///
/// The palette is Apple's dark-mode system palette rather than an invented one. Using the
/// real values is most of what makes an interface read as native: people have seen
/// #0A84FF and #FF453A ten thousand times, and an approximation of them reads as *almost*
/// right, which is worse than not trying at all.

/// Surfaces get lighter as they rise. Apple's dark mode builds depth from layered greys,
/// not from shadow — shadow barely reads on a dark ground.
abstract final class AppColour {
  /// Window background. Deliberately not pure black: #000 makes every border and shadow
  /// invisible and the whole interface read as a void.
  static const base = Color(0xFF1C1C1E);

  /// Cards and grouped content sitting on [base].
  static const surface = Color(0xFF2C2C2E);

  /// Popovers, sheets, menus — anything floating above a card.
  static const elevated = Color(0xFF3A3A3C);

  /// Hover and pressed states on an otherwise flat surface.
  static const fill = Color(0x1FFFFFFF);
  static const fillStrong = Color(0x2EFFFFFF);

  /// Hairlines. Apple's separators are barely there by design; if you can clearly see
  /// one, it is too strong.
  static const separator = Color(0x26FFFFFF);

  // Text. Apple layers label opacity rather than picking different greys, so text keeps
  // its relationship to whatever surface it happens to sit on.
  static const label = Color(0xFFFFFFFF);
  static const labelSecondary = Color(0x99EBEBF5);
  static const labelTertiary = Color(0x4DEBEBF5);
  static const labelQuaternary = Color(0x2EEBEBF5);

  // System accents, dark variants.
  static const accent = Color(0xFF0A84FF);
  static const red = Color(0xFFFF453A);
  static const orange = Color(0xFFFF9F0A);
  static const yellow = Color(0xFFFFD60A);
  static const green = Color(0xFF30D158);
  static const purple = Color(0xFFBF5AF2);
  static const grey = Color(0xFF8E8E93);
  static const indigo = Color(0xFF5E5CE6);
  static const pink = Color(0xFFFF375F);
  static const teal = Color(0xFF40C8E0);
  static const mint = Color(0xFF63E6E2);
  static const cyan = Color(0xFF64D2FF);
  static const brown = Color(0xFFAC8E68);

  // Semantic aliases. Screens use these, never the raw colour, so "overdue" can change
  // hue in exactly one place.
  static const overdue = red;
  static const soon = orange;
  static const done = green;
}

/// Corner radii.
///
/// This replaces the earlier "two radii only" rule. That rule existed to stop arbitrary
/// mixing in a glass aesthetic; Apple uses a considered scale instead, and matching it
/// matters more than the simpler constraint. The discipline is that these are the only
/// values, each with a fixed job.
abstract final class AppRadius {
  /// Inline chips, tags, small inputs.
  static const small = 8.0;

  /// Buttons, fields, list-row selection.
  static const medium = 12.0;

  /// Cards and panels.
  static const large = 20.0;

  /// Sheets and outer window chrome.
  static const xlarge = 28.0;

  /// Pills and circles only — avatars, toggles, badges.
  static const round = 999.0;

  static const smallAll = BorderRadius.all(Radius.circular(small));
  static const mediumAll = BorderRadius.all(Radius.circular(medium));
  static const largeAll = BorderRadius.all(Radius.circular(large));
  static const xlargeAll = BorderRadius.all(Radius.circular(xlarge));
  static const roundAll = BorderRadius.all(Radius.circular(round));
}

/// Heights for controls that sit side by side.
///
/// Padding plus line-height is not enough to align a text field against a button: each
/// computes its own height from a different font size, and they land a pixel or two
/// apart. Anything in a toolbar row gets an explicit height from here instead.
abstract final class AppSize {
  /// Toolbar controls — search, buttons, segmented switches.
  static const control = 34.0;

  /// Inline chips inside a form.
  static const chip = 28.0;

  /// The smallest target on a touch screen. Anything a finger has to hit is at least this
  /// big, even where what it draws is smaller.
  static const touch = 44.0;

  /// A dashboard card holding one figure.
  static const metricCard = 120.0;

  /// One of the window's own buttons, drawn in the app because the window has no bar of
  /// its own. The circle is small, as it is on a Mac; what it is hit with is [touch].
  static const windowButton = 12.0;

  /// A day in a phone's month grid: seven of them across a 360-point screen, each still
  /// big enough to tap.
  static const dayCell = 36.0;

  /// An on-off switch, and the knob that slides across it.
  static const switchWidth = 46.0;
  static const switchHeight = 28.0;
  static const switchKnob = 24.0;
}

/// Widths at which the layout changes shape.
abstract final class AppBreakpoint {
  /// Narrower than this is a phone: one column, the toolbar under the title, sheets rising
  /// from the bottom.
  static const compact = 600.0;

  /// Narrower than this, the sidebar becomes a drawer.
  static const sidebar = 900.0;
}

/// 4pt grid, 8pt preferred. Apple's layouts are mostly multiples of 8, with 4 as the
/// half-step for tight vertical rhythm.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;
}

/// Inter, standing in for SF Pro.
///
/// SF Pro is licensed for Apple-platform apps only and cannot legally ship in a Linux or
/// Android build. Inter was drawn with SF-adjacent metrics and is the honest substitute.
abstract final class AppFont {
  static const ui = 'Inter';
}

/// Type scale, close to iOS with the display sizes tightened slightly for desktop
/// density.
///
/// Weight carries hierarchy more than size does, which is very characteristic of Apple:
/// two adjacent levels often differ by a point or two of size but a clear step of weight.
abstract final class AppText {
  static const _f = AppFont.ui;

  static const largeTitle = TextStyle(
    fontFamily: _f,
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontVariations: [FontVariation('wght', 700)],
    color: AppColour.label,
  );

  static const title = TextStyle(
    fontFamily: _f,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    fontVariations: [FontVariation('wght', 600)],
    color: AppColour.label,
  );

  static const title3 = TextStyle(
    fontFamily: _f,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    fontVariations: [FontVariation('wght', 600)],
    color: AppColour.label,
  );

  /// Emphasised body — row titles, button labels.
  static const headline = TextStyle(
    fontFamily: _f,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    fontVariations: [FontVariation('wght', 600)],
    color: AppColour.label,
  );

  static const body = TextStyle(
    fontFamily: _f,
    fontSize: 15,
    height: 1.4,
    fontVariations: [FontVariation('wght', 400)],
    color: AppColour.label,
  );

  static const callout = TextStyle(
    fontFamily: _f,
    fontSize: 13,
    height: 1.4,
    fontVariations: [FontVariation('wght', 400)],
    color: AppColour.labelSecondary,
  );

  static const footnote = TextStyle(
    fontFamily: _f,
    fontSize: 12,
    height: 1.35,
    fontVariations: [FontVariation('wght', 400)],
    color: AppColour.labelSecondary,
  );

  /// Section headers above grouped content. Sentence case, never caps.
  static const caption = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    fontVariations: [FontVariation('wght', 500)],
    color: AppColour.labelTertiary,
  );

  /// Big dashboard figures. Tabular so a live update never makes the layout shimmer.
  static const metric = TextStyle(
    fontFamily: _f,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.4,
    fontVariations: [FontVariation('wght', 700)],
    color: AppColour.label,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const metricSmall = TextStyle(
    fontFamily: _f,
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    fontVariations: [FontVariation('wght', 700)],
    color: AppColour.label,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Numbers in running text — dates, counts, durations.
  static const numeric = TextStyle(
    fontFamily: _f,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    color: AppColour.labelSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Motion.
///
/// Apple's interface motion is quick and settles rather than bounces: things arrive fast
/// and land softly, and leave faster than they came. Anything that visibly oscillates reads
/// as a toy, and anything slow reads as the app being slow.
abstract final class AppMotion {
  static const spring = SpringDescription(mass: 1, stiffness: 220, damping: 30);

  /// Press feedback: felt more than seen.
  static const instant = Duration(milliseconds: 110);

  /// Hover, selection, small changes of state.
  static const quick = Duration(milliseconds: 180);

  /// Content changing in place: a screen, a size, a count.
  static const medium = Duration(milliseconds: 280);

  /// Surfaces arriving from off screen: sheets, the drawer.
  static const slow = Duration(milliseconds: 420);

  /// Most motion: a brisk start and a gentle settle.
  static const standard = Cubic(0.2, 0, 0, 1);

  /// Arriving: fast off the mark, then a long soft landing.
  static const enter = Cubic(0.05, 0.7, 0.1, 1);

  /// Leaving: eases away, then goes.
  static const exit = Cubic(0.3, 0, 0.8, 0.15);

  static const undoWindow = Duration(seconds: 5);

  /// [duration], or none at all where the system has been asked for less motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : duration;
}

/// Vibrancy — the one place translucency is used.
abstract final class AppMaterial {
  /// macOS sidebar material is a heavy blur with a tint, not a light frost.
  static const sidebarBlur = 30.0;
  static const sheetBlur = 40.0;

  /// Tint over the blur, so content behind never resolves into recognisable shapes.
  static const sidebarTint = Color(0xCC1C1C1E);
  static const sheetTint = Color(0xE62C2C2E);
}
