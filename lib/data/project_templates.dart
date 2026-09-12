import 'db/tables.dart';
import 'repository/project_repository.dart';

/// Ready-made project shapes.
///
/// A new project arriving with the right sections and the right fields is the difference
/// between a tool you configure and a tool you use. Every one of these is only a preset —
/// nothing here is special-cased anywhere else in the app, so a template you build by
/// hand is exactly as capable as one that shipped.
class ProjectTemplate {
  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.summary,
    required this.icon,
    required this.colour,
    required this.sections,
    required this.fields,
    this.suggestedPurpose,
  });

  final String id;

  /// What the template is called when you pick it.
  final String name;

  /// One line explaining what it is for, shown under the name. A template list without
  /// these is a guessing game.
  final String summary;

  /// Emoji, so no icon font is needed and a custom template can use any glyph.
  final String icon;
  final int colour;

  final List<String> sections;
  final List<FieldDefSpec> fields;
  final String? suggestedPurpose;

  static const _blue = 0xFF0A84FF;
  static const _purple = 0xFFBF5AF2;
  static const _green = 0xFF30D158;
  static const _orange = 0xFFFF9F0A;
  static const _grey = 0xFF8E8E93;

  static const all = <ProjectTemplate>[
    ProjectTemplate(
      id: 'developer',
      name: 'Software project',
      summary: 'Backlog through review, with components and pull requests',
      icon: '⌘',
      colour: _blue,
      suggestedPurpose: 'Ship the thing',
      sections: ['Backlog', 'In progress', 'In review', 'Shipped'],
      fields: [
        FieldDefSpec(
          name: 'Area',
          type: FieldType.select,
          options: [
            FieldOption(label: 'Frontend', colour: _blue),
            FieldOption(label: 'Backend', colour: _purple),
            FieldOption(label: 'Infra', colour: _orange),
            FieldOption(label: 'Bug', colour: 0xFFFF453A),
          ],
        ),
        FieldDefSpec(name: 'Pull request', type: FieldType.url, showInline: false),
        FieldDefSpec(name: 'Points', type: FieldType.number),
      ],
    ),

    ProjectTemplate(
      id: 'designer',
      name: 'Design project',
      summary: 'Exploration to handoff, with stages and Figma links',
      icon: '◈',
      colour: _purple,
      suggestedPurpose: 'Make it good before making it real',
      sections: ['Ideas', 'Exploring', 'Refining', 'Ready for build'],
      fields: [
        FieldDefSpec(
          name: 'Fidelity',
          type: FieldType.select,
          options: [
            FieldOption(label: 'Sketch', colour: _grey),
            FieldOption(label: 'Wireframe', colour: _blue),
            FieldOption(label: 'Hi-fi', colour: _purple),
          ],
        ),
        FieldDefSpec(name: 'Figma', type: FieldType.url, showInline: false),
        FieldDefSpec(name: 'Needs review', type: FieldType.checkbox),
      ],
    ),

    ProjectTemplate(
      id: 'coursework',
      name: 'Coursework',
      summary: 'A subject\'s assignments and labs, weighted by what they count for',
      icon: '✎',
      colour: _orange,
      suggestedPurpose: 'Pass, ideally well',
      sections: ['Not started', 'Working on it', 'Submitted'],
      fields: [
        FieldDefSpec(
          name: 'Kind',
          type: FieldType.select,
          options: [
            FieldOption(label: 'Assignment', colour: _blue),
            FieldOption(label: 'Lab', colour: _green),
            FieldOption(label: 'Quiz', colour: _orange),
            FieldOption(label: 'Exam', colour: 0xFFFF453A),
          ],
        ),
        // Knowing a task is worth 30% of the grade changes what you do with it.
        FieldDefSpec(name: 'Worth %', type: FieldType.number),
        FieldDefSpec(name: 'Submitted to', type: FieldType.url, showInline: false),
      ],
    ),

    ProjectTemplate(
      id: 'research',
      name: 'Research',
      summary: 'Reading through writing, tracking sources and confidence',
      icon: '◎',
      colour: _green,
      suggestedPurpose: 'Understand it well enough to explain it',
      sections: ['To read', 'Reading', 'Noted', 'Written up'],
      fields: [
        FieldDefSpec(name: 'Source', type: FieldType.url),
        FieldDefSpec(
          name: 'Confidence',
          type: FieldType.select,
          options: [
            FieldOption(label: 'Skimmed', colour: _grey),
            FieldOption(label: 'Understood', colour: _blue),
            FieldOption(label: 'Could teach it', colour: _green),
          ],
        ),
      ],
    ),

    ProjectTemplate(
      id: 'content',
      name: 'Writing or content',
      summary: 'Draft to published, with channel and status',
      icon: '✦',
      colour: 0xFFFFD60A,
      sections: ['Ideas', 'Drafting', 'Editing', 'Published'],
      fields: [
        FieldDefSpec(
          name: 'Channel',
          type: FieldType.select,
          options: [
            FieldOption(label: 'Blog', colour: _blue),
            FieldOption(label: 'Video', colour: 0xFFFF453A),
            FieldOption(label: 'Social', colour: _purple),
          ],
        ),
        FieldDefSpec(name: 'Link', type: FieldType.url, showInline: false),
      ],
    ),

    ProjectTemplate(
      id: 'blank',
      name: 'Start from nothing',
      summary: 'Three plain sections and no fields. Build it up as you go',
      icon: '○',
      colour: _grey,
      sections: ['To do', 'Doing', 'Done'],
      fields: [],
    ),
  ];

  static ProjectTemplate? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
