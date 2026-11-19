import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/state/providers.dart';

/// The focus timer's sessions, against a real database: one runs at a time, and a session
/// counts only what it was set for.
void main() {
  late AppDatabase db;
  late ProviderContainer app;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    app = ProviderContainer(overrides: [databaseProvider.overrideWith((ref) => db)]);
  });
  tearDown(() async {
    app.dispose();
    await db.close();
  });

  final nine = DateTime(2026, 9, 11, 9);

  test('starting a session ends the one that was running', () async {
    final scope = await app.read(appScopeProvider.future);
    final first = await scope.focus.start(workspaceId: scope.workspace.id, plannedMin: 25, now: nine);
    await scope.focus.start(
      workspaceId: scope.workspace.id,
      plannedMin: 5,
      now: nine.add(const Duration(minutes: 10)),
      isBreak: true,
    );
    final rows = await db.select(db.focusSessions).get();
    expect(rows, hasLength(2));
    final ended = rows.singleWhere((r) => r.id == first.id);
    expect(ended.endedAt, nine.add(const Duration(minutes: 10)));
    final running = rows.singleWhere((r) => r.id != first.id);
    expect(running.endedAt, isNull);
    expect(running.kind, 'break');
    expect(running.taskId, isNull, reason: 'a break is on no task');
  });

  test('a session ended after its length counts only its length', () async {
    final scope = await app.read(appScopeProvider.future);
    final session = await scope.focus.start(workspaceId: scope.workspace.id, plannedMin: 25, now: nine);
    await scope.focus.end(session, at: nine.add(const Duration(hours: 3)));
    final row = await db.select(db.focusSessions).getSingle();
    expect(row.endedAt, nine.add(const Duration(minutes: 25)));
  });

  test('sessions are written to sync, as every change is', () async {
    final scope = await app.read(appScopeProvider.future);
    await scope.focus.start(workspaceId: scope.workspace.id, plannedMin: 25, now: nine);
    final queued = await db.select(db.outbox).get();
    expect(queued.where((q) => q.targetTable == 'focus_sessions'), isNotEmpty);
  });
}
