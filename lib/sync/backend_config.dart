/// The Supabase project devices sync with.
///
/// Both values are public by design and safe to ship. The publishable key identifies the
/// project and grants nothing on its own: what a signed-in account can read is decided by
/// row level security, and devices hold no write grants at all (see supabase/migrations).
/// The secret key never appears in the app.
abstract final class BackendConfig {
  static const url = 'https://your-project.supabase.co';
  static const publishableKey = 'sb_publishable_your_key';
}
