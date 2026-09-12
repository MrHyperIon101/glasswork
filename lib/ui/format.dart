import 'package:flutter/widgets.dart';

import '../data/db/database.dart';
import '../theme/tokens.dart';

/// How a due date should read and colour.
class DueInfo {
  const DueInfo({required this.label, required this.colour});

  final String label;
  final Color colour;
}

abstract final class Format {
  static const _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Null when the task has no due date at all.
  ///
  /// All-day and timed tasks are compared differently on purpose: an all-day task is
  /// late only once the *day* has passed, while a timed one is late the moment the
  /// instant has.
  static DueInfo? due(Task task, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    if (task.dueAt case final at?) {
      final day = DateTime(at.year, at.month, at.day);
      final days = day.difference(today).inDays;
      final time = '${_two(at.hour)}:${_two(at.minute)}';

      if (at.isBefore(now)) {
        return DueInfo(
          label: days == 0 ? 'Overdue · $time' : _lateLabel(-days),
          colour: AppColour.overdue,
        );
      }
      return DueInfo(
        label: '${_dayWord(days, day)} · $time',
        colour: days == 0 ? AppColour.soon : AppColour.textDim,
      );
    }

    if (task.dueDate case final iso?) {
      final day = _parseIso(iso);
      if (day == null) return null;
      final days = day.difference(today).inDays;

      if (days < 0) {
        return DueInfo(label: _lateLabel(-days), colour: AppColour.overdue);
      }
      return DueInfo(
        label: _dayWord(days, day),
        colour: days == 0 ? AppColour.soon : AppColour.textDim,
      );
    }

    return null;
  }

  static String _lateLabel(int daysLate) =>
      daysLate == 1 ? 'Overdue by a day' : 'Overdue by $daysLate days';

  static String _dayWord(int days, DateTime day) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days > 1 && days < 7) return _weekdayNames[day.weekday - 1];
    return '${day.day}/${day.month}';
  }

  static DateTime? _parseIso(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String estimate(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
