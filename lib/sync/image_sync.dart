import 'package:drift/drift.dart';
import 'package:supabase/supabase.dart';

import '../data/db/database.dart';
import '../images/image_store.dart';

/// Where the bytes of note images go to reach other devices, and come from.
///
/// An interface for the same reason the transport is one: what matters — send what storage
/// lacks, fetch what this device lacks, keep going past one that is not there yet — is proved
/// against a fake with no network at all.
abstract interface class ImageBlobs {
  /// Sends [bytes] to [path]. Bytes already there count as sent.
  Future<void> upload(String path, Uint8List bytes, String mime);

  /// The bytes at [path]. Throws [ImageNotStoredException] when there are none yet.
  Future<Uint8List> download(String path);
}

/// Storage refused an image's bytes: not a network failure, and trying again will not
/// change it, so it must not stop the images after it from going.
class ImageRefusedException implements Exception {
  const ImageRefusedException(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'storage refused $path: $reason';
}

/// Storage has no bytes at a path, because the device that added the image has not sent
/// them yet.
class ImageNotStoredException implements Exception {
  const ImageNotStoredException(this.path);

  final String path;

  @override
  String toString() => 'no image stored at $path yet';
}

/// What one pass did.
class ImageSyncReport {
  const ImageSyncReport({
    this.sent = 0,
    this.fetched = 0,
    this.waiting = 0,
    this.refused = 0,
    this.more = false,
  });

  final int sent;
  final int fetched;

  /// Images storage would not take. Left unsent, and tried again next time.
  final int refused;

  /// Images another device added and has not sent yet, to try again for soon.
  final int waiting;

  /// Whether there was more than one pass takes, so another should follow.
  final bool more;
}

/// Sends the image files this device holds and storage lacks, and fetches the ones it lacks.
///
/// Runs after rows have synced, never in a UI path: an image shows from its file on the
/// device that added it at once, and on others as soon as its bytes arrive. A tombstoned
/// image is still sent, since undoing the delete on another device needs it there.
class ImageSync {
  ImageSync({required AppDatabase db, required ImageStore store, required ImageBlobs blobs})
    : _db = db,
      _store = store,
      _blobs = blobs;

  final AppDatabase _db;
  final ImageStore _store;
  final ImageBlobs _blobs;

  /// Files sent or fetched in one pass, so a first sync of many images is spread out.
  static const batch = 20;

  /// Throws what stopped it — most likely no connection — having kept everything done so far.
  Future<ImageSyncReport> run() async {
    var sent = 0;
    var fetched = 0;
    var waiting = 0;
    var refused = 0;

    // Up: held here, not yet in storage.
    final unsent =
        await (_db.select(_db.noteImages).join([
                innerJoin(_db.imageFiles, _db.imageFiles.imageId.equalsExp(_db.noteImages.id)),
              ])
              ..where(_db.imageFiles.stored.equals(false))
              ..limit(batch + 1))
            .map((row) => row.readTable(_db.noteImages))
            .get();
    for (final image in unsent.take(batch)) {
      final bytes = await _store.read(image.id, image.mimeType);
      // Its file is gone from this device, so there is nothing to send.
      if (bytes == null) continue;
      try {
        await _blobs.upload(image.storagePath, bytes, image.mimeType);
      } on ImageRefusedException {
        refused++;
        continue;
      }
      await _markHeld(image.id);
      sent++;
    }

    // Down: live images this device has no file of.
    final missing =
        await (_db.select(_db.noteImages)
              ..where(
                (i) =>
                    i.deletedAt.isNull() &
                    i.id.isNotInQuery(_db.selectOnly(_db.imageFiles)..addColumns([_db.imageFiles.imageId])),
              )
              ..limit(batch + 1))
            .get();
    for (final image in missing.take(batch)) {
      try {
        final bytes = await _blobs.download(image.storagePath);
        await _store.write(image.id, image.mimeType, bytes);
        await _markHeld(image.id);
        fetched++;
      } on ImageNotStoredException {
        waiting++;
      }
    }

    return ImageSyncReport(
      sent: sent,
      fetched: fetched,
      waiting: waiting,
      refused: refused,
      // Refused ones stay unsent, and would otherwise read as more to do every time.
      more: unsent.length - refused > batch || missing.length > batch,
    );
  }

  /// This device holds the file, and storage has it too.
  Future<void> _markHeld(String imageId) => _db
      .into(_db.imageFiles)
      .insertOnConflictUpdate(ImageFilesCompanion.insert(imageId: imageId, stored: const Value(true)));
}

/// [ImageBlobs] in the project's storage, in the private `note-images` bucket, where a device
/// may read and add only its own workspaces' folders.
class SupabaseImageBlobs implements ImageBlobs {
  SupabaseImageBlobs(this._client);

  static const bucket = 'note-images';

  final SupabaseClient _client;

  @override
  Future<void> upload(String path, Uint8List bytes, String mime) async {
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    } on StorageException catch (error) {
      // Sent before, by a pass that stopped before it could say so.
      if (error.statusCode == '409' || error.message.toLowerCase().contains('exists')) return;
      // Not allowed there, or not an image storage takes: no retry will change that.
      if (error.statusCode == '403' ||
          error.statusCode == '413' ||
          error.statusCode == '415' ||
          error.message.toLowerCase().contains('security policy')) {
        throw ImageRefusedException(path, error.message);
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List> download(String path) async {
    try {
      return await _client.storage.from(bucket).download(path);
    } on StorageException catch (error) {
      if (error.statusCode == '404' ||
          error.statusCode == '400' ||
          error.message.toLowerCase().contains('not found')) {
        throw ImageNotStoredException(path);
      }
      rethrow;
    }
  }
}
