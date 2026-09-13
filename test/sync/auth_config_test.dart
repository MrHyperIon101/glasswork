import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/sync/sync_auth.dart';

/// The app and the project agree about signing in.
///
/// The project enforces the rules; the app only tells people what they are before they
/// run into them. If the two drift apart, the app's advice turns into a lie — it accepts a
/// password the server refuses — and nothing else would catch it.
void main() {
  late String config;

  setUpAll(() => config = File('supabase/config.toml').readAsStringSync());

  /// The body of `[name]`, up to the next table that is not commented out.
  String section(String name) {
    final header = '[$name]\n';
    final start = config.indexOf(header);
    if (start == -1) fail('[$name] not found in supabase/config.toml');
    final rest = config.substring(start + header.length);
    final end = rest.indexOf(RegExp(r'^\[', multiLine: true));
    return end == -1 ? rest : rest.substring(0, end);
  }

  String? setting(String sectionName, String key) =>
      RegExp('^$key\\s*=\\s*(.+)\$', multiLine: true)
          .firstMatch(section(sectionName))
          ?.group(1)
          ?.trim();

  test('the shortest password the app allows is the one the project accepts', () {
    expect(
      int.tryParse(setting('auth', 'minimum_password_length') ?? ''),
      SyncAuth.minimumPasswordLength,
    );
  });

  test('a new account needs no email confirmation, since nothing here opens the link', () {
    expect(setting('auth.email', 'enable_confirmations'), 'false');
  });

  test('no email template is declared, since the free plan refuses to change them', () {
    // Commented-out examples from `supabase init` are fine; a live table is not.
    expect(
      RegExp(r'^\[auth\.email\.template\.', multiLine: true).hasMatch(config),
      isFalse,
    );
  });
}
