import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../images/device_images.dart';
import '../../images/image_store.dart';
import '../../state/providers.dart';
import '../../state/sync_controller.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';

/// One image of a note, from its file on this device, or a quiet stand-in while its file is
/// still on its way from another device.
class NoteImageView extends ConsumerWidget {
  const NoteImageView({
    required this.image,
    this.fit = BoxFit.cover,
    this.decodeWidth,
    super.key,
  });

  final NoteImage image;
  final BoxFit fit;

  /// How wide it is decoded, in logical pixels, so a thumbnail does not hold a whole photo
  /// in memory. Null for its full size.
  final double? decodeWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(imageFolderProvider).value;
    final held = ref.watch(localImagesProvider).value?.contains(image.id) ?? false;

    if (folder == null || !held) return _Waiting(image: image);

    final ratio = MediaQuery.devicePixelRatioOf(context);
    return Image.file(
      ImageStore.fileIn(folder, image.id, image.mimeType),
      fit: fit,
      cacheWidth: decodeWidth == null ? null : (decodeWidth! * ratio).round(),
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, synchronous) => synchronous
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.standard,
              child: child,
            ),
      errorBuilder: (context, error, stack) => _Waiting(image: image, broken: true),
    );
  }
}

class _Waiting extends ConsumerWidget {
  const _Waiting({required this.image, this.broken = false});

  final NoteImage image;
  final bool broken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(syncProvider) is SyncOn;
    return ColoredBox(
      color: AppColour.fill,
      child: Center(
        child: Tooltip(
          message: broken
              ? 'This image could not be read'
              : syncing
              ? 'On its way from another device'
              : 'Sign in to sync, and this image arrives from the device that added it',
          child: Icon(
            broken ? Icons.broken_image_outlined : Icons.cloud_download_outlined,
            size: 20,
            color: AppColour.labelTertiary,
          ),
        ),
      ),
    );
  }
}

/// A note's images as tiles to open, each with a way to take it out of the note.
class NoteImageGrid extends ConsumerWidget {
  const NoteImageGrid({required this.images, super.key});

  final List<NoteImage> images;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = AppLayout.compact(context) ? 96.0 : 132.0;

    Future<void> remove(NoteImage image) async {
      final scope = ref.read(appScopeProvider).value;
      if (scope == null) return;
      await scope.noteImages.softDelete(image.id);
      ref
          .read(undoProvider.notifier)
          .offer('Removed an image', () => scope.noteImages.restore(image.id));
    }

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final (i, image) in images.indexed)
          FadeSlideIn(
            key: ValueKey(image.id),
            child: _Tile(
              size: size,
              image: image,
              onOpen: () => showImageViewer(context, images, i),
              onRemove: () => remove(image),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.size,
    required this.image,
    required this.onOpen,
    required this.onRemove,
  });

  final double size;
  final NoteImage image;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final touch = AppLayout.touch;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Pressable(
        onTap: widget.onOpen,
        pressedScale: 0.97,
        child: SizedBox.square(
          dimension: widget.size,
          child: ClipRRect(
            borderRadius: AppRadius.mediumAll,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NoteImageView(image: widget.image, decodeWidth: widget.size),
                // Under the pointer on a desktop; always there to a finger.
                Positioned(
                  top: AppSpace.xs,
                  right: AppSpace.xs,
                  child: AnimatedOpacity(
                    duration: AppMotion.of(context, AppMotion.quick),
                    opacity: touch || _hovered ? 1 : 0,
                    child: Tooltip(
                      message: 'Remove image',
                      child: GestureDetector(
                        key: ValueKey('remove-image-${widget.image.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onRemove,
                        child: Container(
                          width: AppSize.chip,
                          height: AppSize.chip,
                          decoration: const BoxDecoration(
                            color: AppMaterial.sheetTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 15, color: AppColour.label),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A note's images large, one at a time, to zoom into and move between.
Future<void> showImageViewer(BuildContext context, List<NoteImage> images, int index) =>
    showAppDialog<void>(
      context: context,
      builder: (context) => _Viewer(images: images, initial: index),
    );

class _Viewer extends StatefulWidget {
  const _Viewer({required this.images, required this.initial});

  final List<NoteImage> images;
  final int initial;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int by) {
    final next = (_index + by).clamp(0, widget.images.length - 1);
    _pages.animateToPage(
      next,
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
      },
      child: Focus(
        autofocus: true,
        child: Dialog.fullscreen(
          backgroundColor: AppColour.base,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: NoteImageView(image: widget.images[i], fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: AppSpace.lg,
                left: AppSpace.lg,
                right: AppSpace.lg,
                child: SafeArea(
                  child: Row(
                    children: [
                      if (count > 1)
                        Text('${_index + 1} of $count', style: AppText.callout),
                      const Spacer(),
                      _RoundButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (count > 1 && !AppLayout.touch) ...[
                Positioned(
                  left: AppSpace.lg,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _RoundButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Previous',
                      onTap: _index > 0 ? () => _go(-1) : null,
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpace.lg,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _RoundButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Next',
                      onTap: _index < count - 1 ? () => _go(1) : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: MouseRegion(
      cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Pressable(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: AppMotion.of(context, AppMotion.quick),
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            width: AppSize.touch,
            height: AppSize.touch,
            decoration: const BoxDecoration(color: AppColour.elevated, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: AppColour.label),
          ),
        ),
      ),
    ),
  );
}

/// Asks this device for images, and puts them in [noteId], or in a new note when there is
/// none yet. Returns the note they went into, or null when none were chosen.
///
/// [paste] takes the image on the clipboard instead of asking.
Future<String?> addImagesToNote(WidgetRef ref, {String? noteId, bool paste = false}) async {
  final device = ref.read(deviceImagesProvider);
  final picked = paste
      ? [?await device.paste()]
      : await device.pick();
  final scope = ref.read(appScopeProvider).value;
  if (picked.isEmpty || scope == null) return null;

  final id = noteId ?? (await scope.notes.create(workspaceId: scope.workspace.id)).id;
  for (final image in picked) {
    await scope.noteImages.add(workspaceId: scope.workspace.id, noteId: id, image: image);
  }
  return id;
}
