import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads the source, because nothing else would notice.
///
/// A repository that writes a synced table directly makes an edit that works perfectly on
/// this device and never reaches any other. No behavioural test fails — the row is right
/// there — so the check that matters is that the write path is the only path.
void main() {
  test('only SyncWriter writes synced tables', () {
    // Never synced, and written directly on purpose.
    const localOnly = {'localSettings', 'outbox'};

    // A database (`db`, `_db`, `scope.db`...) given a table to write, and that table.
    final tableWrite = RegExp(
      r'\b\w*db\s*\.\s*(into|update|delete)\s*\(\s*([\w.]+)\s*,?\s*\)',
      caseSensitive: false,
    );
    final rawWrite = RegExp(
      r'\b\w*db\s*\.\s*(customInsert|customUpdate|customStatement|batch)\s*\(',
      caseSensitive: false,
    );

    final violations = <String>[];
    var localWrites = 0;

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      // The write path itself, and generated code.
      if (path.startsWith('lib/sync/') || path.endsWith('.g.dart')) continue;
      final source = file.readAsStringSync();

      for (final match in tableWrite.allMatches(source)) {
        if (localOnly.contains(match.group(2)!.split('.').last)) {
          localWrites++;
        } else {
          violations.add('$path:${_lineOf(source, match.start)}  ${match.group(0)}');
        }
      }
      for (final match in rawWrite.allMatches(source)) {
        violations.add('$path:${_lineOf(source, match.start)}  ${match.group(0)}');
      }
    }

    // The client id is written directly, on purpose — so if this finds nothing, the
    // pattern has stopped matching real code and the scan below proves nothing.
    expect(localWrites, greaterThan(0), reason: 'the scan matched no writes at all');
    expect(violations, isEmpty, reason: 'write these through SyncWriter');
  });
}

int _lineOf(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;
