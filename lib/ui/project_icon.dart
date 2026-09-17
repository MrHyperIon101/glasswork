import 'package:flutter/material.dart';

/// What a project's icon is: one of the symbols below, or whatever emoji or letters were
/// typed for it.
///
/// Stored in the project's `icon` text as it is, so it syncs like any field: a symbol as
/// `sym:` and its name, and typed text as the text itself. The templates' glyphs are typed
/// text too, so projects made before there was a choice keep theirs.
abstract final class ProjectIcon {
  static const symbolPrefix = 'sym:';

  /// How much typed text an icon keeps: an emoji, or a couple of letters.
  static const typedLength = 2;

  /// The symbols on offer, in the order the picker shows them.
  static const symbols = <String, IconData>{
    // Study and work.
    'school': Icons.school_rounded,
    'menu_book': Icons.menu_book_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    'history_edu': Icons.history_edu_rounded,
    'edit_note': Icons.edit_note_rounded,
    'science': Icons.science_rounded,
    'biotech': Icons.biotech_rounded,
    'calculate': Icons.calculate_rounded,
    'functions': Icons.functions_rounded,
    'psychology': Icons.psychology_rounded,
    'translate': Icons.translate_rounded,
    'description': Icons.description_rounded,
    'work': Icons.work_rounded,
    'business_center': Icons.business_center_rounded,
    'groups': Icons.groups_rounded,
    'campaign': Icons.campaign_rounded,
    'handshake': Icons.handshake_rounded,
    'gavel': Icons.gavel_rounded,
    'account_balance': Icons.account_balance_rounded,
    'checklist': Icons.checklist_rounded,
    'inventory': Icons.inventory_2_rounded,
    'folder': Icons.folder_rounded,
    // Making things.
    'code': Icons.code_rounded,
    'terminal': Icons.terminal_rounded,
    'data_object': Icons.data_object_rounded,
    'memory': Icons.memory_rounded,
    'developer_board': Icons.developer_board_rounded,
    'storage': Icons.storage_rounded,
    'cloud': Icons.cloud_rounded,
    'bug_report': Icons.bug_report_rounded,
    'build': Icons.build_rounded,
    'construction': Icons.construction_rounded,
    'architecture': Icons.architecture_rounded,
    'rocket_launch': Icons.rocket_launch_rounded,
    'lightbulb': Icons.lightbulb_rounded,
    'palette': Icons.palette_rounded,
    'brush': Icons.brush_rounded,
    'draw': Icons.draw_rounded,
    'design_services': Icons.design_services_rounded,
    'photo_camera': Icons.photo_camera_rounded,
    'videocam': Icons.videocam_rounded,
    'movie': Icons.movie_rounded,
    'mic': Icons.mic_rounded,
    'headphones': Icons.headphones_rounded,
    'music_note': Icons.music_note_rounded,
    'piano': Icons.piano_rounded,
    'extension': Icons.extension_rounded,
    // Life.
    'home': Icons.home_rounded,
    'favorite': Icons.favorite_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'directions_run': Icons.directions_run_rounded,
    'hiking': Icons.hiking_rounded,
    'sports_soccer': Icons.sports_soccer_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'spa': Icons.spa_rounded,
    'medical_services': Icons.medical_services_rounded,
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'savings': Icons.savings_rounded,
    'payments': Icons.payments_rounded,
    'trending_up': Icons.trending_up_rounded,
    'flight': Icons.flight_rounded,
    'luggage': Icons.luggage_rounded,
    'directions_car': Icons.directions_car_rounded,
    'sailing': Icons.sailing_rounded,
    'pets': Icons.pets_rounded,
    'eco': Icons.eco_rounded,
    'park': Icons.park_rounded,
    'public': Icons.public_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'celebration': Icons.celebration_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'event': Icons.event_rounded,
    'bedtime': Icons.bedtime_rounded,
    'flag': Icons.flag_rounded,
    'star': Icons.star_rounded,
    'bolt': Icons.bolt_rounded,
    'local_fire_department': Icons.local_fire_department_rounded,
    'diamond': Icons.diamond_rounded,
  };

  /// Emoji offered beside the field, for a start.
  static const suggestedEmoji = [
    '📚', '🎓', '💻', '🧪', '📝', '🎨', '🎵', '🎬', //
    '🏋️', '⚽', '🎮', '🌱', '🏠', '✈️', '💼', '💰',
  ];

  /// The stored form of the symbol called [name].
  static String symbol(String name) => '$symbolPrefix$name';

  /// The symbol [icon] names, or null when it is typed text, or a symbol this version does
  /// not have.
  static IconData? symbolOf(String? icon) => icon != null && icon.startsWith(symbolPrefix)
      ? symbols[icon.substring(symbolPrefix.length)]
      : null;

  /// Text typed for an icon, as it is kept: its first [typedLength] characters as a person
  /// counts them, so an emoji built of several code points stays whole, with no spaces.
  /// Null when nothing was typed.
  static String? typed(String text) {
    final kept = text.replaceAll(RegExp(r'\s'), '').characters.take(typedLength).toString();
    return kept.isEmpty ? null : kept;
  }
}

/// A project's icon in its colour, the same size whether it is a symbol, an emoji or letters.
class ProjectGlyph extends StatelessWidget {
  const ProjectGlyph({required this.icon, required this.colour, this.size = 17, super.key});

  final String? icon;
  final Color colour;
  final double size;

  /// What shows for a project with no icon at all.
  static const none = '○';

  @override
  Widget build(BuildContext context) {
    if (ProjectIcon.symbolOf(icon) case final symbol?) {
      return Icon(symbol, size: size, color: colour);
    }
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          // A symbol from a newer version of the app has no glyph here yet.
          icon == null || icon!.startsWith(ProjectIcon.symbolPrefix) ? none : icon!,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.8, height: 1, color: colour),
        ),
      ),
    );
  }
}
