import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'linux_reminder_files.dart';
import 'reminder_plan.dart';
import 'reminders.dart';

/// Reminders on Linux.
///
/// While the app is open it raises them itself, with buttons that act on the task. While
/// it is closed a systemd user timer raises them (see [LinuxReminderFiles]), so a reminder
/// never depends on Glasswork having been left open.
class LinuxReminders implements ReminderGateway {
  LinuxReminders({
    required this.dataDir,
    required this.configHome,
    required this.runtimeDir,
    FlutterLocalNotificationsPlugin? plugin,
    Future<ProcessResult> Function(String executable, List<String> arguments)? run,
    DateTime Function()? clock,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _run = run ?? Process.run,
       _clock = clock ?? DateTime.now;

  /// Where the schedule and the script are kept: the app's support directory.
  final Future<String> Function() dataDir;

  /// `XDG_CONFIG_HOME`, where systemd looks for a user's units.
  final String configHome;

  /// `XDG_RUNTIME_DIR`, where the app says it is open. Null outside a desktop session.
  final String? runtimeDir;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<ProcessResult> Function(String, List<String>) _run;
  final DateTime Function() _clock;

  List<PlannedReminder> _plan = const [];
  Timer? _next;

  /// What was last written for the timer, so nothing is rewritten, and systemd not
  /// reloaded, when the reminders have not changed.
  String? _written;

  static const _details = NotificationDetails(
    linux: LinuxNotificationDetails(
      defaultActionName: 'Open',
      actions: [
        LinuxNotificationAction(key: 'done', label: 'Mark done'),
        LinuxNotificationAction(key: 'snooze', label: 'Snooze 10 min'),
      ],
    ),
  );

  @override
  Future<ReminderResponse?> start(
    void Function(ReminderResponse response) onResponse,
  ) async {
    await _plugin.initialize(
      settings: InitializationSettings(
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open',
          defaultIcon: ThemeLinuxIcon(LinuxReminderFiles.appId),
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final read = ReminderResponse.read(
          payload: response.payload,
          actionId: response.actionId,
        );
        if (read != null) onResponse(read);
      },
    );

    // Tells the timer the app is open and raising reminders itself.
    if (runtimeDir case final dir?) {
      try {
        await File('$dir/${LinuxReminderFiles.pidFile}').writeAsString('$pid');
      } on FileSystemException catch (error) {
        debugPrint('Reminders: could not record that the app is open: $error');
      }
    }
    return null;
  }

  @override
  Future<bool> permitted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    _plan = reminders;
    _armNext();
    await _writeTimer(reminders);
  }

  void _armNext() {
    _next?.cancel();
    final now = _clock();
    final soonest = _plan.where((r) => r.at.isAfter(now)).firstOrNull;
    if (soonest == null) return;
    _next = Timer(soonest.at.difference(now), () => _raise(soonest));
  }

  Future<void> _raise(PlannedReminder reminder) async {
    _plan = [for (final r in _plan) if (r != reminder) r];
    _armNext();

    try {
      await _plugin.show(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body.isEmpty ? null : reminder.body,
        notificationDetails: _details,
        payload: reminder.taskId,
      );
    } on Object catch (error) {
      debugPrint('Reminders: could not show "${reminder.title}": $error');
    }

    // Recorded, so the timer catching up later does not show it a second time.
    try {
      await File('${await dataDir()}/${LinuxReminderFiles.firedFile}').writeAsString(
        LinuxReminderFiles.fired(reminder),
        mode: FileMode.append,
      );
    } on FileSystemException catch (error) {
      debugPrint('Reminders: could not record "${reminder.title}" as shown: $error');
    }
  }

  Future<void> _writeTimer(List<PlannedReminder> reminders) async {
    final schedule = LinuxReminderFiles.schedule(reminders);
    final timer = LinuxReminderFiles.timer(reminders);
    if ('$schedule$timer' == _written) return;

    try {
      final data = await dataDir();
      await Directory(data).create(recursive: true);
      final script = File('$data/${LinuxReminderFiles.scriptFile}');
      await script.writeAsString(LinuxReminderFiles.script);
      await File('$data/${LinuxReminderFiles.scheduleFile}').writeAsString(schedule);
      final fired = File('$data/${LinuxReminderFiles.firedFile}');
      if (await fired.exists()) {
        await fired.writeAsString(
          LinuxReminderFiles.pruneFired(await fired.readAsString(), _clock()),
        );
      }

      final units = Directory('$configHome/systemd/user');
      await units.create(recursive: true);
      final unit = LinuxReminderFiles.unit;
      await File('${units.path}/$unit.service').writeAsString(
        LinuxReminderFiles.service(script.path),
      );
      final timerFile = File('${units.path}/$unit.timer');

      if (reminders.isEmpty) {
        // A timer with nothing to fire on is refused by systemd, so it is taken away.
        await _systemctl(['disable', '--now', '$unit.timer'], quiet: true);
        if (await timerFile.exists()) await timerFile.delete();
        await _systemctl(['daemon-reload']);
      } else {
        await timerFile.writeAsString(timer);
        await _systemctl(['daemon-reload']);
        await _systemctl(['enable', '$unit.timer']);
        // A restart is what makes a running timer take up its new times.
        await _systemctl(['restart', '$unit.timer']);
      }
      _written = '$schedule$timer';
    } on Object catch (error) {
      // No systemd, or no user session: reminders still come while the app is open.
      debugPrint('Reminders: cannot schedule them for while the app is closed: $error');
    }
  }

  Future<void> _systemctl(List<String> arguments, {bool quiet = false}) async {
    final result = await _run('systemctl', ['--user', ...arguments]);
    if (result.exitCode != 0 && !quiet) {
      throw ProcessException(
        'systemctl',
        ['--user', ...arguments],
        '${result.stderr}'.trim(),
        result.exitCode,
      );
    }
  }
}
