import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desktop/desktop_shell.dart';
import '../../search/spotlight_service.dart';
import '../../state/providers.dart';
import '../../state/undo_controller.dart';
import '../../theme/tokens.dart';
import '../glass/glass_surface.dart';
import '../layout.dart';
import '../widgets/window_controls.dart';

/// Whether the app's own Spotlight is open, and with what typed. Null while closed.
class SpotlightOpen extends Notifier<String?> {
  @override
  String? build() => null;

  void open([String query = '']) => state = query;
  void close() => state = null;
}

final spotlightOpenProvider = NotifierProvider<SpotlightOpen, String?>(SpotlightOpen.new);

/// Opens Spotlight: on a GNOME desktop with Glasswork Spotlight, the shell's own, over every
/// window; anywhere else — the phone, another desktop, the extension not running — the app's.
Future<void> openSpotlight(WidgetRef ref, {String query = ''}) async {
  if (WindowControls.available && await ref.read(desktopShellProvider).openShellSpotlight(query)) {
    return;
  }
  ref.read(spotlightOpenProvider.notifier).open(query);
}

/// The spring Spotlight opens on, as the shell's does (spring.js): a response of 0.26 s with
/// 0.86 of its bounce damped — the faintest overshoot. The one thing in the app that is
/// allowed to overshoot at all; under reduce-motion it is not shown moving.
class _SpotlightSpring extends Curve {
  const _SpotlightSpring();

  static const _response = 0.26;
  static const _damping = 0.86;
  static const seconds = 0.32;

  @override
  double transformInternal(double t) {
    final s = t * seconds;
    const omega = 2 * math.pi / _response;
    const decay = _damping * omega;
    final ringing = omega * math.sqrt(1 - _damping * _damping);
    return 1 - math.exp(-decay * s) * (math.cos(ringing * s) + (decay / ringing) * math.sin(ringing * s));
  }
}

/// The app's own Spotlight: a capsule of glass a little way down the screen, and under it what
/// was found — Glasswork's tasks, notes, projects and actions, ranked as the shell's are, and
/// the line typed offered as a task. The same SpotlightService answers both.
class SpotlightOverlay extends ConsumerStatefulWidget {
  const SpotlightOverlay({super.key});

  @override
  ConsumerState<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends ConsumerState<SpotlightOverlay> with SingleTickerProviderStateMixin {
  final _text = TextEditingController();
  final _focus = FocusNode();
  late final _motion = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_SpotlightSpring.seconds * 1000).round()),
    reverseDuration: AppMotion.quick,
  );
  Timer? _debounce;
  List<SpotlightResult> _results = const [];
  SpotlightResult? _add;
  int _selected = 0;
  bool _shown = false;
  int _asked = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _focus.dispose();
    _motion.dispose();
    super.dispose();
  }

  void _opened(String query) {
    _shown = true;
    _text.text = query;
    _text.selection = TextSelection(baseOffset: 0, extentOffset: query.length);
    _motion.duration = AppMotion.of(context, Duration(milliseconds: (_SpotlightSpring.seconds * 1000).round()));
    _motion.forward(from: 0);
    _search();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  Future<void> _close() async {
    await _motion.reverse();
    if (!mounted) return;
    setState(() => _shown = false);
    ref.read(spotlightOpenProvider.notifier).close();
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 60), _search);
  }

  Future<void> _search() async {
    final service = ref.read(spotlightServiceProvider);
    final query = _text.text.trim();
    final asked = ++_asked;
    final results = query.isEmpty
        ? [...await service.recents(limit: 6), ...service.actionResults().take(4)]
        : await service.query(query, limit: 12);
    final add = query.isEmpty ? null : await service.previewAdd(query);
    if (!mounted || asked != _asked) return;
    setState(() {
      _results = results;
      _add = (add?['title'] as String?)?.isNotEmpty ?? false ? add : null;
      _selected = 0;
    });
  }

  int get _count => _results.length + (_add == null ? 0 : 1) + (_text.text.trim().isEmpty ? 0 : 1);

  Future<void> _activate(int index) async {
    final service = ref.read(spotlightServiceProvider);
    final query = _text.text.trim();
    if (index < _results.length) {
      await _close();
      await service.activate(_results[index]['id']! as String);
      return;
    }
    if (_add != null && index == _results.length) {
      await _close();
      final id = await service.addTask(query);
      if (id != null) {
        ref.read(undoProvider.notifier).offer('Added “${_add!['title']}”', () async {
          final scope = ref.read(appScopeProvider).value;
          await scope?.tasks.softDelete(id);
        });
      }
      return;
    }
    // Everything it matched, in the app's own search.
    await _close();
    ref.read(searchQueryProvider.notifier).set(query);
  }

  KeyEventResult _key(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_text.text.isNotEmpty) {
        _text.clear();
        _changed();
      } else {
        _close();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      if (_count == 0) return KeyEventResult.handled;
      setState(() => _selected = (_selected + (key == LogicalKeyboardKey.arrowDown ? 1 : -1) + _count) % _count);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      final control = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      _activate(control && _add != null ? _results.length : _selected);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static IconData _icon(SpotlightResult r) => switch ((r['kind'], r['id'])) {
    ('task', _) => Icons.check_circle_outline_rounded,
    ('note', _) => Icons.sticky_note_2_outlined,
    ('project', _) || ('area', _) => Icons.folder_outlined,
    (_, 'action:new-task') => Icons.add_rounded,
    (_, 'action:new-note') => Icons.edit_note_rounded,
    (_, 'action:start-focus') => Icons.timer_outlined,
    (_, 'action:time-budget') => Icons.calendar_month_outlined,
    (_, 'action:plan-day') => Icons.auto_awesome_outlined,
    (_, 'action:focus') => Icons.timer_outlined,
    (_, 'action:radar') => Icons.radar_rounded,
    (_, 'action:review') => Icons.nightlight_outlined,
    (_, 'action:settings') => Icons.settings_outlined,
    _ => Icons.arrow_forward_rounded,
  };

  @override
  Widget build(BuildContext context) {
    // Opened from anywhere — a key, a button, Spotlight's own action — as it is asked to be.
    ref.listen(spotlightOpenProvider, (_, query) {
      if (query != null && !_shown) setState(() => _opened(query));
      // Closed from outside — Back on a phone — it still leaves as it always does.
      if (query == null && _shown) _close();
    });
    if (!_shown) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final width = math.min(680.0, size.width - 2 * AppSpace.lg);
    final top = AppLayout.touch ? size.height * 0.08 : size.height * 0.22;
    final typed = _text.text.trim();

    Widget row(int index, {required IconData icon, required String title, String? subtitle}) {
      final selected = index == _selected;
      return MouseRegion(
        onEnter: (_) => setState(() => _selected = index),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _activate(index),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.quick),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mediumAll,
              color: selected ? AppColour.accent.withValues(alpha: 0.85) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColour.label),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.footnote.copyWith(
                              color: selected ? AppColour.label : AppColour.labelSecondary,
                            )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[
      if (typed.isEmpty && _results.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.xs),
          child: Text('Recent and suggested', style: AppText.caption),
        ),
      for (final (i, r) in _results.indexed)
        row(i, icon: _icon(r), title: r['title']! as String, subtitle: r['subtitle'] as String?),
      if (_add case final add?)
        row(
          _results.length,
          icon: Icons.add_task_rounded,
          title: 'Add “${add['title']}”',
          subtitle: [
            ...((add['chips'] as List?) ?? const []).cast<String>(),
            add['sentence'] as String? ?? '',
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
      if (typed.isNotEmpty)
        row(
          _results.length + (_add == null ? 0 : 1),
          icon: Icons.search_rounded,
          title: 'Show all results for “$typed”',
        ),
    ];

    final scale = Tween(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _motion, curve: const _SpotlightSpring(), reverseCurve: Curves.easeIn),
    );

    return Positioned.fill(
      child: GestureDetector(
        // A tap on nothing closes it; nothing behind it dims.
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _motion, curve: const Interval(0, 0.4)),
              child: ScaleTransition(
                scale: scale,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () {},
                  child: SizedBox(
                    width: width,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassSurface(
                          radius: AppRadius.round,
                          tint: AppMaterial.sheetTint,
                          blur: AppMaterial.sheetBlur,
                          hairline: true,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                          child: SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 22, color: AppColour.labelSecondary),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Focus(
                                    onKeyEvent: _key,
                                    child: TextField(
                                      controller: _text,
                                      focusNode: _focus,
                                      onChanged: (_) => _changed(),
                                      style: AppText.title3.copyWith(fontWeight: FontWeight.w400),
                                      cursorColor: AppColour.accent,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: 'Spotlight Search',
                                        hintStyle: AppText.title3.copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: AppColour.labelTertiary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (rows.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.sm),
                          GlassSurface(
                            radius: AppRadius.large,
                            tint: AppMaterial.sheetTint,
                            blur: AppMaterial.sheetBlur,
                            hairline: true,
                            padding: const EdgeInsets.all(AppSpace.sm),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: size.height * 0.55),
                              child: Material(
                                type: MaterialType.transparency,
                                child: ListView(shrinkWrap: true, children: rows),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
