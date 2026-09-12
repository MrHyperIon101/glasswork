import 'hlc.dart';

/// Field values alongside the clock each one was last written at.
///
/// Column names are the database's (snake_case), since this same shape is what travels
/// to the server and what the `merge_row` function reads there.
class VersionedFields {
  const VersionedFields(this.values, this.versions);

  const VersionedFields.empty() : values = const {}, versions = const {};

  final Map<String, Object?> values;

  /// Column -> encoded [Hlc].
  final Map<String, String> versions;
}

class MergeResult {
  const MergeResult({
    required this.values,
    required this.versions,
    required this.accepted,
    required this.rejected,
  });

  final Map<String, Object?> values;
  final Map<String, String> versions;

  /// Incoming fields that were newer and now hold.
  final Set<String> accepted;

  /// Incoming fields that lost to something already here. Worth logging: a steady
  /// stream of these from one device means its edits are consistently arriving stale.
  final Set<String> rejected;

  bool get changed => accepted.isNotEmpty;
}

/// Last-writer-wins, per field, ordered by hybrid logical clock.
///
/// Per *field* rather than per row is the whole point. Editing a title on the phone and a
/// due date on the laptop are not in conflict at all, and row-level last-writer-wins would
/// throw one of them away.
///
/// This is a pure function and it is mirrored exactly by the `merge_row` function in
/// Postgres. The two must agree, which is why the rules live here with tests rather than
/// only in SQL.
///
/// Properties the tests hold it to:
///   * idempotent — delivering the same change twice changes nothing the second time;
///   * order-independent — merging A then B gives the same row as B then A;
///   * causal — a stale offline edit cannot overwrite a newer one, however late it syncs.
abstract final class FieldMerge {
  static MergeResult apply({
    required VersionedFields current,
    required VersionedFields incoming,
  }) {
    final values = Map<String, Object?>.of(current.values);
    final versions = Map<String, String>.of(current.versions);
    final accepted = <String>{};
    final rejected = <String>{};

    for (final entry in incoming.values.entries) {
      final column = entry.key;
      final incomingClock = Hlc.tryDecode(incoming.versions[column]);

      // A change with no readable clock cannot be ordered against anything. Refusing it
      // is visible and recoverable; guessing a position for it is neither.
      if (incomingClock == null) {
        rejected.add(column);
        continue;
      }

      final currentRaw = current.versions[column];
      final currentClock = Hlc.tryDecode(currentRaw);

      final wins =
          // Nothing here yet, or what is here has an unreadable clock and should be
          // healed by a valid one rather than kept forever.
          currentClock == null ||
          incomingClock > currentClock;

      if (wins) {
        values[column] = entry.value;
        versions[column] = incomingClock.encode();
        accepted.add(column);
      } else if (incomingClock < currentClock) {
        rejected.add(column);
      }
      // Equal clocks are the same write delivered twice: nothing to do, and not a
      // conflict worth reporting.
    }

    return MergeResult(
      values: values,
      versions: versions,
      accepted: accepted,
      rejected: rejected,
    );
  }
}
