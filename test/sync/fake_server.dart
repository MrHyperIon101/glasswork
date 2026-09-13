import 'package:glasswork/sync/field_merge.dart';
import 'package:glasswork/sync/sync_transport.dart';

/// An in-memory stand-in for Supabase.
///
/// Merges pushes with the same `FieldMerge` rules the real `merge_rows` Postgres function
/// follows, and serves pulls ordered by `(updatedAt, id)`. Anything the engine gets
/// right against this, it gets right against the real server — provided the SQL agrees
/// with `FieldMerge`, which is its own test.
class FakeServer implements SyncTransport {
  FakeServer({required this.now});

  /// Server time, which becomes `updatedAt`.
  final DateTime Function() now;

  final _tables = <String, Map<String, ServerRow>>{};

  /// Makes the next push fail as an unreachable network would.
  bool failNextPush = false;

  /// Makes the next pull fail as an unreachable network would.
  bool failNextPull = false;

  /// Runs mid-push, after the engine has read the outbox but before the server replies.
  Future<void> Function()? duringPush;

  int pushCalls = 0;

  /// Every field a push delivered that lost to what the server already held, as
  /// `table.id.column`. Lets a test prove a stale edit was sent and refused, rather than
  /// merely never sent — the two leave the server in the same final state.
  final rejected = <String>[];

  @override
  Future<void> push(List<RowChange> changes) async {
    pushCalls++;
    if (duringPush case final hook?) {
      duringPush = null;
      await hook();
    }
    if (failNextPush) {
      failNextPush = false;
      throw const SyncTransportException('network unreachable');
    }

    for (final change in changes) {
      final table = _tables.putIfAbsent(change.table, () => {});
      final existing = table[change.id];
      final result = FieldMerge.apply(
        current: existing == null
            ? const VersionedFields.empty()
            : VersionedFields(existing.values, existing.versions),
        incoming: VersionedFields(change.values, change.versions),
      );
      for (final column in result.rejected) {
        rejected.add('${change.table}.${change.id}.$column');
      }

      // Only a real change moves updated_at — the same as the SQL function, which does
      // not issue an UPDATE when nothing was accepted.
      if (existing == null || result.changed) {
        table[change.id] = ServerRow(
          values: result.values,
          versions: result.versions,
          clientId: change.clientId,
          updatedAt: now(),
        );
      }
    }
  }

  @override
  Future<PullPage> pull(
    String table, {
    DateTime? since,
    PullCursor? after,
    required int limit,
  }) async {
    if (failNextPull) {
      failNextPull = false;
      throw const SyncTransportException('network unreachable');
    }
    final rows =
        [
          for (final entry in (_tables[table] ?? const {}).entries)
            RemoteRow(
              table: table,
              id: entry.key,
              values: Map.of(entry.value.values),
              versions: Map.of(entry.value.versions),
              clientId: entry.value.clientId,
              updatedAt: entry.value.updatedAt,
            ),
        ].where((r) {
          if (since != null && r.updatedAt.isBefore(since)) return false;
          if (after == null) return true;
          final byTime = r.updatedAt.compareTo(after.updatedAt);
          return byTime > 0 || (byTime == 0 && r.id.compareTo(after.id) > 0);
        }).toList()..sort((a, b) {
          final byTime = a.updatedAt.compareTo(b.updatedAt);
          return byTime != 0 ? byTime : a.id.compareTo(b.id);
        });

    return PullPage(rows: rows.take(limit).toList(), hasMore: rows.length > limit);
  }

  ServerRow? row(String table, String id) => _tables[table]?[id];

  /// Rewrites a row's `updated_at`, as a transaction that started earlier than it
  /// committed would have stamped it.
  void backdate(String table, String id, DateTime to) {
    final r = _tables[table]![id]!;
    _tables[table]![id] = ServerRow(
      values: r.values,
      versions: r.versions,
      clientId: r.clientId,
      updatedAt: to,
    );
  }

  /// Takes a row off the server, returning it — to stage a parent that has not arrived.
  ServerRow remove(String table, String id) => _tables[table]!.remove(id)!;

  void put(String table, String id, ServerRow row) =>
      _tables.putIfAbsent(table, () => {})[id] = row;
}

class ServerRow {
  const ServerRow({
    required this.values,
    required this.versions,
    required this.updatedAt,
    this.clientId,
  });

  final Map<String, Object?> values;
  final Map<String, String> versions;
  final String? clientId;
  final DateTime updatedAt;

  ServerRow withUpdatedAt(DateTime to) => ServerRow(
    values: values,
    versions: versions,
    clientId: clientId,
    updatedAt: to,
  );
}
