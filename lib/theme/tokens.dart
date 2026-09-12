import 'package:flutter/widgets.dart';

/// Design tokens. Every colour, radius, space and duration in the app comes from here —
/// no literal hex and no magic padding in widget files.

abstract final class AppColour {
  /// Root background, under the mesh backdrop.
  static const base = Color(0xFF07080C);

  // Backdrop blobs. Kept in sync with shaders/mesh_common.glsl by hand; if you change one,
  // change both. They are duplicated because the shader cannot read Dart constants.
  static const meshViolet = Color(0xFF2A1B5E);
  static const meshTeal = Color(0xFF0B4F6C);
  static const meshPlum = Color(0xFF6B2D5C);

  static const accent = Color(0xFF7C8CFF);
  static const text = Color(0xFFECEDF2);
  static const textDim = Color(0xFF8B90A3);

  static const overdue = Color(0xFFFF6B81);
  static const soon = Color(0xFFFFB86B);
  static const done = Color(0xFF5BD6A0);
}

/// Two radii only. Surfaces get [surface], controls get [control]. Nothing in between —
/// a mix of arbitrary radii is what makes glass UIs look cheap.
abstract final class AppRadius {
  static const surface = Radius.circular(20);
  static const control = Radius.circular(999);

  static const surfaceAll = BorderRadius.all(surface);
  static const controlAll = BorderRadius.all(control);

  /// Same two values as doubles, for the shader uniform and for widgets that need a
  /// number rather than a [Radius].
  static const surfaceValue = 20.0;
  static const controlValue = 999.0;
}

/// Glass material constants. Shared by the shader path and the flat fallback so the
/// three quality levels stay recognisably the same material.
abstract final class AppGlass {
  /// Tinted solid used by [GlassQuality.flat].
  static const flatFill = Color(0x1AFFFFFF);

  /// 1px inner stroke — rgba(255,255,255,0.18).
  static const edge = Color(0x2EFFFFFF);

  /// Backdrop blur for surfaces that genuinely overlap content.
  static const blurSigma = 18.0;

  /// No more than this many glass surfaces on screen at once. It is fill-rate expensive
  /// and the whole effect collapses if the app drops frames.
  static const maxOnScreen = 4;
}

/// 4px base scale.
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

/// One family for UI, one for anything numeric.
///
/// The font files are not bundled yet — until Geist is added to pubspec.yaml under
/// `fonts:`, these names fall back to the platform default. See README for the download
/// step; Geist is MIT-licensed.
abstract final class AppFont {
  static const ui = 'Geist';
  static const mono = 'GeistMono';
}

/// Scale from the design system: 32 / 24 / 18 / 15 / 13 / 11.
///
/// Anything numeric — dates, counts, durations, keyboard hints — uses [numeric], which
/// carries tabular figures so due-date columns do not shimmer as they re-render.
abstract final class AppText {
  static const _bodyHeight = 1.45;

  static const display = TextStyle(
    fontFamily: AppFont.ui,
    fontSize: 32,
    height: 1.2,
    color: AppColour.text,
  );
  static const title = TextStyle(
    fontFamily: AppFont.ui,
    fontSize: 24,
    height: 1.25,
    color: AppColour.text,
  );
  static const heading = TextStyle(
    fontFamily: AppFont.ui,
    fontSize: 18,
    height: 1.3,
    color: AppColour.text,
  );
  static const body = TextStyle(
    fontFamily: AppFont.ui,
    fontSize: 15,
    height: _bodyHeight,
    color: AppColour.text,
  );
  static const small = TextStyle(
    fontFamily: AppFont.ui,
    fontSize: 13,
    height: _bodyHeight,
    color: AppColour.textDim,
  );
  static const tiny = TextStyle(
    fontFamily: AppFont.ui,
    fontSize: 11,
    height: _bodyHeight,
    color: AppColour.textDim,
  );

  /// Tabular figures. Use for every number the user reads.
  static const numeric = TextStyle(
    fontFamily: AppFont.mono,
    fontSize: 13,
    height: _bodyHeight,
    color: AppColour.textDim,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Motion answers actions. Spring physics, not curves.
abstract final class AppMotion {
  /// The house spring. Reach for this before writing a new one.
  static const spring = SpringDescription(mass: 1, stiffness: 180, damping: 22);

  /// For the few places a duration is unavoidable (cross-fades, undo toasts).
  static const quick = Duration(milliseconds: 140);
  static const undoWindow = Duration(seconds: 5);
}
