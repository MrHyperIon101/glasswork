import 'package:drift/drift.dart';

import '../db/database.dart';
import '../preferences.dart';

/// Reads and writes [Preferences], in `LocalSettings`.
///
/// Straight to the database rather than through the sync writer: preferences belong to
/// this device and never sync.
class PreferencesRepository {
  PreferencesRepository(this._db);

  final AppDatabase _db;

  Stream<Preferences> watch() => _stored().watch().map(_read);

  Future<Preferences> read() async => _read(await _stored().get());

  Future<void> setMorning(int minutes) =>
      _put(Preferences.morningKey, Preferences.clampMorning(minutes));

  Future<void> setEvening(int minutes) =>
      _put(Preferences.eveningKey, Preferences.clampEvening(minutes));

  Future<void> setSnooze(int minutes) =>
      _put(Preferences.snoozeKey, Preferences.clampSnooze(minutes));

  Future<void> setKeepInTray(bool keep) => _put(Preferences.keepInTrayKey, keep);

  /// Null goes back to the first project.
  Future<void> setCaptureProject(String? projectId) async {
    if (projectId == null) {
      await (_db.delete(
        _db.localSettings,
      )..where((s) => s.key.equals(Preferences.captureProjectKey))).go();
      return;
    }
    await _put(Preferences.captureProjectKey, projectId);
  }

  SimpleSelectStatement<$LocalSettingsTable, LocalSetting> _stored() =>
      _db.select(_db.localSettings)..where((s) => s.key.isIn(Preferences.keys));

  static Preferences _read(List<LocalSetting> rows) =>
      Preferences.fromStored({for (final row in rows) row.key: row.value});

  Future<void> _put(String key, Object value) => _db
      .into(_db.localSettings)
      .insertOnConflictUpdate(
        LocalSettingsCompanion.insert(key: key, value: '$value'),
      );
}
