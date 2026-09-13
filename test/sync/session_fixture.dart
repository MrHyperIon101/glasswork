import 'dart:convert';

/// The account the auth fixtures sign in as.
const userId = '00000000-0000-4000-8000-00000000000a';
const email = 'me@example.com';

/// A session as the auth server returns one, its access token expiring in [expiresIn].
///
/// The token is shaped like a real one — the client reads its expiry from the payload — but
/// is signed with nothing, which is all a test that never reaches a server needs.
Map<String, Object?> sessionJson({required Duration expiresIn}) {
  final expiresAt = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return {
    'access_token': [
      segment({'alg': 'HS256', 'typ': 'JWT'}),
      segment({
        'sub': userId,
        'exp': expiresAt,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': email,
      }),
      'signature',
    ].join('.'),
    'token_type': 'bearer',
    'expires_in': expiresIn.inSeconds,
    'expires_at': expiresAt,
    'refresh_token': 'refresh-token',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': email,
      'app_metadata': {'provider': 'email'},
      'user_metadata': <String, Object?>{},
      'created_at': '2026-09-13T09:30:00Z',
    },
  };
}
