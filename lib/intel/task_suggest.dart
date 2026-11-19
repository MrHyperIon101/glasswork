/// What your own history suggests for a task being added: the project, labels and estimate
/// of the past tasks most like it. Offline and pure — no model, just your titles — and only
/// ever offered, never applied: the composer shows each as a chip to take or leave.
library;

/// A task already there, as the suggestions see it.
class PastTask {
  const PastTask({
    required this.title,
    this.projectId,
    this.labels = const [],
    this.estimateMin,
    this.trackedMin,
  });

  final String title;
  final String? projectId;
  final List<String> labels;
  final int? estimateMin;

  /// How long it really took, where that was tracked. Preferred over the estimate.
  final int? trackedMin;
}

class TaskSuggestion {
  const TaskSuggestion({this.projectId, this.labels = const [], this.estimateMin, this.basedOn = 0});

  static const none = TaskSuggestion();

  final String? projectId;
  final List<String> labels;
  final int? estimateMin;

  /// How many past tasks it was worked out from, for the chip to say.
  final int basedOn;

  bool get isEmpty => projectId == null && labels.isEmpty && estimateMin == null;
}

abstract final class TaskSuggest {
  /// How alike two titles must be to count: a third of their words in common.
  static const _alike = 0.3;

  /// Alike enough that one past task alone is worth going by.
  static const _closely = 0.5;

  static const _filler = {
    'a', 'an', 'and', 'at', 'by', 'do', 'for', 'in', 'is', 'it', 'me', 'my', 'of', 'on',
    'or', 'the', 'to', 'up', 'with',
  };

  /// What the past tasks most like [title] have in common. [history] newest first: among
  /// equally alike tasks, the newest count first.
  static TaskSuggestion suggest(String title, List<PastTask> history, {int most = 5}) {
    final words = _words(title);
    if (words.isEmpty) return TaskSuggestion.none;

    final alike = <({PastTask task, double score})>[];
    for (final task in history) {
      final theirs = _words(task.title);
      if (theirs.isEmpty) continue;
      final shared = words.intersection(theirs);
      // At least one real word in common, not a short one that happens to match.
      if (!shared.any((w) => w.length >= 3)) continue;
      final score = shared.length / words.union(theirs).length;
      if (score >= _alike) alike.add((task: task, score: score));
    }
    if (alike.isEmpty) return TaskSuggestion.none;
    // Most alike first; the sort is stable, so newest first among equals.
    alike.sort((a, b) => b.score.compareTo(a.score));
    final near = alike.take(most).toList();
    // One alone is enough only when it is very like this one.
    final enough = near.length >= 2 || near.first.score >= _closely;
    if (!enough) return TaskSuggestion.none;

    final tasks = [for (final n in near) n.task];
    return TaskSuggestion(
      projectId: _mostOf([for (final t in tasks) ?t.projectId], tasks.length),
      labels: _common([for (final t in tasks) t.labels], tasks.length),
      estimateMin: _median([for (final t in tasks) ?(t.trackedMin ?? t.estimateMin)]),
      basedOn: tasks.length,
    );
  }

  /// Lower case, without filler words, a plural's s taken off: "Labs" and "lab" agree.
  static Set<String> _words(String text) => {
    for (final w in text.toLowerCase().split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)))
      if (w.isNotEmpty && !_filler.contains(w))
        w.length > 3 && w.endsWith('s') && !w.endsWith('ss') ? w.substring(0, w.length - 1) : w,
  };

  /// What more than half of [of] tasks have.
  static String? _mostOf(List<String> values, int of) {
    final counts = <String, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    for (final MapEntry(:key, :value) in counts.entries) {
      if (value * 2 > of) return key;
    }
    return null;
  }

  /// The labels at least half of [of] tasks carry, most common first.
  static List<String> _common(List<List<String>> labels, int of) {
    final counts = <String, int>{};
    for (final list in labels) {
      for (final l in list.toSet()) {
        counts[l] = (counts[l] ?? 0) + 1;
      }
    }
    final kept = [for (final e in counts.entries) if (e.value * 2 >= of) e.key];
    return kept..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  /// The middle of [minutes], to the nearest five: one long outlier does not drag it.
  static int? _median(List<int> minutes) {
    if (minutes.isEmpty) return null;
    final sorted = [...minutes]..sort();
    final mid = sorted.length ~/ 2;
    final middle = sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
    final rounded = (middle / 5).round() * 5;
    return rounded < 5 ? 5 : rounded;
  }
}
