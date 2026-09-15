import 'reminder_plan.dart';

/// The files that let Linux raise reminders while Glasswork is closed.
///
/// Linux has no notification scheduler of its own. A systemd user timer is the nearest
/// thing: it outlives the app, catches up after the computer was asleep or off, and costs
/// nothing between reminders. It fires at each reminder's time and runs [script], which
/// shows whatever has come due, unless the app is open and showing reminders itself.
///
/// Pure text, so exactly what gets written can be tested.
abstract final class LinuxReminderFiles {
  static const appId = 'dev.mrhyperion.glasswork';
  static const unit = '$appId-reminders';

  /// The binary's name, as the kernel reports it for a running process.
  static const processName = 'glasswork';

  /// Reminders missed by longer than this, say while the computer was off, are dropped
  /// rather than raised hours late.
  static const catchUp = Duration(hours: 12);

  static const scheduleFile = 'reminders.tsv';
  static const firedFile = 'reminders-fired.tsv';
  static const scriptFile = 'show-reminders.sh';

  /// Where the running app records its process id, relative to `XDG_RUNTIME_DIR`.
  static const pidFile = '$appId.pid';

  /// The timer: one trigger per reminder, each an exact instant.
  static String timer(List<PlannedReminder> reminders) => [
    '# Written by Glasswork, and rewritten whenever its reminders change.',
    '[Unit]',
    'Description=Glasswork reminders',
    '',
    '[Timer]',
    for (final reminder in reminders) 'OnCalendar=${calendar(reminder.at)}',
    // Catches up on a reminder missed while the computer was off.
    'Persistent=true',
    'AccuracySec=1s',
    '',
    '[Install]',
    'WantedBy=timers.target',
    '',
  ].join('\n');

  /// The service the timer starts.
  static String service(String scriptPath) => [
    '# Written by Glasswork.',
    '[Unit]',
    'Description=Show Glasswork reminders that have come due',
    '',
    '[Service]',
    'Type=oneshot',
    'ExecStart=/bin/sh "$scriptPath"',
    '',
  ].join('\n');

  /// `2026-09-16 03:30:00 UTC`: a calendar time systemd reads as exactly that instant.
  static String calendar(DateTime at) {
    final u = at.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-${_two(u.month)}-${_two(u.day)} '
        '${_two(u.hour)}:${_two(u.minute)}:${_two(u.second)} UTC';
  }

  /// One line per reminder: unix seconds, task id, title and body, separated by tabs.
  static String schedule(List<PlannedReminder> reminders) => [
    for (final reminder in reminders)
      '${seconds(reminder.at)}\t${reminder.taskId}\t'
          '${_flat(reminder.title, 'Reminder')}\t${_flat(reminder.body, 'Glasswork')}\n',
  ].join();

  /// The line recording that [reminder] was shown, so it is never shown twice.
  static String fired(PlannedReminder reminder) =>
      '${seconds(reminder.at)}\t${reminder.taskId}\n';

  static int seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

  /// The records worth keeping from [firedText] as of [now]: the rest are older than any
  /// reminder that could still be caught up on.
  static String pruneFired(String firedText, DateTime now) {
    final oldest = seconds(now.subtract(catchUp * 2));
    return [
      for (final line in firedText.split('\n'))
        if (int.tryParse(line.split('\t').first) case final at?
            when at >= oldest)
          '$line\n',
    ].join();
  }

  /// A title or body as one line, with no tab to break the schedule's columns.
  static String _flat(String text, String fallback) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.isEmpty ? fallback : flat;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Shows reminders that have come due. POSIX sh, and nothing beyond what every desktop
  /// has: `notify-send` from libnotify, `date` and `grep`.
  static final script =
      '''
#!/bin/sh
# Written by Glasswork. Shows reminders that have come due, unless Glasswork is open, when
# it shows them itself.
dir="\$(dirname "\$0")"
schedule="\$dir/$scheduleFile"
fired="\$dir/$firedFile"
pidfile="\${XDG_RUNTIME_DIR:-/tmp}/$pidFile"

if [ -f "\$pidfile" ]; then
  pid="\$(cat "\$pidfile")"
  if [ -n "\$pid" ] && [ "\$(cat "/proc/\$pid/comm" 2>/dev/null)" = "$processName" ]; then
    exit 0
  fi
fi

[ -f "\$schedule" ] || exit 0
touch "\$fired"
now="\$(date +%s)"
tab="\$(printf '\\t')"

while IFS="\$tab" read -r at id title body; do
  [ -n "\$at" ] || continue
  [ "\$at" -le "\$now" ] || continue
  [ \$((now - at)) -le ${catchUp.inSeconds} ] || continue
  key="\$(printf '%s\\t%s' "\$at" "\$id")"
  grep -qxF "\$key" "\$fired" && continue
  notify-send --app-name=Glasswork --icon=$appId \\
    --hint=string:desktop-entry:$appId -- "\$title" "\$body"
  printf '%s\\n' "\$key" >> "\$fired"
done < "\$schedule"
''';
}
