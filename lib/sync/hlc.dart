import 'dart:math' as math;

/// Hybrid logical clock: how two devices agree which edit to a field came last.
///
/// Wall clocks alone cannot do this. A phone and a laptop disagree about the time by
/// seconds on a good day, and a device that has been offline since Monday carries Monday's
/// edits into a Wednesday sync. Ordering by server arrival time is worse — it is exactly
/// backwards for that offline device, which is why `updated_at` must never be used to
/// resolve conflicts (see docs/architecture.md, Sync).
///
/// An HLC is a wall-clock reading plus a counter plus the device id. It stays close to
/// real time, but it never goes backwards and it always moves past any clock it has
/// *seen*. So once a device has received Tuesday's edit, anything it writes afterwards
/// orders after Tuesday — even if its own clock is running slow.
class Hlc implements Comparable<Hlc> {
  const Hlc(this.wallMs, this.counter, this.nodeId)
    : assert(wallMs >= 0, 'wall time cannot be negative'),
      assert(counter >= 0, 'counter cannot be negative');

  /// The clock a device starts from before it has written or seen anything.
  const Hlc.zero(this.nodeId) : wallMs = 0, counter = 0;

  /// Milliseconds since the epoch, never less than any clock this one has observed.
  final int wallMs;

  /// Tiebreak for events inside the same millisecond.
  final int counter;

  /// The device. Final tiebreak, so two clocks can never compare as equal unless they
  /// really are the same event from the same device.
  final String nodeId;

  /// Five decimal digits. A human-driven app does not produce 100,000 edits inside one
  /// millisecond; reaching it means something is looping.
  static const maxCounter = 99999;

  /// How far ahead of this device's clock a received clock may be.
  ///
  /// Offline time never produces a *future* timestamp — only a wrong clock does. Accepting
  /// one would drag every device's clock forward, after which a correctly-clocked device's
  /// genuinely later edit would compare as older and lose. Five minutes tolerates ordinary
  /// skew and still catches a phone set to the wrong year.
  static const defaultMaxDrift = Duration(minutes: 5);

  /// A local event: an edit made on this device.
  ///
  /// Strictly after this clock, even if the wall clock has gone backwards — an NTP
  /// correction or a manual time change must not let a new edit sort before an old one.
  Hlc send(int nowMs) {
    final wall = math.max(wallMs, nowMs);
    final next = wall == wallMs ? counter + 1 : 0;
    return _normalised(wall, next);
  }

  /// Folds in a clock received from another device.
  ///
  /// The result is after both this clock and [remote], which is what gives the causal
  /// guarantee: nothing this device writes afterwards can order before what it just saw.
  Hlc receive(
    Hlc remote,
    int nowMs, {
    Duration maxDrift = defaultMaxDrift,
  }) {
    if (remote.wallMs - nowMs > maxDrift.inMilliseconds) {
      throw ClockDriftException(remote: remote, nowMs: nowMs, maxDrift: maxDrift);
    }

    final wall = math.max(math.max(wallMs, remote.wallMs), nowMs);

    final int next;
    if (wall == wallMs && wall == remote.wallMs) {
      next = math.max(counter, remote.counter) + 1;
    } else if (wall == wallMs) {
      next = counter + 1;
    } else if (wall == remote.wallMs) {
      next = remote.counter + 1;
    } else {
      next = 0;
    }
    return _normalised(wall, next);
  }

  /// Counter overflow advances the wall clock by a millisecond rather than throwing. It
  /// keeps the clock monotonic, and throwing here would fail a user's edit over an
  /// internal bookkeeping limit.
  Hlc _normalised(int wall, int next) =>
      next > maxCounter ? Hlc(wall + 1, 0, nodeId) : Hlc(wall, next, nodeId);

  /// Fixed-width text that sorts in exactly the same order as [compareTo].
  ///
  /// This is what gets stored in `field_versions` and compared in Postgres, so the
  /// server can order two clocks with a plain string comparison and no parsing. Wall time
  /// is padded to 15 digits, which lasts until the year 33658.
  String encode() =>
      '${wallMs.toString().padLeft(15, '0')}:'
      '${counter.toString().padLeft(5, '0')}:'
      '$nodeId';

  static Hlc decode(String encoded) {
    final first = encoded.indexOf(':');
    final second = first < 0 ? -1 : encoded.indexOf(':', first + 1);
    if (first <= 0 || second < 0) {
      throw FormatException('not an HLC', encoded);
    }

    final wall = int.tryParse(encoded.substring(0, first));
    final counter = int.tryParse(encoded.substring(first + 1, second));
    final node = encoded.substring(second + 1);

    if (wall == null || counter == null || wall < 0 || counter < 0) {
      throw FormatException('not an HLC', encoded);
    }
    if (node.isEmpty) {
      throw FormatException('HLC has no node id', encoded);
    }
    return Hlc(wall, counter, node);
  }

  /// Null for null or malformed input, for callers that treat an unreadable clock as
  /// simply unorderable.
  static Hlc? tryDecode(String? encoded) {
    if (encoded == null) return null;
    try {
      return decode(encoded);
    } on FormatException {
      return null;
    }
  }

  @override
  int compareTo(Hlc other) {
    final byWall = wallMs.compareTo(other.wallMs);
    if (byWall != 0) return byWall;
    final byCounter = counter.compareTo(other.counter);
    if (byCounter != 0) return byCounter;
    return nodeId.compareTo(other.nodeId);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.wallMs == wallMs &&
      other.counter == counter &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash(wallMs, counter, nodeId);

  @override
  String toString() => 'Hlc(${encode()})';
}

/// A received clock was further in the future than any honest clock should be.
///
/// Surfaced rather than swallowed. The sync engine must stop and report this: carrying on
/// would either poison every device's clock or silently drop that device's edits, and
/// both are invisible until the numbers are already wrong.
class ClockDriftException implements Exception {
  const ClockDriftException({
    required this.remote,
    required this.nowMs,
    required this.maxDrift,
  });

  final Hlc remote;
  final int nowMs;
  final Duration maxDrift;

  Duration get aheadBy => Duration(milliseconds: remote.wallMs - nowMs);

  @override
  String toString() =>
      'ClockDriftException: device ${remote.nodeId} reports a time '
      '${aheadBy.inMinutes} min ahead of this one (limit ${maxDrift.inMinutes} min). '
      'Check its date and time settings.';
}
