import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/tokens.dart';

/// A colour for every block title in the timetables, different from each other's while there
/// are colours enough to go round.
final blockColoursProvider = Provider<Map<String, Color>>((ref) {
  final commitments = ref.watch(commitmentsProvider).value ?? const [];
  return BlockStyle.assign([for (final block in commitments) block.title]);
});

/// How a timetable block is told apart from the others: a colour of its own, and a short
/// name for where its whole name will not fit.
///
/// Both come from the block's title, so every "DBMS lecture" is the same colour on every
/// day and every device, and a phone's timeline, too narrow for names, still says which
/// block is which.
abstract final class BlockStyle {
  static const palette = [
    AppColour.purple,
    AppColour.accent,
    AppColour.orange,
    AppColour.teal,
    AppColour.pink,
    AppColour.green,
    AppColour.indigo,
    AppColour.yellow,
    AppColour.cyan,
    AppColour.brown,
  ];

  static const _minor = {'a', 'an', 'the', 'of', 'and', 'for', 'to', 'in', 'on', 'with', 'at', '&'};

  /// The colour a block with this [title] prefers, on its own. Letter case and spacing do
  /// not change it.
  static Color colourOf(String title) => palette[_hash(_normal(title)) % palette.length];

  /// Colours for all of [titles] together. Each takes the colour it prefers unless a title
  /// earlier in alphabetical order already has it, and then the next one free, so two blocks
  /// look alike only once there are more blocks than colours. The same titles get the same
  /// colours on every device, whatever order they come in.
  static Map<String, Color> assign(Iterable<String> titles) {
    final names = {for (final title in titles) _normal(title)}.toList()..sort();
    final taken = <int>{};
    return {
      for (final name in names) name: palette[_slot(name, taken)],
    };
  }

  /// [title]'s colour among [assigned], or the one it prefers if it has none there.
  static Color colourIn(Map<String, Color> assigned, String title) =>
      assigned[_normal(title)] ?? colourOf(title);

  static int _slot(String name, Set<int> taken) {
    var slot = _hash(name) % palette.length;
    for (var tries = 0; tries < palette.length && taken.contains(slot); tries++) {
      slot = (slot + 1) % palette.length;
    }
    taken.add(slot);
    return slot;
  }

  static String _normal(String title) => title.trim().toLowerCase();

  static int _hash(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// A few letters for [title]: an acronym it starts with ("DBMS lecture" → "DBMS"), or
  /// else the first letters of its words ("Operating systems lab" → "OSL", "Lab 6" → "L6").
  static String abbreviate(String title) {
    final words = [
      for (final word in title.split(RegExp(r'[\s\-_:/,.()]+')))
        if (word.isNotEmpty && !_minor.contains(word.toLowerCase())) word,
    ];
    if (words.isEmpty) return title.trim().isEmpty ? '·' : title.trim()[0].toUpperCase();

    final first = words.first;
    final acronym = RegExp(r'^[A-Z0-9]{2,5}$').hasMatch(first);
    if (acronym) return first;
    if (words.length == 1) {
      return first.length <= 3 ? first : first.substring(0, 3);
    }
    return [for (final word in words.take(3)) word[0].toUpperCase()].join();
  }
}
