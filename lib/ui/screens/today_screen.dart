import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/task_stats.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../surface.dart';
import '../widgets/content_header.dart';
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
    final header = ContentHeader(
      title: _greeting(now),
      subtitle: _longDate(now),
      onMenu: onMenu,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // A phone scrolls one column. Fitting the dashboard into its height instead is what
        // squashed every card on it to a sliver.
        if (constraints.maxWidth < AppBreakpoint.compact) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.xxl,
            ),
            children: [
              header,
              const SizedBox(height: AppSpace.xl),
              if (stats != null) _PhoneDashboard(stats: stats),
            ],
          );
        }

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
              header,
              const SizedBox(height: AppSpace.xxl),
              if (stats == null)
                const Spacer()
              else ...[
                Expanded(child: _Bento(stats: stats)),
                const SizedBox(height: AppSpace.lg),
                const WeekLoadStrip(),
              ],
            ],
          ),
        );
      },
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

/// The dashboard as one scrolling column: today's tasks, then the figures, then the week.
class _PhoneDashboard extends StatelessWidget {
  const _PhoneDashboard({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FocusCard(stats: stats, fill: false),
      const SizedBox(height: AppSpace.md),
      _MetricHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _OverdueCard(stats: stats)),
            const SizedBox(width: AppSpace.md),
            const Expanded(child: _AtRiskCard()),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.md),
      _MetricHeight(child: _NextUpCard(stats: stats)),
      const SizedBox(height: AppSpace.md),
      const WeekLoadStrip(),
    ],
  );
}

/// A metric card's height, or more when its text needs it: a title that runs to two lines,
/// or a phone with its font size turned up. A fixed height clipped both.
class _MetricHeight extends StatelessWidget {
  const _MetricHeight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: AppSize.metricCard),
    child: IntrinsicHeight(child: child),
  );
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
                          _MetricHeight(child: sideCards[i]),
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
  const _FocusCard({required this.stats, this.fill = true});

  final TaskStats stats;

  /// Fills the height it is given, as a dashboard tile; or takes only the height its tasks
  /// need, in a phone's scrolling column.
  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider).value;
    final items = [...stats.overdue, ...stats.dueToday];
    final progress = stats.todayProgress;
    final estimated = stats.estimatedMinutesToday > 0;

    Widget row(Task task) => TaskRow(
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

    return AppSurface(
      padding: EdgeInsets.all(fill ? AppSpace.xxl : AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stats.todayTotal}', style: AppText.metric),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: Text(
                    stats.todayTotal == 1 ? 'task on today' : 'tasks on today',
                    style: AppText.callout,
                  ),
                ),
              ),
              if (fill && estimated) _EstimatePill(stats: stats),
            ],
          ),
          // On a phone the estimate gets its own line rather than crowding the count.
          if (!fill && estimated) ...[
            const SizedBox(height: AppSpace.sm),
            _EstimatePill(stats: stats),
          ],
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
          if (fill)
            Expanded(
              child: items.isEmpty
                  ? _ClearState(completedToday: stats.completedToday)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: AppSpace.sm),
                      itemCount: items.length,
                      itemBuilder: (context, i) => row(items[i]),
                    ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
              child: _ClearState(completedToday: stats.completedToday),
            )
          else ...[
            const SizedBox(height: AppSpace.sm),
            for (final task in items) row(task),
          ],
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Add something below, or take the afternoon.',
            style: AppText.footnote,
            textAlign: TextAlign.center,
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
