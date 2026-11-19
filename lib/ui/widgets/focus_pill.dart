import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/preferences.dart';
import '../../state/providers.dart';
import '../../state/reminders_controller.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../glass/glass_surface.dart';
import '../motion.dart';
import 'field_controls.dart';

/// The focus timer, while one runs: a glass pill at the top centre of every screen, with the
/// time left and what it is on. It is the sessions that are the timer, so it survives going
/// from screen to screen, closing the app and coming back, and shows a session another device
/// started. When one reaches its length it ends it, says so, and offers what comes next.
class FocusPill extends ConsumerStatefulWidget {
  const FocusPill({super.key});

  @override
  ConsumerState<FocusPill> createState() => _FocusPillState();
}

class _FocusPillState extends ConsumerState<FocusPill> {
  Timer? _tick;

  /// Sessions this device has already said were over, and ones put away by hand.
  final _announced = <String>{};
  final _dismissed = <String>{};

  /// How long a finished session goes on being offered a next step.
  static const _offerFor = Duration(minutes: 10);

  /// Ticks each second while there is a session to show, and not otherwise: an idle app is
  /// never drawn again for nothing.
  void _keepTicking(bool needed) {
    if (needed && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!needed && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(focusSessionsProvider).value ?? const <FocusSession>[];
    final latest = sessions.firstOrNull;
    final now = DateTime.now();
    final state = latest == null ? null : _stateOf(latest, now);
    // A session that has not started yet, or one on the edge of ending, still needs the tick.
    _keepTicking(state != null || (latest != null && latest.endedAt == null));

    return Presence(
      visible: state != null,
      builder: (context, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(animation),
          child: state == null ? const SizedBox.shrink() : _pill(latest!, state, now),
        ),
      ),
    );
  }

  /// Running, finished a moment ago, or nothing to show.
  _PillState? _stateOf(FocusSession session, DateTime now) {
    if (_dismissed.contains(session.id)) return null;
    final end = session.startedAt.add(Duration(minutes: session.plannedMin));
    if (session.endedAt == null && now.isBefore(end)) return _PillState.running;
    // Reached its length: end it here, once, and say so.
    if (session.endedAt == null || !session.endedAt!.isBefore(end)) {
      if (now.difference(end) > _offerFor) return null;
      if (_announced.add(session.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finish(session));
      }
      return _PillState.finished;
    }
    // Stopped by hand: nothing more to say.
    return null;
  }

  Future<void> _finish(FocusSession session) async {
    final scope = ref.read(appScopeProvider).value;
    if (session.endedAt == null && scope != null) {
      await scope.focus.end(session, at: DateTime.now());
    }
    final breakMin = (ref.read(preferencesProvider).value ?? const Preferences()).breakMin;
    final title = _taskTitle(session.taskId);
    if (session.kind == 'break') {
      await ref.read(reminderGatewayProvider).announce('Break over', 'Ready to focus again?');
    } else {
      await ref.read(reminderGatewayProvider).announce(
        'Focus done',
        '${Format.estimate(session.plannedMin)}${title == null ? '' : ' on $title'}. '
            'Time for a ${Format.estimate(breakMin)} break.',
      );
    }
  }

  String? _taskTitle(String? taskId) {
    if (taskId == null) return null;
    final tasks = ref.read(allTasksProvider).value ?? const <Task>[];
    return tasks.where((t) => t.id == taskId).firstOrNull?.title;
  }

  Widget _pill(FocusSession session, _PillState state, DateTime now) {
    final isBreak = session.kind == 'break';
    final total = Duration(minutes: session.plannedMin);
    final left = session.startedAt.add(total).difference(now);
    final done = state == _PillState.finished;
    final progress = done ? 1.0 : 1 - left.inMilliseconds / total.inMilliseconds;
    final title = _taskTitle(session.taskId);
    final tint = isBreak ? AppColour.green : AppColour.accent;
    final controller = ref.read(focusControllerProvider);
    final breakMin = (ref.watch(preferencesProvider).value ?? const Preferences()).breakMin;

    final label = switch ((isBreak, done)) {
      (false, false) => title == null ? 'Focus' : 'Focusing on $title',
      (true, false) => 'Break',
      (false, true) => 'Focus done${title == null ? '' : ' — $title'}',
      (true, true) => 'Break over',
    };

    return Semantics(
      liveRegion: true,
      label: done ? label : '$label, ${_clock(left)} left',
      child: GlassSurface(
        radius: AppRadius.round,
        tint: AppMaterial.sheetTint,
        blur: AppMaterial.sheetBlur,
        hairline: true,
        padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.xs, AppSpace.xs),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Ring(progress: progress.clamp(0, 1).toDouble(), colour: tint),
              const SizedBox(width: AppSpace.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.callout.copyWith(color: AppColour.label),
                ),
              ),
              if (!done) ...[
                const SizedBox(width: AppSpace.md),
                Text(
                  _clock(left),
                  style: AppText.callout.copyWith(
                    color: tint,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                GhostButton(label: isBreak ? 'Skip' : 'Stop', onTap: controller.stop),
              ] else ...[
                const SizedBox(width: AppSpace.md),
                if (!isBreak)
                  GhostButton(
                    label: 'Break ${Format.estimate(breakMin)}',
                    onTap: () {
                      _dismissed.add(session.id);
                      controller.startBreak();
                    },
                  )
                else
                  GhostButton(
                    label: 'Focus again',
                    onTap: () {
                      _dismissed.add(session.id);
                      final last = ref.read(focusSessionsProvider).value
                          ?.where((s) => s.kind == 'focus')
                          .firstOrNull;
                      controller.start(taskId: last?.taskId);
                    },
                  ),
                GhostButton(label: 'Done', onTap: () => setState(() => _dismissed.add(session.id))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "24:59", "1:04:10".
  static String _clock(Duration left) {
    final s = left.isNegative ? 0 : left.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
  }
}

enum _PillState { running, finished }

/// How far through it is, as a ring filling round.
class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 22,
    child: CustomPaint(painter: _RingPainter(progress, colour)),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.colour);

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(2), 0, math.pi * 2, false, stroke..color = AppColour.fill);
    canvas.drawArc(rect.deflate(2), -math.pi / 2, math.pi * 2 * progress, false, stroke..color = colour);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.colour != colour;
}
