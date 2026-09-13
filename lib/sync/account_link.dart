import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../data/repository/workspace_repository.dart';
import 'sync_engine.dart';
import 'sync_transport.dart';
import 'sync_writer.dart';
import 'synced_tables.dart';

/// What this device holds of its own.
class DeviceContent {
  const DeviceContent({
    required this.tasks,
    required this.projects,
    required this.blocks,
    required this.labels,
  });

  final int tasks;
  final int projects;

  /// Timetable blocks.
  final int blocks;
  final int labels;

  /// Nothing anyone made. The starter project every install begins with does not count.
  bool get isEmpty => tasks == 0 && blocks == 0 && labels == 0 && projects <= 1;
}

/// What linking this device to an account will do, worked out before anything changes.
sealed class LinkPlan {
  const LinkPlan();
}

/// The account has nothing yet, so this device's work becomes the account's.
final class ClaimAccount extends LinkPlan {
  const ClaimAccount();
}

/// This device already syncs with the account.
final class AlreadyLinked extends LinkPlan {
  const AlreadyLinked();
}

/// The account has work from another device, and this device has a workspace of its own.
final class AdoptAccount extends LinkPlan {
  const AdoptAccount({required this.workspaceId, required this.device});

  /// The account's workspace.
  final String workspaceId;

  /// What this device has of its own.
  final DeviceContent device;

  /// Whether there is anything here worth asking about. With only the starter project,
  /// taking on the account's work loses nothing.
  bool get needsChoice => !device.isEmpty;
}

/// This device's work already syncs with a different account. It exists there under the
/// same ids, so it cannot also be given to this one.
final class LinkedElsewhere extends LinkPlan {
  const LinkedElsewhere();
}

enum LinkChoice {
  /// Keep this device's work, and add it to the account.
  combine,

  /// Remove this device's work and take the account's. A backup is written first.
  replace,
}

/// The step between signing in and syncing.
///
/// Every device creates a workspace on first launch, long before anyone signs in. So the
/// second device to sign in holds a workspace of its own while the account already has
/// one, and something has to decide what becomes of the device's. This decides it.
class AccountLink {
  AccountLink({
    required AppDatabase db,
    required SyncWriter writer,
    required SyncEngine engine,
    required SyncTransport transport,
    required Future<String> Function() backupPath,
  }) : _db = db,
       _writer = writer,
       _engine = engine,
       _transport = transport,
       _backupPath = backupPath;

  final AppDatabase _db;
  final SyncWriter _writer;
  final SyncEngine _engine;
  final SyncTransport _transport;
  final Future<String> Function() _backupPath;

  static const _accountKey = 'sync_account';

  WorkspaceRepository get _workspaces => WorkspaceRepository(_writer);

  /// The account this device syncs with, if it has ever linked to one.
  Future<String?> linkedAccount() async {
    final row =
        await (_db.select(_db.localSettings)
              ..where((s) => s.key.equals(_accountKey)))
            .getSingleOrNull();
    return row?.value;
  }

  /// What linking to [userId] would do. Reads the server; changes nothing here.
  Future<LinkPlan> plan(String userId) async {
    final linked = await linkedAccount();
    if (linked != null && linked != userId) return const LinkedElsewhere();

    final local = await _workspaces.ensureSeeded();
    final remote = await _accountWorkspaces();
    if (remote.isEmpty) return const ClaimAccount();
    if (remote.contains(local.id)) return const AlreadyLinked();

    return AdoptAccount(
      workspaceId: remote.first,
      device: await _content(local.id),
    );
  }

  /// Makes this device's work the account's. It goes up with the next sync.
  Future<void> claim(String userId) async {
    final local = await _workspaces.ensureSeeded();
    // Rows written before sync existed carry no clocks, and would otherwise never be sent.
    await _writer.stampUnversioned(_db.syncedTables);
    await _finish(userId, workspaceId: local.id);
  }

  /// Records a link the server already agrees with.
  Future<void> confirm(String userId) async =>
      _finish(userId, workspaceId: (await _workspaces.ensureSeeded()).id);

  /// Takes on the account's work, doing [choice] with this device's.
  ///
  /// Everything is fetched before anything of this device's changes, and until linking
  /// completes the device keeps opening its own workspace. A dropped connection leaves it
  /// exactly as it was, ready to try again.
  Future<void> adopt(String userId, AdoptAccount plan, LinkChoice choice) async {
    final local = (await _workspaces.ensureSeeded()).id;
    // Pinned before the pull, so the account's workspace arriving cannot take its place
    // on the next launch if this is interrupted.
    await _workspaces.setActive(local);

    await _engine.pull();

    switch (choice) {
      case LinkChoice.combine:
        await _writer.stampUnversioned(_db.syncedTables);
        await _moveInto(from: local, to: plan.workspaceId);
      case LinkChoice.replace:
        if (!plan.device.isEmpty) {
          await _db.customStatement('VACUUM INTO ?', [await _backupPath()]);
        }
        await _remove(local);
    }
    await _finish(userId, workspaceId: plan.workspaceId);
  }

  Future<void> _finish(String userId, {required String workspaceId}) async {
    await _workspaces.setActive(workspaceId);
    await _db
        .into(_db.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(key: _accountKey, value: userId),
        );
  }

  /// The account's live workspaces, oldest first — the order every device agrees on.
  Future<List<String>> _accountWorkspaces() async {
    final rows = <RemoteRow>[];
    PullCursor? after;
    while (true) {
      final page = await _transport.pull(
        'workspaces',
        after: after,
        limit: SyncEngine.pageSize,
      );
      rows.addAll(page.rows);
      if (!page.hasMore || page.rows.isEmpty) break;
      after = PullCursor(page.rows.last.updatedAt, page.rows.last.id);
    }

    final live = rows.where((r) => r.values['deleted_at'] == null).toList()
      ..sort((a, b) {
        final DateTime? createdA = DateTime.tryParse('${a.values['created_at']}');
        final DateTime? createdB = DateTime.tryParse('${b.values['created_at']}');
        final byCreated = (createdA ?? DateTime(0)).compareTo(
          createdB ?? DateTime(0),
        );
        return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
      });
    return [for (final row in live) row.id];
  }

  Future<DeviceContent> _content(String workspaceId) async {
    Future<int> live(String table) async {
      final row = await _db
          .customSelect(
            'SELECT COUNT(*) AS n FROM "$table" '
            'WHERE workspace_id = ? AND deleted_at IS NULL',
            variables: [Variable.withString(workspaceId)],
          )
          .getSingle();
      return row.read<int>('n');
    }

    return DeviceContent(
      tasks: await live('tasks'),
      projects: await live('boards'),
      blocks: await live('commitments'),
      labels: await live('labels'),
    );
  }

  /// Moves this device's rows into the account's workspace, ahead of pushing them.
  ///
  /// Written directly rather than through [SyncWriter]: none of these rows has reached a
  /// server, and each is already queued with every field it has, `workspace_id` included.
  Future<void> _moveInto({required String from, required String to}) {
    return _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');

      // A workspace has one fallback timetable and one profile. The account's are kept;
      // this device's blocks move onto the account's fallback.
      final accountFallback = await _db
          .customSelect(
            'SELECT id FROM schedules '
            'WHERE workspace_id = ? AND is_fallback = 1 AND deleted_at IS NULL '
            'ORDER BY created_at, id LIMIT 1',
            variables: [Variable.withString(to)],
          )
          .getSingleOrNull();
      if (accountFallback != null) {
        await _db.customUpdate(
          'UPDATE commitments SET schedule_id = ? WHERE schedule_id IN '
          '(SELECT id FROM schedules WHERE workspace_id = ? AND is_fallback = 1)',
          variables: [
            Variable.withString(accountFallback.read<String>('id')),
            Variable.withString(from),
          ],
          updates: {_db.commitments},
        );
        await _db.customUpdate(
          'DELETE FROM schedules WHERE workspace_id = ? AND is_fallback = 1',
          variables: [Variable.withString(from)],
          updates: {_db.schedules},
          updateKind: UpdateKind.delete,
        );
      }

      final accountProfile = await _db
          .customSelect(
            'SELECT 1 FROM capacity_profiles WHERE workspace_id = ? LIMIT 1',
            variables: [Variable.withString(to)],
          )
          .getSingleOrNull();
      if (accountProfile != null) {
        await _db.customUpdate(
          'DELETE FROM capacity_profiles WHERE workspace_id = ?',
          variables: [Variable.withString(from)],
          updates: {_db.capacityProfiles},
          updateKind: UpdateKind.delete,
        );
      }

      for (final table in _db.syncedTables) {
        if (table.actualTableName == 'workspaces') continue;
        await _db.customUpdate(
          'UPDATE "${table.actualTableName}" SET workspace_id = ? WHERE workspace_id = ?',
          variables: [Variable.withString(to), Variable.withString(from)],
          updates: {table},
        );
      }
      await _db.customUpdate(
        'DELETE FROM workspaces WHERE id = ?',
        variables: [Variable.withString(from)],
        updates: {_db.workspaces},
        updateKind: UpdateKind.delete,
      );
    });
  }

  /// Removes this device's workspace and everything in it.
  ///
  /// Hard deletes, which nothing else in the app ever does: these rows never reached a
  /// server, so there is no tombstone to keep and nobody to tell.
  Future<void> _remove(String workspaceId) {
    return _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');

      for (final table in _db.syncedTables.reversed) {
        final name = table.actualTableName;
        await _db.customUpdate(
          name == 'workspaces'
              ? 'DELETE FROM workspaces WHERE id = ?'
              : 'DELETE FROM "$name" WHERE workspace_id = ?',
          variables: [Variable.withString(workspaceId)],
          updates: {table},
          updateKind: UpdateKind.delete,
        );
      }
      // Everything queued was this device's own, and none of it exists any more.
      await _db.customUpdate(
        'DELETE FROM outbox',
        updates: {_db.outbox},
        updateKind: UpdateKind.delete,
      );
    });
  }
}
