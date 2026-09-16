import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/reminders/linux_reminder_files.dart';
import 'package:glasswork/reminders/linux_reminders.dart';
import 'package:glasswork/reminders/reminder_plan.dart';
import 'package:glasswork/reminders/reminders.dart';

/// Stands in for the desktop's notifications, writing down what it was asked to show.
class _Notifications implements FlutterLocalNotificationsPlugin {
  final shown = <(int, String?)>[];

  /// The buttons on each notification shown.
  final buttons = <List<String>>[];

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add((id, title));
    buttons.add([
      for (final action in notificationDetails?.linux?.actions ?? const []) action.label,
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory root;
  late List<List<String>> commands;
  late _Notifications notifications;
  late DateTime now;

  LinuxReminders reminders({bool systemd = true}) => LinuxReminders(
    dataDir: () async => '${root.path}/data',
    configHome: '${root.path}/config',
    runtimeDir: '${root.path}/run',
    plugin: notifications,
    run: (executable, arguments) async {
      if (!systemd) throw ProcessException(executable, arguments, 'not found');
      commands.add([executable, ...arguments]);
      return ProcessResult(0, 0, '', '');
    },
    clock: () => now,
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('glasswork-linux-reminders');
    commands = [];
    notifications = _Notifications();
    now = DateTime.now().toUtc();
  });
  tearDown(() => root.delete(recursive: true));

  PlannedReminder reminder(String taskId, Duration fromNow) => PlannedReminder(
    id: ReminderPlan.notificationId(taskId),
    taskId: taskId,
    at: now.add(fromNow),
    title: 'Task $taskId',
  );

  const tenMinutes = Duration(minutes: 10);

  File unit(String kind) =>
      File('${root.path}/config/systemd/user/${LinuxReminderFiles.unit}.$kind');
  File data(String name) => File('${root.path}/data/$name');
  const timer = '${LinuxReminderFiles.unit}.timer';

  test('writes the timer, its service, the schedule and the script, then starts it', () async {
    final due = reminder('a', const Duration(hours: 1));
    await reminders().schedule([due], snooze: tenMinutes);

    expect(
      unit('timer').readAsStringSync(),
      contains('OnCalendar=${LinuxReminderFiles.calendar(due.at)}\n'),
    );
    expect(
      unit('service').readAsStringSync(),
      contains(data(LinuxReminderFiles.scriptFile).path),
    );
    expect(data(LinuxReminderFiles.scheduleFile).readAsStringSync(), contains('\ta\tTask a\t'));
    expect(data(LinuxReminderFiles.scriptFile).readAsStringSync(), LinuxReminderFiles.script);
    expect(commands, [
      ['systemctl', '--user', 'daemon-reload'],
      ['systemctl', '--user', 'enable', timer],
      ['systemctl', '--user', 'restart', timer],
    ]);
  });

  test('the same reminders again touch nothing', () async {
    final gateway = reminders();
    await gateway.schedule([reminder('a', const Duration(hours: 1))], snooze: tenMinutes);
    commands.clear();

    await gateway.schedule([reminder('a', const Duration(hours: 1))], snooze: tenMinutes);
    expect(commands, isEmpty);
  });

  test('with no reminders left, the timer is taken away', () async {
    final gateway = reminders();
    await gateway.schedule([reminder('a', const Duration(hours: 1))], snooze: tenMinutes);
    commands.clear();

    await gateway.schedule(const [], snooze: tenMinutes);
    expect(unit('timer').existsSync(), isFalse);
    expect(commands, [
      ['systemctl', '--user', 'disable', '--now', timer],
      ['systemctl', '--user', 'daemon-reload'],
    ]);
  });

  test('while open, raises a reminder itself when it comes due, and records it', () async {
    final due = reminder('a', const Duration(milliseconds: 50));
    await reminders().schedule([due], snooze: tenMinutes);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(notifications.shown, [(due.id, 'Task a')]);
    expect(notifications.buttons.single, ['Mark done', 'Snooze 10 min']);
    expect(
      data(LinuxReminderFiles.firedFile).readAsStringSync(),
      LinuxReminderFiles.fired(due),
      reason: 'so the timer does not show it a second time',
    );
  });

  test('without systemd, reminders still come while the app is open', () async {
    await reminders(systemd: false).schedule([reminder('a', const Duration(milliseconds: 50))], snooze: tenMinutes);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(notifications.shown, hasLength(1));
  });

  test('a Snooze button says the length it was scheduled with', () async {
    await reminders().schedule(
      [reminder('a', const Duration(milliseconds: 50))],
      snooze: const Duration(minutes: 30),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(notifications.buttons.single, ['Mark done', 'Snooze 30 min']);
  });

  test('a sample shows at once, with no buttons to act on a task', () async {
    expect(await reminders().showSample(), isTrue);
    expect(notifications.shown, [(ReminderPlan.sampleId, SampleReminder.title)]);
    expect(notifications.buttons.single, isEmpty);
  });
}
