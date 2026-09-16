import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/preferences.dart';
import 'package:glasswork/data/repository/preferences_repository.dart';

void main() {
  late AppDatabase db;
  late PreferencesRepository preferences;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    preferences = PreferencesRepository(db);
  });
  tearDown(() => db.close());

  Future<void> store(String key, String value) => db
      .into(db.localSettings)
      .insertOnConflictUpdate(LocalSettingsCompanion.insert(key: key, value: value));

  test('nothing chosen reads as the defaults', () async {
    expect(
      await preferences.read(),
      const Preferences(morningMin: 9 * 60, eveningMin: 18 * 60, snoozeMin: 10),
    );
  });

  test('what is set is what is read, and the watch sees each change', () async {
    final seen = <Preferences>[];
    final subscription = preferences.watch().listen(seen.add);
    addTearDown(subscription.cancel);

    await preferences.setMorning(8 * 60);
    await preferences.setEvening(19 * 60 + 30);
    await preferences.setSnooze(30);
    await preferences.setCaptureProject('project-b');
    await pumpEventQueue();

    const chosen = Preferences(
      morningMin: 8 * 60,
      eveningMin: 19 * 60 + 30,
      snoozeMin: 30,
      captureProjectId: 'project-b',
    );
    expect(await preferences.read(), chosen);
    expect(seen.last, chosen);

    await preferences.setCaptureProject(null);
    expect((await preferences.read()).captureProjectId, isNull);
  });

  test('a value out of bounds is kept to the nearest one allowed', () async {
    await preferences.setMorning(20 * 60);
    await preferences.setEvening(9 * 60);
    await preferences.setSnooze(24 * 60);
    expect(
      await preferences.read(),
      const Preferences(
        morningMin: Preferences.latestMorningMin,
        eveningMin: Preferences.earliestEveningMin,
        snoozeMin: Preferences.longestSnoozeMin,
      ),
    );
  });

  test('a damaged stored value reads as the default, or the nearest allowed', () async {
    await store(Preferences.morningKey, 'soon');
    await store(Preferences.eveningKey, '99999');
    await store(Preferences.snoozeKey, '');
    await store(Preferences.captureProjectKey, '');
    expect(
      await preferences.read(),
      const Preferences(eveningMin: Preferences.latestEveningMin),
    );
  });

  test('other local settings are left alone', () async {
    await store('client_id', 'device-a');
    await preferences.setSnooze(5);
    await preferences.setCaptureProject(null);

    final client = await (db.select(db.localSettings)
          ..where((s) => s.key.equals('client_id')))
        .getSingle();
    expect(client.value, 'device-a');
  });

  test('Snooze steps through its lengths, and from between two to the next', () {
    expect(Preferences.stepSnooze(10, 1), 15);
    expect(Preferences.stepSnooze(10, -1), 5);
    expect(Preferences.stepSnooze(12, 1), 15);
    expect(Preferences.stepSnooze(12, -1), 10);
    expect(Preferences.stepSnooze(120, 1), 120);
    expect(Preferences.stepSnooze(5, -1), 5);
  });
}
