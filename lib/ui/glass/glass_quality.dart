/// How much work a [GlassSurface] is allowed to do.
///
/// Lives in its own file so the backdrop can read it without importing the glass widget,
/// which would be a cycle.
enum GlassQuality {
  /// Procedural refraction: the shader displaces its backdrop lookup along the surface's
  /// edge normal. This is the one that reads as thick glass.
  full,

  /// Shader still reconstructs and tints the backdrop, but without displacement. Cheaper,
  /// and the fallback if a platform can't hold frame rate with [full].
  blurOnly,

  /// No shader at all — a tinted solid with the same edge treatment. Must still look
  /// deliberate; this is a supported appearance, not a broken one.
  flat,
}
