import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacity/scheduler.dart';
import '../../data/quick_add_parser.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../format.dart';

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

  /// Set when the arithmetic says the thing you just typed will not fit. Holds the
  /// pending text so "Add anyway" does not make you retype it.
  ScheduledTask? _warning;
  String? _pending;

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

  /// Runs the feasibility check before writing. If it does not fit, the sheet says so
  /// and waits — but "Add anyway" is always available. The app is an advisor, not a
  /// warden; it just declines to let you find out at 1am.
  Future<void> _submit({bool force = false}) async {
    final text = force ? (_pending ?? '') : _controller.text.trim();
    if (text.isEmpty) return;

    final parsed = QuickAddParser.parse(text, now: DateTime.now());
    if (parsed.title.isEmpty) return;

    final scope = ref.read(appScopeProvider).value;
    final listId = ref.read(captureListIdProvider);
    if (scope == null || listId == null) return;

    if (!force) {
      final due = parsed.dueAt ?? _isoToDate(parsed.dueDate);
      if (due != null) {
        final plan = previewFeasibility(
          ref,
          PlannedTask(
            id: '__candidate__',
            title: parsed.title,
            dueDay: DateTime(due.year, due.month, due.day),
            estimateMin:
                parsed.estimateMin ?? CapacityScheduler.assumedEstimateMin,
            priority: parsed.priority,
            estimateAssumed: parsed.estimateMin == null,
          ),
        );
        if (plan != null && plan.state == Feasibility.impossible) {
          setState(() {
            _warning = plan;
            _pending = text;
          });
          return;
        }
      }
    }

    setState(() {
      _warning = null;
      _pending = null;
    });

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

  static DateTime? _isoToDate(String? iso) {
    if (iso == null) return null;
    final p = iso.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    return (y == null || m == null || d == null) ? null : DateTime(y, m, d);
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    final chips = parsed?.spans ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_warning case final w?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _DoesNotFit(
              plan: w,
              onAnyway: () => _submit(force: true),
              onCancel: () => setState(() {
                _warning = null;
                _pending = null;
              }),
            ),
          ),
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

/// The push-back at capture.
///
/// States the arithmetic plainly and by how much, because "you're overloaded" invites an
/// argument and "2h 30m short" does not.
class _DoesNotFit extends StatelessWidget {
  const _DoesNotFit({
    required this.plan,
    required this.onAnyway,
    required this.onCancel,
  });

  final ScheduledTask plan;
  final VoidCallback onAnyway;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final short = plan.shortfallMin > 0
        ? '${Format.estimate(plan.shortfallMin)} short'
        : '${-plan.slackDays} ${-plan.slackDays == 1 ? 'day' : 'days'} late';

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColour.red.withValues(alpha: 0.12),
        borderRadius: AppRadius.mediumAll,
        border: Border.all(color: AppColour.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColour.red,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              'This does not fit before the deadline — $short at your current '
              'commitments.',
              style: AppText.callout.copyWith(color: AppColour.label),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Text('Cancel', style: AppText.callout),
          ),
          const SizedBox(width: AppSpace.lg),
          GestureDetector(
            onTap: onAnyway,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Add anyway',
              style: AppText.headline.copyWith(color: AppColour.red),
            ),
          ),
        ],
      ),
    );
  }
}
