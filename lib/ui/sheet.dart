import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'layout.dart';
import 'motion.dart';
import 'surface.dart';

/// A sheet over the content: its scrim, its material, and where it sits.
///
/// Centred with a width cap on a desktop. On a phone it rises from the bottom and spans the
/// width: the thumb is down there, and the keyboard pushes it up from there anyway.
///
/// Keyboard focus moves into the sheet as it opens, and back to what had it once the sheet
/// closes. Without its own focus scope, a field asking for focus in a sheet was refused while
/// the screen behind held it: the new task sheet opened with nothing to type into, and Esc,
/// sent to the screen behind, closed nothing.
class ModalSheet extends StatefulWidget {
  const ModalSheet({
    required this.onClose,
    required this.child,
    this.maxWidth = 640,
    this.maxHeight = 720,
    this.alignment = const Alignment(0, -0.1),
    this.scrim = 0.62,
    super.key,
  });

  final VoidCallback onClose;
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  /// Where a centred sheet sits. Unused on a phone.
  final Alignment alignment;

  /// How dark the layer over the content gets.
  final double scrim;

  @override
  State<ModalSheet> createState() => _ModalSheetState();
}

class _ModalSheetState extends State<ModalSheet> {
  final _scope = FocusScopeNode(debugLabel: 'ModalSheet');

  @override
  void initState() {
    super.initState();
    // A field in the sheet that asks for focus has it by now. Otherwise the sheet itself
    // takes it, so its keys, Esc among them, reach it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_scope.hasFocus) _scope.requestFocus();
    });
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.compact(context);
    final onClose = widget.onClose;
    final scrim = widget.scrim;
    final child = FocusScope(node: _scope, child: widget.child);

    return Stack(
      children: [
        // Fades in on its own, so the sheet's spring is not muddied by it.
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.quick,
            builder: (context, t, _) => GestureDetector(
              onTap: onClose,
              child: ColoredBox(color: Color.fromRGBO(0, 0, 0, scrim * t)),
            ),
          ),
        ),
        if (compact)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.sm,
                AppSpace.huge,
                AppSpace.sm,
                AppSpace.sm,
              ),
              child: SpringIn(
                from: 1,
                slide: AppSpace.huge,
                child: VibrancyMaterial.sheet(
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          )
        else
          Align(
            alignment: widget.alignment,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: SpringIn(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.maxWidth,
                    maxHeight: widget.maxHeight,
                  ),
                  child: VibrancyMaterial.sheet(child: child),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
