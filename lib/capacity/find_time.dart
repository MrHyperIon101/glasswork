import 'day_agenda.dart';
import 'ledger.dart';
import 'task_slot.dart';

/// Find a time: the first stretch of free time, from now until the day it is due, that holds
/// a task of [minutes] whole — where the agenda says there is free time, so never in sleep, a
/// class, a meal, another task's time or the past. Null when there is none. Pure.
abstract final class FindTime {
  static const _step = 5;

  /// [days] consecutive from today; [slotsOn] the tasks already given a time on a day.
  static DateTime? next({
    required List<DayCapacity> days,
    required List<TaskSlot> Function(DateTime day) slotsOn,
    required int minutes,
    required DateTime now,
    DateTime? dueDay,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final nowMin = now.hour * 60 + now.minute;
    for (final day in days) {
      final date = DateTime(day.date.year, day.date.month, day.date.day);
      if (dueDay != null && date.isAfter(DateTime(dueDay.year, dueDay.month, dueDay.day))) break;
      final from = date == today ? nowMin : -1;
      for (final entry in DayAgenda.of(day, from, tasks: slotsOn(date))) {
        if (!entry.free || !entry.usable || entry.endMin <= from) continue;
        final start = ((entry.startMin > from ? entry.startMin : from) + _step - 1) ~/ _step * _step;
        if (entry.endMin - start >= minutes) return date.add(Duration(minutes: start));
      }
    }
    return null;
  }
}
