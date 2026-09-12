# Glasswork

Local-first task app with a capacity engine. Linux + Android.

See `docs/architecture.md` for the architectural constraints — they are not suggestions, and several of
them exist because the obvious alternative is subtly broken.

## Status

Phase 0 (shell). Working: procedural mesh backdrop, `GlassSurface` with a three-level
quality ladder, Drift schema carrying the sync-column tail, frame instrumentation.

Measured on Linux (RTX 4060, Impeller GLES, 1920x1116, four glass surfaces):

```
raster p50 0.6ms   p95 1.3ms   over-budget 0%   ~61fps
```

Budget is 16.7ms, so roughly 4% of a frame.

## Run

```bash
flutter run -d linux
```

```bash
flutter test
```

Codegen after touching `lib/data/db/tables.dart`:

```bash
dart run build_runner build
```

## Pending setup

**Fonts.** The design system specifies Geist and Geist Mono; the files are not vendored yet,
so type currently falls back to the platform default. Download from
[vercel/geist-font](https://github.com/vercel/geist-font) (MIT), drop the .ttf files in
`fonts/`, and declare them under `flutter: fonts:` in `pubspec.yaml`. `AppFont.ui` and
`AppFont.mono` already reference the family names.

**Android.** The SDK at `~/Android/Sdk` is missing two pieces. Install them from Android
Studio's SDK Manager (*Settings → Languages & Frameworks → Android SDK → SDK Tools*) so they
land in the existing SDK rather than a second one under `/opt`:

- Android SDK Command-line Tools (latest)
- NDK (Side by side) — needed because `sqlite3` 3.x builds its native library from source
  via Dart native assets

Then accept the licences and confirm:

```bash
flutter doctor --android-licenses
```

```bash
flutter devices
```

The Android performance gate needs a **physical device**, not the emulator — the emulator
does not tell the truth about fill rate, and fill rate is the whole question for glass.

## Layout

```
shaders/
  mesh_common.glsl   shared gradient function — the reason glass works without backdrop sampling
  mesh.frag          fullscreen backdrop
  glass.frag         one glass surface; reconstructs the backdrop at a refracted UV
lib/
  theme/tokens.dart  every colour, radius, space, duration
  ui/backdrop/       mesh backdrop, owns the clock, provides GlassRuntime
  ui/glass/          GlassSurface — the only glass in the app
  data/db/           Drift schema and generated code
  dev/frame_stats.dart  frame timing reporter (debug/profile only)
```
