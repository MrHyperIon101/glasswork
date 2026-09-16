import 'package:flutter/foundation.dart';

import '../capacity/ledger.dart';
import 'format.dart';

/// What each setting says about itself, worked out from the person's own figures.
///
/// Pure, with the time and the week passed in, so every sentence Settings shows can be
/// checked by a test rather than assembled inside a widget.
abstract final class SettingsText {
  /// A morning at [morningMin], against when you get up [tomorrow].
  static String morningEffect(int morningMin, DaySleep tomorrow) {
    final up = Format.clock(tomorrow.wakeMin);
    final gap = morningMin - tomorrow.wakeMin;
    return switch (gap) {
      0 => 'Tomorrow you get up at $up, so a morning reminder comes as you get up.',
      > 0 =>
        'Tomorrow you get up at $up, so a morning reminder comes '
            '${Format.estimate(gap)} after that.',
      _ =>
        'Tomorrow you get up at $up, so a morning reminder would come '
            '${Format.estimate(-gap)} before you are up.',
    };
  }

  /// An evening at [eveningMin], against when you go to bed [tonight].
  static String eveningEffect(int eveningMin, DaySleep tonight) {
    final bed = Format.clock(tonight.bedtimeMin);
    final gap = tonight.bedtimeFromMidnight - eveningMin;
    return switch (gap) {
      0 => 'Tonight you go to bed at $bed, so an evening reminder comes as you do.',
      > 0 =>
        'Tonight you go to bed at $bed, so an evening reminder comes '
            '${Format.estimate(gap)} before that.',
      _ =>
        'Tonight you go to bed at $bed, so an evening reminder would come after you '
            'are in bed.',
    };
  }

  /// When a reminder snoozed at [now] for [snoozeMin] comes back.
  static String snoozeEffect(int snoozeMin, DateTime now) {
    final back = now.add(Duration(minutes: snoozeMin));
    final time = Format.clock(back.hour * 60 + back.minute);
    final nextDay =
        DateTime(back.year, back.month, back.day) != DateTime(now.year, now.month, now.day);
    return 'A reminder snoozed now comes back at $time${nextDay ? ' tomorrow' : ''}.';
  }

  /// Where a task added outside any project goes.
  static String captureEffect({required String project, String? section}) =>
      'Tasks you add from Today, Next 7 days or All open work go to $project'
      '${section == null ? '' : ', in $section'}.';

  /// Whether reminders show on this device, and what that means.
  static ({String value, String detail}) notifications({
    required bool permitted,
    required TargetPlatform platform,
  }) => switch ((permitted, platform)) {
    (true, TargetPlatform.android) => (
      value: 'On',
      detail: 'Reminders show on this phone, even while Glasswork is closed.',
    ),
    (true, _) => (
      value: 'On',
      detail:
          'Reminders show as desktop notifications, and still come while Glasswork is '
          'closed.',
    ),
    (false, TargetPlatform.android) => (
      value: 'Off',
      detail:
          "This phone won't show reminders until notifications are allowed for "
          'Glasswork.',
    ),
    (false, _) => (
      value: 'Off',
      detail: "Reminders can't be shown on this device.",
    ),
  };

  /// What became of a sample reminder.
  static String sampleResult({required bool shown}) => shown
      ? 'Sent. It should be on screen now.'
      : "It couldn't be shown. Check that notifications are allowed for Glasswork.";

  /// Where the tasks are kept: [folder], already written the way a person reads it, where
  /// there is one worth naming.
  static String dataLocation({required TargetPlatform platform, String? folder}) =>
      switch ((platform, folder)) {
        (TargetPlatform.android, _) => 'Kept on this phone, inside Glasswork.',
        (_, final path?) => 'Kept on this device, in $path.',
        _ => 'Kept on this device.',
      };

  /// A week's sleep in a line: "Up at 07:00 and in bed by 23:30, every day", or for the
  /// pattern most days share, "… on 5 days of the week".
  static String sleepSummary(List<DaySleep> week) {
    final counts = <DaySleep, int>{};
    for (final day in week) {
      counts[day] = (counts[day] ?? 0) + 1;
    }
    // Most days first; among equals, the one earliest in the week.
    final (common, days) = counts.entries
        .map((e) => (e.key, e.value))
        .reduce((a, b) => b.$2 > a.$2 ? b : a);
    final pattern =
        'Up at ${Format.clock(common.wakeMin)} and in bed by '
        '${Format.clock(common.bedtimeMin)}';
    return days == week.length ? '$pattern, every day' : '$pattern on $days days of the week';
  }

  /// The rest of the profile in a line: "Meals 1h 30m · Buffer 1h · Focus 65% · Gaps under
  /// 25m ignored".
  static String profileSummary(CapacitySettings settings) => [
    'Meals ${Format.estimate(settings.mealsMin)}',
    'Buffer ${Format.estimate(settings.bufferMin)}',
    'Focus ${(settings.focusFactor * 100).round()}%',
    'Gaps under ${Format.estimate(settings.minGapMin)} ignored',
  ].join(' · ');

  /// Where the app is installed, from [executable], when it is where the installer puts
  /// it under [home]. Null for a build run from anywhere else.
  static String? installedAt(String executable, String home) {
    const folder = '.local/opt/dev.mrhyperion.glasswork';
    final prefix = '$home/$folder/';
    return executable.startsWith(prefix) ? '~/$folder' : null;
  }

  /// [path] with the home folder written as ~.
  static String homeRelative(String path, String home) =>
      home.length > 1 && path.startsWith('$home/') ? '~${path.substring(home.length)}' : path;
}
