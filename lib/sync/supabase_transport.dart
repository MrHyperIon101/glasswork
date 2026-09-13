import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';

import 'sync_transport.dart';
import 'sync_writer.dart';

/// [SyncTransport] over Supabase: the `merge_rows` and `pull_rows` functions in
/// supabase/migrations, called as RPCs.
///
/// A translation and nothing more. The rules the engine relies on — how fields merge, the
/// order rows page in, what a clock looks like — are enforced by those functions and
/// checked against a real database by supabase/checks/sync_schema_checks.sql.
class SupabaseTransport implements SyncTransport {
  SupabaseTransport(this._client, {this.timeout = const Duration(seconds: 30)});

  final SupabaseClient _client;

  /// How long one call may take before it counts as unreachable.
  final Duration timeout;

  /// Changes per `merge_rows` call. The server takes up to 1000; half that keeps each
  /// call comfortably inside [timeout].
  static const pushBatch = 500;

  @override
  Future<void> push(List<RowChange> changes) async {
    for (var start = 0; start < changes.length; start += pushBatch) {
      final batch = changes.sublist(
        start,
        math.min(start + pushBatch, changes.length),
      );
      await _call(
        () => _client.rpc(
          'merge_rows',
          params: {
            'changes': [for (final change in batch) encodeChange(change)],
          },
        ),
      );
    }
  }

  @override
  Future<PullPage> pull(
    String table, {
    DateTime? since,
    PullCursor? after,
    required int limit,
  }) async {
    final result = await _call(
      () => _client.rpc(
        'pull_rows',
        params: {
          'target': table,
          'since': since?.toUtc().toIso8601String(),
          'after_updated_at': after?.updatedAt.toUtc().toIso8601String(),
          'after_id': after?.id,
          'max_rows': limit,
        },
      ),
    );
    if (result is! List) {
      throw SyncTransportException(
        'pull_rows answered with ${result.runtimeType}, not a list of rows',
      );
    }

    final rows = [
      for (final row in result)
        decodeRow(table, Map<String, dynamic>.from(row as Map)),
    ];
    // A full page may have more behind it. A short one cannot.
    return PullPage(rows: rows, hasMore: rows.length >= limit);
  }

  /// A change as `merge_rows` reads it.
  static Map<String, Object?> encodeChange(RowChange change) => {
    'table': change.table,
    'id': change.id,
    'values': change.values,
    'versions': change.versions,
    'client_id': change.clientId,
  };

  /// A row as `pull_rows` returns it: every column, with `field_versions` an object.
  static RemoteRow decodeRow(String table, Map<String, dynamic> json) {
    final id = json['id'];
    final updatedAt = DateTime.tryParse('${json['updated_at']}');
    if (id is! String || updatedAt == null) {
      throw SyncTransportException(
        'a $table row arrived without an id or updated_at',
      );
    }

    final versions = json['field_versions'];
    return RemoteRow(
      table: table,
      id: id,
      values: {
        for (final entry in json.entries)
          if (!SyncWriter.bookkeeping.contains(entry.key)) entry.key: entry.value,
      },
      versions: {
        if (versions is Map)
          for (final entry in versions.entries)
            if (entry.value is String) '${entry.key}': entry.value as String,
      },
      clientId: json['client_id'] as String?,
      updatedAt: updatedAt.toUtc(),
    );
  }

  Future<Object?> _call(Future<Object?> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      throw _refusal(e);
    } on AuthRetryableFetchException catch (e) {
      throw SyncOfflineException('could not reach the server: ${e.message}');
    } on AuthException catch (e) {
      // Refreshing the sign-in was refused, as opposed to unreachable.
      throw SyncSignedOutException(e.message);
    } on TimeoutException {
      throw const SyncOfflineException('the server did not answer in time');
    } on SocketException catch (e) {
      throw SyncOfflineException('could not reach the server: ${e.message}');
    } on HandshakeException catch (e) {
      throw SyncOfflineException('could not reach the server: ${e.message}');
    } on http.ClientException catch (e) {
      throw SyncOfflineException('could not reach the server: ${e.message}');
    }
  }

  static SyncTransportException _refusal(PostgrestException e) => switch (e.code) {
    // merge_rows: a change stamped later than the server's clock allows.
    'GW001' => DeviceClockAheadException(e.message),
    // The token itself is no good: malformed, or signed with a key no longer in use.
    'PGRST301' => SyncSignedOutException(e.message),
    // merge_rows with no signed-in caller, or a signed-out request reaching a function.
    '42501'
        when e.message.contains('sign in') ||
            e.message.contains('permission denied') =>
      SyncSignedOutException(e.message),
    _ => SyncTransportException('${e.code ?? 'refused'}: ${e.message}'),
  };
}
