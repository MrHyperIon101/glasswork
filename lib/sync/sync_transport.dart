/// What the sync engine needs from a server, and nothing more.
///
/// An interface rather than Supabase calls inside the engine, for two reasons. The rules
/// that matter — push dirty fields, pull with an overlap, merge per field — can be proved
/// against an in-memory server with two simulated devices and no network at all. And the
/// real implementation is then the only file in the app that knows Supabase exists.
abstract interface class SyncTransport {
  /// Sends changed fields for a batch of rows.
  ///
  /// The server merges each field by its clock, exactly as `FieldMerge` does, so this
  /// must be safe to call again with the same batch. Throws [SyncTransportException] on
  /// failure; the engine then leaves the outbox untouched.
  Future<void> push(List<RowChange> changes);

  /// Rows in [table] changed at or after [since], in `(updatedAt, id)` order.
  ///
  /// [after] continues from the last row of the previous page. Paging by position
  /// rather than by re-querying from a timestamp is what stops a page full of rows
  /// sharing one `updated_at` from being fetched forever.
  Future<PullPage> pull(
    String table, {
    DateTime? since,
    PullCursor? after,
    required int limit,
  });
}

/// Changed fields for one row, on their way up.
class RowChange {
  const RowChange({
    required this.table,
    required this.id,
    required this.values,
    required this.versions,
    required this.clientId,
  });

  final String table;
  final String id;

  /// Wire-form values, dirty fields only.
  final Map<String, Object?> values;

  /// Encoded clock per field in [values].
  final Map<String, String> versions;

  /// The device that made the change. Carried because it is also the tiebreak for equal
  /// order keys, and that tiebreak has to agree on every device.
  final String? clientId;
}

/// A row as the server holds it, on its way down.
class RemoteRow {
  const RemoteRow({
    required this.table,
    required this.id,
    required this.values,
    required this.versions,
    required this.updatedAt,
    this.clientId,
  });

  final String table;
  final String id;
  final Map<String, Object?> values;
  final Map<String, String> versions;
  final String? clientId;

  /// Assigned by the server when the row last changed.
  ///
  /// The pull cursor, and **never** used to decide a conflict. It is arrival order, and
  /// arrival order is exactly backwards for a device that was offline.
  final DateTime updatedAt;
}

class PullCursor {
  const PullCursor(this.updatedAt, this.id);

  final DateTime updatedAt;
  final String id;
}

class PullPage {
  const PullPage({required this.rows, required this.hasMore});

  final List<RemoteRow> rows;
  final bool hasMore;
}

/// The server could not be reached, or refused the request.
///
/// Expected, and not an error in any user-facing sense: this app works offline, and a
/// failed sync is simply one that happens later.
class SyncTransportException implements Exception {
  const SyncTransportException(this.message);

  final String message;

  @override
  String toString() => 'SyncTransportException: $message';
}

/// The server could not be reached at all: no network, or no answer in time.
///
/// Kept apart from a server that answers with a refusal, because this needs nothing from
/// anyone but a connection. It is "offline", not "something went wrong".
class SyncOfflineException extends SyncTransportException {
  const SyncOfflineException(super.message);
}

/// The server refused this device's changes because their clocks are ahead of its time.
///
/// This device's date or time is set wrong. Retrying cannot help until someone fixes it,
/// so it is worth saying so rather than retrying quietly forever.
class DeviceClockAheadException extends SyncTransportException {
  const DeviceClockAheadException(super.message);
}

/// The server no longer accepts this device's sign-in.
class SyncSignedOutException extends SyncTransportException {
  const SyncSignedOutException(super.message);
}
