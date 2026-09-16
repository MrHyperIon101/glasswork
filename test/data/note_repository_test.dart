import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/repository/note_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late NoteRepository notes;
  late String workspaceId;
  // Ahead of the real clock, which stamps created_at, so the order is decided by the edits.
  var nowMs = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final writer = SyncWriter(db, clientId: 'laptop', nowMs: () => nowMs);
    workspaceId = (await WorkspaceRepository(writer).ensureSeeded()).id;
    notes = NoteRepository(writer);
  });
  tearDown(() => db.close());

  Future<List<String>> outboxFor(String id) async => [
    for (final entry in await (db.select(db.outbox)..where((o) => o.rowId.equals(id))).get())
      entry.changedFields,
  ];

  test('a note typed in one go keeps its first line as the title, and syncs', () async {
    final note = await notes.capture(workspaceId: workspaceId, text: 'Groceries\nmilk\neggs');

    expect((note.title, note.bodyMd, note.pinned), ('Groceries', 'milk\neggs', false));
    expect(await outboxFor(note.id), isNotEmpty, reason: 'queued to reach other devices');
  });

  test('pinned first, then the note written to most recently', () async {
    final first = await notes.create(workspaceId: workspaceId, title: 'First');
    nowMs += 60000;
    await notes.create(workspaceId: workspaceId, title: 'Second');
    nowMs += 60000;
    await notes.setBody(first.id, 'written to again');
    final pinned = await notes.create(workspaceId: workspaceId, title: 'Pinned');
    await notes.setPinned(pinned.id, pinned: true);

    final shown = await notes.watchAll(workspaceId).first;
    expect([for (final n in shown) n.title], ['Pinned', 'First', 'Second']);
  });

  test('a deleted note is gone from the list until it is restored', () async {
    final note = await notes.create(workspaceId: workspaceId, title: 'Draft');

    await notes.softDelete(note.id);
    expect(await notes.watchAll(workspaceId).first, isEmpty);
    expect(await notes.watchNote(note.id).first, isNull);
    expect(
      (await (db.select(db.notes)..where((n) => n.id.equals(note.id))).getSingle()).deletedAt,
      isNotNull,
      reason: 'a tombstone, never a hard delete',
    );

    await notes.restore(note.id);
    expect([for (final n in await notes.watchAll(workspaceId).first) n.title], ['Draft']);
  });
}
