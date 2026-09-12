import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../order_key.dart';

/// The single workspace, its boards and lists.
///
/// v1 ships exactly one workspace, created on first launch. The table exists because the
/// schema is shaped for sharing later; the UI never exposes it.
class WorkspaceRepository {
  WorkspaceRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();
  static const _clientIdKey = 'client_id';

  /// Stable identity for this device, created once and then never changed.
  ///
  /// It tiebreaks equal order keys and becomes the HLC node id when sync lands. If this
  /// ever changed between launches, two devices could not be told apart in a merge.
  Future<String> clientId() async {
    final existing = await _setting(_clientIdKey);
    if (existing != null) return existing;

    final id = _uuid.v4();
    await _db
        .into(_db.localSettings)
        .insert(LocalSettingsCompanion.insert(key: _clientIdKey, value: id));
    return id;
  }

  /// Creates the default workspace, board and list if they are not there yet, and
  /// returns them. Safe to call on every launch.
  Future<Workspace> ensureSeeded() async {
    final existing = await _db.select(_db.workspaces).getSingleOrNull();
    if (existing != null) return existing;

    final client = await clientId();
    final workspaceId = _uuid.v4();
    final boardId = _uuid.v4();

    return _db.transaction(() async {
      final workspace = await _db
          .into(_db.workspaces)
          .insertReturning(
            WorkspacesCompanion.insert(
              id: workspaceId,
              name: 'Personal',
              clientId: Value(client),
            ),
          );

      await _db
          .into(_db.boards)
          .insert(
            BoardsCompanion.insert(
              id: boardId,
              workspaceId: workspaceId,
              name: 'Personal',
              purpose: const Value('Everything with nowhere better to go'),
              icon: const Value('◍'),
              colour: const Value(0xFF0A84FF),
              orderKey: OrderKey.first,
              clientId: Value(client),
            ),
          );

      // "Inbox" says nothing about what it holds. These name the state of the work.
      var key = OrderKey.first;
      for (final (i, section) in ['To do', 'Doing', 'Done'].indexed) {
        await _db.into(_db.lists).insert(
          ListsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: boardId,
            name: section,
            orderKey: key,
            isDoneColumn: Value(i == 2),
            clientId: Value(client),
          ),
        );
        key = OrderKey.after(key);
      }

      return workspace;
    });
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

  Future<BoardList> createList({
    required String workspaceId,
    required String boardId,
    required String name,
  }) async {
    final last =
        await (_db.select(_db.lists)
              ..where((l) => l.boardId.equals(boardId) & l.deletedAt.isNull())
              ..orderBy([
                (l) => OrderingTerm(
                  expression: l.orderKey,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return _db
        .into(_db.lists)
        .insertReturning(
          ListsCompanion.insert(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            boardId: boardId,
            name: name,
            orderKey: last == null
                ? OrderKey.first
                : OrderKey.after(last.orderKey),
            clientId: Value(await clientId()),
          ),
        );
  }

  Future<String?> _setting(String key) async {
    final row =
        await (_db.select(
          _db.localSettings,
        )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }
}
