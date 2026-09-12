import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/tables.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../surface.dart';
import '../widgets/content_header.dart';
import '../widgets/quick_add.dart';
import '../widgets/task_row.dart';
import '../widgets/week_load_strip.dart';

/// The Today dashboard.
///
/// Every figure here is derived by [TaskStats] from the task list — nothing is a
/// placeholder and nothing is invented. The capacity numbers from §10 (usable minutes,
/// day load, feasibility) are deliberately absent until the engine that computes them
/// exists in phase 2; a dashboard that shows a number it cannot justify is worse than one
/// that shows fewer.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: _greeting(now),
            subtitle: _longDate(now),
            onMenu: onMenu,
          ),
          const SizedBox(height: AppSpace.xxl),
          if (stats == null)
            const Spacer()
          else ...[
            Expanded(child: _Bento(stats: stats)),
            const SizedBox(height: AppSpace.lg),
            const WeekLoadStrip(),
          ],
          const SizedBox(height: AppSpace.lg),
          const QuickAdd(),
        ],
      ),
    );
  }

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String _longDate(DateTime now) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

class _Bento extends StatelessWidget {
  const _Bento({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1040;
        final medium = constraints.maxWidth >= 720;

        final sideCards = [
          _OverdueCard(stats: stats),
          const _AtRiskCard(),
          _NextUpCard(stats: stats),
        ];

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _FocusCard(stats: stats)),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (final (i, card) in sideCards.indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpace.lg),
                      Expanded(child: card),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _FocusCard(stats: stats)),
            const SizedBox(height: AppSpace.lg),
            Expanded(
              flex: 2,
              child: medium
                  ? Row(
                      children: [
                        for (final (i, card) in sideCards.indexed) ...[
                          if (i > 0) const SizedBox(width: AppSpace.lg),
                          Expanded(child: card),
                        ],
                      ],
                    )
                  : ListView.separated(
                      itemCount: sideCards.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpace.lg),
                      itemBuilder: (_, i) =>
                          SizedBox(height: 132, child: sideCards[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// The hero card: what is actually on today, and how far through it you are.
class _FocusCard extends ConsumerWidget {
  const _FocusCard({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final items = [...stats.overdue, ...stats.dueToday];
    final progress = stats.todayProgress;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stats.todayTotal}', style: AppText.metric),
              const SizedBox(width: AppSpace.md),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text(
                  stats.todayTotal == 1 ? 'task on today' : 'tasks on today',
                  style: AppText.callout,
                ),
              ),
              const Spacer(),
              if (stats.estimatedMinutesToday > 0)
                _EstimatePill(stats: stats),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpace.lg),
            _ProgressBar(value: progress),
            const SizedBox(height: AppSpace.sm),
            Text(
              '${stats.completedToday} of '
              '${stats.todayTotal + stats.completedToday} done',
              style: AppText.numeric,
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          const AppDivider(),
          Expanded(
            child: items.isEmpty
                ? _ClearState(completedToday: stats.completedToday)
                : ListView.builder(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final task = items[i];
                      return TaskRow(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: () => scope?.tasks.setDone(
                          task.id,
                          done: task.status != TaskStatus.done,
                        ),
                        onTap: () => ref.read(openTaskProvider.notifier).open(task.id),
                        onDelete: () async {
                          if (scope == null) return;
                          await scope.tasks.softDelete(task.id);
                          ref
                              .read(undoProvider.notifier)
                              .offer(
                                'Deleted "${task.title}"',
                                () => scope.tasks.restore(task.id),
                              );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EstimatePill extends StatelessWidget {
  const _EstimatePill({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: AppColour.fill,
        borderRadius: AppRadius.roundAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Format.estimate(stats.estimatedMinutesToday),
            style: AppText.numeric.copyWith(color: AppColour.label),
          ),
          // A total that silently ignores unestimated work would be a lie, so it says so.
          if (stats.untimedToday > 0)
            Text(
              '  + ${stats.untimedToday} untimed',
              style: AppText.numeric.copyWith(color: AppColour.labelTertiary),
            ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.roundAll,
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColour.fill)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                decoration: const BoxDecoration(color: AppColour.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearState extends StatelessWidget {
  const _ClearState({required this.completedToday});

  final int completedToday;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 30,
            color: AppColour.green,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            completedToday > 0
                ? 'Today is clear. $completedToday done.'
                : 'Nothing due today.',
            style: AppText.body.copyWith(color: AppColour.labelSecondary),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Add something below, or take the afternoon.',
            style: AppText.footnote,
          ),
        ],
      ),
    );
  }
}

class _OverdueCard extends ConsumerWidget {
  const _OverdueCard({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = stats.overdue.length;
    final worst = stats.overdue.isEmpty ? null : stats.overdue.first;

    return GestureDetector(
      onTap: count == 0
          ? null
          : () => ref
                .read(destinationProvider.notifier)
                .go(const AllDestination()),
      child: _MetricCard(
        label: 'Overdue',
        value: '$count',
        caption: worst == null
            ? 'Nothing late'
            : Format.due(worst, DateTime.now())?.label ?? '',
        tint: count == 0 ? AppColour.grey : AppColour.red,
        icon: Icons.error_outline,
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    final next = stats.nextUp;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.arrow_forward,
                size: 15,
                color: AppColour.labelTertiary,
              ),
              const SizedBox(width: AppSpace.sm),
              Text('Next up', style: AppText.caption),
            ],
          ),
          const Spacer(),
          if (next == null)
            Text(
              'Nothing scheduled ahead',
              style: AppText.callout,
            )
          else ...[
            Text(
              next.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.headline,
            ),
            const SizedBox(height: AppSpace.xs),
            Builder(
              builder: (context) {
                final due = Format.due(next, DateTime.now());
                return Text(
                  due?.label ?? '',
                  style: AppText.numeric.copyWith(
                    color: due?.colour ?? AppColour.labelSecondary,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// What the arithmetic says will not fit.
///
/// This is the card the whole capacity engine exists to produce. It counts tasks the
/// scheduler could not place before their deadline at the current commitments — not tasks
/// that are merely late, which is what Overdue already covers.
class _AtRiskCard extends ConsumerWidget {
  const _AtRiskCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final impossible = schedule.impossible;
    final tight = schedule.tight;

    final caption = switch ((impossible.length, tight.length)) {
      (0, 0) => 'Everything fits',
      (0, final t) => '$t with no slack',
      (_, _) => impossible.first.task.title,
    };

    return _MetricCard(
      label: "Won't fit",
      value: '${impossible.length}',
      caption: caption,
      tint: impossible.isEmpty ? AppColour.grey : AppColour.red,
      icon: Icons.warning_amber_rounded,
    );
  }
}

/// A single figure with a label and one line of context.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.tint,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: tint),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(label, style: AppText.caption)),
            ],
          ),
          const Spacer(),
          Text(value, style: AppText.metricSmall.copyWith(color: tint)),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.footnote,
          ),
        ],
      ),
    );
  }
}
