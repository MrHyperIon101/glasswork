import 'package:uuid/uuid.dart';

/// Ids for rows that can exist only once, derived from what makes them unique.
///
/// Most rows get a random id, because two tasks with the same title are still two tasks.
/// A few rows are one-per-key: a label on a task, a field's value on a task, a
/// workspace's capacity profile. Given random ids, two devices that each create one of
/// those offline both sync, and a lookup expecting one row finds two.
///
/// A derived id makes both devices create the *same* row. The merge then folds their
/// edits together field by field, as it would for any row edited in two places.
///
/// Only for keys that never change. A label's name can be edited, so labels keep random
/// ids: one derived from the name would collide with a renamed label.
abstract final class NaturalId {
  /// Fixed forever. Changing it changes every derived id, and devices already in use
  /// would stop agreeing about which row is which.
  static const namespace = '536ab03c-6336-46b8-b85c-c4fa6df1df13';

  static const _uuid = Uuid();

  static String taskLabel(String taskId, String labelId) =>
      _derive('task-label', [taskId, labelId]);

  static String fieldValue(String taskId, String fieldId) =>
      _derive('field-value', [taskId, fieldId]);

  static String capacityProfile(String workspaceId) =>
      _derive('capacity-profile', [workspaceId]);

  static String fallbackSchedule(String workspaceId) =>
      _derive('fallback-schedule', [workspaceId]);

  // Ids are UUIDs and never contain '/', so the joined name is unambiguous.
  static String _derive(String kind, List<String> key) =>
      _uuid.v5(namespace, [kind, ...key].join('/'));
}
