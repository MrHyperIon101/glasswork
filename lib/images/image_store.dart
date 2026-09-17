import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Where this device keeps the bytes of note images: a file each, named by the image, in
/// the app's own data folder, never the person's Pictures.
class ImageStore {
  ImageStore(this._folder);

  final Future<Directory> Function() _folder;

  static String extensionFor(String mime) => switch (mime) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'jpg',
  };

  Future<File> fileFor(String imageId, String mime) async => fileIn(await _folder(), imageId, mime);

  /// Where [imageId]'s file is in [folder], for a widget that has the folder already.
  static File fileIn(Directory folder, String imageId, String mime) =>
      File('${folder.path}/$imageId.${extensionFor(mime)}');

  /// Writes the bytes whole or not at all: to a file beside it, then renamed into place, so
  /// an image is never half there after the app is closed mid-write.
  Future<File> write(String imageId, String mime, Uint8List bytes) async {
    final file = await fileFor(imageId, mime);
    await file.parent.create(recursive: true);
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    return partial.rename(file.path);
  }

  Future<Uint8List?> read(String imageId, String mime) async {
    final file = await fileFor(imageId, mime);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<bool> has(String imageId, String mime) async =>
      (await fileFor(imageId, mime)).exists();
}

/// The folder image files are kept in on this device.
final imageFolderProvider = FutureProvider<Directory>(
  (ref) async => Directory('${(await getApplicationSupportDirectory()).path}/note_images'),
);

final imageStoreProvider = Provider<ImageStore>(
  (ref) => ImageStore(() => ref.read(imageFolderProvider.future)),
);
