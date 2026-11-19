import '../data/recents.dart';

/// What a Spotlight result is.
enum SpotlightKind { task, note, project, area, action }

/// One thing Spotlight can find: what it is called, what it says under that, and other
/// words it answers to.
class SpotlightItem {
  const SpotlightItem({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.keywords = const [],
    this.done = false,
  });

  final SpotlightKind kind;
  final String id;
  final String title;
  final String subtitle;

  /// Other words it answers to: "timetable" for Time budget, "pomodoro" for Start focus.
  final List<String> keywords;

  /// A finished task: still found, below everything still to do.
  final bool done;

  /// How it is named outside the app, over D-Bus: kind and id together.
  String get key => '${kind.name}:$id';

  @override
  String toString() => 'SpotlightItem($key, $title)';
}

/// A match and how good it is.
class SpotlightHit {
  const SpotlightHit(this.item, this.score);

  final SpotlightItem item;
  final double score;
}

/// Ranks what matches a query. Pure, and total, so the same query over the same things comes
/// back in the same order on every device and in every test.
///
/// Better matches first: the whole title, then a title that starts with the query, then a
/// word in it that does, then every word of the query starting a word, then the query
/// anywhere in it, then its letters in order. What you opened lately is nudged up — never
/// past a better match of a different strength.
abstract final class SpotlightIndex {
  static List<SpotlightHit> search(
    String query,
    List<SpotlightItem> items, {
    List<Recent> recents = const [],
    required DateTime now,
    int limit = 30,
  }) {
    final q = _normal(query);
    if (q.isEmpty) return const [];

    final lastOpened = <String, DateTime>{
      for (final recent in recents.reversed) '${_kindOf(recent.kind)?.name}:${recent.id}': recent.at,
    };

    final hits = <SpotlightHit>[];
    for (final item in items) {
      var score = _match(q, _normal(item.title));
      for (final keyword in item.keywords) {
        final viaKeyword = _match(q, _normal(keyword));
        if (viaKeyword != null) score = _max(score, viaKeyword * 0.9);
      }
      if (item.subtitle.isNotEmpty) {
        final viaSubtitle = _match(q, _normal(item.subtitle));
        if (viaSubtitle != null) score = _max(score, viaSubtitle * 0.5);
      }
      if (score == null) continue;

      if (item.done) score -= 150;
      if (lastOpened[item.key] case final at?) score += _recency(now.difference(at));
      hits.add(SpotlightHit(item, score));
    }

    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byTitle = a.item.title.toLowerCase().compareTo(b.item.title.toLowerCase());
      return byTitle != 0 ? byTitle : a.item.key.compareTo(b.item.key);
    });
    return hits.take(limit).toList();
  }

  /// How good a match [q] is in [text], both normalised, or null for none.
  static double? _match(String q, String text) {
    if (text.isEmpty) return null;
    if (text == q) return 1000;
    // Shorter titles first among equals: "Lab" before "Lab report" for "lab".
    final shortness = -0.5 * (text.length - q.length).clamp(0, 100);
    if (text.startsWith(q)) return 900 + shortness;

    // The same letters, written together or apart: "wifi" is "Wi-Fi", "app store" "AppStore".
    final joinedQ = q.replaceAll(_breaks, '');
    final joinedText = text.replaceAll(_breaks, '');
    if (joinedQ.isNotEmpty && (joinedQ != q || joinedText != text)) {
      if (joinedText == joinedQ) return 950;
      if (joinedText.startsWith(joinedQ)) return 850 + shortness;
    }

    final words = text.split(_breaks).where((w) => w.isNotEmpty).toList();
    if (words.any((w) => w.startsWith(q))) return 700 + shortness;

    final parts = q.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1 && parts.every((p) => words.any((w) => w.startsWith(p)))) {
      return 600 + shortness;
    }
    if (text.contains(q)) return 500 + shortness;

    // Its letters in order, fewer gaps better: "dbrp" finds "DBMS report".
    if (q.length < 2) return null;
    var at = 0;
    var gaps = 0;
    var last = -1;
    for (final char in q.replaceAll(' ', '').split('')) {
      final found = text.indexOf(char, at);
      if (found < 0) return null;
      if (last >= 0 && found != last + 1) gaps++;
      last = found;
      at = found + 1;
    }
    return 300 - 8.0 * gaps + shortness;
  }

  /// Opened in the last hour counts for most; after a week, nothing.
  static double _recency(Duration ago) {
    if (ago < const Duration(hours: 1)) return 80;
    if (ago < const Duration(days: 1)) return 50;
    if (ago < const Duration(days: 7)) return 20;
    return 0;
  }

  static SpotlightKind? _kindOf(RecentKind kind) => switch (kind) {
    RecentKind.task => SpotlightKind.task,
    RecentKind.note => SpotlightKind.note,
    RecentKind.project => SpotlightKind.project,
  };

  static double? _max(double? a, double b) => a == null || b > a ? b : a;

  static final _breaks = RegExp(r'[^a-z0-9]+');

  static String _normal(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
