import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/sync_controller.dart';
import '../../state/sync_summary.dart';
import '../../theme/tokens.dart';

/// The colour a [SyncTone] reads in.
Color syncToneColour(SyncTone tone) => switch (tone) {
  SyncTone.quiet => AppColour.labelTertiary,
  SyncTone.active => AppColour.accent,
  SyncTone.good => AppColour.green,
  SyncTone.warning => AppColour.orange,
  SyncTone.problem => AppColour.red,
};

/// The glyph for where sync stands.
IconData syncIcon(SyncState state) => switch (state) {
  SyncStarting() => Icons.cloud_outlined,
  SyncSignedOut() => Icons.cloud_off_outlined,
  SyncLinking() => Icons.cloud_sync_outlined,
  SyncChoosing() => Icons.call_split,
  SyncLinkedElsewhere() => Icons.error_outline,
  SyncOn(syncing: true) => Icons.sync,
  SyncOn(problem: SyncProblem.offline) => Icons.cloud_off_outlined,
  SyncOn(problem: SyncProblem.deviceClock || SyncProblem.otherDeviceClock) =>
    Icons.schedule,
  SyncOn(problem: SyncProblem.failed) => Icons.error_outline,
  SyncOn() => Icons.cloud_done_outlined,
};

/// Sync at the foot of the sidebar: where it stands, and the way into the sync sheet.
class SyncStatusRow extends ConsumerStatefulWidget {
  const SyncStatusRow({this.onOpen, super.key});

  /// Called after the sheet opens, so a drawer can close behind it.
  final VoidCallback? onOpen;

  @override
  ConsumerState<SyncStatusRow> createState() => _SyncStatusRowState();
}

class _SyncStatusRowState extends ConsumerState<SyncStatusRow> {
  bool _hovered = false;

  /// Keeps "5 min ago" true while nothing else changes.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncProvider);
    final summary = summarizeSync(state, DateTime.now());

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          ref.read(syncSheetOpenProvider.notifier).open();
          widget.onOpen?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          margin: const EdgeInsets.all(AppSpace.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColour.fill : null,
            borderRadius: AppRadius.mediumAll,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Icon(
                  syncIcon(state),
                  size: 17,
                  color: syncToneColour(summary.tone),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      style: AppText.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      summary.detail,
                      style: AppText.footnote,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
