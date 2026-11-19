import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_writer.dart';
import '../db/database.dart';

/// Focus sessions: the focus timer's, and the time they track.
///
/// Local-first like everything else, and written only through [SyncWriter], so a session
/// started on one device runs on every other one too. One runs at a time: starting a session
/// ends whichever was running.
class FocusRepository {
  FocusRepository(this._writer);

  final SyncWriter _writer;

  AppDatabase get _db => _writer.db;

  static const _uuid = Uuid();

  /// Every live session in the workspace, the newest first.
  Stream<List<FocusSession>> watchAll(String workspaceId) =>
      (_db.select(_db.focusSessions)
            ..where((s) => s.workspaceId.equals(workspaceId) & s.deletedAt.isNull())
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt), (s) => OrderingTerm.desc(s.id)]))
          .watch();

  /// Starts a session of [plannedMin] minutes at [now] — focus on [taskId], or a break —
  /// ending any that was still running then.
  Future<FocusSession> start({
    required String workspaceId,
    required int plannedMin,
    required DateTime now,
    String? taskId,
    bool isBreak = false,
  }) => _db.transaction(() async {
    final running = await (_db.select(_db.focusSessions)
          ..where((s) => s.workspaceId.equals(workspaceId) & s.endedAt.isNull() & s.deletedAt.isNull()))
        .get();
    for (final session in running) {
      await end(session, at: now);
    }
    return _writer.insert(
      _db.focusSessions,
      FocusSessionsCompanion.insert(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        taskId: Value(isBreak ? null : taskId),
        startedAt: now,
        plannedMin: plannedMin,
        kind: Value(isBreak ? 'break' : 'focus'),
      ),
    );
  });

  /// Ends [session] at [at], or at its planned end if that came first: a session left
  /// running past its length — the app was closed — counts only the time it was set for.
  Future<void> end(FocusSession session, {required DateTime at}) {
    final planned = session.startedAt.add(Duration(minutes: session.plannedMin));
    return _writer.update(
      _db.focusSessions,
      session.id,
      FocusSessionsCompanion(endedAt: Value(at.isAfter(planned) ? planned : at)),
    );
  }
}
