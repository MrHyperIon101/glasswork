import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An image made ready for a note by the platform: upright, no longer than 2048 pixels on
/// its longest side, and a JPEG, or a PNG where it has transparency to keep.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.mime,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final String mime;

  /// An image as the platform sends one, or null for anything else.
  static PickedImage? fromPlatform(Object? value) {
    if (value is! Map) return null;
    final bytes = value['bytes'];
    final width = value['width'];
    final height = value['height'];
    final mime = value['mime'];
    if (bytes is! Uint8List || width is! int || height is! int || mime is! String) {
      return null;
    }
    if (bytes.isEmpty || width <= 0 || height <= 0 || !mime.startsWith('image/')) return null;
    return PickedImage(bytes: bytes, width: width, height: height, mime: mime);
  }
}

/// Where images for notes come from on this device: the photo picker on a phone, the file
/// chooser and the clipboard on a desktop. The platform side is `MainActivity.kt` and
/// `linux/runner/images_channel.cc`, over the `dev.mrhyperion.glasswork/images` channel.
class DeviceImages {
  DeviceImages([MethodChannel? channel]) : _channel = channel ?? const MethodChannel(name);

  static const name = 'dev.mrhyperion.glasswork/images';

  final MethodChannel _channel;

  /// Images chosen, each made ready. Empty when none were, or nothing here can choose.
  Future<List<PickedImage>> pick() async {
    final picked = await _call<List<Object?>>('pickImages');
    return [
      for (final value in picked ?? const <Object?>[]) ?PickedImage.fromPlatform(value),
    ];
  }

  /// Only a desktop has a clipboard this can paste an image from.
  bool get canPaste => defaultTargetPlatform == TargetPlatform.linux;

  /// The image on the clipboard, or null when there is none.
  Future<PickedImage?> paste() async =>
      canPaste ? PickedImage.fromPlatform(await _call<Object?>('pasteImage')) : null;

  Future<T?> _call<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('Images: $method failed: ${error.message}');
      return null;
    }
  }
}

final deviceImagesProvider = Provider<DeviceImages>((ref) => DeviceImages());
