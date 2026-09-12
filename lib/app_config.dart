/// The app's name lives here and nowhere else. Renaming it is a one-line change.
abstract final class AppConfig {
  static const name = 'Glasswork';

  /// Deep-link scheme for the Supabase auth callback on Android (phase 4).
  static const authScheme = 'dev.mrhyperion.glasswork';
}
