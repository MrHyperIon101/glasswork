import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/app_config.dart';
import 'package:glasswork/theme/tokens.dart';

/// What the platforms show before any Dart runs: the app's name, its icon, and the colour
/// of its launch screen.
///
/// Each is spelled out in files Dart never reads — the Android manifest and resources, the
/// GTK runner, the Linux desktop entry. Every copy can drift from the app's own, and nothing
/// but this would notice before someone looked at a phone.
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// A PNG's width, height, and whether it has an alpha channel, from its header.
  ({int width, int height, bool alpha}) png(String path) {
    final bytes = File(path).readAsBytesSync();
    final header = ByteData.sublistView(bytes);
    return (
      width: header.getUint32(16),
      height: header.getUint32(20),
      alpha: bytes[25] == 6,
    );
  }

  String applicationId() => RegExp(
    r'set\(APPLICATION_ID "([^"]+)"\)',
  ).firstMatch(read('linux/CMakeLists.txt'))!.group(1)!;

  group('Android', () {
    const res = 'android/app/src/main/res';

    test('shows the app name under its icon', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('android:label="${AppConfig.name}"'));
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    });

    test('has every icon at every density, at the size for that density', () {
      const densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4};
      for (final MapEntry(key: density, value: scale) in densities.entries) {
        for (final (name, dp) in [
          ('ic_launcher', 48),
          ('ic_launcher_round', 48),
          ('ic_launcher_foreground', 108),
        ]) {
          final icon = png('$res/mipmap-$density/$name.png');
          final size = (dp * scale).round();
          expect((icon.width, icon.height), (size, size), reason: '$density/$name');
          expect(icon.alpha, isTrue, reason: '$density/$name is round, so needs alpha');
        }
      }
    });

    test('its adaptive icons are the disc on a clear background', () {
      for (final name in ['ic_launcher', 'ic_launcher_round']) {
        final icon = read('$res/mipmap-anydpi-v26/$name.xml');
        expect(icon, contains('@android:color/transparent'), reason: name);
        expect(icon, contains('@mipmap/ic_launcher_foreground'), reason: name);
      }
    });

    test("launches on the app's own background, not a white flash", () {
      final colour = RegExp(
        r'<color name="app_background">#([0-9A-Fa-f]{6})</color>',
      ).firstMatch(read('$res/values/colors.xml'));
      expect(colour, isNotNull);
      expect(
        0xFF000000 | int.parse(colour!.group(1)!, radix: 16),
        AppColour.base.toARGB32(),
      );

      expect(
        read('$res/values/themes.xml'),
        isNot(contains('Theme.Light')),
        reason: 'the app is dark in both system modes',
      );
      expect(
        read('$res/values-v31/themes.xml'),
        contains(
          '<item name="android:windowSplashScreenBackground">@color/app_background</item>',
        ),
      );
      expect(
        Directory('$res/values-night').existsSync(),
        isFalse,
        reason: 'a night theme would take precedence over values-v31 and lose its splash colour',
      );
    });
  });

  group('Linux', () {
    test('the window and the app grid show the app name', () {
      final titles = RegExp(
        r'set_title\([^,]+,\s*"([^"]*)"\)',
      ).allMatches(read('linux/runner/my_application.cc')).map((m) => m.group(1));
      expect(titles, isNotEmpty);
      expect(titles, everyElement(AppConfig.name));

      final entry = read('linux/packaging/${applicationId()}.desktop');
      expect(entry, contains('\nName=${AppConfig.name}\n'));
    });

    test('the desktop entry, its icon and the window share one application id', () {
      // GNOME on Wayland matches a window to its entry, and so to its icon, by this id.
      final id = applicationId();
      final entry = read('linux/packaging/$id.desktop');
      expect(entry, contains('\nIcon=$id\n'));
      expect(entry, contains('\nStartupWMClass=$id\n'));
      expect(entry, contains('\nExec=@EXEC@\n'), reason: 'the installer fills it in');

      for (final size in [16, 24, 32, 48, 64, 128, 256, 512]) {
        final icon = png('linux/packaging/icons/${size}x$size/apps/$id.png');
        expect((icon.width, icon.height), (size, size));
        expect(icon.alpha, isTrue);
      }
    });
  });
}
