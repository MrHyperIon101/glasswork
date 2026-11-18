import '../data/db/database.dart';
import '../data/quick_add_parser.dart';
import 'providers.dart';

/// Adds a task from one typed line to [sectionId]: its dates, priority, estimate, labels,
/// reminder and time read out of it, the rest its title. Null when nothing was left to call it.
///
/// The one way a line becomes a task, so the composer's list of several and Spotlight's
/// "Add task" read a line exactly as each other does.
Future<Task?> addTaskFromLine(
  AppScope scope,
  String line, {
  required String sectionId,
  required DateTime now,
  required int morningMin,
}) async {
  final parsed = QuickAddParser.parse(line, now: now, morningMin: morningMin);
  if (parsed.title.isEmpty) return null;

  final created = await scope.tasks.create(
    listId: sectionId,
    workspaceId: scope.workspace.id,
    title: parsed.title,
    dueAt: parsed.dueAt,
    dueDate: parsed.dueDate,
    priority: parsed.priority,
    estimateMin: parsed.estimateMin,
    remindAt: parsed.remindAt,
    startAt: parsed.startAt,
  );
  for (final name in parsed.labels) {
    final label = await scope.labels.ensure(workspaceId: scope.workspace.id, name: name);
    await scope.labels.attach(
      workspaceId: scope.workspace.id,
      taskId: created.id,
      labelId: label.id,
    );
  }
  return created;
}
