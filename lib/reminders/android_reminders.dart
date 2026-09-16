import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../theme/tokens.dart';
import 'reminder_plan.dart';
import 'reminders.dart';

/// Reminders on Android: notifications the system raises at the minute they are due,
/// whether or not the app is running, and puts back after a restart.
class AndroidReminders implements ReminderGateway {
  AndroidReminders([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// How a reminder shows: with buttons for its task, or, for the sample, with none.
  static NotificationDetails _details({Duration? snooze}) => NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Tasks you asked to be reminded about',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      color: AppColour.accent,
      actions: [
        if (snooze != null) ...[
          // Both open the app, which does the work. Handled in the background instead, a
          // button would write to the database from a second engine, beside the app's own.
          const AndroidNotificationAction('done', 'Mark done', showsUserInterface: true),
          AndroidNotificationAction('snooze', snoozeLabel(snooze), showsUserInterface: true),
        ],
      ],
    ),
  );

  @override
  Future<ReminderResponse?> start(
    void Function(ReminderResponse response) onResponse,
  ) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final read = ReminderResponse.read(
          payload: response.payload,
          actionId: response.actionId,
        );
        if (read != null) onResponse(read);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp != true || response == null) return null;
    return ReminderResponse.read(
      payload: response.payload,
      actionId: response.actionId,
    );
  }

  @override
  Future<bool> permitted() async => await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async {
    if (await permitted()) return true;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> showSample() async {
    if (!await permitted()) return false;
    await _plugin.show(
      id: ReminderPlan.sampleId,
      title: SampleReminder.title,
      body: SampleReminder.body,
      notificationDetails: _details(),
    );
    return true;
  }

  @override
  Future<void> schedule(List<PlannedReminder> reminders, {required Duration snooze}) async {
    final details = _details(snooze: snooze);
    final wanted = {for (final reminder in reminders) reminder.id};
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (!wanted.contains(pending.id)) await _plugin.cancel(id: pending.id);
    }

    // At the minute where Android allows it. Where it does not, within a few minutes,
    // which beats a reminder that never comes.
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    for (final reminder in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body.isEmpty ? null : reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: reminder.taskId,
        );
      } on ArgumentError {
        // Came due while the plan was being applied. The next plan leaves it out.
      }
    }
  }
}
