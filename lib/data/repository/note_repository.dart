import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../note_text.dart';

/// Quick notes: a title and some text, kept and synced alongside the tasks.
///
/// The same contract as every repository: nothing here awaits the network, every write goes
/// through [SyncWriter], and deleting is a tombstone that can be undone.
class NoteRepository {
  NoteRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  /// Live notes, pinned first, then the most recently written.
  Stream<List<Note>> watchAll(String workspaceId) =>
      (_db.select(_db.notes)
            ..where((n) => n.workspaceId.equals(workspaceId) & n.deletedAt.isNull()))
          .watch()
          .map(NoteText.sorted);

  Stream<Note?> watchNote(String id) =>
      (_db.select(_db.notes)..where((n) => n.id.equals(id) & n.deletedAt.isNull()))
          .watchSingleOrNull();

  Future<Note> create({
    required String workspaceId,
    String title = '',
    String body = '',
  }) => _writer.insert(
    _db.notes,
    NotesCompanion.insert(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      title: title,
      bodyMd: Value(body),
    ),
  );

  /// A note from text typed in one go: its first line the title, the rest the body.
  Future<Note> capture({required String workspaceId, required String text}) {
    final (:title, :body) = NoteText.split(text);
    return create(workspaceId: workspaceId, title: title, body: body);
  }

  Future<void> setTitle(String id, String title) =>
      _writer.update(_db.notes, id, NotesCompanion(title: Value(title)));

  Future<void> setBody(String id, String body) =>
      _writer.update(_db.notes, id, NotesCompanion(bodyMd: Value(body)));

  Future<void> setPinned(String id, {required bool pinned}) =>
      _writer.update(_db.notes, id, NotesCompanion(pinned: Value(pinned)));

  Future<void> softDelete(String id) =>
      _writer.update(_db.notes, id, NotesCompanion(deletedAt: Value(DateTime.now())));

  Future<void> restore(String id) =>
      _writer.update(_db.notes, id, const NotesCompanion(deletedAt: Value(null)));
}
