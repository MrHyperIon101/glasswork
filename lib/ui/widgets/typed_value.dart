import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../layout.dart';

/// A value that can be typed as well as stepped.
///
/// Stepping a start time from 09:00 to midnight a quarter hour at a time took thirty-six
/// taps. This takes the text as typed and hands it to [onSubmit], which decides whether it
/// can be read. Text it cannot read is put back, never guessed at.
class TypedValue extends StatefulWidget {
  const TypedValue({
    required this.text,
    required this.onSubmit,
    this.onEdit,
    this.keyboardType = TextInputType.text,
    this.error = false,
    super.key,
  });

  /// The value as it reads when nobody is typing into it.
  final String text;

  /// Called with the text when typing finishes. Returns whether it could be read; when it
  /// could not, the field goes back to [text].
  final bool Function(String text) onSubmit;

  /// Called on every keystroke, for checks that should follow the typing.
  final ValueChanged<String>? onEdit;

  final TextInputType keyboardType;

  /// Marks the value as unusable, for a reason decided outside.
  final bool error;

  /// Room for "12:30pm" or "10h 45m".
  static const width = 84.0;

  @override
  State<TypedValue> createState() => _TypedValueState();
}

class _TypedValueState extends State<TypedValue> {
  late final _controller = TextEditingController(text: widget.text);
  final _focus = FocusNode();

  /// Typed into since the value was last set.
  bool _dirty = false;

  /// A keystroke this frame may change [TypedValue.text], and that change is the owner
  /// taking in the typing, not a new value to show over it.
  bool _typing = false;

  /// The last text typed could not be read.
  bool _rejected = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(TypedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == oldWidget.text) {
      if (!_focus.hasFocus && _controller.text != widget.text) {
        _controller.text = widget.text;
      }
      return;
    }
    if (_typing) return;

    // Set from outside: a step, a suggested time, a change from another device. It replaces
    // whatever was typed, which must not come back when the field loses focus.
    _controller.value = TextEditingValue(
      text: widget.text,
      selection: TextSelection.collapsed(offset: widget.text.length),
    );
    _dirty = false;
    _rejected = false;
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (_focus.hasFocus) {
      _rejected = false;
      // Selected, so typing replaces the value instead of adding to it.
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      if (_dirty) {
        _dirty = false;
        _rejected = !widget.onSubmit(_controller.text);
      }
      // Shown as its owner formats it once the change has been taken in, which can be a
      // frame, or a database write, away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focus.hasFocus) _controller.text = widget.text;
      });
    }
    setState(() {});
  }

  void _edited(String text) {
    _dirty = true;
    _typing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _typing = false);
    if (_rejected) setState(() => _rejected = false);
    widget.onEdit?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final error = _rejected || widget.error;
    final focused = _focus.hasFocus;

    return AnimatedContainer(
      duration: AppMotion.quick,
      width: TypedValue.width,
      height: AppLayout.touch ? AppSize.touch - AppSpace.sm : AppSize.chip,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      decoration: BoxDecoration(
        color: focused ? AppColour.fillStrong : AppColour.fill,
        borderRadius: AppRadius.smallAll,
        border: Border.all(
          color: error
              ? AppColour.red
              : focused
              ? AppColour.accent
              : Colors.transparent,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: AppText.numeric.copyWith(
          color: error ? AppColour.red : AppColour.label,
        ),
        cursorColor: AppColour.accent,
        cursorWidth: 1.5,
        onChanged: _edited,
        onSubmitted: (_) => _focus.unfocus(),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
