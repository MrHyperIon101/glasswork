import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/state/providers.dart';

/// Launch, without the window: the same provider the app awaits at its root.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<AppScope> boot() {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWith((ref) => db)],
    );
    addTearDown(container.dispose);
    return container.read(appScopeProvider.future);
  }

  test('first launch creates the workspace, its profile and the fallback timetable', () async {
    final scope = await boot();

    expect(scope.workspace.name, 'Personal');
    expect(await scope.capacity.watchProfile(scope.workspace.id).first, isNotNull);
    expect(
      (await scope.capacity.watchSchedules(scope.workspace.id).first).where(
        (s) => s.isFallback,
      ),
      hasLength(1),
    );
  });

  test('a relaunch finds everything and queues nothing', () async {
    // A launch that queued writes would push changes nobody made, on every start.
    final first = await boot();
    final queued = (await db.select(db.outbox).get()).length;

    final second = await boot();

    expect(second.workspace.id, first.workspace.id);
    expect(second.writer.clientId, first.writer.clientId);
    expect(await db.select(db.outbox).get(), hasLength(queued));
  });

  test('a database from before sync opens without duplicating anything', () async {
    // Earlier versions gave the profile and the fallback random ids, where derived ones
    // are now expected. Launch has to find those rather than make a second of each.
    await db
        .into(db.workspaces)
        .insert(WorkspacesCompanion.insert(id: 'ws', name: 'Personal'));
    await db
        .into(db.capacityProfiles)
        .insert(CapacityProfilesCompanion.insert(id: 'old-profile', workspaceId: 'ws'));
    await db
        .into(db.schedules)
        .insert(
          SchedulesCompanion.insert(
            id: 'old-fallback',
            workspaceId: 'ws',
            name: 'Everyday',
            isFallback: const Value(true),
            orderKey: 'a0',
          ),
        );

    final scope = await boot();

    expect(scope.workspace.id, 'ws');
    expect(await db.select(db.capacityProfiles).get(), hasLength(1));
    expect(await db.select(db.schedules).get(), hasLength(1));
    expect(await db.select(db.outbox).get(), isEmpty, reason: 'nothing needed writing');
  });
}
