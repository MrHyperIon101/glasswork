import 'dart:async';

import 'package:supabase/supabase.dart';

/// Word from the server that another device has changed something, so this device can
/// pull at once instead of at its next interval.
///
/// Only a prompt: the rows still arrive through a pull, so a missed or doubled message
/// costs a round trip at most, never data.
abstract interface class ChangeFeed {
  /// Starts listening for changes made by any device but [clientId]. [onChange] is called
  /// for each one, and [onLive] whenever the feed connects or drops.
  void start({
    required String clientId,
    required void Function() onChange,
    required void Function(bool live) onLive,
  });

  Future<void> stop();

  /// Whether a changed row, as the server describes it, was written by another device.
  /// A row with no writer recorded counts as another's.
  static bool fromAnotherDevice(
    Map<String, dynamic> newRecord,
    Map<String, dynamic> oldRecord,
    String clientId,
  ) {
    final record = newRecord.isNotEmpty ? newRecord : oldRecord;
    return record['client_id'] != clientId;
  }
}

/// A feed with nothing to say, where there is no server to listen to: under test, or
/// before sync is set up.
class NoChangeFeed implements ChangeFeed {
  const NoChangeFeed();

  @override
  void start({
    required String clientId,
    required void Function() onChange,
    required void Function(bool live) onLive,
  }) {}

  @override
  Future<void> stop() async {}
}

/// Supabase Realtime. Every synced table is in the `supabase_realtime` publication, and row
/// level security decides which of its changes this account hears about.
class SupabaseChangeFeed implements ChangeFeed {
  SupabaseChangeFeed(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;

  @override
  void start({
    required String clientId,
    required void Function() onChange,
    required void Function(bool live) onLive,
  }) {
    unawaited(stop());
    _channel = _client
        .channel('sync:$clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          callback: (payload) {
            if (ChangeFeed.fromAnotherDevice(
              payload.newRecord,
              payload.oldRecord,
              clientId,
            )) {
              onChange();
            }
          },
        )
        .subscribe(
          (status, error) => onLive(status == RealtimeSubscribeStatus.subscribed),
        );
  }

  @override
  Future<void> stop() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await _client.removeChannel(channel);
  }
}
