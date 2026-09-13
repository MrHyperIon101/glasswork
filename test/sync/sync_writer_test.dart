import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/hlc.dart';
import 'package:glasswork/sync/sync_writer.dart';

void main() {
  late AppDatabase db;
  late String workspaceId;
  late String listId;
  var now = 1757000000000;

  SyncWriter writer({String client = 'device-a'}) =>
      SyncWriter(db, clientId: client, nowMs: () => now);

  Future<Map<String, String>> versionsOf(String id) async {
    final row = await db
        .customSelect(
          'SELECT field_versions FROM tasks WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingle();
    return SyncWriter.decodeVersions(row.data['field_versions'] as String?);
  }

  Future<List<OutboxData>> outbox() => db.select(db.outbox).get();

  Future<String> seedTask(SyncWriter w, {String id = 't1'}) async {
    await w.insert(
      db.tasks,
      TasksCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        listId: listId,
        title: 'Lab report',
        orderKey: 'a0',
      ),
    );
    return id;
  }

  setUp(() async {
    now = 1757000000000;
    db = AppDatabase(NativeDatabase.memory());
    final workspaces = WorkspaceRepository(writer());
    workspaceId = (await workspaces.ensureSeeded()).id;
    listId = (await workspaces.watchLists(workspaceId).first).first.id;
    // Seeding went through a writer too. Every test starts with nothing queued.
    await db.delete(db.outbox).go();
  });

  tearDown(() => db.close());

  group('update', () {
    test('stamps exactly the fields that changed', () async {
      final w = writer();
      final id = await seedTask(w);
      await db.delete(db.outbox).go();

      now += 1000;
      await w.update(db.tasks, id, const TasksCompanion(title: Value('Renamed')));

      final versions = await versionsOf(id);
      final titleClock = Hlc.decode(versions['title']!);
      final orderClock = Hlc.decode(versions['order_key']!);

      expect(titleClock > orderClock, isTrue,
          reason: 'the rename is newer than the insert');
    });

    test('marks exactly the changed fields dirty', () async {
      final w = writer();
      final id = await seedTask(w);
      await db.delete(db.outbox).go();

      await w.update(db.tasks, id, const TasksCompanion(title: Value('Renamed')));

      final entries = await outbox();
      expect(entries, hasLength(1));
      expect(entries.single.targetTable, 'tasks');
      expect(entries.single.rowId, id);
      expect(SyncWriter.decodeFieldNames(entries.single.changedFields), {'title'});
    });

    test('fields not in the patch keep the clock they already had', () async {
      final w = writer();
      final id = await seedTask(w);
      final before = await versionsOf(id);

      now += 5000;
      await w.update(db.tasks, id, const TasksCompanion(priority: Value(3)));

      final after = await versionsOf(id);
      expect(after['title'], before['title']);
      expect(after['priority'], isNot(before['priority']));
    });

    test('setting a field back to null is recorded as a change', () async {
      // Restoring a deleted task clears deleted_at. Dropping that as "absent" would mean
      // the restore never syncs and the task stays deleted on every other device.
      final w = writer();
      final id = await seedTask(w);

      await w.update(db.tasks, id, TasksCompanion(deletedAt: Value(DateTime.now())));
      await db.delete(db.outbox).go();

      await w.update(db.tasks, id, const TasksCompanion(deletedAt: Value(null)));

      expect(
        SyncWriter.decodeFieldNames((await outbox()).single.changedFields),
        {'deleted_at'},
      );
    });

    test('bookkeeping columns are never recorded, and cannot be spoofed', () async {
      final w = writer();
      final id = await seedTask(w);
      await db.delete(db.outbox).go();

      await w.update(
        db.tasks,
        id,
        TasksCompanion(
          title: const Value('Renamed'),
          clientId: const Value('someone-else'),
          fieldVersions: const Value('{"title":"forged"}'),
          updatedAt: Value(DateTime(2000)),
        ),
      );

      expect(
        SyncWriter.decodeFieldNames((await outbox()).single.changedFields),
        {'title'},
      );
      final row = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
      expect(row.clientId, 'device-a');
      expect((await versionsOf(id))['title'], isNot('forged'));
    });

    test('a patch that changes nothing syncable leaves the outbox alone', () async {
      final w = writer();
      final id = await seedTask(w);
      await db.delete(db.outbox).go();

      await w.update(db.tasks, id, const TasksCompanion(clientId: Value('x')));

      expect(await outbox(), isEmpty);
    });
  });

  group('updateWhere', () {
    test('stamps and queues every matching row, and no other', () async {
      final w = writer();
      for (final id in ['t1', 't2', 'other']) {
        await seedTask(w, id: id);
      }
      await db.delete(db.outbox).go();

      final written = await w.updateWhere(
        db.tasks,
        (t) => t.id.isIn(['t1', 't2']),
        const TasksCompanion(priority: Value(3)),
      );

      expect(written, unorderedEquals(['t1', 't2']));
      final entries = await outbox();
      expect({for (final e in entries) e.rowId}, {'t1', 't2'});
      for (final e in entries) {
        expect(SyncWriter.decodeFieldNames(e.changedFields), {'priority'});
      }
      expect(
        (await versionsOf('other'))['priority'],
        isNot((await versionsOf('t1'))['priority']),
        reason: 'the row outside the filter keeps its clock',
      );
    });

    test('stamps rows whose filter column the patch rewrites', () async {
      // Deleting a section moves its tasks by rewriting list_id — the very column the
      // filter reads. Matching after the write would find nothing, and the move would
      // never sync.
      final w = writer();
      final id = await seedTask(w);
      final elsewhere = (await db.select(db.lists).get())
          .firstWhere((l) => l.id != listId)
          .id;
      await db.delete(db.outbox).go();

      final written = await w.updateWhere(
        db.tasks,
        (t) => t.listId.equals(listId),
        TasksCompanion(listId: Value(elsewhere)),
      );

      expect(written, [id]);
      expect(
        SyncWriter.decodeFieldNames((await outbox()).single.changedFields),
        {'list_id'},
      );
    });

    test('matching nothing writes nothing and spends no clock', () async {
      final w = writer();
      await seedTask(w);
      await db.delete(db.outbox).go();
      final before = await w.clock;

      final written = await w.updateWhere(
        db.tasks,
        (t) => t.id.equals('missing'),
        const TasksCompanion(priority: Value(1)),
      );

      expect(written, isEmpty);
      expect(await outbox(), isEmpty);
      expect(await w.clock, before);
    });
  });

  group('outbox coalescing', () {
    /// Renaming fires on every keystroke. That must not become an outbox row per key.
    test('repeated edits to one row share a single entry', () async {
      final w = writer();
      final id = await seedTask(w);
      await db.delete(db.outbox).go();

      for (final title in ['L', 'La', 'Lab', 'Lab r', 'Lab report']) {
        now += 50;
        await w.update(db.tasks, id, TasksCompanion(title: Value(title)));
      }

      expect(await outbox(), hasLength(1));
    });

    test('the entry holds the union of fields and the newest clock', () async {
      final w = writer();
      final id = await seedTask(w);
      await db.delete(db.outbox).go();

      await w.update(db.tasks, id, const TasksCompanion(title: Value('a')));
      now += 1000;
      await w.update(db.tasks, id, const TasksCompanion(priority: Value(2)));

      final entry = (await outbox()).single;
      expect(SyncWriter.decodeFieldNames(entry.changedFields), {'title', 'priority'});
      expect(entry.hlc, (await w.clock).encode());
    });

    test('different rows get different entries', () async {
      final w = writer();
      await seedTask(w, id: 't1');
      await seedTask(w, id: 't2');

      expect(await outbox(), hasLength(2));
    });
  });

  group('insert', () {
    test('marks every column dirty, including SQLite defaults', () async {
      // status and priority were never set by the companion, but they are part of the
      // row. A server applying its own defaults instead would quietly disagree.
      final w = writer();
      await seedTask(w);

      final fields = SyncWriter.decodeFieldNames((await outbox()).single.changedFields);
      expect(fields, containsAll(['title', 'status', 'priority', 'created_at']));
      expect(fields.intersection(SyncWriter.bookkeeping), isEmpty);
    });

    test('versions every column it marks', () async {
      final w = writer();
      final id = await seedTask(w);

      final fields = SyncWriter.decodeFieldNames((await outbox()).single.changedFields);
      expect((await versionsOf(id)).keys.toSet(), fields);
    });

    test('refuses a row without an explicit id', () async {
      // Rejected before any SQL runs: an outbox entry with no row id could never be
      // pushed, so failing loudly beats queuing something that silently never syncs.
      expect(
        () => writer().insert(
          db.workspaces,
          const WorkspacesCompanion(name: Value('No id')),
        ),
        throwsArgumentError,
      );
    });

    test('returns the row as stored, bookkeeping included', () async {
      final w = writer();
      final row = await w.insert(
        db.tasks,
        TasksCompanion.insert(
          id: 'fresh',
          workspaceId: workspaceId,
          listId: listId,
          title: 'x',
          orderKey: 'a0',
        ),
      );
      expect(row.clientId, 'device-a');
      expect(row.fieldVersions, isNot('{}'));
    });
  });

  group('the clock', () {
    test('stays monotonic when the wall clock goes backwards', () async {
      final w = writer();
      final id = await seedTask(w);

      now = 9000000000000;
      await w.update(db.tasks, id, const TasksCompanion(title: Value('ahead')));
      final ahead = await w.clock;

      now = 1000;
      await w.update(db.tasks, id, const TasksCompanion(title: Value('behind')));

      expect(await w.clock > ahead, isTrue);
    });

    test('survives a restart', () async {
      final first = writer();
      final id = await seedTask(first);
      now = 9000000000000;
      await first.update(db.tasks, id, const TasksCompanion(title: Value('before')));
      final beforeRestart = await first.clock;

      // A new writer over the same database, with the wall clock now earlier.
      now = 1000;
      final second = writer();
      await second.update(db.tasks, id, const TasksCompanion(title: Value('after')));

      expect(await second.clock > beforeRestart, isTrue);
    });

    test('a stored clock from another device is not continued', () async {
      await writer(client: 'device-a').update(db.tasks, await seedTask(writer()),
          const TasksCompanion(title: Value('a')));

      final other = writer(client: 'device-b');
      expect((await other.clock).nodeId, 'device-b');
    });

    test('observing a remote clock moves every later write past it', () async {
      final w = writer();
      final id = await seedTask(w);

      final remote = Hlc(now + 60000, 7, 'device-b');
      await w.observe(remote);
      await w.update(db.tasks, id, const TasksCompanion(title: Value('after')));

      expect(Hlc.decode((await versionsOf(id))['title']!) > remote, isTrue);
    });

    test('loading it outside a transaction cannot deadlock one already open', () async {
      // A read issued outside a transaction queues behind any open one. If the open
      // transaction then waited on that same read, neither could ever finish, and every
      // write in the app would hang without an error.
      final id = await seedTask(writer());
      final fresh = writer(); // has not loaded its clock yet

      final inside = Completer<void>();
      final release = Completer<void>();
      final transaction = db.transaction(() async {
        await db.customSelect('SELECT 1').get(); // the transaction now holds the lock
        inside.complete();
        await release.future;
        await fresh.update(db.tasks, id, const TasksCompanion(title: Value('x')));
      });

      await inside.future;
      final outside = fresh.clock; // queued behind the open transaction
      release.complete();

      await transaction.timeout(const Duration(seconds: 5));
      expect((await outside).nodeId, 'device-a');
    });
  });

  test('refuses a local-only table', () {
    expect(
      () => writer().update(
        db.outbox,
        'anything',
        const OutboxCompanion(hlc: Value('x')),
      ),
      throwsArgumentError,
    );
  });
}
