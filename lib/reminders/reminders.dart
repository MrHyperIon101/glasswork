import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/db/database.dart';
import 'reminder_plan.dart';

/// What was done with a reminder, from one of its buttons.
enum ReminderAction {
  /// Marked the task done.
  done,

  /// Asked to be reminded again shortly.
  snooze,
}

/// A reminder someone responded to: tapped open, or one of its buttons.
class ReminderResponse {
  const ReminderResponse({required this.taskId, this.action});

  final String taskId;

  /// Null when the notification itself was tapped.
  final ReminderAction? action;

  /// Reads the task and button a platform hands back. Null for a notification that is not
  /// a reminder.
  static ReminderResponse? read({String? payload, String? actionId}) {
    if (payload == null || payload.isEmpty) return null;
    return ReminderResponse(
      taskId: payload,
      action: ReminderAction.values.where((a) => a.name == actionId).firstOrNull,
    );
  }
}

/// A platform's notifications, as reminders need them.
abstract interface class ReminderGateway {
  /// Gets ready to raise reminders, calling [onResponse] whenever one is responded to.
  /// Returns the response that launched the app, if one did.
  Future<ReminderResponse?> start(void Function(ReminderResponse response) onResponse);

  /// Whether this device shows reminders.
  Future<bool> permitted();

  /// Asks to show reminders, where the platform leaves that to the person. Returns whether
  /// it now may.
  Future<bool> requestPermission();

  /// Makes [reminders] the ones this device raises, dropping any others it had.
  Future<void> schedule(List<PlannedReminder> reminders);
}

/// For platforms, and tests, with no notifications to raise reminders with.
class NoReminders implements ReminderGateway {
  const NoReminders();

  @override
  Future<ReminderResponse?> start(void Function(ReminderResponse) onResponse) async =>
      null;

  @override
  Future<bool> permitted() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}
}

/// Keeps this device's reminders in step with the tasks.
///
/// Works the plan out again whenever the tasks change, and hands it to the platform only
/// when it differs from the last, and only once the changes pause: typing a task's title
/// would otherwise reschedule its reminder on every keystroke.
class ReminderService {
  ReminderService(
    this._gateway, {
    this.describe,
    this.settle = const Duration(milliseconds: 800),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// How long a snoozed reminder waits.
  static const snoozeFor = Duration(minutes: 10);

  final ReminderGateway _gateway;

  /// Writes the line under a reminder's title.
  final String Function(Task task)? describe;

  /// How long the tasks must stay unchanged before the plan is applied.
  final Duration settle;

  final DateTime Function() _clock;

  List<Task>? _tasks;
  List<PlannedReminder>? _scheduled;

  /// Whether the platform is ready to take reminders. Nothing is handed to it before, since
  /// a platform asked to schedule before it has started may refuse, or lose them.
  bool _started = false;

  Timer? _pending;
  Timer? _nextDue;

  /// Starts the platform's notifications and schedules what is due. Returns the response
  /// that launched the app, if a reminder did.
  ///
  /// Never throws. A device whose notifications cannot start still runs the app, only
  /// without reminders.
  Future<ReminderResponse?> start(
    void Function(ReminderResponse response) onResponse,
  ) async {
    final ReminderResponse? launch;
    try {
      launch = await _gateway.start(onResponse);
    } on Object catch (error) {
      debugPrint('Reminders: notifications could not start: $error');
      return null;
    }
    _started = true;
    unawaited(_apply());
    return launch;
  }

  Future<bool> permitted() => _gateway.permitted();

  Future<bool> requestPermission() => _gateway.requestPermission();

  /// Takes the latest tasks.
  void update(List<Task> tasks) {
    _tasks = tasks;
    _pending?.cancel();
    _pending = Timer(settle, _apply);
  }

  /// Works the plan out again now, as when the app comes back to the foreground after its
  /// timers were paused.
  void refresh() {
    _pending?.cancel();
    _apply();
  }

  Future<void> _apply() async {
    final tasks = _tasks;
    if (!_started || tasks == null) return;

    final plan = ReminderPlan.upcoming(tasks, _clock(), describe: describe);
    _watchForNext(plan);
    if (_scheduled != null && listEquals(plan, _scheduled)) return;
    _scheduled = plan;

    try {
      await _gateway.schedule(plan);
    } on Object catch (error) {
      // Tried again the next time anything changes, or the app comes back to the front.
      _scheduled = null;
      debugPrint('Reminders: could not schedule: $error');
    }
  }

  /// Plans again once the soonest reminder has passed, so one beyond the limit moves up
  /// into the plan.
  void _watchForNext(List<PlannedReminder> plan) {
    _nextDue?.cancel();
    if (plan.length < ReminderPlan.limit) return;
    final wait = plan.first.at.difference(_clock()) + const Duration(seconds: 1);
    _nextDue = Timer(wait.isNegative ? Duration.zero : wait, refresh);
  }

  void dispose() {
    _pending?.cancel();
    _nextDue?.cancel();
  }
}
