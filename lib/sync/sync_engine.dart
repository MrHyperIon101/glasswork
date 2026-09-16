import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/db/database.dart';
import 'field_merge.dart';
import 'hlc.dart';
import 'sync_transport.dart';
import 'sync_writer.dart';
import 'wire_codec.dart';

/// What one sync attempt did.
class SyncReport {
  const SyncReport({this.pushed = 0, this.pulled = 0, this.error});

  final int pushed;

  /// Rows that actually changed locally. Rows pulled back unchanged — including ones this
  /// device just pushed — are not counted.
  final int pulled;

  final Exception? error;

  bool get ok => error == null;

  /// A device reported an implausible time. Needs a person to fix a clock setting, so it
  /// is worth telling them rather than retrying quietly forever.
  bool get clockDrift => error is ClockDriftException;

  /// The server refused this device's own changes as dated in the future. Also a clock
  /// setting, but this device's.
  bool get deviceClockAhead => error is DeviceClockAheadException;

  /// The sign-in has ended; syncing again needs a new one.
  bool get signedOut => error is SyncSignedOutException;
}

/// Pushes local changes up and pulls remote ones down.
///
/// Never in any UI path. Local writes go to the database and return; this runs later, in
/// the background, and a failure here means "try again later", never "your edit is lost".
///
/// ### Why pulling holds no lock while it waits on the network
///
/// Fetching inside a database transaction would hold SQLite's write lock for the whole
/// round-trip, and every local edit would queue behind it — so a slow connection would
/// freeze the app, which is local-first broken by the back door. Instead everything is
/// fetched first with no lock held, then applied in one short local transaction.
///
/// ### Why that transaction defers foreign keys
///
/// A task can arrive in the same pull as the list it belongs to, or before it. With
/// checks deferred to commit, a pull either applies completely or rolls back completely —
/// cursors included — and simply retries next cycle once the parent has arrived. It is
/// never left half-applied.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SyncWriter writer,
    required SyncTransport transport,
    required List<TableInfo<Table, Object?>> tables,
  }) : _db = db,
       _writer = writer,
       _transport = transport,
       _tables = List.unmodifiable(tables);

  final AppDatabase _db;
  final SyncWriter _writer;
  final SyncTransport _transport;

  /// Parents before children. Applied in this order within a pull.
  final List<TableInfo<Table, Object?>> _tables;

  /// Re-read this far behind the stored cursor on every pull.
  ///
  /// Postgres' `now()` is the time a transaction *started*. A long transaction can commit
  /// a row stamped earlier than a cursor this device has already moved past, and without
  /// the overlap that row would never be pulled. Re-reading is free because applying a
  /// row twice changes nothing. Assumes no transaction runs longer than this.
  static const overlap = Duration(seconds: 60);

  static const pageSize = 500;

  static const _cursorPrefix = 'sync_cursor:';

  Future<SyncReport> syncOnce() async {
    var pushed = 0;
    try {
      pushed = await push();
      final pulled = await pull();
      return SyncReport(pushed: pushed, pulled: pulled);
    } on Exception catch (e) {
      // Exceptions only. An Error is a bug, and hiding a bug inside a background sync
      // report is how it survives to production.
      return SyncReport(pushed: pushed, error: e);
    }
  }

  // --- push ---------------------------------------------------------------------

  /// Sends every dirty row. Returns how many were sent.
  Future<int> push() async {
    final entries = await (_db.select(
      _db.outbox,
    )..orderBy([(o) => OrderingTerm(expression: o.seq)])).get();
    if (entries.isEmpty) return 0;

    final changes = <RowChange>[];
    final sent = <OutboxData>[];

    for (final entry in entries) {
      final table = _tableNamed(entry.targetTable);
      if (table == null) continue;

      final change = await _readChange(table, entry);
      if (change == null) {
        // The row is gone locally. Synced rows are tombstoned rather than deleted, so
        // this should not happen — but an entry that can never be pushed must not block
        // the queue forever.
        await (_db.delete(_db.outbox)..where((o) => o.seq.equals(entry.seq)))
            .go();
        continue;
      }
      changes.add(change);
      sent.add(entry);
    }
    if (changes.isEmpty) return 0;

    // Throws on failure, leaving the outbox exactly as it was.
    await _transport.push(changes);

    for (final entry in sent) {
      // Only if nothing touched the entry while the push was in flight. An edit that
      // landed meanwhile replaced its clock, so this matches nothing and the entry stays
      // to go out next time.
      await (_db.delete(_db.outbox)..where(
            (o) => o.seq.equals(entry.seq) & o.hlc.equals(entry.hlc),
          ))
          .go();
    }
    return changes.length;
  }

  Future<RowChange?> _readChange(
    TableInfo<Table, Object?> table,
    OutboxData entry,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM "${table.actualTableName}" WHERE id = ?',
          variables: [Variable.withString(entry.rowId)],
          readsFrom: {table},
        )
        .getSingleOrNull();
    if (row == null) return null;

    final versions = SyncWriter.decodeVersions(
      row.data['field_versions'] as String?,
    );
    final values = <String, Object?>{};
    final sentVersions = <String, String>{};

    for (final name in SyncWriter.decodeFieldNames(entry.changedFields)) {
      final column = WireCodec.column(table, name);
      final version = versions[name];
      // A field with no clock cannot be ordered on the server either; sending it would
      // only be refused there.
      if (column == null || version == null) continue;
      values[name] = WireCodec.toWire(column, row.data[name]);
      sentVersions[name] = version;
    }

    return RowChange(
      table: table.actualTableName,
      id: entry.rowId,
      values: values,
      versions: sentVersions,
      clientId: row.data['client_id'] as String?,
    );
  }

  // --- pull ---------------------------------------------------------------------

  /// Fetches and applies remote changes. Returns how many rows changed locally.
  Future<int> pull() async {
    // 1. The network, holding no lock, and every table at once. They are independent reads,
    //    and one after another each waited out the round trip before it.
    final names = [for (final table in _tables) table.actualTableName];
    final startedAt = <String, DateTime?>{
      for (final name in names) name: await _readCursor(name),
    };
    final pages = await Future.wait([
      for (final name in names) _fetchAll(name, startedAt[name]?.subtract(overlap)),
    ]);
    final fetched = <String, List<RemoteRow>>{
      for (final (i, name) in names.indexed) name: pages[i],
    };

    // 2. Apply locally, atomically, parents first.
    var changed = 0;
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');

      for (final table in _tables) {
        final name = table.actualTableName;
        var high = startedAt[name];

        for (final remote in fetched[name]!) {
          if (await _apply(table, remote)) changed++;
          if (high == null || remote.updatedAt.isAfter(high)) {
            high = remote.updatedAt;
          }
        }

        // Written inside the same transaction as the rows, so a rollback cannot leave
        // a cursor pointing past rows that were never applied.
        if (high != null && high != startedAt[name]) {
          await _writeCursor(name, high);
        }
      }
    });
    return changed;
  }

  Future<List<RemoteRow>> _fetchAll(String table, DateTime? since) async {
    final rows = <RemoteRow>[];
    PullCursor? after;

    while (true) {
      final page = await _transport.pull(
        table,
        since: since,
        after: after,
        limit: pageSize,
      );
      rows.addAll(page.rows);
      if (!page.hasMore || page.rows.isEmpty) break;
      after = PullCursor(page.rows.last.updatedAt, page.rows.last.id);
    }
    return rows;
  }

  /// Merges one remote row into the local copy. Returns whether anything changed.
  ///
  /// Writes directly rather than through [SyncWriter]: routing a pulled row through the
  /// writer would re-stamp it with a fresh local clock and mark it dirty, and it would
  /// echo straight back to the server as though this device had edited it.
  Future<bool> _apply(
    TableInfo<Table, Object?> table,
    RemoteRow remote,
  ) async {
    // Fold the remote clock in first, so this device's next edit orders after what it
    // has now seen. Throws ClockDriftException for an implausible clock, which rolls the
    // whole pull back rather than applying data stamped by a broken clock.
    final newest = _newestClock(remote.versions);
    if (newest != null) await _writer.observe(newest);

    final name = table.actualTableName;
    final local = await _db
        .customSelect(
          'SELECT * FROM "$name" WHERE id = ?',
          variables: [Variable.withString(remote.id)],
          readsFrom: {table},
        )
        .getSingleOrNull();

    final incoming = <String, Object?>{};
    for (final entry in remote.values.entries) {
      if (SyncWriter.bookkeeping.contains(entry.key)) continue;
      final column = WireCodec.column(table, entry.key);
      // A column this schema version does not have: ignored, not an error, so an older
      // app keeps syncing with a newer server.
      if (column == null) continue;
      incoming[entry.key] = WireCodec.toStored(column, entry.value);
    }

    final updatedAt = Variable.withInt(
      remote.updatedAt.toUtc().millisecondsSinceEpoch ~/ 1000,
    );

    if (local == null) {
      // Nothing local to conflict with, so every value is taken — including any the
      // server holds without a clock, which a merge would otherwise refuse.
      final columns = incoming.keys.toList()..sort();
      final names = ['id', ...columns, 'field_versions', 'client_id', 'updated_at'];

      await _db.customInsert(
        'INSERT INTO "$name" (${names.map((n) => '"$n"').join(', ')}) '
        'VALUES (${List.filled(names.length, '?').join(', ')})',
        variables: [
          Variable.withString(remote.id),
          for (final c in columns) Variable<Object>(incoming[c]),
          Variable.withString(jsonEncode(remote.versions)),
          Variable<Object>(remote.clientId),
          updatedAt,
        ],
        updates: {table},
      );
      return true;
    }

    final result = FieldMerge.apply(
      current: VersionedFields(
        local.data,
        SyncWriter.decodeVersions(local.data['field_versions'] as String?),
      ),
      incoming: VersionedFields(incoming, remote.versions),
    );
    if (!result.changed) return false;

    final columns = result.accepted.toList()..sort();
    await _db.customUpdate(
      'UPDATE "$name" SET '
      '${[for (final c in columns) '"$c" = ?', 'field_versions = ?', 'client_id = ?', 'updated_at = ?'].join(', ')} '
      'WHERE id = ?',
      variables: [
        for (final c in columns) Variable<Object>(result.values[c]),
        Variable.withString(jsonEncode(result.versions)),
        Variable<Object>(remote.clientId),
        updatedAt,
        Variable.withString(remote.id),
      ],
      updates: {table},
    );
    return true;
  }

  // --- helpers ------------------------------------------------------------------

  TableInfo<Table, Object?>? _tableNamed(String name) {
    for (final t in _tables) {
      if (t.actualTableName == name) return t;
    }
    return null;
  }

  static Hlc? _newestClock(Map<String, String> versions) {
    Hlc? newest;
    for (final raw in versions.values) {
      final clock = Hlc.tryDecode(raw);
      if (clock != null && (newest == null || clock > newest)) newest = clock;
    }
    return newest;
  }

  Future<DateTime?> _readCursor(String table) async {
    final row =
        await (_db.select(_db.localSettings)
              ..where((s) => s.key.equals('$_cursorPrefix$table')))
            .getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value)?.toUtc();
  }

  Future<void> _writeCursor(String table, DateTime cursor) => _db
      .into(_db.localSettings)
      .insertOnConflictUpdate(
        LocalSettingsCompanion.insert(
          key: '$_cursorPrefix$table',
          value: cursor.toUtc().toIso8601String(),
        ),
      );
}
