import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/sync/hlc.dart';
import 'package:glasswork/sync/synced_tables.dart';

/// The server schema checked against the local one, with no server involved.
///
/// The two drifting apart fails silently. `merge_rows` ignores any column its table does
/// not have, so a column added here but never to a migration would take edits on every
/// device and sync none of them. This reads the migrations and compares.
void main() {
  late AppDatabase db;
  late String sql;

  setUpAll(() {
    final migrations =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    sql = migrations.map((f) => f.readAsStringSync()).join('\n');
  });

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Column names declared in `create table public.<table> ( ... );`, one per line.
  Set<String> serverColumns(String table) {
    final block = RegExp(
      'create table public\\.$table \\((.*?)\\n\\);',
      dotAll: true,
    ).firstMatch(sql);
    if (block == null) fail('no create table for $table in supabase/migrations');

    const notColumns = {'primary', 'unique', 'constraint', 'check', 'foreign'};
    return {
      for (final line in block.group(1)!.split('\n'))
        if (RegExp(r'^\s+([a-z_]+)\s').firstMatch(line)?.group(1) case final name?
            when !notColumns.contains(name))
          name,
      // And every column a later migration adds.
      for (final statement in RegExp(
        'alter table public\\.$table\\s(.*?);',
        dotAll: true,
      ).allMatches(sql))
        for (final added in RegExp(
          r'add column (?:if not exists )?([a-z_]+)',
        ).allMatches(statement.group(1)!))
          added.group(1)!,
    };
  }

  test('every synced table has exactly the same columns on the server', () {
    for (final table in db.syncedTables) {
      expect(
        serverColumns(table.actualTableName),
        {for (final c in table.$columns) c.name},
        reason: table.actualTableName,
      );
    }
  });

  test('the server syncs the same tables, in the same order', () {
    // The last definition, since a migration that adds a synced table replaces the list.
    final list = RegExp(
      r'create (?:or replace )?function private\.synced_tables\(\).*?array\[(.*?)\]',
      dotAll: true,
    ).allMatches(sql).lastOrNull;
    if (list == null) fail('private.synced_tables() not found in supabase/migrations');

    expect(
      [
        for (final name in list.group(1)!.split(','))
          name.trim().replaceAll("'", ''),
      ],
      [for (final t in db.syncedTables) t.actualTableName],
    );
  });

  test('the server reads clocks with exactly the pattern Hlc.decode uses', () {
    expect(sql, contains("'${Hlc.canonicalPattern}'"));
  });
}
