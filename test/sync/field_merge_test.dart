import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/sync/field_merge.dart';
import 'package:glasswork/sync/hlc.dart';

const phone = 'phone';
const laptop = 'laptop';

/// Monday, Tuesday, Wednesday, as HLC wall times.
const monday = 1000000;
const tuesday = 2000000;
const wednesday = 3000000;

String at(int wall, String node, [int counter = 0]) =>
    Hlc(wall, counter, node).encode();

VersionedFields change(Map<String, Object?> values, String clock) =>
    VersionedFields(values, {for (final k in values.keys) k: clock});

void main() {
  test('the first write to a field is accepted', () {
    final result = FieldMerge.apply(
      current: const VersionedFields.empty(),
      incoming: change({'title': 'Lab report'}, at(monday, phone)),
    );

    expect(result.values['title'], 'Lab report');
    expect(result.accepted, {'title'});
    expect(result.rejected, isEmpty);
  });

  test('a newer write wins', () {
    final current = change({'title': 'old'}, at(monday, phone));
    final result = FieldMerge.apply(
      current: current,
      incoming: change({'title': 'new'}, at(tuesday, laptop)),
    );

    expect(result.values['title'], 'new');
    expect(result.versions['title'], at(tuesday, laptop));
  });

  /// The bug docs/architecture.md exists to prevent.
  ///
  /// Phone edits the title offline on Monday. Laptop edits the same title on Tuesday and
  /// syncs. Phone reconnects on Wednesday. If ordering used arrival time, Monday's stale
  /// edit would win because it arrived last. It must not.
  test("a stale offline edit syncing late does not overwrite Tuesday's", () {
    final afterTuesday = change({'title': 'Tuesday (laptop)'}, at(tuesday, laptop));

    final mondayEditArrivingWednesday = change(
      {'title': 'Monday (phone)'},
      at(monday, phone),
    );

    final result = FieldMerge.apply(
      current: afterTuesday,
      incoming: mondayEditArrivingWednesday,
    );

    expect(result.values['title'], 'Tuesday (laptop)');
    expect(result.rejected, {'title'});
    expect(result.changed, isFalse);
  });

  /// And the reason for merging per field rather than per row.
  test('edits to different fields on different devices both survive', () {
    final row = VersionedFields(
      {'title': 'Lab report', 'due_date': '2026-09-20'},
      {'title': at(monday, phone), 'due_date': at(monday, phone)},
    );

    // Phone renames; laptop moves the date. Row-level LWW would drop one of them.
    final phoneRename = change({'title': 'DBMS lab report'}, at(tuesday, phone));
    final laptopReschedule = change({'due_date': '2026-09-22'}, at(tuesday, laptop));

    final afterPhone = FieldMerge.apply(current: row, incoming: phoneRename);
    final afterBoth = FieldMerge.apply(
      current: VersionedFields(afterPhone.values, afterPhone.versions),
      incoming: laptopReschedule,
    );

    expect(afterBoth.values['title'], 'DBMS lab report');
    expect(afterBoth.values['due_date'], '2026-09-22');
  });

  test('delivering the same change twice changes nothing the second time', () {
    final incoming = change({'title': 'once'}, at(tuesday, laptop));

    final first = FieldMerge.apply(
      current: const VersionedFields.empty(),
      incoming: incoming,
    );
    final second = FieldMerge.apply(
      current: VersionedFields(first.values, first.versions),
      incoming: incoming,
    );

    expect(second.values, first.values);
    expect(second.versions, first.versions);
    expect(second.changed, isFalse);
    expect(second.rejected, isEmpty, reason: 'a redelivery is not a conflict');
  });

  test('merge order does not change the result', () {
    const base = VersionedFields(
      {'title': 'base', 'priority': 0, 'notes_md': null},
      {},
    );
    final a = VersionedFields(
      {'title': 'from A', 'priority': 3},
      {'title': at(tuesday, phone), 'priority': at(monday, phone)},
    );
    final b = VersionedFields(
      {'title': 'from B', 'priority': 1},
      {'title': at(monday, laptop), 'priority': at(wednesday, laptop)},
    );

    VersionedFields applyAll(List<VersionedFields> changes) {
      var row = base;
      for (final c in changes) {
        final r = FieldMerge.apply(current: row, incoming: c);
        row = VersionedFields(r.values, r.versions);
      }
      return row;
    }

    final ab = applyAll([a, b]);
    final ba = applyAll([b, a]);

    expect(ab.values, ba.values);
    expect(ab.versions, ba.versions);
    // A's title is newer; B's priority is newer.
    expect(ab.values['title'], 'from A');
    expect(ab.values['priority'], 1);
  });

  test('identical wall times are broken by device, the same way everywhere', () {
    final fromPhone = change({'title': 'phone'}, at(tuesday, phone));
    final fromLaptop = change({'title': 'laptop'}, at(tuesday, laptop));

    final one = FieldMerge.apply(
      current: VersionedFields(
        FieldMerge.apply(current: const VersionedFields.empty(), incoming: fromPhone).values,
        {'title': at(tuesday, phone)},
      ),
      incoming: fromLaptop,
    );
    final other = FieldMerge.apply(
      current: VersionedFields(
        FieldMerge.apply(current: const VersionedFields.empty(), incoming: fromLaptop).values,
        {'title': at(tuesday, laptop)},
      ),
      incoming: fromPhone,
    );

    // 'phone' > 'laptop' as strings, so the phone's edit holds on both sides.
    expect(one.values['title'], 'phone');
    expect(other.values['title'], 'phone');
  });

  test('a change with no clock is refused rather than guessed', () {
    final result = FieldMerge.apply(
      current: change({'title': 'kept'}, at(monday, phone)),
      incoming: const VersionedFields({'title': 'unversioned'}, {}),
    );

    expect(result.values['title'], 'kept');
    expect(result.rejected, {'title'});
  });

  test('an unreadable stored clock is healed by a valid incoming one', () {
    final result = FieldMerge.apply(
      current: const VersionedFields({'title': 'corrupt'}, {'title': 'garbage'}),
      incoming: change({'title': 'healed'}, at(monday, phone)),
    );

    expect(result.values['title'], 'healed');
    expect(result.versions['title'], at(monday, phone));
  });

  test('fields the change does not mention are left alone', () {
    final row = VersionedFields(
      {'title': 'keep me', 'priority': 2},
      {'title': at(monday, phone), 'priority': at(monday, phone)},
    );
    final result = FieldMerge.apply(
      current: row,
      incoming: change({'priority': 3}, at(tuesday, laptop)),
    );

    expect(result.values['title'], 'keep me');
    expect(result.versions['title'], at(monday, phone));
    expect(result.values['priority'], 3);
  });

  /// Deletion is just another field, so it merges like one.
  test('a delete and a concurrent edit both survive, and restore shows the edit', () {
    var row = VersionedFields(
      {'title': 'Lab report', 'deleted_at': null},
      {'title': at(monday, phone), 'deleted_at': at(monday, phone)},
    );

    // Laptop deletes the task; phone renames it, neither having seen the other.
    for (final c in [
      change({'deleted_at': '2026-09-15T10:00:00Z'}, at(tuesday, laptop)),
      change({'title': 'DBMS lab report'}, at(tuesday, phone, 1)),
    ]) {
      final r = FieldMerge.apply(current: row, incoming: c);
      row = VersionedFields(r.values, r.versions);
    }

    expect(row.values['deleted_at'], isNotNull, reason: 'still deleted');
    expect(row.values['title'], 'DBMS lab report', reason: 'the rename is not lost');

    // Undo on the laptop, later.
    final restored = FieldMerge.apply(
      current: row,
      incoming: change({'deleted_at': null}, at(wednesday, laptop)),
    );
    expect(restored.values['deleted_at'], isNull);
    expect(restored.values['title'], 'DBMS lab report');
  });
}
