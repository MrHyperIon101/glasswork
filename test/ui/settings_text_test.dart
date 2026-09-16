import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/ledger.dart';
import 'package:glasswork/ui/settings_text.dart';

void main() {
  const up7bed2330 = DaySleep(wakeMin: 7 * 60, bedtimeMin: 23 * 60 + 30);

  test('a morning is told against when you get up tomorrow', () {
    expect(
      SettingsText.morningEffect(9 * 60, up7bed2330),
      'Tomorrow you get up at 07:00, so a morning reminder comes 2h after that.',
    );
    expect(
      SettingsText.morningEffect(7 * 60, up7bed2330),
      'Tomorrow you get up at 07:00, so a morning reminder comes as you get up.',
    );
    expect(
      SettingsText.morningEffect(6 * 60 + 30, up7bed2330),
      'Tomorrow you get up at 07:00, so a morning reminder would come 30m before you are up.',
    );
  });

  test('an evening is told against when you go to bed tonight, even after midnight', () {
    expect(
      SettingsText.eveningEffect(18 * 60, up7bed2330),
      'Tonight you go to bed at 23:30, so an evening reminder comes 5h 30m before that.',
    );
    expect(
      SettingsText.eveningEffect(22 * 60, const DaySleep(wakeMin: 9 * 60, bedtimeMin: 60)),
      'Tonight you go to bed at 01:00, so an evening reminder comes 3h before that.',
    );
    expect(
      SettingsText.eveningEffect(22 * 60, const DaySleep(wakeMin: 6 * 60, bedtimeMin: 21 * 60)),
      'Tonight you go to bed at 21:00, so an evening reminder would come after you are in bed.',
    );
  });

  test('a snooze says when the reminder comes back, and when that is tomorrow', () {
    expect(
      SettingsText.snoozeEffect(10, DateTime(2026, 9, 16, 18, 5)),
      'A reminder snoozed now comes back at 18:15.',
    );
    expect(
      SettingsText.snoozeEffect(90, DateTime(2026, 9, 16, 23, 0)),
      'A reminder snoozed now comes back at 00:30 tomorrow.',
    );
  });

  test('notifications say what they mean on each device', () {
    expect(
      SettingsText.notifications(permitted: true, platform: TargetPlatform.android).detail,
      contains('even while Glasswork is closed'),
    );
    expect(
      SettingsText.notifications(permitted: false, platform: TargetPlatform.android),
      (
        value: 'Off',
        detail: "This phone won't show reminders until notifications are allowed for Glasswork.",
      ),
    );
    expect(
      SettingsText.notifications(permitted: true, platform: TargetPlatform.linux).detail,
      contains('desktop notifications'),
    );
  });

  test('the tray says what closing the window will do, or why there is no tray', () {
    expect(SettingsText.tray(available: false, on: false).effect, isNull);
    expect(
      SettingsText.tray(available: false, on: false).explanation,
      contains('AppIndicator'),
    );
    expect(
      SettingsText.tray(available: true, on: true).effect,
      'On: closing the window keeps Glasswork in the tray.',
    );
    expect(
      SettingsText.tray(available: true, on: false).effect,
      startsWith('Off: closing the window quits Glasswork.'),
    );
  });

  test('a week of sleep reads as its pattern', () {
    expect(
      SettingsText.sleepSummary(List.filled(7, up7bed2330)),
      'Up at 07:00 and in bed by 23:30, every day',
    );
    const weekend = DaySleep(wakeMin: 9 * 60, bedtimeMin: 60);
    expect(
      SettingsText.sleepSummary([...List.filled(5, up7bed2330), weekend, weekend]),
      'Up at 07:00 and in bed by 23:30 on 5 days of the week',
    );
  });

  test('the rest of the profile reads in one line', () {
    expect(
      SettingsText.profileSummary(const CapacitySettings()),
      'Meals 1h 30m · Buffer 1h · Focus 65% · Gaps under 25m ignored',
    );
  });

  test('where a task added outside a project goes', () {
    expect(
      SettingsText.captureEffect(project: 'Glasswork', section: 'Backlog'),
      'Tasks you add from Today, Next 7 days or All open work go to Glasswork, in Backlog.',
    );
    expect(
      SettingsText.captureEffect(project: 'Glasswork'),
      'Tasks you add from Today, Next 7 days or All open work go to Glasswork.',
    );
  });

  test('the installed app is recognised by where the installer puts it', () {
    expect(
      SettingsText.installedAt(
        '/home/me/.local/opt/dev.mrhyperion.glasswork/glasswork',
        '/home/me',
      ),
      '~/.local/opt/dev.mrhyperion.glasswork',
    );
    expect(
      SettingsText.installedAt('/home/me/code/glasswork/build/bundle/glasswork', '/home/me'),
      isNull,
    );
  });

  test('paths read from the home folder, and data where it is', () {
    expect(
      SettingsText.homeRelative('/home/me/.local/share/dev.mrhyperion.glasswork', '/home/me'),
      '~/.local/share/dev.mrhyperion.glasswork',
    );
    expect(SettingsText.homeRelative('/var/lib/glasswork', '/home/me'), '/var/lib/glasswork');
    expect(SettingsText.homeRelative('/home/meg/data', '/home/me'), '/home/meg/data');
    expect(
      SettingsText.dataLocation(platform: TargetPlatform.linux, folder: '~/.local/share/x'),
      'Kept on this device, in ~/.local/share/x.',
    );
    expect(
      SettingsText.dataLocation(platform: TargetPlatform.android, folder: '/data/x'),
      'Kept on this phone, inside Glasswork.',
    );
  });
}
