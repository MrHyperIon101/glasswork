import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/db/database.dart';
import 'hlc.dart';

/// The single write path for synced tables.
///
/// Every change to a synced row does three things atomically: writes the row, stamps the
/// changed fields in `field_versions` with a fresh hybrid logical clock, and marks those
/// fields dirty in the outbox. Doing that by hand at each of the app's write sites is how
/// one gets missed — and a missed stamp is an edit that silently never syncs, or syncs
/// and loses a conflict it should have won.
///
/// ### Why the outbox records field *names*, not values
///
/// The detail sheet renames a task on every keystroke. Storing a value per edit would
/// mean either an outbox row per keystroke, or coalescing them under one clock — and one
/// clock for several fields overstates when the earlier ones were written, which is an
/// ordering bug. Instead the outbox records which fields are dirty, and a push reads the
/// row's current values alongside their real per-field clocks. Coalescing is then a set
/// union, and always correct, because `field_versions` stays the single authority.
///
/// This still honours "changed fields, not row snapshots": only dirty fields are sent.
class SyncWriter {
  SyncWriter(this._db, {required this.clientId, int Function()? nowMs})
    : _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;

  /// This device. Every clock it mints carries this as its node id.
  final String clientId;

  final int Function() _nowMs;

  static const _clockKey = 'hlc';

  /// Columns this writer maintains itself.
  ///
  /// Never recorded as a user change. Syncing `client_id` or `field_versions` as data
  /// would let one device overwrite another's bookkeeping, and `updated_at` belongs to
  /// the server (see docs/architecture.md, Sync).
  static const bookkeeping = {'id', 'field_versions', 'client_id', 'updated_at'};

  Hlc? _clock;
  Future<void>? _loading;

  /// The last clock this device minted or observed.
  Future<Hlc> get clock async {
    await _ensureClock();
    return _clock!;
  }

  // --- writes -----------------------------------------------------------------

  /// Updates one row by id.
  Future<void> update<T extends Table, D>(
    TableInfo<T, D> table,
    String id,
    Insertable<D> patch,
  ) async {
    _requireSynced(table);
    final dirty = _dirtyFrom(patch);
    final idColumn = _idColumn(table);

    await _db.transaction(() async {
      await (_db.update(table)..where((_) => idColumn.equals(id))).write(patch);
      if (dirty.isEmpty) return;

      final hlc = await _tick();
      await _stamp(table, id, dirty, hlc);
      await _markDirty(table, id, dirty, hlc);
    });
  }

  /// Inserts a row, which must carry an explicit id.
  ///
  /// Every column is marked dirty, not only the ones the companion set. Defaults applied
  /// by SQLite — a status, a priority, a creation time — are part of the row too, and a
  /// server that filled in its own defaults instead would quietly disagree with this
  /// device about what was created.
  Future<D> insert<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    _requireSynced(table);

    final idValue = row.toColumns(false)['id'];
    if (idValue is! Variable<String> || idValue.value == null) {
      throw ArgumentError(
        'rows inserted through SyncWriter must set an explicit id; '
        'without one the outbox has nothing to point at',
      );
    }
    final id = idValue.value!;
    final dirty = {
      for (final c in table.$columns)
        if (!bookkeeping.contains(c.name)) c.name,
    };
    final idColumn = _idColumn(table);

    return _db.transaction(() async {
      await _db.into(table).insert(row);
      final hlc = await _tick();
      await _stamp(table, id, dirty, hlc);
      await _markDirty(table, id, dirty, hlc);

      return (_db.select(table)..where((_) => idColumn.equals(id))).getSingle();
    });
  }

  /// Folds in a clock seen on data from another device.
  ///
  /// Called when pulled rows are applied. After it, nothing this device writes can order
  /// before what it just received, even with a slow wall clock.
  Future<void> observe(
    Hlc remote, {
    Duration maxDrift = Hlc.defaultMaxDrift,
  }) async {
    await _ensureClock();
    // No await between reading the clock and replacing it: two concurrent calls must not
    // both start from the same value.
    final next = _clock!.receive(remote, _nowMs(), maxDrift: maxDrift);
    _clock = next;
    await _persistClock(next);
  }

  // --- internals ----------------------------------------------------------------

  Future<Hlc> _tick() async {
    await _ensureClock();
    final next = _clock!.send(_nowMs());
    _clock = next;
    await _persistClock(next);
    return next;
  }

  Future<void> _ensureClock() => _loading ??= _loadClock();

  Future<void> _loadClock() async {
    final row =
        await (_db.select(_db.localSettings)
              ..where((s) => s.key.equals(_clockKey)))
            .getSingleOrNull();
    final stored = Hlc.tryDecode(row?.value);

    // A clock stamped with a different device id — a database copied from another
    // machine, say — is not this device's to continue.
    _clock = stored != null && stored.nodeId == clientId
        ? stored
        : Hlc.zero(clientId);
  }

  Future<void> _persistClock(Hlc clock) => _db
      .into(_db.localSettings)
      .insertOnConflictUpdate(
        LocalSettingsCompanion.insert(key: _clockKey, value: clock.encode()),
      );

  Future<void> _stamp(
    TableInfo<Table, Object?> table,
    String id,
    Set<String> dirty,
    Hlc hlc,
  ) async {
    final name = table.actualTableName;
    final current = await _db
        .customSelect(
          'SELECT field_versions FROM "$name" WHERE id = ?',
          variables: [Variable.withString(id)],
          readsFrom: {table},
        )
        .getSingleOrNull();

    final versions = decodeVersions(current?.data['field_versions'] as String?);
    final encoded = hlc.encode();
    for (final column in dirty) {
      versions[column] = encoded;
    }

    await _db.customUpdate(
      'UPDATE "$name" SET field_versions = ?, client_id = ?, updated_at = ? '
      'WHERE id = ?',
      variables: [
        Variable.withString(jsonEncode(versions)),
        Variable.withString(clientId),
        Variable.withInt(_nowMs() ~/ 1000),
        Variable.withString(id),
      ],
      updates: {table},
    );
  }

  /// Adds [dirty] to this row's outbox entry, creating it if there is none.
  ///
  /// The entry's clock is always replaced with the newest one. The push relies on that:
  /// it only removes an entry whose clock is unchanged since it was read, so an edit that
  /// lands mid-push leaves the entry behind to go out again.
  Future<void> _markDirty(
    TableInfo<Table, Object?> table,
    String id,
    Set<String> dirty,
    Hlc hlc,
  ) async {
    final name = table.actualTableName;
    final existing =
        await (_db.select(_db.outbox)
              ..where((o) => o.targetTable.equals(name) & o.rowId.equals(id))
              ..orderBy([
                (o) => OrderingTerm(expression: o.seq, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.outbox)
          .insert(
            OutboxCompanion.insert(
              targetTable: name,
              rowId: id,
              changedFields: encodeFieldNames(dirty),
              hlc: hlc.encode(),
            ),
          );
      return;
    }

    final merged = {...decodeFieldNames(existing.changedFields), ...dirty};
    await (_db.update(_db.outbox)..where((o) => o.seq.equals(existing.seq)))
        .write(
          OutboxCompanion(
            changedFields: Value(encodeFieldNames(merged)),
            hlc: Value(hlc.encode()),
          ),
        );
  }

  static Set<String> _dirtyFrom<D>(Insertable<D> patch) => {
    // false, not true: setting a field back to null — restoring a deleted task clears
    // deleted_at — is a change, and nullToAbsent would silently drop it.
    for (final name in patch.toColumns(false).keys)
      if (!bookkeeping.contains(name)) name,
  };

  static void _requireSynced(TableInfo<Table, Object?> table) {
    if (!table.$columns.any((c) => c.name == 'field_versions')) {
      throw ArgumentError(
        '${table.actualTableName} is local-only; write it directly, not through SyncWriter',
      );
    }
  }

  static GeneratedColumn<String> _idColumn(TableInfo<Table, Object?> table) {
    for (final c in table.$columns) {
      if (c.name == 'id') return c as GeneratedColumn<String>;
    }
    throw ArgumentError('${table.actualTableName} has no id column');
  }

  // --- shared encodings -----------------------------------------------------------

  /// Sorted, so the same set always encodes identically.
  static String encodeFieldNames(Iterable<String> names) =>
      jsonEncode(names.toSet().toList()..sort());

  static Set<String> decodeFieldNames(String json) {
    try {
      final raw = jsonDecode(json);
      return raw is List ? raw.whereType<String>().toSet() : <String>{};
    } on FormatException {
      return <String>{};
    }
  }

  static Map<String, String> decodeVersions(String? json) {
    if (json == null || json.isEmpty) return <String, String>{};
    try {
      final raw = jsonDecode(json);
      if (raw is! Map) return <String, String>{};
      return {
        for (final entry in raw.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } on FormatException {
      return <String, String>{};
    }
  }
}
