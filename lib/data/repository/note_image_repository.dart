import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../images/device_images.dart';
import '../../images/image_store.dart';
import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../order_key.dart';

/// Images in notes.
///
/// Local-first like everything else: an image added is a file on this device and a row in
/// the database before anything goes near the network, and shows at once. The row syncs
/// through [SyncWriter]; the bytes go to storage afterwards, in `ImageSync`, and come down to
/// other devices the same way. Deleting is a tombstone with undo, and leaves the bytes where
/// they are, so an undo on any device finds them.
class NoteImageRepository {
  NoteImageRepository(this._writer, this._store);

  final SyncWriter _writer;
  final ImageStore _store;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  /// Every live image in the workspace, each note's in its order.
  Stream<List<NoteImage>> watchAll(String workspaceId) =>
      (_db.select(_db.noteImages)
            ..where((i) => i.workspaceId.equals(workspaceId) & i.deletedAt.isNull())
            ..orderBy([
              (i) => OrderingTerm(expression: i.noteId),
              (i) => OrderingTerm(expression: i.orderKey),
              (i) => OrderingTerm(expression: i.clientId),
            ]))
          .watch();

  /// The images this device holds the files of.
  Stream<Set<String>> watchLocal() =>
      _db.select(_db.imageFiles).watch().map((rows) => {for (final row in rows) row.imageId});

  /// Adds [image] to the end of [noteId]'s images.
  Future<NoteImage> add({
    required String workspaceId,
    required String noteId,
    required PickedImage image,
  }) async {
    final id = _uuid.v4();
    // The file first: a row whose file is not there yet would show as missing.
    await _store.write(id, image.mime, image.bytes);

    return _db.transaction(() async {
      final last =
          await (_db.select(_db.noteImages)
                ..where((i) => i.noteId.equals(noteId))
                ..orderBy([(i) => OrderingTerm.desc(i.orderKey)])
                ..limit(1))
              .getSingleOrNull();
      final row = await _writer.insert(
        _db.noteImages,
        NoteImagesCompanion.insert(
          id: id,
          workspaceId: workspaceId,
          noteId: noteId,
          storagePath: '$workspaceId/$id.${ImageStore.extensionFor(image.mime)}',
          mimeType: image.mime,
          width: image.width,
          height: image.height,
          byteCount: image.bytes.length,
          orderKey: last == null ? OrderKey.first : OrderKey.after(last.orderKey),
        ),
      );
      // Held here, and not yet in storage.
      await _db.into(_db.imageFiles).insertOnConflictUpdate(
        ImageFilesCompanion.insert(imageId: id, stored: const Value(false)),
      );
      return row;
    });
  }

  Future<void> softDelete(String id) =>
      _writer.update(_db.noteImages, id, NoteImagesCompanion(deletedAt: Value(DateTime.now())));

  Future<void> restore(String id) =>
      _writer.update(_db.noteImages, id, const NoteImagesCompanion(deletedAt: Value(null)));
}
