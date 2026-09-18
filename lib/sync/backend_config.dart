/// The Supabase project devices sync with, given at build time.
///
/// Kept out of the source so a clone of this repository never carries someone else's
/// project: pass it with `--dart-define-from-file=backend.json` (see `backend.example.json`
/// and the README). Both values are public by design — the publishable key grants nothing on
/// its own, since row level security decides what a signed-in account can read and devices
/// hold no write grants at all. The secret key never appears in the app.
///
/// A build without them is a working app that keeps everything on the one device.
abstract final class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Whether this build has a project to sync with.
  static bool get configured => url.isNotEmpty && publishableKey.isNotEmpty;
}
