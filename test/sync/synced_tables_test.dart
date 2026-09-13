import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/sync/synced_tables.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('every table carrying the sync columns is synced, and only those', () {
    // A new synced table left off the list would never sync, and nothing would say so.
    final synced = [for (final t in db.syncedTables) t.actualTableName];
    final carrying = {
      for (final t in db.allTables)
        if (t.$columns.any((c) => c.name == 'field_versions')) t.actualTableName,
    };

    expect(synced.toSet(), carrying);
    expect(synced, hasLength(carrying.length), reason: 'no table listed twice');
  });

  test('parents come before children', () async {
    final order = [for (final t in db.syncedTables) t.actualTableName];
    var checked = 0;

    for (final (i, table) in order.indexed) {
      final keys = await db.customSelect('PRAGMA foreign_key_list("$table")').get();
      for (final key in keys) {
        final parent = key.read<String>('table');
        expect(
          order.indexOf(parent),
          inInclusiveRange(0, i - 1),
          reason: '$table references $parent, which must sync before it',
        );
        checked++;
      }
    }

    expect(checked, greaterThan(0), reason: 'found no foreign keys to check');
  });
}
