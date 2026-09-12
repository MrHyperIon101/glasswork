import 'dart:convert';

/// What is being hidden from the current project view.
///
/// Kept out of the provider file and free of Flutter so it can be tested directly, and
/// so saved views have something to serialise. A saved view is nothing more than a name,
/// a render kind, and one of these.
class ProjectFilter {
  const ProjectFilter({
    this.labelIds = const {},
    this.priorities = const {},
    this.hideCompleted = false,
    this.onlyAtRisk = false,
  });

  final Set<String> labelIds;
  final Set<int> priorities;
  final bool hideCompleted;
  final bool onlyAtRisk;

  static const empty = ProjectFilter();

  bool get isEmpty =>
      labelIds.isEmpty && priorities.isEmpty && !hideCompleted && !onlyAtRisk;

  int get activeCount =>
      labelIds.length +
      priorities.length +
      (hideCompleted ? 1 : 0) +
      (onlyAtRisk ? 1 : 0);

  ProjectFilter copyWith({
    Set<String>? labelIds,
    Set<int>? priorities,
    bool? hideCompleted,
    bool? onlyAtRisk,
  }) => ProjectFilter(
    labelIds: labelIds ?? this.labelIds,
    priorities: priorities ?? this.priorities,
    hideCompleted: hideCompleted ?? this.hideCompleted,
    onlyAtRisk: onlyAtRisk ?? this.onlyAtRisk,
  );

  /// Only non-default values are written, so a stored filter stays readable and adding a
  /// new option later does not invalidate what is already saved.
  String encode() {
    final map = <String, Object?>{
      if (labelIds.isNotEmpty) 'labels': labelIds.toList()..sort(),
      if (priorities.isNotEmpty) 'priorities': priorities.toList()..sort(),
      if (hideCompleted) 'hideCompleted': true,
      if (onlyAtRisk) 'onlyAtRisk': true,
    };
    return jsonEncode(map);
  }

  /// Tolerant by design. A filter is a view preference, not data — if a stored one is
  /// malformed or references a label that has since been deleted, showing everything is
  /// the right failure. Throwing would make a bad row unopenable.
  static ProjectFilter decode(String? json) {
    if (json == null || json.trim().isEmpty) return empty;

    Object? raw;
    try {
      raw = jsonDecode(json);
    } on FormatException {
      return empty;
    }
    if (raw is! Map) return empty;

    return ProjectFilter(
      labelIds: _strings(raw['labels']),
      priorities: _ints(raw['priorities']),
      hideCompleted: raw['hideCompleted'] == true,
      onlyAtRisk: raw['onlyAtRisk'] == true,
    );
  }

  /// Drops label ids that no longer exist.
  ///
  /// A deleted label leaving a filter behind would hide every task with no way to see
  /// why — the chip for it is gone from the bar, so there would be nothing to un-tick.
  ProjectFilter pruned(Set<String> knownLabelIds) {
    final kept = labelIds.where(knownLabelIds.contains).toSet();
    return kept.length == labelIds.length ? this : copyWith(labelIds: kept);
  }

  static Set<String> _strings(Object? v) =>
      v is List ? v.whereType<String>().toSet() : const {};

  static Set<int> _ints(Object? v) =>
      v is List ? v.whereType<int>().toSet() : const {};

  @override
  bool operator ==(Object other) =>
      other is ProjectFilter &&
      other.hideCompleted == hideCompleted &&
      other.onlyAtRisk == onlyAtRisk &&
      _sameSet(other.labelIds, labelIds) &&
      _sameSet(other.priorities, priorities);

  @override
  int get hashCode => Object.hash(
    hideCompleted,
    onlyAtRisk,
    Object.hashAllUnordered(labelIds),
    Object.hashAllUnordered(priorities),
  );

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
