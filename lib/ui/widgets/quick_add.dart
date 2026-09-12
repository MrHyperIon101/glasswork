import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/quick_add_parser.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';

/// The capture line. Types a task, parses dates and flags out of it, creates it.
///
/// Whatever the parser took is shown as chips *before* you commit, because the point of
/// a hand-written parser is not that it is always right — it is that you can see when it
/// is wrong.
class QuickAdd extends ConsumerStatefulWidget {
  const QuickAdd({super.key});

  @override
  ConsumerState<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends ConsumerState<QuickAdd> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  ParsedQuickAdd? _parsed;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reparse);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _reparse() {
    final text = _controller.text;
    setState(() {
      _parsed = text.trim().isEmpty
          ? null
          : QuickAddParser.parse(text, now: DateTime.now());
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final parsed = QuickAddParser.parse(text, now: DateTime.now());
    if (parsed.title.isEmpty) return;

    final scope = ref.read(appScopeProvider).value;
    final listId = ref.read(captureListIdProvider);
    if (scope == null || listId == null) return;

    _controller.clear();
    await scope.tasks.create(
      listId: listId,
      workspaceId: scope.workspace.id,
      title: parsed.title,
      dueAt: parsed.dueAt,
      dueDate: parsed.dueDate,
      priority: parsed.priority,
      estimateMin: parsed.estimateMin,
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    final chips = parsed?.spans ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: [
                for (final span in chips) _ParseChip(span: span),
                if (parsed!.title.isNotEmpty)
                  Text(
                    '→ ${parsed.title}',
                    style: AppText.callout.copyWith(color: AppColour.label),
                  ),
              ],
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColour.fill,
            borderRadius: AppRadius.mediumAll,
            border: Border.all(color: AppColour.separator),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.escape): _ClearIntent(),
              },
              child: Actions(
                actions: {
                  _ClearIntent: CallbackAction<_ClearIntent>(
                    onInvoke: (_) {
                      _controller.clear();
                      return null;
                    },
                  ),
                },
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onSubmitted: (_) => _submit(),
                  style: AppText.body,
                  cursorColor: AppColour.accent,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpace.md,
                    ),
                    hintText: 'Add a task — try "lab report tmrw 5pm !high"',
                    hintStyle: AppText.body.copyWith(color: AppColour.labelTertiary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClearIntent extends Intent {
  const _ClearIntent();
}

class _ParseChip extends StatelessWidget {
  const _ParseChip({required this.span});

  final ParseSpan span;

  @override
  Widget build(BuildContext context) {
    final colour = switch (span.kind) {
      ParseKind.due => AppColour.orange,
      ParseKind.priority => AppColour.red,
      ParseKind.label => AppColour.accent,
      ParseKind.estimate => AppColour.green,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: AppColour.fill,
        borderRadius: AppRadius.mediumAll,
        border: Border.all(color: colour.withValues(alpha: 0.5)),
      ),
      child: Text(
        span.label,
        style: AppText.numeric.copyWith(color: colour),
      ),
    );
  }
}
