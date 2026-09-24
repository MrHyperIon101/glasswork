import 'db/database.dart';

/// Projects as the sidebar lists them.
class ProjectGroup {
  const ProjectGroup(this.area, this.projects);

  /// Null for the projects in no area.
  final Area? area;

  /// In their own order.
  final List<Board> projects;
}

abstract final class ProjectGroups {
  /// The projects in no area first, then each of [areas] in order with its own, even when
  /// it has none, so a new area is there to put projects in.
  ///
  /// A project whose area is not among [areas] — deleted, or not yet arrived from another
  /// device — lists with the projects in no area, rather than nowhere.
  static List<ProjectGroup> of(List<Board> projects, List<Area> areas) {
    final known = {for (final area in areas) area.id};
    return [
      ProjectGroup(null, [
        for (final project in projects)
          if (!known.contains(project.areaId)) project,
      ]),
      for (final area in areas)
        ProjectGroup(area, [
          for (final project in projects)
            if (project.areaId == area.id) project,
        ]),
    ];
  }
}

/// A set of ids kept in one `LocalSettings` row, separated by commas — how this device
/// remembers what it has folded away.
abstract final class IdSet {
  static Set<String> parse(String? stored) => {
    for (final id in (stored ?? '').split(','))
      if (id.trim().isNotEmpty) id.trim(),
  };

  static String format(Set<String> ids) => (ids.toList()..sort()).join(',');
}

/// Which areas the sidebar shows closed, as this device keeps them.
abstract final class CollapsedAreas {
  static const key = 'sidebar.collapsed_areas';

  static Set<String> parse(String? stored) => IdSet.parse(stored);

  static String format(Set<String> ids) => IdSet.format(ids);
}
