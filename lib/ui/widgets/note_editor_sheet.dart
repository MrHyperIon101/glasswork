import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/note_text.dart';
import '../../images/device_images.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';
import '../sheet.dart';
import '../surface.dart';
import 'field_controls.dart';
import 'note_images.dart';

/// A note, open to write in.
///
/// Everything saves as it is typed, as the task sheet does. A new note has no row at all
/// until something is typed into it, so opening one and closing it again leaves nothing
/// behind on this device or any other.
class NoteEditorSheet extends ConsumerWidget {
  const NoteEditorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(openNoteProvider);
    void close() => ref.read(openNoteProvider.notifier).close();

    return SheetPresence(
      open: editing != null,
      builder: (context) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
        child: ModalSheet(
          onClose: close,
          maxWidth: 680,
          maxHeight: 760,
          alignment: const Alignment(0, -0.15),
          child: _Editor(
            key: ValueKey(editing!.serial),
            note: editing.note,
            onClose: close,
          ),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.note, required this.onClose, super.key});

  /// Null for a new note.
  final Note? note;
  final VoidCallback onClose;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _body = TextEditingController(text: widget.note?.bodyMd ?? '');

  late String? _id = widget.note?.id;
  late String _writtenTitle = widget.note?.title ?? '';
  late String _writtenBody = widget.note?.bodyMd ?? '';

  /// Saves in the order they were asked for, one at a time, so a note being created is
  /// never created twice by fast typing.
  Future<void> _saving = Future.value();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    _saving = _saving.then((_) => _save());
  }

  Future<void> _save() async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;
    final title = _title.text;
    final body = _body.text;

    final id = _id;
    if (id == null) {
      if (title.trim().isEmpty && body.trim().isEmpty) return;
      final note = await scope.notes.create(
        workspaceId: scope.workspace.id,
        title: title,
        body: body,
      );
      _id = note.id;
      _writtenTitle = title;
      _writtenBody = body;
      return;
    }
    if (title != _writtenTitle) {
      _writtenTitle = title;
      await scope.notes.setTitle(id, title);
    }
    if (body != _writtenBody) {
      _writtenBody = body;
      await scope.notes.setBody(id, body);
    }
  }

  Future<void> _togglePin(bool pinned) async {
    await _saving;
    final scope = ref.read(appScopeProvider).value;
    final id = _id;
    if (scope == null || id == null) return;
    await scope.notes.setPinned(id, pinned: !pinned);
  }

  /// Images chosen, or the one pasted, added to this note, which they make if it is new.
  Future<void> _addImages({bool paste = false}) async {
    await _saving;
    final id = await addImagesToNote(ref, noteId: _id, paste: paste);
    if (id != null && mounted && _id == null) setState(() => _id = id);
  }

  Future<void> _delete() async {
    await _saving;
    final scope = ref.read(appScopeProvider).value;
    final id = _id;
    widget.onClose();
    if (scope == null || id == null) return;
    final heading = NoteText.heading(
      (widget.note ?? _draft()).copyWith(title: _title.text, bodyMd: _body.text),
      images: ref.read(noteImagesProvider).value?[id]?.length ?? 0,
    );
    await scope.notes.softDelete(id);
    ref
        .read(undoProvider.notifier)
        .offer('Deleted "$heading"', () => scope.notes.restore(id));
  }

  Note _draft() => Note(
    id: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    fieldVersions: '{}',
    workspaceId: '',
    title: '',
    bodyMd: '',
    pinned: false,
  );

  @override
  Widget build(BuildContext context) {
    // The note as it stands, for its pin and when it was written.
    final live = _id == null
        ? null
        : (ref.watch(notesProvider).value ?? const <Note>[])
              .where((n) => n.id == _id)
              .firstOrNull;
    final pinned = live?.pinned ?? false;
    final exists = _id != null;
    final compact = AppLayout.compact(context);
    final images = _id == null
        ? const <NoteImage>[]
        : ref.watch(noteImagesProvider).value?[_id] ?? const <NoteImage>[];
    final device = ref.watch(deviceImagesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.md,
            AppSpace.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppColour.yellow),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.quick),
                  child: Text(
                    key: ValueKey(exists),
                    exists
                        ? 'Saved · ${NoteText.when(live == null ? DateTime.now() : NoteText.editedAt(live), DateTime.now())}'
                        : 'New note',
                    style: AppText.footnote,
                  ),
                ),
              ),
              _ToolButton(
                key: const ValueKey('note-add-images'),
                icon: Icons.add_photo_alternate_outlined,
                tooltip: 'Add images',
                onTap: _addImages,
              ),
              if (device.canPaste)
                _ToolButton(
                  icon: Icons.content_paste_rounded,
                  tooltip: 'Paste an image',
                  onTap: () => _addImages(paste: true),
                ),
              _ToolButton(
                icon: pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                tooltip: pinned ? 'Unpin' : 'Pin to the top',
                tint: pinned ? AppColour.yellow : null,
                onTap: exists ? () => _togglePin(pinned) : null,
              ),
              _ToolButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete note',
                onTap: exists ? _delete : null,
              ),
              const SizedBox(width: AppSpace.xs),
              PrimaryButton(label: 'Done', enabled: true, onTap: widget.onClose),
            ],
          ),
        ),
        const AppDivider(),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? AppSpace.lg : AppSpace.xxl,
              AppSpace.lg,
              compact ? AppSpace.lg : AppSpace.xxl,
              AppSpace.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('note-title'),
                  controller: _title,
                  autofocus: widget.note == null,
                  onChanged: (_) => _changed(),
                  style: AppText.title,
                  cursorColor: AppColour.yellow,
                  cursorWidth: 1.5,
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Title',
                    hintStyle: AppText.title.copyWith(color: AppColour.labelQuaternary),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.medium),
                  curve: AppMotion.standard,
                  alignment: Alignment.topCenter,
                  child: images.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.lg),
                          child: NoteImageGrid(images: images),
                        ),
                ),
                TextField(
                  key: const ValueKey('note-body'),
                  controller: _body,
                  onChanged: (_) => _changed(),
                  style: AppText.body.copyWith(height: 1.55),
                  cursorColor: AppColour.yellow,
                  cursorWidth: 1.5,
                  minLines: compact ? 6 : 12,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Start writing…',
                    hintStyle: AppText.body.copyWith(color: AppColour.labelTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatefulWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tint,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final size = AppLayout.touch ? AppSize.touch : AppSize.control;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Pressable(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.quick),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _hovered && enabled ? AppColour.fill : null,
              borderRadius: AppRadius.mediumAll,
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: !enabled
                  ? AppColour.labelQuaternary
                  : widget.tint ?? AppColour.labelSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
