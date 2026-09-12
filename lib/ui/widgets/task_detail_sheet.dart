import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../surface.dart';

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

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: close,
            child: const ColoredBox(color: Color(0xA6000000)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
              child: VibrancyMaterial.sheet(
                child: _Body(task: task, onClose: close),
              ),
            ),
          ),
        ),
      ],
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
              _Section(label: 'Due', child: _DueControls(task: task)),
              const SizedBox(height: AppSpace.xl),
              _Section(label: 'Priority', child: _PriorityControls(task: task)),
              const SizedBox(height: AppSpace.xl),
              _Section(label: 'Estimate', child: _EstimateControls(task: task)),
              const SizedBox(height: AppSpace.xl),
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

class _DueControls extends ConsumerWidget {
  const _DueControls({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final today = DateTime.now();
    final due = Format.due(task, today);

    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    void setDate(DateTime? d) => scope?.tasks.setDue(
      task.id,
      dueAt: null,
      dueDate: d == null ? null : iso(d),
    );

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        if (due != null)
          _Chip(
            label: due.label,
            selected: true,
            tint: due.colour,
            onTap: () {},
          ),
        _Chip(
          label: 'Today',
          selected: false,
          onTap: () => setDate(today),
        ),
        _Chip(
          label: 'Tomorrow',
          selected: false,
          onTap: () => setDate(today.add(const Duration(days: 1))),
        ),
        _Chip(
          label: 'Next week',
          selected: false,
          onTap: () => setDate(today.add(const Duration(days: 7))),
        ),
        _Chip(
          label: 'Pick…',
          selected: false,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: today,
              firstDate: DateTime(today.year - 1),
              lastDate: DateTime(today.year + 5),
            );
            if (picked != null) setDate(picked);
          },
        ),
        if (due != null)
          _Chip(
            label: 'Clear',
            selected: false,
            tint: AppColour.labelTertiary,
            onTap: () => setDate(null),
          ),
      ],
    );
  }
}

class _PriorityControls extends ConsumerWidget {
  const _PriorityControls({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    const options = [(0, 'None'), (1, 'Low'), (2, 'Medium'), (3, 'High')];
    const tints = [
      AppColour.labelTertiary,
      AppColour.grey,
      AppColour.orange,
      AppColour.red,
    ];

    return Wrap(
      spacing: AppSpace.sm,
      children: [
        for (final (value, label) in options)
          _Chip(
            label: label,
            selected: task.priority == value,
            tint: tints[value],
            onTap: () => scope?.tasks.setPriority(task.id, value),
          ),
      ],
    );
  }
}

class _EstimateControls extends ConsumerWidget {
  const _EstimateControls({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    // Sizes, not a number field. One tap is the difference between estimating
    // everything and estimating nothing.
    const sizes = [15, 30, 60, 120, 240];

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final mins in sizes)
          _Chip(
            label: Format.estimate(mins),
            selected: task.estimateMin == mins,
            onTap: () => scope?.tasks.setEstimate(
              task.id,
              task.estimateMin == mins ? null : mins,
            ),
          ),
      ],
    );
  }
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

class _Chip extends StatefulWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tint = widget.tint ?? AppColour.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm - 1,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? tint.withValues(alpha: 0.18)
                : _hovered
                ? AppColour.fillStrong
                : AppColour.fill,
            borderRadius: AppRadius.smallAll,
            border: Border.all(
              color: widget.selected
                  ? tint.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            widget.label,
            style: AppText.numeric.copyWith(
              color: widget.selected ? tint : AppColour.labelSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

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
