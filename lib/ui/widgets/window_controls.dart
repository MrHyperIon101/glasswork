import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desktop/desktop_shell.dart';
import '../../theme/tokens.dart';
import '../motion.dart';

/// The window's own buttons, in the app rather than in a bar above it.
///
/// The Linux window is built without a title bar (`linux/runner/my_application.cc`): a
/// strip in the desktop's theme sitting on top of a window drawn in this one is exactly the
/// seam the rest of the app avoids. So minimise, maximise and close are one capsule at the
/// top-right of the app's own header — the same pill Voxtrona draws — and ask the runner
/// over the desktop channel.
///
/// Where there is no window to control — Android, a test with no runner answering —
/// [available] is false and nothing is drawn.
class WindowControls extends ConsumerWidget {
  const WindowControls({super.key});

  /// Whether this build has a window of its own to control.
  static bool get available => defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!available) return const SizedBox.shrink();
    final shell = ref.watch(desktopShellProvider);
    final maximized = ref.watch(windowMaximizedProvider);

    return Container(
      height: AppSize.windowPill,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      decoration: const BoxDecoration(
        color: AppMaterial.windowPillTint,
        borderRadius: AppRadius.roundAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Button(
            key: const ValueKey('window-minimize'),
            tooltip: 'Minimise',
            glyph: Icons.remove_rounded,
            onTap: shell.minimize,
          ),
          const SizedBox(width: AppSpace.xs),
          _Button(
            key: const ValueKey('window-zoom'),
            tooltip: maximized ? 'Restore' : 'Maximise',
            glyph: maximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
            // The square is drawn smaller than the other two, so the three read as one size.
            glyphSize: _Button.squareGlyph,
            onTap: () async => ref
                .read(windowMaximizedProvider.notifier)
                .set(await shell.toggleMaximize()),
          ),
          const SizedBox(width: AppSpace.xs),
          _Button(
            key: const ValueKey('window-close'),
            tooltip: 'Close',
            glyph: Icons.close_rounded,
            danger: true,
            onTap: shell.closeWindow,
          ),
        ],
      ),
    );
  }
}

/// One button in the pill: a glyph, and a circle that fills only under the pointer — red
/// for close, the way a window's close button warns before it is pressed.
class _Button extends StatefulWidget {
  const _Button({
    required this.tooltip,
    required this.glyph,
    required this.onTap,
    this.glyphSize = standardGlyph,
    this.danger = false,
    super.key,
  });

  static const standardGlyph = 18.0;
  static const squareGlyph = 15.0;

  final String tooltip;
  final IconData glyph;
  final double glyphSize;
  final bool danger;
  final VoidCallback onTap;

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fill = !_hovered
        ? AppColour.fill.withValues(alpha: 0)
        : widget.danger
        ? AppColour.red
        : AppColour.fill;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Pressable(
          onTap: widget.onTap,
          pressedScale: 0.92,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.quick),
            curve: AppMotion.standard,
            width: AppSize.windowButton,
            height: AppSize.windowButton,
            decoration: BoxDecoration(color: fill, borderRadius: AppRadius.roundAll),
            child: Icon(
              widget.glyph,
              size: widget.glyphSize,
              color: AppColour.label.withValues(alpha: _hovered ? 1 : 0.86),
            ),
          ),
        ),
      ),
    );
  }
}

/// Makes [child] the window's handle: dragging it moves the window, and a double click
/// maximises or restores it — the two things a title bar did that the buttons do not.
///
/// Translucent, so what is inside it still takes its own taps: a drag that starts on
/// empty header space moves the window, a click on a button is that button's.
class WindowDrag extends ConsumerWidget {
  const WindowDrag({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!WindowControls.available) return child;
    final shell = ref.watch(desktopShellProvider);

    // All of its area, not only what is drawn in it: the empty part of a title bar is the
    // part people grab.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => shell.startDrag(),
      onDoubleTap: () async =>
          ref.read(windowMaximizedProvider.notifier).set(await shell.toggleMaximize()),
      child: child,
    );
  }
}
