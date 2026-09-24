import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../state/providers.dart';
import '../state/undo_controller.dart';

/// Ticks a task off, or puts it back.
///
/// In one place because every surface that can complete a task has to do it the same
/// way: the row leaves the open work at once, and the five seconds of undo that every
/// destructive action gets applies here too — ticking the wrong line is as easy as
/// deleting it, and on a board it happens with a drag.
///
/// Nothing is moved. A completed task keeps the section it was filed under and is simply
/// drawn under the project's completed column, so reopening it puts it back where it
/// came from without anything having to be remembered.
Future<void> setTaskDone(WidgetRef ref, Task task, {required bool done}) async {
  final scope = ref.read(appScopeProvider).value;
  if (scope == null) return;
  await scope.tasks.setDone(task.id, done: done);
  if (!done) return;
  ref
      .read(undoProvider.notifier)
      .offer(
        'Completed "${task.title}"',
        () => scope.tasks.setDone(task.id, done: false),
      );
}
