import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/repository/project_repository.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';

/// Labels on a task.
///
/// Rendered wherever the task is, not only in its detail sheet — a label you have to
/// open something to see is a label doing no work.
class TaskLabelChips extends ConsumerWidget {
  const TaskLabelChips({required this.taskId, this.dense = false, super.key});

  final String taskId;

  /// Dense mode drops the text and shows coloured dots. A list row has room for a due
  /// date and an estimate already; four label names would push the title out.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(labelsForTaskProvider(taskId));
    if (labels.isEmpty) return const SizedBox.shrink();

    if (dense) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in labels)
            Tooltip(
              message: '#${label.name}',
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: label.colour == null
                      ? AppColour.grey
                      : Color(label.colour!),
                  borderRadius: AppRadius.roundAll,
                ),
              ),
            ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: [
        for (final label in labels) _Chip(label: '#${label.name}', tint: _of(label)),
      ],
    );
  }

  static Color _of(Label label) =>
      label.colour == null ? AppColour.grey : Color(label.colour!);
}

/// Values for the project's fields that asked to be shown inline.
///
/// Only fields marked `showInline` appear here. A card that renders every field becomes
/// a form, and the point of a board is to scan it.
class InlineFieldChips extends ConsumerWidget {
  const InlineFieldChips({
    required this.task,
    required this.projectId,
    super.key,
  });

  final Task task;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(fieldsProvider(projectId)).value ?? const [];
    final inline = fields.where((f) => f.showInline).toList();
    if (inline.isEmpty) return const SizedBox.shrink();

    final values = ref.watch(fieldValuesProvider(projectId)).value ?? const {};
    final mine = values[task.id] ?? const <String, String?>{};

    final chips = <Widget>[];
    for (final field in inline) {
      final raw = mine[field.id];
      if (raw == null || raw.isEmpty) continue;

      switch (field.type) {
        case FieldType.checkbox:
          // Only shown when true: "Needs review: no" is noise on every card.
          if (raw == 'true') {
            chips.add(_Chip(label: field.name, tint: AppColour.green));
          }

        case FieldType.select:
          chips.add(
            _Chip(label: raw, tint: _optionColour(field, raw)),
          );

        case FieldType.multiSelect:
          for (final choice in _decodeList(raw)) {
            chips.add(_Chip(label: choice, tint: _optionColour(field, choice)));
          }

        case FieldType.date:
          final parsed = DateTime.tryParse(raw);
          chips.add(
            _Chip(
              label: parsed == null ? raw : Format.shortDate(parsed),
              tint: AppColour.grey,
            ),
          );

        case FieldType.url:
          // The value is a URL; the field's name is the useful label.
          chips.add(_Chip(label: field.name, tint: AppColour.accent));

        case FieldType.text:
        case FieldType.number:
          chips.add(_Chip(label: '${field.name} $raw', tint: AppColour.grey));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: AppSpace.xs, runSpacing: AppSpace.xs, children: chips);
  }

  static Color _optionColour(FieldDef field, String label) {
    for (final o in FieldOption.decode(field.optionsJson)) {
      if (o.label == label && o.colour != null) return Color(o.colour!);
    }
    return AppColour.grey;
  }

  static List<String> _decodeList(String raw) {
    try {
      final parsed = jsonDecode(raw);
      return parsed is List ? parsed.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 1),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.16),
      borderRadius: AppRadius.smallAll,
    ),
    child: Text(
      label,
      style: AppText.numeric.copyWith(color: tint),
    ),
  );
}

/// Resolves which project a task belongs to, via its section.
///
/// Tasks hold a section id, not a project id — denormalising the project onto the task
/// would be a second source of truth to keep in step on every board drag.
final projectOfTaskProvider = Provider.family<String?, String>((ref, taskId) {
  final sections = ref.watch(allSectionsProvider).value ?? const [];
  final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];

  final listId = tasks.where((t) => t.id == taskId).map((t) => t.listId).firstOrNull;
  if (listId == null) return null;

  return sections.where((s) => s.id == listId).map((s) => s.boardId).firstOrNull;
});
