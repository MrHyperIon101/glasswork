import 'package:drift/drift.dart';

import '../db/database.dart';
import '../completed.dart';
import '../preferences.dart';
import '../project_groups.dart';

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

  /// The areas the sidebar shows closed. Kept here, beside the preferences, because how
  /// this device's sidebar was left is this device's alone.
  Stream<Set<String>> watchCollapsedAreas() => _watchIds(CollapsedAreas.key);

  Future<void> setAreaCollapsed(String areaId, {required bool collapsed}) =>
      _toggleId(CollapsedAreas.key, areaId, on: collapsed);

  /// The projects showing their completed work folded away. This device's own, for the
  /// same reason.
  Stream<Set<String>> watchCollapsedCompleted() =>
      _watchIds(CollapsedCompleted.key);

  Future<void> setCompletedCollapsed(
    String projectId, {
    required bool collapsed,
  }) => _toggleId(CollapsedCompleted.key, projectId, on: collapsed);

  Stream<Set<String>> _watchIds(String key) =>
      (_db.select(_db.localSettings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => IdSet.parse(row?.value));

  Future<void> _toggleId(String key, String id, {required bool on}) =>
      _db.transaction(() async {
        final row =
            await (_db.select(_db.localSettings)..where((s) => s.key.equals(key)))
                .getSingleOrNull();
        final ids = IdSet.parse(row?.value);
        on ? ids.add(id) : ids.remove(id);
        await _put(key, IdSet.format(ids));
      });

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
