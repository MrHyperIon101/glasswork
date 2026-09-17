import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/repository/note_image_repository.dart';
import 'package:glasswork/data/repository/note_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/images/device_images.dart';
import 'package:glasswork/images/image_store.dart';
import 'package:glasswork/sync/image_sync.dart';
import 'package:glasswork/sync/sync_writer.dart';

/// Storage as a map, with a way to fail.
class FakeBlobs implements ImageBlobs {
  final stored = <String, Uint8List>{};
  final uploads = <String>[];
  Object? failUploads;

  /// Paths storage will not take.
  final refuse = <String>{};

  @override
  Future<void> upload(String path, Uint8List bytes, String mime) async {
    if (failUploads case final error?) throw error;
    if (refuse.contains(path)) throw ImageRefusedException(path, 'new row violates row-level security policy');
    uploads.add(path);
    stored[path] = bytes;
  }

  @override
  Future<Uint8List> download(String path) async =>
      stored[path] ?? (throw ImageNotStoredException(path));
}

PickedImage picture(int shade) => PickedImage(
  bytes: Uint8List.fromList(List.filled(64, shade)),
  width: 8,
  height: 8,
  mime: 'image/jpeg',
);

void main() {
  late AppDatabase db;
  late SyncWriter writer;
  late Directory folder;
  late ImageStore store;
  late FakeBlobs blobs;
  late NoteImageRepository images;
  late ImageSync sync;
  late String workspaceId;
  late String noteId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    writer = SyncWriter(db, clientId: 'laptop');
    workspaceId = (await WorkspaceRepository(writer).ensureSeeded()).id;
    noteId = (await NoteRepository(writer).create(workspaceId: workspaceId, title: 'Whiteboard')).id;
    folder = await Directory.systemTemp.createTemp('glasswork_images_');
    store = ImageStore(() async => folder);
    blobs = FakeBlobs();
    images = NoteImageRepository(writer, store);
    sync = ImageSync(db: db, store: store, blobs: blobs);
  });

  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });

  /// A row as another device's image arrives in a pull: no file here.
  Future<NoteImage> arrived(String id, {DateTime? deletedAt}) => writer.insert(
    db.noteImages,
    NoteImagesCompanion.insert(
      id: id,
      workspaceId: workspaceId,
      noteId: noteId,
      storagePath: '$workspaceId/$id.jpg',
      mimeType: 'image/jpeg',
      width: 8,
      height: 8,
      byteCount: 64,
      orderKey: 'a0',
      deletedAt: Value(deletedAt),
    ),
  );

  test('an image added is a file and a row at once, and goes up on the next pass', () async {
    final image = await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(7));

    expect(await store.read(image.id, image.mimeType), picture(7).bytes);
    expect(image.storagePath, '$workspaceId/${image.id}.jpg');
    expect(await images.watchLocal().first, {image.id});

    final report = await sync.run();
    expect((report.sent, report.fetched), (1, 0));
    expect(blobs.stored[image.storagePath], picture(7).bytes);

    expect((await sync.run()).sent, 0, reason: 'sent once, and known to be there');
  });

  test("another device's image comes down; one it has not sent yet is waited for", () async {
    final ready = await arrived('11111111-0000-4000-8000-000000000001');
    final early = await arrived('11111111-0000-4000-8000-000000000002');
    blobs.stored[ready.storagePath] = picture(3).bytes;

    var report = await sync.run();
    expect((report.fetched, report.waiting), (1, 1));
    expect(await store.read(ready.id, ready.mimeType), picture(3).bytes);
    expect(await store.has(early.id, early.mimeType), isFalse);

    blobs.stored[early.storagePath] = picture(4).bytes;
    report = await sync.run();
    expect((report.fetched, report.waiting), (1, 0));
    expect(await images.watchLocal().first, {ready.id, early.id});
    expect(blobs.uploads, isEmpty, reason: 'what came from storage is not sent back');
  });

  test('a deleted image is still sent, for an undo elsewhere, but never fetched', () async {
    final mine = await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(1));
    await images.softDelete(mine.id);
    final theirs = await arrived('22222222-0000-4000-8000-000000000001', deletedAt: DateTime.now());
    blobs.stored[theirs.storagePath] = picture(2).bytes;

    final report = await sync.run();
    expect((report.sent, report.fetched), (1, 0));
    expect(await store.has(theirs.id, theirs.mimeType), isFalse);
  });

  test('a pass that cannot reach storage stops, and keeps what it had done', () async {
    final first = await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(1));
    await sync.run();
    await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(2));
    blobs.failUploads = const SocketException('offline');

    await expectLater(sync.run(), throwsA(isA<SocketException>()));
    expect(blobs.stored.keys, [first.storagePath]);

    blobs.failUploads = null;
    expect((await sync.run()).sent, 1, reason: 'the one not sent goes next time');
  });

  test('an image storage refuses is left unsent, and the images after it still go', () async {
    final refused = await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(1));
    final fine = await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(2));
    blobs.refuse.add(refused.storagePath);

    final report = await sync.run();
    expect((report.sent, report.refused, report.more), (1, 1, false));
    expect(blobs.stored.keys, [fine.storagePath]);
  });

  test('many images go a batch at a time, and say there is more', () async {
    for (var i = 0; i < ImageSync.batch + 5; i++) {
      await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(i));
    }
    final first = await sync.run();
    expect((first.sent, first.more), (ImageSync.batch, true));
    final second = await sync.run();
    expect((second.sent, second.more), (5, false));
  });

  test('deleting is a tombstone that undo lifts, and the file stays', () async {
    final image = await images.add(workspaceId: workspaceId, noteId: noteId, image: picture(9));
    await images.softDelete(image.id);
    expect(await images.watchAll(workspaceId).first, isEmpty);
    expect(await store.has(image.id, image.mimeType), isTrue);

    await images.restore(image.id);
    expect([for (final i in await images.watchAll(workspaceId).first) i.id], [image.id]);
  });
}
