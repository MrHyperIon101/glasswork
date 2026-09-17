/// The app's name lives here and nowhere else. Renaming it is a one-line change.
abstract final class AppConfig {
  static const name = 'Glasswork';

  /// The version pubspec.yaml builds, as Settings shows it. A test holds the two together;
  /// bump both for every release.
  static const version = '0.5.1+7';

  /// "0.3.0 (build 3)".
  static String get versionLabel {
    final [name, build] = version.split('+');
    return '$name (build $build)';
  }
}
