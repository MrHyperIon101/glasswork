import 'db/database.dart';
import 'db/tables.dart';

/// Where a project's finished work is shown.
///
/// Ticking a task moves nothing: the task keeps the section it was filed under, and this
/// only says where the views draw it. So reopening one puts it back where it came from
/// with nothing remembered, and renaming or deleting a Done section loses no work — the
/// board falls back to a completed column of its own.
abstract final class CompletedSection {
  /// What a section is called when it holds finished work, whichever word a project uses.
  static const names = {'done', 'completed', 'complete', 'finished'};

  /// The section completed work is drawn under, or null where the project has none and
  /// the board adds a column of its own instead.
  ///
  /// The `isDoneColumn` flag decides it — every project is created with its last section
  /// flagged — and the name is only a fallback, for a board built before anything read
  /// the flag. Two devices can each flag a different section offline and both survive the
  /// merge, so this takes the first in the sections' own order rather than assuming one.
  static BoardList? of(List<BoardList> sections) {
    for (final section in sections) {
      if (section.isDoneColumn) return section;
    }
    for (final section in sections) {
      if (names.contains(section.name.trim().toLowerCase())) return section;
    }
    return null;
  }

  /// The open work filed under [sectionId], in the order it was given.
  static List<Task> openIn(List<Task> tasks, String sectionId) => [
    for (final task in tasks)
      if (task.listId == sectionId && task.status != TaskStatus.done) task,
  ];

  /// Everything finished, wherever it was filed.
  static List<Task> done(List<Task> tasks) => [
    for (final task in tasks)
      if (task.status == TaskStatus.done) task,
  ];
}

/// The projects whose completed work is folded away, on this device.
///
/// Local, like which areas the sidebar shows closed: how you left a view is yours, not
/// something to push to your other devices.
abstract final class CollapsedCompleted {
  static const key = 'project.collapsed_completed';

  /// The smart views share one fold between them: they are one list of work seen
  /// several ways, not a place of their own. No project can collide with it — a project
  /// id is a uuid.
  static const smartViews = '~views';
}
