import '../sync/hlc.dart';
import '../sync/sync_writer.dart';
import 'db/database.dart';

/// How a note reads, derived from its stored fields.
///
/// Pure, so what a note card and the editor show — its heading, a preview, when it was last
/// written — is checked by a test rather than worked out inside a widget.
abstract final class NoteText {
  /// Longest a heading taken from typed text may be. Past this, the text is a body that
  /// happened to have no line break, not a title.
  static const headingLimit = 80;

  static const previewLimit = 180;

  /// Text typed in one go, as a title and a body: the first line is the title when it is
  /// short enough to be one, and the rest is the body.
  static ({String title, String body}) split(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return (title: '', body: '');
    final lineEnd = trimmed.indexOf('\n');
    final first = (lineEnd == -1 ? trimmed : trimmed.substring(0, lineEnd)).trim();
    if (first.length > headingLimit) return (title: '', body: trimmed);
    return (
      title: first,
      body: lineEnd == -1 ? '' : trimmed.substring(lineEnd + 1).trim(),
    );
  }

  /// What a note is called: its title, or the start of its body, or that it is empty.
  /// A note of nothing but [images] is headed by them.
  static String heading(Note note, {int images = 0}) {
    final title = note.title.trim();
    if (title.isNotEmpty) return title;
    final firstLine = note.bodyMd.trim().split('\n').first.trim();
    if (firstLine.isEmpty) {
      return switch (images) {
        0 => 'Empty note',
        1 => 'Image',
        final n => '$n images',
      };
    }
    return firstLine.length <= headingLimit
        ? firstLine
        : '${firstLine.substring(0, headingLimit).trimRight()}…';
  }

  /// A taste of the body, on one run of text, without whatever [heading] already shows.
  static String preview(Note note) {
    var body = note.bodyMd.trim();
    if (note.title.trim().isEmpty) {
      // The heading is this body's first line, so the preview starts after it.
      final lineEnd = body.indexOf('\n');
      body = lineEnd == -1 ? '' : body.substring(lineEnd + 1);
    }
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= previewLimit
        ? flat
        : '${flat.substring(0, previewLimit).trimRight()}…';
  }

  /// When a note was last written, on whichever device: the newest clock on its words or its
  /// pin, since the row keeps no edit time of its own. Its creation where it has no clock.
  static DateTime editedAt(Note note) {
    final versions = SyncWriter.decodeVersions(note.fieldVersions);
    var newest = note.createdAt.toUtc().millisecondsSinceEpoch;
    for (final field in const ['title', 'body_md', 'pinned']) {
      final wall = Hlc.tryDecode(versions[field])?.wallMs;
      if (wall != null && wall > newest) newest = wall;
    }
    return DateTime.fromMillisecondsSinceEpoch(newest, isUtc: true);
  }

  /// Pinned first, then the most recently written, then by id so every device agrees.
  static List<Note> sorted(Iterable<Note> notes) {
    final edited = {for (final note in notes) note.id: editedAt(note)};
    return notes.toList()..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final byTime = edited[b.id]!.compareTo(edited[a.id]!);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }

  /// When, as a note list says it: "Just now", "12 min ago", "14:05" earlier today,
  /// "Yesterday", a weekday within the week, and a date beyond.
  static String when(DateTime at, DateTime now) {
    final local = at.toLocal();
    final ago = now.difference(local);
    if (ago < const Duration(minutes: 1)) return 'Just now';
    if (ago < const Duration(hours: 1)) return '${ago.inMinutes} min ago';

    final days = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(local.year, local.month, local.day))
        .inDays;
    if (days == 0) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }
    if (days == 1) return 'Yesterday';
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (days < 7) return weekdays[local.weekday - 1];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${local.day} ${months[local.month - 1]}'
        '${local.year == now.year ? '' : ' ${local.year}'}';
  }
}
