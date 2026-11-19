import '../search/spotlight_index.dart';

/// Which project "@glasswork" names: the best of them by the same measure Spotlight finds
/// things by — the whole name, then its start, then a word in it, then its letters in order —
/// or none, when nothing comes close. Pure.
abstract final class ProjectMatch {
  /// Below this, a name only has the hint's letters somewhere in it: not what was meant.
  static const _least = 280;

  /// The id of the project [hint] names among [projects] (id and name), or null.
  static String? best(String? hint, List<({String id, String name})> projects, {required DateTime now}) {
    if (hint == null || hint.trim().isEmpty) return null;
    final hits = SpotlightIndex.search(
      hint.replaceAll(RegExp(r'[-_]'), ' '),
      [
        for (final p in projects)
          SpotlightItem(kind: SpotlightKind.project, id: p.id, title: p.name),
      ],
      now: now,
      limit: 1,
    );
    return hits.isNotEmpty && hits.first.score >= _least ? hits.first.item.id : null;
  }
}
