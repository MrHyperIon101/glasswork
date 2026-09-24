import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desktop/desktop_shell.dart';
import '../../theme/tokens.dart';
import '../motion.dart';

/// The window's own buttons, in the app rather than in a bar above it.
///
/// The Linux window is built without a title bar (`linux/runner/my_application.cc`): a
/// strip in the desktop's theme sitting on top of a window in Apple's is exactly the seam
/// the rest of the app is drawn to avoid. So close, minimise and zoom are drawn here, in
/// the corner of the app's own header, and ask the runner over the desktop channel.
///
/// Where there is no window to control — Android, a test with no runner answering —
/// [available] is false and nothing is drawn.
class WindowControls extends ConsumerStatefulWidget {
  const WindowControls({super.key});

  /// Whether this build has a window of its own to control.
  static bool get available => defaultTargetPlatform == TargetPlatform.linux;

  @override
  ConsumerState<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends ConsumerState<WindowControls> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!WindowControls.available) return const SizedBox.shrink();
    final shell = ref.watch(desktopShellProvider);
    final maximized = ref.watch(windowMaximizedProvider);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Button(
            key: const ValueKey('window-close'),
            tooltip: 'Close',
            colour: AppColour.red,
            glyph: Icons.close_rounded,
            lit: _hovered,
            onTap: shell.closeWindow,
          ),
          const SizedBox(width: AppSpace.sm),
          _Button(
            key: const ValueKey('window-minimize'),
            tooltip: 'Minimise',
            colour: AppColour.yellow,
            glyph: Icons.remove_rounded,
            lit: _hovered,
            onTap: shell.minimize,
          ),
          const SizedBox(width: AppSpace.sm),
          _Button(
            key: const ValueKey('window-zoom'),
            tooltip: maximized ? 'Restore' : 'Maximise',
            colour: AppColour.green,
            glyph: maximized
                ? Icons.close_fullscreen_rounded
                : Icons.open_in_full_rounded,
            lit: _hovered,
            onTap: () async => ref
                .read(windowMaximizedProvider.notifier)
                .set(await shell.toggleMaximize()),
          ),
        ],
      ),
    );
  }
}

/// One button: a coloured circle that shows what it does once the pointer is anywhere
/// near the three of them, which is how a Mac does it — three dots at rest, three buttons
/// when you go for one.
class _Button extends StatelessWidget {
  const _Button({
    required this.tooltip,
    required this.colour,
    required this.glyph,
    required this.lit,
    required this.onTap,
    super.key,
  });

  final String tooltip;
  final Color colour;
  final IconData glyph;
  final bool lit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    waitDuration: const Duration(milliseconds: 600),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.88,
        // The circle is small; what a pointer has to hit is not.
        child: SizedBox(
          width: AppSize.windowButton + AppSpace.sm,
          height: AppSize.touch,
          child: Center(
            child: Container(
              width: AppSize.windowButton,
              height: AppSize.windowButton,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: AppRadius.roundAll,
              ),
              child: AnimatedOpacity(
                duration: AppMotion.of(context, AppMotion.quick),
                curve: AppMotion.standard,
                opacity: lit ? 1 : 0,
                child: Icon(glyph, size: 9, color: AppColour.base),
              ),
            ),
          ),
        ),
      ),
    ),
  );
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => shell.startDrag(),
      onDoubleTap: () async =>
          ref.read(windowMaximizedProvider.notifier).set(await shell.toggleMaximize()),
      child: child,
    );
  }
}
