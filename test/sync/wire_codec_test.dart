import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/sync/wire_codec.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('timestamps', () {
    test('stored unix seconds go out as UTC ISO-8601', () {
      const seconds = 1789219055;
      expect(
        WireCodec.toWire(db.tasks.createdAt, seconds),
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
            .toIso8601String(),
      );
      expect(
        (WireCodec.toWire(db.tasks.createdAt, seconds)! as String).endsWith('Z'),
        isTrue,
        reason: 'an offset-less string would be read as local time by Postgres',
      );
    });

    test('round-trips exactly', () {
      const seconds = 1789219055;
      final wire = WireCodec.toWire(db.tasks.createdAt, seconds);
      expect(WireCodec.toStored(db.tasks.createdAt, wire), seconds);
    });

    test('an offset on the wire lands on the right UTC second', () {
      expect(
        WireCodec.toStored(db.tasks.createdAt, '2026-09-12T10:00:00+05:30'),
        DateTime.utc(2026, 9, 12, 4, 30).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('sub-second precision is truncated, as the local store cannot hold it', () {
      expect(
        WireCodec.toStored(db.tasks.createdAt, '2026-09-12T10:00:00.999Z'),
        DateTime.utc(2026, 9, 12, 10).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('rejects a value that is not a timestamp', () {
      expect(
        () => WireCodec.toStored(db.tasks.createdAt, 3.5),
        throwsFormatException,
      );
    });
  });

  group('booleans', () {
    test('0 and 1 go out as false and true', () {
      expect(WireCodec.toWire(db.subtasks.done, 1), isTrue);
      expect(WireCodec.toWire(db.subtasks.done, 0), isFalse);
    });

    test('come back as 1 and 0', () {
      expect(WireCodec.toStored(db.subtasks.done, true), 1);
      expect(WireCodec.toStored(db.subtasks.done, false), 0);
    });
  });

  test('text passes through untouched', () {
    expect(WireCodec.toWire(db.tasks.title, 'Lab report'), 'Lab report');
    expect(WireCodec.toStored(db.tasks.title, 'Lab report'), 'Lab report');
  });

  test('null is null both ways, for every type', () {
    for (final column in [db.tasks.createdAt, db.subtasks.done, db.tasks.title]) {
      expect(WireCodec.toWire(column, null), isNull);
      expect(WireCodec.toStored(column, null), isNull);
    }
  });

  test('finds columns by their SQL name', () {
    expect(WireCodec.column(db.tasks, 'due_date'), isNotNull);
    expect(WireCodec.column(db.tasks, 'dueDate'), isNull,
        reason: 'wire names are snake_case, not Dart names');
  });
}
