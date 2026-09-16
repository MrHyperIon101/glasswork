import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';
import '../widgets/content_header.dart';
import '../widgets/note_widgets.dart';

/// Quick notes, as a gallery: pinned ones first, then the rest, newest first, with a place to
/// jot the next one down at the top.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider).value ?? const <Note>[];
    final pinned = [for (final note in notes) if (note.pinned) note];
    final rest = [for (final note in notes) if (!note.pinned) note];

    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpace.sm : AppSpace.xl,
        gutter,
        compact ? 0 : AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: 'Notes',
            subtitle: switch (notes.length) {
              0 => 'Thoughts worth keeping',
              1 => '1 note',
              final n => '$n notes',
            },
            onMenu: onMenu,
            primaryAction: AccentButton(
              icon: Icons.edit_note_rounded,
              label: 'New note',
              onTap: () => ref.read(openNoteProvider.notifier).create(),
            ),
          ),
          SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.lg),
              children: [
                const QuickNoteField(),
                const SizedBox(height: AppSpace.xl),
                if (notes.isEmpty)
                  const _Empty()
                else ...[
                  if (pinned.isNotEmpty) ...[
                    const _SectionTitle(icon: Icons.push_pin_rounded, label: 'Pinned'),
                    _Gallery(notes: pinned),
                    const SizedBox(height: AppSpace.xl),
                    if (rest.isNotEmpty)
                      const _SectionTitle(icon: Icons.notes_rounded, label: 'Notes'),
                  ],
                  _Gallery(notes: rest),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Row(
      children: [
        Icon(icon, size: 13, color: AppColour.labelTertiary),
        const SizedBox(width: AppSpace.xs),
        Text(label, style: AppText.caption),
      ],
    ),
  );
}

/// Notes in columns, each column as tall as its notes, filled left to right a row at a
/// time so the newest stay at the top.
class _Gallery extends StatelessWidget {
  const _Gallery({required this.notes});

  final List<Note> notes;

  /// A column no narrower than this, where there is room.
  static const _columnWidth = 250.0;
  static const _compactColumnWidth = 150.0;
  static const _mostColumns = 4;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrowest = AppLayout.compact(context) ? _compactColumnWidth : _columnWidth;
        final columns = ((constraints.maxWidth + AppSpace.md) / (narrowest + AppSpace.md))
            .floor()
            .clamp(1, _mostColumns);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  children: [
                    for (var i = c; i < notes.length; i += columns) ...[
                      if (i >= columns) const SizedBox(height: AppSpace.md),
                      FadeSlideIn(
                        key: ValueKey(notes[i].id),
                        delay: Duration(milliseconds: 30 * (i < 8 ? i : 8)),
                        child: NoteCard(note: notes[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.huge),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColour.yellow.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sticky_note_2_outlined, size: 30, color: AppColour.yellow),
        ),
        const SizedBox(height: AppSpace.lg),
        Text('No notes yet', style: AppText.title3),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Write one above, and Return keeps it. It syncs with your tasks.',
          style: AppText.callout,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
