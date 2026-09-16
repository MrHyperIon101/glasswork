import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/reminders/reminder_plan.dart';
import 'package:glasswork/reminders/reminders.dart';

final now = DateTime.utc(2026, 9, 16, 12);

Task task(String id, {DateTime? remindAt, String title = 'Title'}) => Task(
  id: id,
  createdAt: now,
  updatedAt: now,
  fieldVersions: '{}',
  workspaceId: 'ws',
  listId: 'list',
  title: title,
  orderKey: 'a',
  status: TaskStatus.open,
  priority: 0,
  slipCount: 0,
  remindAt: remindAt,
);

/// Records what it is asked to schedule, and fails when told to.
class _Gateway implements ReminderGateway {
  final scheduled = <List<PlannedReminder>>[];
  final snoozes = <Duration>[];
  ReminderResponse? launch;
  bool failStart = false;
  bool failSchedule = false;
  bool failSample = false;

  @override
  Future<ReminderResponse?> start(
    void Function(ReminderResponse response) onResponse,
  ) async {
    if (failStart) throw StateError('no notifications here');
    return launch;
  }

  @override
  Future<bool> permitted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<PlannedReminder> reminders, {required Duration snooze}) async {
    if (failSchedule) throw StateError('refused');
    scheduled.add(reminders);
    snoozes.add(snooze);
  }

  @override
  Future<bool> showSample() async {
    if (failSample) throw StateError('no notification daemon');
    return true;
  }
}

/// Longer than the service is told to wait for changes to pause.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  late _Gateway gateway;
  late ReminderService service;

  setUp(() {
    gateway = _Gateway();
    service = ReminderService(
      gateway,
      settle: const Duration(milliseconds: 5),
      clock: () => now,
    );
  });
  tearDown(() => service.dispose());

  final inAnHour = now.add(const Duration(hours: 1));

  test('hands the platform nothing until it has started', () async {
    service.update([task('a', remindAt: inAnHour)]);
    await settle();
    expect(gateway.scheduled, isEmpty);

    await service.start((_) {});
    await settle();
    expect([for (final r in gateway.scheduled.single) r.taskId], ['a']);
  });

  test('a burst of changes schedules once, and an unchanged plan not again', () async {
    await service.start((_) {});
    for (var i = 0; i < 5; i++) {
      service.update([task('a', remindAt: inAnHour, title: 'Typing $i')]);
    }
    await settle();
    expect(gateway.scheduled, hasLength(1));
    expect(gateway.scheduled.single.single.title, 'Typing 4');

    service.update([task('a', remindAt: inAnHour, title: 'Typing 4')]);
    await settle();
    expect(gateway.scheduled, hasLength(1), reason: 'nothing changed');

    service.update([task('a')]);
    await settle();
    expect(gateway.scheduled.last, isEmpty, reason: 'the reminder was taken off');
  });

  test('hands back the reminder that launched the app', () async {
    gateway.launch = const ReminderResponse(
      taskId: 'a',
      action: ReminderAction.snooze,
    );
    final launch = await service.start((_) {});
    expect(launch?.taskId, 'a');
    expect(launch?.action, ReminderAction.snooze);
  });

  test('notifications that cannot start leave the app running without them', () async {
    gateway.failStart = true;
    expect(await service.start((_) {}), isNull);

    service.update([task('a', remindAt: inAnHour)]);
    await settle();
    expect(gateway.scheduled, isEmpty);
  });

  test('a plan the platform refused is tried again', () async {
    gateway.failSchedule = true;
    await service.start((_) {});
    service.update([task('a', remindAt: inAnHour)]);
    await settle();
    expect(gateway.scheduled, isEmpty);

    gateway.failSchedule = false;
    service.refresh();
    await settle();
    expect([for (final r in gateway.scheduled.single) r.taskId], ['a']);
  });

  test('a new snooze length hands every reminder over again, and the same one does not', () async {
    await service.start((_) {});
    service.update([task('a', remindAt: inAnHour)]);
    await settle();
    expect(gateway.snoozes, [const Duration(minutes: 10)]);

    service.snooze = const Duration(minutes: 30);
    await settle();
    expect(gateway.snoozes, [const Duration(minutes: 10), const Duration(minutes: 30)]);
    expect(
      [for (final r in gateway.scheduled.last) r.taskId],
      ['a'],
      reason: 'the buttons say how long, so the same reminders go again',
    );

    service.snooze = const Duration(minutes: 30);
    await settle();
    expect(gateway.snoozes, hasLength(2));
  });

  test('a sample that cannot be shown says so rather than throwing', () async {
    expect(await service.showSample(), isTrue);
    gateway.failSample = true;
    expect(await service.showSample(), isFalse);
  });

  test('a Snooze button says how long it waits', () {
    expect(snoozeLabel(const Duration(minutes: 10)), 'Snooze 10 min');
    expect(snoozeLabel(const Duration(hours: 1)), 'Snooze 1 hr');
    expect(snoozeLabel(const Duration(minutes: 90)), 'Snooze 1 hr 30 min');
  });

  test('reads what a notification hands back', () {
    expect(
      ReminderResponse.read(payload: 'a', actionId: 'done')?.action,
      ReminderAction.done,
    );
    expect(ReminderResponse.read(payload: 'a')?.action, isNull);
    expect(ReminderResponse.read(payload: 'a', actionId: 'other')?.action, isNull);
    expect(ReminderResponse.read(payload: null), isNull);
    expect(ReminderResponse.read(payload: ''), isNull);
  });
}
