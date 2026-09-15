import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../reminders/reminders.dart';
import '../../state/providers.dart';
import '../../state/reminders_controller.dart';
import '../../state/sync_controller.dart';
import '../../theme/tokens.dart';
import '../layout.dart';
import '../motion.dart';
import '../surface.dart';
import '../widgets/new_project_sheet.dart';
import '../widgets/project_settings_sheet.dart';
import '../widgets/sync_sheet.dart';
import '../widgets/sync_status.dart';
import '../widgets/task_composer.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/undo_toast.dart';
import 'capacity_screen.dart';
import 'list_screen.dart';
import 'project_screen.dart';
import 'today_screen.dart';

const _sidebarWidth = 262.0;

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider);

    return scope.when(
      // Not an empty box. A blank window is indistinguishable from a crash, and that is
      // exactly how a missing migration hid itself once already.
      loading: () => const _Status(
        icon: Icons.hourglass_empty,
        title: 'Opening your data',
        detail: 'This should take a moment.',
      ),
      error: (e, stack) => _Status(
        icon: Icons.error_outline,
        tint: AppColour.red,
        title: "The local database didn't open",
        detail: '$e',
        selectable: true,
      ),
      data: (_) => const _Shell(),
    );
  }
}

/// Whole-screen state, used when there is nothing else to show. Always says something —
/// silence is the one thing it must never do.
class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.title,
    required this.detail,
    this.tint = AppColour.labelTertiary,
    this.selectable = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color tint;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: tint),
              const SizedBox(height: AppSpace.lg),
              Text(title, style: AppText.title3, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.sm),
              if (selectable)
                SelectableText(
                  detail,
                  style: AppText.footnote,
                  textAlign: TextAlign.center,
                )
              else
                Text(detail, style: AppText.footnote, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  bool _drawerOpen = false;

  /// Reminders come due whatever is on screen, so the shell keeps them in step.
  late final _lifecycle = AppLifecycleListener(
    // Timers stop while an app is in the background; coming back, what is due is worked
    // out again.
    onResume: () => ref.read(reminderServiceProvider).refresh(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    // Every change to the tasks can change which reminders are due, and when.
    ref.listenManual(allTasksProvider, (_, next) {
      if (next.value case final tasks?) {
        ref.read(reminderServiceProvider).update(tasks);
      }
    }, fireImmediately: true);
    _startReminders();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _startReminders() async {
    final launch = await ref.read(reminderServiceProvider).start(_respond);
    if (launch != null) await _respond(launch);
  }

  /// Acts on a reminder someone tapped, or on one of its buttons.
  Future<void> _respond(ReminderResponse response) async {
    final scope = await ref.read(appScopeProvider.future);
    switch (response.action) {
      case null:
        ref.read(openTaskProvider.notifier).open(response.taskId);
      case ReminderAction.done:
        await scope.tasks.setDone(response.taskId, done: true);
      case ReminderAction.snooze:
        await scope.tasks.setReminder(
          response.taskId,
          DateTime.now().add(ReminderService.snoozeFor),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync runs whether or not anything on screen shows it. On a phone, the sidebar that
    // does is closed most of the time.
    ref.listen(syncProvider, (_, _) {});

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoint.sidebar;

        final shell = CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
                ref.read(composerOpenProvider.notifier).open(),
            const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
                ref.read(composerOpenProvider.notifier).open(),
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpace.md,
                          AppSpace.md,
                          0,
                          AppSpace.md,
                        ),
                        child: SizedBox(width: _sidebarWidth, child: _Sidebar()),
                      ),
                    Expanded(
                      child: _Content(
                        onMenu: wide
                            ? null
                            : () => setState(() => _drawerOpen = true),
                      ),
                    ),
                  ],
                ),

                // Narrow layout: the sidebar slides over the content rather than
                // squeezing it into uselessness.
                if (!wide && _drawerOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _drawerOpen = false),
                      child: const ColoredBox(color: Color(0x99000000)),
                    ),
                  ),
                  Positioned(
                    left: AppSpace.md,
                    top: AppSpace.md,
                    bottom: AppSpace.md,
                    width: _sidebarWidth,
                    child: _Sidebar(
                      onNavigate: () => setState(() => _drawerOpen = false),
                    ),
                  ),
                ],

                const Positioned.fill(child: TaskDetailSheet()),
                const Positioned.fill(child: TaskComposer()),
                const Positioned.fill(child: NewProjectSheet()),
                const Positioned.fill(child: ProjectSettingsSheet()),
                const Positioned.fill(child: SyncSheet()),

                // Inset from the sides, so a long label is cut short rather than running
                // to the edge of a phone.
                Positioned(
                  left: AppSpace.lg,
                  right: AppSpace.lg,
                  bottom: wide ? AppSpace.xxxl : AppSpace.lg,
                  child: const Center(child: UndoToast()),
                ),
              ],
            ),
          ),
        );

        return _BackCloses(
          drawerOpen: !wide && _drawerOpen,
          onCloseDrawer: () => setState(() => _drawerOpen = false),
          child: shell,
        );
      },
    );
  }
}

/// Back, on Android, closes what is open before it may leave the app: the topmost sheet,
/// then the drawer, then a search.
///
/// The shell draws its sheets itself rather than pushing them as routes, so the navigator
/// knows nothing of them, and without this a back gesture meant to dismiss one closes the
/// whole app instead.
class _BackCloses extends ConsumerWidget {
  const _BackCloses({
    required this.drawerOpen,
    required this.onCloseDrawer,
    required this.child,
  });

  final bool drawerOpen;
  final VoidCallback onCloseDrawer;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Topmost first: the reverse of the order the shell stacks them in.
    final closers = <VoidCallback>[
      if (ref.watch(syncSheetOpenProvider))
        ref.read(syncSheetOpenProvider.notifier).close,
      if (ref.watch(projectSettingsOpenProvider) != null)
        ref.read(projectSettingsOpenProvider.notifier).close,
      if (ref.watch(newProjectOpenProvider))
        ref.read(newProjectOpenProvider.notifier).close,
      if (ref.watch(composerOpenProvider))
        ref.read(composerOpenProvider.notifier).close,
      if (ref.watch(openTaskProvider) != null)
        ref.read(openTaskProvider.notifier).close,
      if (drawerOpen) onCloseDrawer,
      if (ref.watch(searchQueryProvider).isNotEmpty)
        ref.read(searchQueryProvider.notifier).clear,
    ];

    return PopScope<Object?>(
      canPop: closers.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && closers.isNotEmpty) closers.first();
      },
      child: child,
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({this.onNavigate});

  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider).value ?? const <Board>[];
    final sections = ref.watch(allSectionsProvider).value ?? const <BoardList>[];
    final all = ref.watch(allTasksProvider).value ?? const <Task>[];
    final stats = ref.watch(statsProvider);
    final current = ref.watch(destinationProvider);

    /// Open tasks in a project, counted across its sections.
    int openIn(String projectId) {
      final ids = sections
          .where((s) => s.boardId == projectId)
          .map((s) => s.id)
          .toSet();
      return all
          .where((t) => ids.contains(t.listId) && t.status != TaskStatus.done)
          .length;
    }

    void go(Destination d) {
      ref.read(destinationProvider.notifier).go(d);
      ref.read(searchQueryProvider.notifier).clear();
      onNavigate?.call();
    }

    return VibrancyMaterial.sidebar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.lg,
            ),
            child: Text(AppConfig.name, style: AppText.title3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              children: [
                // Names say what they show. "Upcoming" and "All" were shorter and
                // meant nothing at a glance.
                _SidebarRow(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Today',
                  tint: AppColour.accent,
                  badge: stats?.todayTotal,
                  selected: current is TodayDestination,
                  onTap: () => go(const TodayDestination()),
                ),
                _SidebarRow(
                  icon: Icons.date_range_outlined,
                  label: 'Next 7 days',
                  tint: AppColour.orange,
                  selected: current is UpcomingDestination,
                  onTap: () => go(const UpcomingDestination()),
                ),
                _SidebarRow(
                  icon: Icons.layers_outlined,
                  label: 'All open work',
                  tint: AppColour.grey,
                  badge: stats?.open,
                  selected: current is AllDestination,
                  onTap: () => go(const AllDestination()),
                ),
                _SidebarRow(
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  tint: AppColour.green,
                  selected: current is DoneDestination,
                  onTap: () => go(const DoneDestination()),
                ),

                const _SectionLabel('Projects'),

                for (final project in projects)
                  _SidebarRow(
                    emoji: project.icon ?? '○',
                    label: project.name,
                    tint: project.colour == null
                        ? AppColour.purple
                        : Color(project.colour!),
                    badge: openIn(project.id),
                    selected:
                        current is ProjectDestination &&
                        current.projectId == project.id,
                    onTap: () => go(ProjectDestination(project.id)),
                  ),

                _SidebarRow(
                  icon: Icons.add,
                  label: 'New project',
                  tint: AppColour.labelTertiary,
                  muted: true,
                  selected: false,
                  onTap: () {
                    ref.read(newProjectOpenProvider.notifier).open();
                    onNavigate?.call();
                  },
                ),

                const _SectionLabel('Planning'),

                _SidebarRow(
                  icon: Icons.speed_outlined,
                  label: 'Time budget',
                  tint: AppColour.purple,
                  selected: current is CapacityDestination,
                  onTap: () => go(const CapacityDestination()),
                ),
              ],
            ),
          ),
          const AppDivider(),
          SyncStatusRow(onOpen: onNavigate),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.md,
      AppSpace.xl,
      AppSpace.md,
      AppSpace.sm,
    ),
    child: Text(label, style: AppText.caption),
  );
}

/// A sidebar item: tinted glyph or emoji, label, optional count.
///
/// The selected state is a filled pill rather than a colour change, which is what Apple
/// does and what keeps the label legible at every tint.
class _SidebarRow extends StatefulWidget {
  const _SidebarRow({
    required this.label,
    required this.tint,
    required this.selected,
    required this.onTap,
    this.icon,
    this.emoji,
    this.badge,
    this.muted = false,
  });

  final IconData? icon;
  final String? emoji;
  final String label;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;
  final bool muted;

  @override
  State<_SidebarRow> createState() => _SidebarRowState();
}

class _SidebarRowState extends State<_SidebarRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? AppColour.fillStrong
        : _hovered
        ? AppColour.fill
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            // Rows a finger can hit without catching the one beside them.
            vertical: AppLayout.touch ? AppSpace.md : AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: widget.emoji != null
                    ? Text(
                        widget.emoji!,
                        style: TextStyle(fontSize: 13, color: widget.tint),
                      )
                    : Icon(
                        widget.icon,
                        size: 17,
                        color: widget.muted
                            ? AppColour.labelTertiary
                            : widget.tint,
                      ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    color: widget.muted
                        ? AppColour.labelTertiary
                        : AppColour.label,
                    fontVariations: widget.selected
                        ? const [FontVariation('wght', 600)]
                        : null,
                  ),
                ),
              ),
              if (widget.badge case final n? when n > 0) ...[
                // Kept clear of a name cut short, which otherwise runs into it.
                const SizedBox(width: AppSpace.sm),
                Text('$n', style: AppText.numeric),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({this.onMenu});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(destinationProvider);
    final searching = ref.watch(searchQueryProvider).trim().isNotEmpty;

    final Widget screen;
    Object key = destination.runtimeType;

    if (searching) {
      screen = ListScreen(onMenu: onMenu);
      key = 'search';
    } else if (destination is TodayDestination) {
      screen = TodayScreen(onMenu: onMenu);
    } else if (destination is CapacityDestination) {
      screen = CapacityScreen(onMenu: onMenu);
    } else if (destination is ProjectDestination) {
      screen = ProjectScreen(projectId: destination.projectId, onMenu: onMenu);
      key = destination.projectId;
    } else {
      screen = ListScreen(onMenu: onMenu);
    }

    return ScreenSwitcher(
      child: KeyedSubtree(key: ValueKey(key), child: screen),
    );
  }
}
