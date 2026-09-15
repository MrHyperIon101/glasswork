import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../state/reminders_controller.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../sheet.dart';
import '../surface.dart';
import 'field_controls.dart';
import 'reminder_picker.dart';

/// The task inspector.
///
/// Opens over the content as a sheet. Everything edits in place and saves immediately —
/// there is no Save button, because the database is local and a write costs nothing, so a
/// confirmation step would be ceremony with no purpose.
class TaskDetailSheet extends ConsumerWidget {
  const TaskDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(openTaskDetailProvider).value;

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: task == null
          ? const SizedBox.shrink(key: ValueKey('closed'))
          : _Sheet(key: ValueKey(task.id), task: task),
    );
  }
}

class _Sheet extends ConsumerWidget {
  const _Sheet({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() => ref.read(openTaskProvider.notifier).close();

    return ModalSheet(
      onClose: close,
      maxWidth: 560,
      alignment: Alignment.center,
      scrim: 0.65,
      child: _Body(task: task, onClose: close),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.task, required this.onClose});

  final Task task;
  final VoidCallback onClose;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _title = TextEditingController(
    text: widget.task.title,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.task.notesMd ?? '',
  );
  final _subtaskInput = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _subtaskInput.dispose();
    super.dispose();
  }

  AppScope? get _scope => ref.read(appScopeProvider).value;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task.status == TaskStatus.done;
    final subtasks = ref.watch(subtasksProvider(task.id)).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxl,
            AppSpace.xl,
            AppSpace.lg,
            AppSpace.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Check(
                done: done,
                onTap: () =>
                    _scope?.tasks.setDone(task.id, done: !done),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: TextField(
                  controller: _title,
                  style: AppText.title3.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColour.labelTertiary,
                  ),
                  maxLines: null,
                  cursorColor: AppColour.accent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    if (v.trim().isNotEmpty) {
                      _scope?.tasks.rename(task.id, v.trim());
                    }
                  },
                ),
              ),
              _SmallIcon(icon: Icons.close, onTap: widget.onClose),
            ],
          ),
        ),
        const AppDivider(),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xxl,
              AppSpace.lg,
              AppSpace.xxl,
              AppSpace.lg,
            ),
            children: [
              _Section(
                label: 'Due',
                child: DueChips(
                  dueAt: task.dueAt,
                  dueDate: _isoToDate(task.dueDate),
                  onChanged: (at, date) => _scope?.tasks.setDue(
                    task.id,
                    dueAt: at,
                    dueDate: at == null ? _isoOf(date) : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(label: 'Remind me', child: _Reminder(task: task)),
              const SizedBox(height: AppSpace.xl),
              _Section(
                label: 'Priority',
                child: PriorityChips(
                  value: task.priority,
                  onChanged: (p) => _scope?.tasks.setPriority(task.id, p),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(
                label: 'Estimate',
                child: EstimateChips(
                  value: task.estimateMin,
                  onChanged: (m) => _scope?.tasks.setEstimate(task.id, m),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(
                label: 'Labels',
                child: _TaskLabels(task: task),
              ),
              const SizedBox(height: AppSpace.xl),
              _CustomFields(task: task),
              _Section(
                label: subtasks.isEmpty
                    ? 'Steps'
                    : 'Steps · ${subtasks.where((s) => s.done).length}'
                          '/${subtasks.length}',
                child: _Subtasks(
                  task: task,
                  subtasks: subtasks,
                  controller: _subtaskInput,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(
                label: 'Notes',
                child: TextField(
                  controller: _notes,
                  style: AppText.body,
                  maxLines: null,
                  minLines: 3,
                  cursorColor: AppColour.accent,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColour.fill,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mediumAll,
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Anything worth remembering',
                    hintStyle: AppText.callout.copyWith(
                      color: AppColour.labelTertiary,
                    ),
                    contentPadding: const EdgeInsets.all(AppSpace.md),
                  ),
                  onChanged: (v) =>
                      _scope?.tasks.setNotes(task.id, v.isEmpty ? null : v),
                ),
              ),
            ],
          ),
        ),
        const AppDivider(),
        Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              _TextButton(
                label: 'Delete task',
                tint: AppColour.red,
                onTap: () async {
                  final scope = _scope;
                  if (scope == null) return;
                  widget.onClose();
                  await scope.tasks.softDelete(task.id);
                  ref
                      .read(undoProvider.notifier)
                      .offer(
                        'Deleted "${task.title}"',
                        () => scope.tasks.restore(task.id),
                      );
                },
              ),
              const Spacer(),
              Text(
                'Created ${Format.shortDate(task.createdAt)}',
                style: AppText.numeric.copyWith(
                  color: AppColour.labelTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? _isoOf(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

DateTime? _isoToDate(String? iso) {
  if (iso == null) return null;
  final p = iso.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  return (y == null || m == null || d == null) ? null : DateTime(y, m, d);
}

/// When to be reminded about this task.
class _Reminder extends ConsumerWidget {
  const _Reminder({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;

    return ReminderPicker(
      remindAt: task.remindAt,
      dueAt: task.dueAt,
      dueDate: _isoToDate(task.dueDate),
      permitted: ref.watch(reminderPermissionProvider).value ?? true,
      onChanged: (at) async {
        await scope?.tasks.setReminder(task.id, at);
        if (at == null) return;
        // Asked the first time a reminder is wanted, which is when the question makes
        // sense, rather than at launch.
        await ref.read(reminderServiceProvider).requestPermission();
        ref.invalidate(reminderPermissionProvider);
      },
    );
  }
}

/// Labels on this task. Toggling writes immediately, like everything else here.
class _TaskLabels extends ConsumerWidget {
  const _TaskLabels({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final mine = ref.watch(labelsForTaskProvider(task.id));
    final names = mine.map((l) => l.name).toSet();

    return LabelPicker(
      selectedNames: names,
      onToggle: (name) async {
        if (scope == null) return;
        final label = await scope.labels.ensure(
          workspaceId: task.workspaceId,
          name: name,
        );
        if (names.contains(name)) {
          await scope.labels.detach(taskId: task.id, labelId: label.id);
        } else {
          await scope.labels.attach(
            workspaceId: task.workspaceId,
            taskId: task.id,
            labelId: label.id,
          );
        }
      },
    );
  }
}

/// The project's own fields, if it defines any.
class _CustomFields extends ConsumerWidget {
  const _CustomFields({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final sections = ref.watch(allSectionsProvider).value ?? const [];
    final projectId = sections
        .where((s) => s.id == task.listId)
        .map((s) => s.boardId)
        .firstOrNull;
    if (projectId == null) return const SizedBox.shrink();

    final fields = ref.watch(fieldsProvider(projectId)).value ?? const [];
    if (fields.isEmpty) return const SizedBox.shrink();

    final values = ref.watch(fieldValuesProvider(projectId)).value ?? const {};
    final mine = values[task.id] ?? const <String, String?>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in fields) ...[
          _Section(
            label: field.name,
            child: CustomFieldControl(
              key: ValueKey('${task.id}:${field.id}'),
              field: field,
              value: mine[field.id],
              onChanged: (v) => scope?.projects.setFieldValue(
                workspaceId: task.workspaceId,
                taskId: task.id,
                fieldId: field.id,
                value: v,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.caption),
      const SizedBox(height: AppSpace.sm),
      child,
    ],
  );
}




class _Subtasks extends ConsumerWidget {
  const _Subtasks({
    required this.task,
    required this.subtasks,
    required this.controller,
  });

  final Task task;
  final List<Subtask> subtasks;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;

    Future<void> add() async {
      final text = controller.text.trim();
      if (text.isEmpty || scope == null) return;
      controller.clear();
      await scope.subtasks.create(
        taskId: task.id,
        workspaceId: task.workspaceId,
        title: text,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final step in subtasks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Row(
              children: [
                _Check(
                  done: step.done,
                  small: true,
                  onTap: () =>
                      scope?.subtasks.setDone(step.id, done: !step.done),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    step.title,
                    style: AppText.callout.copyWith(
                      color: step.done
                          ? AppColour.labelTertiary
                          : AppColour.label,
                      decoration: step.done
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColour.labelTertiary,
                    ),
                  ),
                ),
                _SmallIcon(
                  icon: Icons.close,
                  size: 13,
                  onTap: () => scope?.subtasks.softDelete(step.id),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs),
          child: Row(
            children: [
              const Icon(Icons.add, size: 15, color: AppColour.labelTertiary),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: AppText.callout.copyWith(color: AppColour.label),
                  cursorColor: AppColour.accent,
                  onSubmitted: (_) => add(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Add a step',
                    hintStyle: AppText.callout.copyWith(
                      color: AppColour.labelTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- small shared controls --------------------------------------------------


class _Check extends StatelessWidget {
  const _Check({required this.done, required this.onTap, this.small = false});

  final bool done;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 16.0 : 20.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: AnimatedContainer(
            duration: AppMotion.quick,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColour.green : null,
              border: Border.all(
                color: done ? AppColour.green : AppColour.labelQuaternary,
                width: 1.5,
              ),
            ),
            child: done
                ? Icon(
                    Icons.check,
                    size: small ? 10 : 12,
                    color: AppColour.base,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon({required this.icon, required this.onTap, this.size = 16});

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xs),
        child: Icon(icon, size: size, color: AppColour.labelTertiary),
      ),
    ),
  );
}

class _TextButton extends StatefulWidget {
  const _TextButton({
    required this.label,
    required this.onTap,
    required this.tint,
  });

  final String label;
  final VoidCallback onTap;
  final Color tint;

  @override
  State<_TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<_TextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: _hovered ? widget.tint.withValues(alpha: 0.14) : null,
          borderRadius: AppRadius.smallAll,
        ),
        child: Text(
          widget.label,
          style: AppText.callout.copyWith(color: widget.tint),
        ),
      ),
    ),
  );
}
