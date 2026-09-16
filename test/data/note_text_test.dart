import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/note_text.dart';
import 'package:glasswork/sync/hlc.dart';

void main() {
  final created = DateTime.utc(2026, 9, 10, 8);

  Note note({
    String id = 'n',
    String title = '',
    String body = '',
    bool pinned = false,
    Map<String, int> editedMs = const {},
  }) => Note(
    id: id,
    createdAt: created,
    updatedAt: created,
    fieldVersions: jsonEncode({
      for (final entry in editedMs.entries)
        entry.key: Hlc(entry.value, 0, 'laptop').encode(),
    }),
    workspaceId: 'ws',
    title: title,
    bodyMd: body,
    pinned: pinned,
  );

  test('typed text splits into a title line and a body', () {
    expect(NoteText.split('Groceries\nmilk\neggs'), (title: 'Groceries', body: 'milk\neggs'));
    expect(NoteText.split('  Call mum  '), (title: 'Call mum', body: ''));
    expect(NoteText.split('\n\n'), (title: '', body: ''));
    final long = 'word ' * 30;
    expect(
      NoteText.split(long),
      (title: '', body: long.trim()),
      reason: 'a paragraph with no line break is a body, not a title',
    );
  });

  test('a heading is the title, else the first line, else says it is empty', () {
    expect(NoteText.heading(note(title: 'Ideas', body: 'one')), 'Ideas');
    expect(NoteText.heading(note(body: 'first line\nsecond')), 'first line');
    expect(NoteText.heading(note()), 'Empty note');
  });

  test('a preview skips what the heading shows and runs on one line', () {
    expect(NoteText.preview(note(title: 'Ideas', body: 'one\n\ntwo')), 'one two');
    expect(NoteText.preview(note(body: 'first line\nsecond\nthird')), 'second third');
    expect(NoteText.preview(note(body: 'only line')), '');
    expect(NoteText.preview(note(title: 't', body: 'x' * 400)).length, NoteText.previewLimit + 1);
  });

  test('edited is the newest clock on its words, or its creation', () {
    final later = DateTime.utc(2026, 9, 12, 9).millisecondsSinceEpoch;
    expect(NoteText.editedAt(note()), created);
    expect(
      NoteText.editedAt(note(editedMs: {'title': created.millisecondsSinceEpoch, 'body_md': later})),
      DateTime.fromMillisecondsSinceEpoch(later, isUtc: true),
    );
    expect(
      NoteText.editedAt(note(editedMs: {'workspace_id': later})),
      created,
      reason: 'only the words and the pin count as writing it',
    );
  });

  test('pinned come first, then the most recently written', () {
    final ms = DateTime.utc(2026, 9, 12).millisecondsSinceEpoch;
    final old = note(id: 'old', body: 'a', editedMs: {'body_md': ms});
    final fresh = note(id: 'fresh', body: 'b', editedMs: {'body_md': ms + 60000});
    final pinned = note(id: 'pinned', body: 'c', pinned: true);
    expect([for (final n in NoteText.sorted([old, fresh, pinned])) n.id], ['pinned', 'fresh', 'old']);
  });

  test('when reads the way a list of notes says it', () {
    final now = DateTime(2026, 9, 16, 18, 30);
    expect(NoteText.when(now.subtract(const Duration(seconds: 20)), now), 'Just now');
    expect(NoteText.when(now.subtract(const Duration(minutes: 12)), now), '12 min ago');
    expect(NoteText.when(DateTime(2026, 9, 16, 9, 5), now), '09:05');
    expect(NoteText.when(DateTime(2026, 9, 15, 22), now), 'Yesterday');
    expect(NoteText.when(DateTime(2026, 9, 12, 10), now), 'Saturday');
    expect(NoteText.when(DateTime(2026, 8, 2, 10), now), '2 Aug');
    expect(NoteText.when(DateTime(2025, 8, 2, 10), now), '2 Aug 2025');
  });
}
