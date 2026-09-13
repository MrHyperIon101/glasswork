import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_writer.dart';
import '../db/database.dart';
import '../order_key.dart';

/// The workspace this device opens, and its lists.
///
/// v1 ships one workspace, created on first launch. The table exists because the schema
/// is shaped for sharing later; the UI never exposes it.
class WorkspaceRepository {
  WorkspaceRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();
  static const _clientIdKey = 'client_id';
  static const _activeKey = 'workspace_id';

  /// Stable identity for this device, created once and then never changed.
  ///
  /// Static, and given the database rather than a writer, because the writer is built from
  /// it: every clock the writer mints carries this id. It also tiebreaks equal order keys.
  /// If it changed between launches, this device's own earlier edits would look like
  /// another device's.
  static Future<String> ensureClientId(AppDatabase db) {
    return db.transaction(() async {
      final existing =
          await (db.select(db.localSettings)
                ..where((s) => s.key.equals(_clientIdKey)))
              .getSingleOrNull();
      if (existing != null) return existing.value;

      final id = _uuid.v4();
      // Local-only, deliberately: a device's identity is the one thing that must never
      // sync to another device.
      await db
          .into(db.localSettings)
          .insert(LocalSettingsCompanion.insert(key: _clientIdKey, value: id));
      return id;
    });
  }

  /// The workspace to open, created with a starter project on first launch. Safe to call
  /// on every launch.
  ///
  /// The one set with [setActive] if there is one, and otherwise the oldest — never "the
  /// only one". Once sync runs a device can hold more than one workspace, its own and one
  /// pulled from another device, and asking for the only one would throw at launch.
  Future<Workspace> ensureSeeded() {
    return _db.transaction(() async {
      final active = await _activeWorkspace();
      if (active != null) return active;

      final existing =
          await (_db.select(_db.workspaces)
                ..where((w) => w.deletedAt.isNull())
                ..orderBy([
                  (w) => OrderingTerm(expression: w.createdAt),
                  (w) => OrderingTerm(expression: w.id),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return existing;

      final workspace = await _writer.insert(
        _db.workspaces,
        WorkspacesCompanion.insert(id: _uuid.v4(), name: 'Personal'),
      );

      final board = await _writer.insert(
        _db.boards,
        BoardsCompanion.insert(
          id: _uuid.v4(),
          workspaceId: workspace.id,
          name: 'Personal',
          purpose: const Value('Everything with nowhere better to go'),
          icon: const Value('◍'),
          colour: const Value(0xFF0A84FF),
          orderKey: OrderKey.first,
        ),
      );

      // "Inbox" says nothing about what it holds. These name the state of the work.
      var key = OrderKey.first;
      for (final (i, section) in ['To do', 'Doing', 'Done'].indexed) {
        await _writer.insert(
          _db.lists,
          ListsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspace.id,
            boardId: board.id,
            name: section,
            orderKey: key,
            isDoneColumn: Value(i == 2),
          ),
        );
        key = OrderKey.after(key);
      }

      return workspace;
    });
  }

  /// Makes launch open [workspaceId] from now on.
  ///
  /// Pinned at launch and moved only when this device links to an account whose workspace
  /// came from another device, so an older workspace arriving by sync never quietly takes
  /// this device's place.
  Future<void> setActive(String workspaceId) => _db
      .into(_db.localSettings)
      .insertOnConflictUpdate(
        LocalSettingsCompanion.insert(key: _activeKey, value: workspaceId),
      );

  Future<Workspace?> _activeWorkspace() async {
    final setting =
        await (_db.select(_db.localSettings)
              ..where((s) => s.key.equals(_activeKey)))
            .getSingleOrNull();
    if (setting == null) return null;

    return (_db.select(_db.workspaces)
          ..where((w) => w.id.equals(setting.value) & w.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Stream<List<BoardList>> watchLists(String workspaceId) {
    final q = _db.select(_db.lists)
      ..where((l) => l.workspaceId.equals(workspaceId) & l.deletedAt.isNull())
      ..orderBy([
        (l) => OrderingTerm(expression: l.orderKey),
        (l) => OrderingTerm(expression: l.clientId),
      ]);
    return q.watch();
  }
}
