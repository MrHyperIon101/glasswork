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

class _ModalSheetState extends State<ModalSheet> with SingleTickerProviderStateMixin {
  final _scope = FocusScopeNode(debugLabel: 'ModalSheet');

  /// Its own arrival, for a sheet shown without a [SheetPresence] to animate it.
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final presence = SheetAnimation.maybeOf(context);
    if (presence == null && _arrival.isDismissed) {
      _arrival
        ..duration = AppMotion.of(context, AppMotion.slow)
        ..forward();
    }
    // On its way out, the keys go back to what had them before it opened.
    if (presence != null && presence.closing && _scope.hasFocus) {
      _scope.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.compact(context);
    final animation =
        SheetAnimation.maybeOf(context)?.animation ??
        CurvedAnimation(parent: _arrival, curve: AppMotion.enter);
    final child = FocusScope(node: _scope, child: widget.child);

    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: animation,
            child: GestureDetector(
              onTap: widget.onClose,
              child: ColoredBox(color: Color.fromRGBO(0, 0, 0, widget.scrim)),
            ),
          ),
        ),
        if (compact)
          // Rises from the bottom edge, and sinks back into it.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.sm,
                AppSpace.huge,
                AppSpace.sm,
                AppSpace.sm,
              ),
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 1.1),
                  end: Offset.zero,
                ).animate(animation),
                child: VibrancyMaterial.sheet(
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          )
        else
          // Grows a little into place as it fades in, and back as it goes.
          Align(
            alignment: widget.alignment,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.0).animate(animation),
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
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
            ),
          ),
      ],
    );
  }
}
