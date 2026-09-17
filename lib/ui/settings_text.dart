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

  /// What keeping Glasswork in the tray means here, and what it is doing now.
  static ({String explanation, String? effect}) tray({
    required bool available,
    required bool on,
  }) {
    if (!available) {
      return (
        explanation:
            'This desktop has no tray to keep Glasswork in. On GNOME, the AppIndicator '
            'extension adds one.',
        effect: null,
      );
    }
    return (
      explanation:
          "Closing the window leaves Glasswork running as an icon in the top bar, so it opens "
          "at once and its reminders come straight from it. Quit it from the icon's menu.",
      effect: on
          ? 'On: closing the window keeps Glasswork in the tray.'
          : 'Off: closing the window quits Glasswork. Reminders still come while it is closed.',
    );
  }

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

  /// A week's sleep in a line, a night at a time as Time budget lists it: "In bed by 23:30
  /// and up at 07:00, every night", or for the pattern most nights share, "… on 4 nights of
  /// the week". [week] is each day's sleep, Monday first.
  static String sleepSummary(List<DaySleep> week) {
    // A night is a day's bedtime and getting up the day after.
    final counts = <(int, int), int>{};
    for (var day = 0; day < week.length; day++) {
      final night = (week[day].bedtimeMin, week[(day + 1) % week.length].wakeMin);
      counts[night] = (counts[night] ?? 0) + 1;
    }
    // Most nights first; among equals, the one earliest in the week.
    final ((bedtime, wake), nights) = counts.entries
        .map((e) => (e.key, e.value))
        .reduce((a, b) => b.$2 > a.$2 ? b : a);
    final pattern = 'In bed by ${Format.clock(bedtime)} and up at ${Format.clock(wake)}';
    return nights == week.length
        ? '$pattern, every night'
        : '$pattern on $nights nights of the week';
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
