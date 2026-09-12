import 'package:drift/drift.dart';

/// Converts between what SQLite physically stores and what travels to Postgres.
///
/// These are not the same shapes, and the difference is silent if ignored. Drift stores a
/// `DateTime` as whole unix *seconds* in an INTEGER and a `bool` as 0 or 1. Send those
/// as-is and Postgres receives an integer where it expects `timestamptz` and a number
/// where it expects `boolean` — which it will either reject or, worse, coerce.
///
/// Conversion is driven by each column's declared SQL type, so it covers every synced
/// table without a hand-written mapping per table that someone could forget to update.
///
/// Local timestamps have one-second resolution. Anything finer on the wire is truncated
/// on the way in; that loss is intended, since the local database could not represent it.
abstract final class WireCodec {
  /// A stored SQLite value, as it should be sent.
  static Object? toWire(GeneratedColumn<Object> column, Object? stored) {
    if (stored == null) return null;

    if (column.type == DriftSqlType.dateTime) {
      return switch (stored) {
        int seconds => DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toIso8601String(),
        // Only reachable if text storage is ever switched on.
        String text => DateTime.parse(text).toUtc().toIso8601String(),
        _ => throw FormatException(
          'unexpected stored value for ${column.name}',
          stored,
        ),
      };
    }

    if (column.type == DriftSqlType.bool) {
      return switch (stored) {
        int n => n != 0,
        bool b => b,
        _ => throw FormatException(
          'unexpected stored value for ${column.name}',
          stored,
        ),
      };
    }

    return stored;
  }

  /// A value received from the server, in the form SQLite stores.
  static Object? toStored(GeneratedColumn<Object> column, Object? wire) {
    if (wire == null) return null;

    if (column.type == DriftSqlType.dateTime) {
      final instant = switch (wire) {
        String text => DateTime.parse(text),
        int seconds => DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ),
        _ => throw FormatException(
          'unexpected wire value for ${column.name}',
          wire,
        ),
      };
      // Normalised to UTC before truncating, so an offset like +05:30 lands on the
      // right second rather than being read as local time.
      return instant.toUtc().millisecondsSinceEpoch ~/ 1000;
    }

    if (column.type == DriftSqlType.bool) {
      return switch (wire) {
        bool b => b ? 1 : 0,
        int n => n != 0 ? 1 : 0,
        _ => throw FormatException(
          'unexpected wire value for ${column.name}',
          wire,
        ),
      };
    }

    return wire;
  }

  /// A column by its SQL name, or null.
  static GeneratedColumn<Object>? column(TableInfo<Table, Object?> table, String name) {
    for (final c in table.$columns) {
      if (c.name == name) return c;
    }
    return null;
  }
}
