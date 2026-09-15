import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/reminders/linux_reminder_files.dart';
import 'package:glasswork/reminders/reminder_plan.dart';

PlannedReminder reminder(
  String taskId,
  DateTime at, {
  String title = 'Title',
  String body = 'Body',
}) => PlannedReminder(id: 1, taskId: taskId, at: at, title: title, body: body);

void main() {
  test('the timer fires at each reminder, as an exact instant in UTC', () {
    final timer = LinuxReminderFiles.timer([
      reminder('a', DateTime.utc(2026, 9, 16, 3, 30)),
      reminder('b', DateTime.utc(2026, 9, 17, 12, 5, 9)),
    ]);

    expect(timer, contains('OnCalendar=2026-09-16 03:30:00 UTC\n'));
    expect(timer, contains('OnCalendar=2026-09-17 12:05:09 UTC\n'));
    expect(timer, contains('Persistent=true'));
  });

  test('a schedule line is one reminder, whatever its title holds', () {
    final at = DateTime.utc(2026, 9, 16, 3, 30);
    expect(
      LinuxReminderFiles.schedule([
        reminder('a', at, title: 'Two\tcolumns\nand a line', body: ''),
      ]),
      '${at.millisecondsSinceEpoch ~/ 1000}\ta\tTwo columns and a line\tGlasswork\n',
    );
  });

  test('old records of shown reminders are dropped', () {
    final now = DateTime.utc(2026, 9, 16, 12);
    final recent = LinuxReminderFiles.seconds(now.subtract(const Duration(hours: 1)));
    final old = LinuxReminderFiles.seconds(now.subtract(const Duration(days: 3)));

    expect(
      LinuxReminderFiles.pruneFired('$old\told\n$recent\trecent\nnot a record\n', now),
      '$recent\trecent\n',
    );
  });

  group('the script', () {
    late Directory dir;
    late File log;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('glasswork-reminders');
      log = File('${dir.path}/notified.log');
      // Stands in for notify-send, writing down what it was asked to show.
      final fake = File('${dir.path}/bin/notify-send')..createSync(recursive: true);
      fake.writeAsStringSync('#!/bin/sh\nfor a in "\$@"; do last="\$a"; done\n'
          'printf "%s\\n" "\$*" >> "${log.path}"\n');
      await Process.run('chmod', ['+x', fake.path]);
      File('${dir.path}/${LinuxReminderFiles.scriptFile}')
          .writeAsStringSync(LinuxReminderFiles.script);
    });

    tearDown(() => dir.delete(recursive: true));

    Future<List<String>> run() async {
      final result = await Process.run(
        '/bin/sh',
        ['${dir.path}/${LinuxReminderFiles.scriptFile}'],
        environment: {
          'PATH': '${dir.path}/bin:${Platform.environment['PATH']}',
          'XDG_RUNTIME_DIR': dir.path,
        },
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      return log.existsSync() ? log.readAsLinesSync() : const [];
    }

    void schedule(List<PlannedReminder> reminders) =>
        File('${dir.path}/${LinuxReminderFiles.scheduleFile}')
            .writeAsStringSync(LinuxReminderFiles.schedule(reminders));

    test('shows what has come due, once, and nothing ahead or long missed', () async {
      final now = DateTime.now().toUtc();
      schedule([
        reminder('due', now.subtract(const Duration(minutes: 1)), title: 'Due now'),
        reminder('ahead', now.add(const Duration(hours: 1)), title: 'Not yet'),
        reminder('missed', now.subtract(const Duration(hours: 13)), title: 'Too late'),
      ]);

      final shown = await run();
      expect(shown, hasLength(1));
      expect(shown.single, contains('Due now'));
      expect(shown.single, contains('desktop-entry:${LinuxReminderFiles.appId}'));

      expect(await run(), hasLength(1), reason: 'already shown');
    });

    test('stays quiet while the app is open to show reminders itself', () async {
      schedule([
        reminder('due', DateTime.now().toUtc().subtract(const Duration(minutes: 1))),
      ]);
      // A process the kernel names as the app does.
      final app = File('${dir.path}/${LinuxReminderFiles.processName}');
      await File('/bin/sleep').copy(app.path);
      await Process.run('chmod', ['+x', app.path]);
      final running = await Process.start(app.path, ['30']);
      addTearDown(running.kill);
      File('${dir.path}/${LinuxReminderFiles.pidFile}').writeAsStringSync('${running.pid}');

      expect(await run(), isEmpty);

      running.kill();
      await running.exitCode;
      expect(await run(), hasLength(1), reason: 'the app has closed');
    });
  }, skip: !Platform.isLinux);
}
