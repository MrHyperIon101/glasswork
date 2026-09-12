import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../surface.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/undo_toast.dart';
import 'capacity_screen.dart';
import 'list_screen.dart';
import 'today_screen.dart';

/// Width below which the sidebar is hidden behind a button rather than pinned.
const _sidebarBreakpoint = 860.0;
const _sidebarWidth = 252.0;

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(appScopeProvider);

    return scope.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          child: Text(
            "The local database didn't open.\n\n$e",
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (_) => const _Shell(),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _sidebarBreakpoint;

        return Stack(
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
                    onMenu: wide ? null : () => setState(() => _drawerOpen = true),
                  ),
                ),
              ],
            ),

            // Narrow layout: the sidebar slides over the content instead of squeezing it.
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

            const Positioned(
              left: 0,
              right: 0,
              bottom: AppSpace.xxxl,
              child: Center(child: UndoToast()),
            ),
          ],
        );
      },
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({this.onNavigate});

  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(listsProvider).value ?? const <BoardList>[];
    final all = ref.watch(allTasksProvider).value ?? const <Task>[];
    final stats = ref.watch(statsProvider);
    final current = ref.watch(destinationProvider);

    int openIn(String listId) => all
        .where((t) => t.listId == listId && t.status != TaskStatus.done)
        .length;

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
            child: Text('Glasswork', style: AppText.title3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              children: [
                _SidebarRow(
                  icon: Icons.today_outlined,
                  label: 'Today',
                  tint: AppColour.accent,
                  badge: stats?.todayTotal,
                  selected: current is TodayDestination,
                  onTap: () => go(const TodayDestination()),
                ),
                _SidebarRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Upcoming',
                  tint: AppColour.orange,
                  selected: current is UpcomingDestination,
                  onTap: () => go(const UpcomingDestination()),
                ),
                _SidebarRow(
                  icon: Icons.all_inbox_outlined,
                  label: 'All',
                  tint: AppColour.grey,
                  badge: stats?.open,
                  selected: current is AllDestination,
                  onTap: () => go(const AllDestination()),
                ),
                _SidebarRow(
                  icon: Icons.check_circle_outline,
                  label: 'Done',
                  tint: AppColour.green,
                  selected: current is DoneDestination,
                  onTap: () => go(const DoneDestination()),
                ),
                _SidebarRow(
                  icon: Icons.speed_outlined,
                  label: 'Capacity',
                  tint: AppColour.purple,
                  selected: current is CapacityDestination,
                  onTap: () => go(const CapacityDestination()),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.md,
                    AppSpace.xl,
                    AppSpace.md,
                    AppSpace.sm,
                  ),
                  child: Text('Lists', style: AppText.caption),
                ),

                for (final list in lists)
                  _SidebarRow(
                    icon: Icons.circle,
                    iconSize: 10,
                    label: list.name,
                    tint: AppColour.purple,
                    badge: openIn(list.id),
                    selected:
                        current is ListDestination &&
                        current.listId == list.id,
                    onTap: () => go(ListDestination(list.id)),
                  ),

                _SidebarRow(
                  icon: Icons.add,
                  label: 'New list',
                  tint: AppColour.labelTertiary,
                  muted: true,
                  selected: false,
                  onTap: () => _createList(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createList(WidgetRef ref) async {
    final scope = ref.read(appScopeProvider).value;
    if (scope == null) return;
    final boards = await scope.db.select(scope.db.boards).get();
    if (boards.isEmpty) return;

    final created = await scope.workspaces.createList(
      workspaceId: scope.workspace.id,
      boardId: boards.first.id,
      name: 'New list',
    );
    ref.read(destinationProvider.notifier).go(ListDestination(created.id));
  }
}

/// A sidebar item: tinted glyph, label, optional count.
///
/// The selected state is a filled pill rather than a colour change, which is what Apple
/// does and what keeps the label legible at every tint.
class _SidebarRow extends StatefulWidget {
  const _SidebarRow({
    required this.icon,
    required this.label,
    required this.tint,
    required this.selected,
    required this.onTap,
    this.badge,
    this.iconSize = 17,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;
  final double iconSize;
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.muted ? AppColour.labelTertiary : widget.tint,
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
              if (widget.badge case final n? when n > 0)
                Text('$n', style: AppText.numeric),
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

    if (!searching) {
      if (destination is TodayDestination) return TodayScreen(onMenu: onMenu);
      if (destination is CapacityDestination) {
        return CapacityScreen(onMenu: onMenu);
      }
    }
    return ListScreen(onMenu: onMenu);
  }
}
