import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Prints frame timings periodically so the phase 0 performance gate is a measured number
/// rather than an impression.
///
/// Raster time is the one that matters here: the glass shader runs on the GPU, so a
/// fill-rate problem shows up in raster, not build. Budget is 16.67ms for 60fps.
///
/// Off in release builds. Call [start] from main().
abstract final class FrameStats {
  static const _reportEvery = Duration(seconds: 3);

  /// Budget comes from the display, never a hardcoded 60. A 120Hz phone has an 8.3ms
  /// budget, and measuring it against 16.7ms would report a comfortable pass on a device
  /// that was actually dropping frames.
  static double get _budgetMs {
    final hz = ui.PlatformDispatcher.instance.implicitView?.display.refreshRate;
    return (hz == null || hz <= 0) ? 1000.0 / 60.0 : 1000.0 / hz;
  }

  static final List<double> _raster = [];
  static final List<double> _build = [];
  static DateTime _last = DateTime.now();

  static void start() {
    if (kReleaseMode) {
      return;
    }
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _raster.add(t.rasterDuration.inMicroseconds / 1000.0);
      _build.add(t.buildDuration.inMicroseconds / 1000.0);
    }

    final now = DateTime.now();
    if (now.difference(_last) < _reportEvery || _raster.isEmpty) {
      return;
    }
    _last = now;

    final budget = _budgetMs;
    final raster = [..._raster]..sort();
    final build = [..._build]..sort();
    final over = _raster.where((ms) => ms > budget).length;

    // Glass is fill-rate bound, so a raster number means nothing without the pixel count
    // it was measured at.
    final view = ui.PlatformDispatcher.instance.implicitView;
    final px = view == null
        ? 'size=?'
        : '${view.physicalSize.width.toInt()}x${view.physicalSize.height.toInt()}';

    debugPrint(
      'FRAMES $px @${(1000 / budget).round()}Hz '
      'budget=${budget.toStringAsFixed(1)}ms  n=${_raster.length}  '
      'raster p50=${_p(raster, 0.50)} p95=${_p(raster, 0.95)} '
      'max=${raster.last.toStringAsFixed(1)}  '
      'build p95=${_p(build, 0.95)}  '
      'over-budget=$over (${(over * 100 / _raster.length).toStringAsFixed(1)}%)',
    );

    _raster.clear();
    _build.clear();
  }

  static String _p(List<double> sorted, double q) {
    final i = ((sorted.length - 1) * q).round();
    return sorted[i].toStringAsFixed(1);
  }
}
