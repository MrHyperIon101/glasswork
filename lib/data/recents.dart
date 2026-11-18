import 'dart:convert';

/// What can be opened again from Recents.
enum RecentKind { task, note, project }

/// Something opened, and when.
class Recent {
  const Recent(this.kind, this.id, this.at);

  final RecentKind kind;
  final String id;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is Recent && other.kind == kind && other.id == id && other.at == at;

  @override
  int get hashCode => Object.hash(kind, id, at);

  @override
  String toString() => 'Recent(${kind.name} $id at $at)';
}

/// The tasks, notes and projects opened most recently on this device, newest first.
///
/// Kept in one `LocalSettings` row, like which areas are folded away: what you were looking at
/// is this device's, not something to send to your others. Pure, so the order is tested.
abstract final class Recents {
  static const key = 'recents';

  /// How many are kept. Spotlight shows a handful, the home page a few more; nobody goes back
  /// to the twenty-first thing they opened from a list.
  static const keep = 20;

  /// [list] with [opened] at the front, once, and the oldest beyond [keep] gone.
  static List<Recent> record(List<Recent> list, Recent opened) => [
    opened,
    for (final recent in list)
      if (recent.kind != opened.kind || recent.id != opened.id) recent,
  ].take(keep).toList();

  /// Without [id] — when it has been deleted, so Recents never offers something not there.
  static List<Recent> without(List<Recent> list, RecentKind kind, String id) => [
    for (final recent in list)
      if (recent.kind != kind || recent.id != id) recent,
  ];

  /// Tolerant: a damaged or unknown entry is skipped, never thrown on, since Recents is a
  /// convenience and must not stop anything opening.
  static List<Recent> parse(String? stored) {
    if (stored == null || stored.isEmpty) return const [];
    Object? raw;
    try {
      raw = jsonDecode(stored);
    } on FormatException {
      return const [];
    }
    if (raw is! List) return const [];
    final recents = <Recent>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final kind = RecentKind.values.where((k) => k.name == entry['k']).firstOrNull;
      final id = entry['id'];
      final at = DateTime.tryParse('${entry['at']}');
      if (kind == null || id is! String || at == null) continue;
      recents.add(Recent(kind, id, at));
    }
    return recents;
  }

  static String format(List<Recent> list) => jsonEncode([
    for (final recent in list)
      {'k': recent.kind.name, 'id': recent.id, 'at': recent.at.toUtc().toIso8601String()},
  ]);
}
