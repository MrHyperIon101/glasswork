import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/note_text.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';

/// Somewhere to jot a note down without opening anything: type, and Return keeps it.
///
/// Shift and Return starts a new line. On a phone, where Return is how lines are made, the
/// arrow keeps it instead.
class QuickNoteField extends ConsumerStatefulWidget {
  const QuickNoteField({this.hint = 'Jot something down…', super.key});

  final String hint;

  @override
  ConsumerState<QuickNoteField> createState() => _QuickNoteFieldState();
}

class _QuickNoteFieldState extends ConsumerState<QuickNoteField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// The moment of the last save, for the tick that confirms it.
  int _saved = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _keep() async {
    final text = _controller.text;
    final scope = ref.read(appScopeProvider).value;
    if (text.trim().isEmpty || scope == null) return;
    _controller.clear();
    setState(() => _saved++);
    await scope.notes.capture(workspaceId: scope.workspace.id, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final touch = AppLayout.touch;
    final hasText = _controller.text.trim().isNotEmpty;
    final focused = _focus.hasFocus;

    return CallbackShortcuts(
      bindings: {
        if (!touch) const SingleActivator(LogicalKeyboardKey.enter): _keep,
      },
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.quick),
        curve: AppMotion.standard,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.xs,
          AppSpace.xs,
          AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: focused ? AppColour.fillStrong : AppColour.fill,
          borderRadius: AppRadius.mediumAll,
          border: Border.all(
            color: focused
                ? AppColour.yellow.withValues(alpha: 0.45)
                : AppColour.yellow.withValues(alpha: 0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  style: AppText.body,
                  cursorColor: AppColour.yellow,
                  cursorWidth: 1.5,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hint,
                    // One line, however narrow the field, rather than a column of words.
                    hintMaxLines: 1,
                    hintStyle: AppText.body.copyWith(color: AppColour.labelTertiary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            // A tick for a moment after keeping one, then the arrow again.
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.quick),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _saved > 0 && !hasText
                  ? _Saved(key: ValueKey('saved$_saved'), onDone: () {
                      if (mounted) setState(() => _saved = 0);
                    })
                  : Pressable(
                      key: const ValueKey('keep'),
                      onTap: hasText ? _keep : null,
                      child: AnimatedContainer(
                        duration: AppMotion.of(context, AppMotion.quick),
                        width: touch ? AppSize.touch - AppSpace.sm : AppSize.chip + AppSpace.xs,
                        height: touch ? AppSize.touch - AppSpace.sm : AppSize.chip + AppSpace.xs,
                        decoration: BoxDecoration(
                          color: hasText ? AppColour.yellow : AppColour.fill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: hasText ? AppColour.base : AppColour.labelTertiary,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A green tick that shows for a moment, then hands back.
class _Saved extends StatefulWidget {
  const _Saved({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  State<_Saved> createState() => _SavedState();
}

class _SavedState extends State<_Saved> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final size = AppLayout.touch ? AppSize.touch - AppSpace.sm : AppSize.chip + AppSpace.xs;
    return SizedBox.square(
      dimension: size,
      child: Center(child: AnimatedCheck(done: true, size: size - AppSpace.sm)),
    );
  }
}

/// A note as a card: what it is called, a taste of what it says, and when it was written.
class NoteCard extends ConsumerStatefulWidget {
  const NoteCard({required this.note, this.previewLines = 6, super.key});

  final Note note;
  final int previewLines;

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  bool _hovered = false;

  Future<void> _delete() async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;
    final note = widget.note;
    await scope.notes.softDelete(note.id);
    ref
        .read(undoProvider.notifier)
        .offer('Deleted "${NoteText.heading(note)}"', () => scope.notes.restore(note.id));
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final preview = NoteText.preview(note);
    final touch = AppLayout.touch;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Pressable(
        pressedScale: 0.98,
        onTap: () => ref.read(openNoteProvider.notifier).edit(note),
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.quick),
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.elevated : AppColour.surface,
            borderRadius: AppRadius.largeAll,
            border: Border.all(
              color: note.pinned
                  ? AppColour.yellow.withValues(alpha: 0.35)
                  : AppColour.separator.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      NoteText.heading(note),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.headline,
                    ),
                  ),
                  if (note.pinned) ...[
                    const SizedBox(width: AppSpace.sm),
                    const Icon(Icons.push_pin_rounded, size: 14, color: AppColour.yellow),
                  ],
                  // Revealed under the pointer, so cards stay calm at rest. A phone deletes
                  // from the note itself.
                  if (!touch)
                    AnimatedOpacity(
                      duration: AppMotion.of(context, AppMotion.quick),
                      opacity: _hovered ? 1 : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpace.sm),
                        child: GestureDetector(
                          onTap: _hovered ? _delete : null,
                          behavior: HitTestBehavior.opaque,
                          child: const Tooltip(
                            message: 'Delete note',
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: AppColour.labelTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  preview,
                  maxLines: widget.previewLines,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.callout,
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              Text(
                NoteText.when(NoteText.editedAt(note), DateTime.now()),
                style: AppText.numeric.copyWith(color: AppColour.labelTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
