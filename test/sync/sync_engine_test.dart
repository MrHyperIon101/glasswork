import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/sync/hlc.dart';
import 'package:glasswork/sync/sync_transport.dart';
import 'package:glasswork/sync/sync_writer.dart';

import 'device.dart';
import 'fake_server.dart';

/// Shared wall clock in milliseconds. Every device and the server read this, so a test
/// can move "time" forward by days and every clock agrees about when it is.
var nowMs = 0;

const day = 86400000;
const sunday = 1757203200000; // 2026-09-06
final monday = sunday + day;
final tuesday = sunday + 2 * day;
final wednesday = sunday + 3 * day;

Future<void> seed(Device d, {String taskTitle = 'Lab report'}) async {
  final w = d.writer;
  await w.insert(d.db.workspaces, WorkspacesCompanion.insert(id: 'ws', name: 'Personal'));
  await w.insert(
    d.db.boards,
    BoardsCompanion.insert(id: 'b', workspaceId: 'ws', name: 'Sem V', orderKey: 'a0'),
  );
  await w.insert(
    d.db.lists,
    ListsCompanion.insert(
      id: 'l',
      workspaceId: 'ws',
      boardId: 'b',
      name: 'To do',
      orderKey: 'a0',
    ),
  );
  await w.insert(
    d.db.tasks,
    TasksCompanion.insert(
      id: 't',
      workspaceId: 'ws',
      listId: 'l',
      title: taskTitle,
      orderKey: 'a0',
    ),
  );
}

void main() {
  late FakeServer server;
  late Device laptop;
  late Device phone;

  setUp(() {
    nowMs = sunday;
    server = FakeServer(now: () => DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true));
    laptop = Device('laptop', server, now: () => nowMs);
    phone = Device('phone', server, now: () => nowMs);
  });

  tearDown(() async {
    await laptop.close();
    await phone.close();
  });

  group('push', () {
    test('sends dirty rows and clears the outbox', () async {
      await seed(laptop);
      expect(await laptop.dirtyCount(), 4);

      final report = await laptop.sync();

      expect(report.pushed, 4);
      expect(await laptop.dirtyCount(), 0);
      expect(server.row('tasks', 't')!.values['title'], 'Lab report');
    });

    test('a failed push loses nothing', () async {
      await seed(laptop);
      server.failNextPush = true;

      final report = await laptop.engine.syncOnce();

      expect(report.ok, isFalse);
      expect(report.error, isA<SyncTransportException>());
      expect(await laptop.dirtyCount(), 4, reason: 'still queued to go out');
      expect((await laptop.task('t'))!.title, 'Lab report', reason: 'local data intact');

      // And it goes out on the next attempt.
      await laptop.sync();
      expect(server.row('tasks', 't'), isNotNull);
    });

    test('an edit made while a push is in flight is not lost', () async {
      await seed(laptop);
      await laptop.sync();

      await laptop.rename('t', 'first');
      server.duringPush = () => laptop.rename('t', 'typed during the push');

      await laptop.sync();

      expect(await laptop.dirtyCount(), 1, reason: 'the late edit is still queued');
      await laptop.sync();
      expect(server.row('tasks', 't')!.values['title'], 'typed during the push');
    });
  });

  group('pull', () {
    test('an empty device receives everything, parents before children', () async {
      await seed(laptop);
      await laptop.sync();

      final report = await phone.sync();

      expect(report.pulled, 4);
      expect((await phone.task('t'))!.title, 'Lab report');
    });

    test('pulling back what this device just pushed changes nothing', () async {
      await seed(laptop);
      await laptop.sync();

      final report = await laptop.sync();

      expect(report.pulled, 0, reason: 'no echo');
      expect(await laptop.dirtyCount(), 0, reason: 'pulled rows are not re-marked dirty');
    });

    test('pulled rows keep the remote clocks, not fresh local ones', () async {
      // Re-stamping on apply would make every pulled row look newly edited here, and
      // it would win conflicts it has no right to win.
      await seed(laptop);
      await laptop.sync();
      await phone.sync();

      final remote = server.row('tasks', 't')!.versions['title'];
      final local = SyncWriter.decodeVersions((await phone.task('t'))!.fieldVersions);
      expect(local['title'], remote);
    });

    test('carries the client id, so order-key tiebreaks agree across devices', () async {
      await seed(laptop);
      await laptop.sync();
      await phone.sync();

      expect((await phone.task('t'))!.clientId, 'laptop');
    });
  });

  /// The scenario docs/architecture.md is written around, end to end, on two real databases.
  test("Monday's offline edit does not overwrite Tuesday's when it syncs on Wednesday", () async {
    await seed(laptop, taskTitle: 'original');
    await laptop.sync();
    await phone.sync();

    // Monday: the phone renames the task, offline. No sync.
    nowMs = monday;
    await phone.rename('t', 'Monday (phone, offline)');

    // Tuesday: the laptop renames it too, and syncs.
    nowMs = tuesday;
    await laptop.rename('t', 'Tuesday (laptop)');
    await laptop.sync();

    // Wednesday: the phone comes back online. Its edit arrives last — and must lose.
    nowMs = wednesday;
    await phone.sync();
    await laptop.sync();

    // The stale edit really was sent and refused — not merely never sent. Without this
    // the test passes just as well if the phone's push had silently dropped the title.
    expect(server.rejected, contains('tasks.t.title'));

    expect(server.row('tasks', 't')!.values['title'], 'Tuesday (laptop)');
    expect((await phone.task('t'))!.title, 'Tuesday (laptop)');
    expect((await laptop.task('t'))!.title, 'Tuesday (laptop)');
  });

  test('edits to different fields on two devices both survive', () async {
    await seed(laptop);
    await laptop.sync();
    await phone.sync();

    nowMs = monday;
    await phone.rename('t', 'DBMS lab report');
    await laptop.writer.update(
      laptop.db.tasks,
      't',
      const TasksCompanion(priority: Value(3)),
    );

    await laptop.sync();
    await phone.sync();
    await laptop.sync();

    for (final device in [phone, laptop]) {
      final t = (await device.task('t'))!;
      expect(t.title, 'DBMS lab report', reason: device.name);
      expect(t.priority, 3, reason: device.name);
    }
  });

  test('a delete on one device and a rename on the other both survive', () async {
    await seed(laptop);
    await laptop.sync();
    await phone.sync();

    nowMs = monday;
    await laptop.writer.update(
      laptop.db.tasks,
      't',
      TasksCompanion(deletedAt: Value(DateTime.fromMillisecondsSinceEpoch(nowMs))),
    );
    nowMs += 1000;
    await phone.rename('t', 'renamed while deleted elsewhere');

    await laptop.sync();
    await phone.sync();
    await laptop.sync();

    for (final device in [phone, laptop]) {
      final t = (await device.task('t'))!;
      expect(t.deletedAt, isNotNull, reason: '${device.name}: still deleted');
      expect(t.title, 'renamed while deleted elsewhere',
          reason: '${device.name}: the rename is not lost, so undo shows it');
    }
  });

  group('the delta-pull overlap', () {
    test('catches a row committed with a time behind the cursor', () async {
      await seed(laptop, taskTitle: 'original');
      await laptop.sync();
      await phone.sync();
      final phoneCursor = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);

      nowMs += 10 * 60000;
      await laptop.rename('t', 'from a slow transaction');
      await laptop.sync();

      // It started before the phone's last pull but committed after, so it carries an
      // updated_at the phone's cursor has already moved past.
      server.backdate('tasks', 't', phoneCursor.subtract(const Duration(seconds: 30)));

      await phone.sync();
      expect((await phone.task('t'))!.title, 'from a slow transaction');
    });

    test('documents its limit: beyond the window, a row is missed', () async {
      // Not a desirable behaviour — the stated assumption. If transactions ever run
      // longer than SyncEngine.overlap, this is what breaks.
      await seed(laptop, taskTitle: 'original');
      await laptop.sync();
      await phone.sync();
      final phoneCursor = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);

      nowMs += 10 * 60000;
      await laptop.rename('t', 'too far back');
      await laptop.sync();
      server.backdate('tasks', 't', phoneCursor.subtract(const Duration(minutes: 5)));

      await phone.sync();
      expect((await phone.task('t'))!.title, 'original');
    });
  });

  test('a child arriving before its parent rolls back whole, then self-heals', () async {
    await seed(laptop);
    await laptop.sync();

    // Stage it: the list has not reached the server yet, but its task has.
    final list = server.remove('lists', 'l');

    final failed = await phone.engine.syncOnce();
    expect(failed.ok, isFalse, reason: 'foreign key fails at commit');
    // And for that reason specifically. Otherwise any exception at all would satisfy
    // this test — including a real bug in applying rows.
    expect('${failed.error}', contains('FOREIGN KEY'));
    expect(await phone.task('t'), isNull, reason: 'nothing half-applied');
    expect(
      await (phone.db.select(phone.db.workspaces)).get(),
      isEmpty,
      reason: 'the whole pull rolled back, parents included',
    );

    // The list arrives.
    nowMs += 1000;
    server.put('lists', 'l', list.withUpdatedAt(
      DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
    ));

    final healed = await phone.sync();
    expect(healed.ok, isTrue);
    expect((await phone.task('t'))!.title, 'Lab report');
  });

  test('a remote clock from a device set to the wrong year stops the sync', () async {
    await seed(laptop);
    await laptop.sync();

    // Poison one field's clock as a phone with a wildly wrong date would.
    final row = server.row('tasks', 't')!;
    final poisoned = Hlc(nowMs + 400 * day, 0, 'broken-phone').encode();
    server.put(
      'tasks',
      't',
      ServerRow(
        values: {...row.values, 'title': 'from the future'},
        versions: {...row.versions, 'title': poisoned},
        clientId: 'broken-phone',
        updatedAt: row.updatedAt,
      ),
    );

    final report = await phone.engine.syncOnce();

    expect(report.clockDrift, isTrue);
    expect(await phone.task('t'), isNull,
        reason: 'refused rather than applied; nothing from that pull committed');
  });

  test('rows written before sync existed reach the other device once stamped', () async {
    // Direct inserts, as every write was before sync: no clocks, no outbox entries.
    final db = laptop.db;
    await db.into(db.workspaces).insert(WorkspacesCompanion.insert(id: 'ws', name: 'Personal'));
    await db.into(db.boards).insert(
      BoardsCompanion.insert(id: 'b', workspaceId: 'ws', name: 'Sem V', orderKey: 'a0'),
    );
    await db.into(db.lists).insert(
      ListsCompanion.insert(id: 'l', workspaceId: 'ws', boardId: 'b', name: 'To do', orderKey: 'a0'),
    );
    await db.into(db.tasks).insert(
      TasksCompanion.insert(
        id: 't',
        workspaceId: 'ws',
        listId: 'l',
        title: 'From before sync',
        orderKey: 'a0',
      ),
    );

    expect((await laptop.sync()).pushed, 0, reason: 'nothing queued, so nothing goes');

    final tables = <TableInfo<Table, Object?>>[db.workspaces, db.boards, db.lists, db.tasks];
    expect(await laptop.writer.stampUnversioned(tables), 4);
    await laptop.sync();
    await phone.sync();

    expect((await phone.task('t'))!.title, 'From before sync');
  });
}
