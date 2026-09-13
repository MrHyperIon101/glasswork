import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/repository/capacity_repository.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/sync/account_link.dart';
import 'package:glasswork/sync/sync_transport.dart';

import 'device.dart';
import 'fake_server.dart';

/// Linking devices to one account, on two simulated devices sharing one server.
void main() {
  const account = '00000000-0000-4000-8000-00000000000a';
  var nowMs = 0;

  late FakeServer server;
  late Device laptop;
  late Device phone;
  late Directory scratch;

  setUp(() async {
    nowMs = 1757203200000; // 2026-09-06
    server = FakeServer(
      now: () => DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
    );
    laptop = Device('laptop', server, now: () => nowMs);
    phone = Device('phone', server, now: () => nowMs);
    scratch = await Directory.systemTemp.createTemp('account_link_test');
  });

  tearDown(() async {
    await laptop.close();
    await phone.close();
    await scratch.delete(recursive: true);
  });

  String backupOf(Device device) => '${scratch.path}/${device.name}.sqlite';

  AccountLink linkFor(Device device) => AccountLink(
    db: device.db,
    writer: device.writer,
    engine: device.engine,
    transport: server,
    backupPath: () async => backupOf(device),
  );

  /// A device as the app leaves it on first launch.
  Future<String> launch(Device device) async {
    final workspace = await WorkspaceRepository(device.writer).ensureSeeded();
    final capacity = CapacityRepository(device.writer);
    await capacity.ensureProfile(workspace.id);
    await capacity.ensureFallbackSchedule(workspace.id);
    return workspace.id;
  }

  /// The laptop signs in first, to an empty account, and syncs.
  Future<String> laptopClaims() async {
    final workspace = await launch(laptop);
    await linkFor(laptop).claim(account);
    await laptop.sync();
    return workspace;
  }

  Future<void> addTask(Device device, String workspaceId, String title) async {
    final list =
        (await WorkspaceRepository(device.writer).watchLists(workspaceId).first)
            .first;
    await TaskRepository(
      device.writer,
    ).create(listId: list.id, workspaceId: workspaceId, title: title);
  }

  test('the first device claims an empty account', () async {
    final workspace = await launch(laptop);
    final link = linkFor(laptop);

    expect(await link.plan(account), isA<ClaimAccount>());
    await link.claim(account);
    await laptop.sync();

    expect(server.row('workspaces', workspace), isNotNull);
    expect(
      await link.plan(account),
      isA<AlreadyLinked>(),
      reason: 'signing in again later changes nothing',
    );
  });

  test('claiming sends rows written before sync existed', () async {
    final workspace = await launch(laptop);
    final list =
        (await WorkspaceRepository(laptop.writer).watchLists(workspace).first).first;
    await laptop.db.into(laptop.db.tasks).insert(
      TasksCompanion.insert(
        id: 'legacy',
        workspaceId: workspace,
        listId: list.id,
        title: 'From before sync',
        orderKey: 'a0',
      ),
    );

    await linkFor(laptop).claim(account);
    await laptop.sync();

    expect(server.row('tasks', 'legacy')!.values['title'], 'From before sync');
  });

  test("a second device with only its starter project takes the account's work", () async {
    final laptopWorkspace = await laptopClaims();
    final phoneWorkspace = await launch(phone);
    final link = linkFor(phone);

    final plan = await link.plan(account) as AdoptAccount;
    expect(plan.workspaceId, laptopWorkspace);
    expect(plan.needsChoice, isFalse, reason: 'nothing here to lose');

    await link.adopt(account, plan, LinkChoice.replace);

    final db = phone.db;
    expect((await WorkspaceRepository(phone.writer).ensureSeeded()).id, laptopWorkspace);
    expect((await db.select(db.workspaces).get()).map((w) => w.id), [laptopWorkspace]);
    expect(
      await (db.select(db.boards)..where((b) => b.workspaceId.equals(phoneWorkspace))).get(),
      isEmpty,
    );
    expect(await phone.dirtyCount(), 0, reason: "the phone's starter rows are never sent");
    expect(File(backupOf(phone)).existsSync(), isFalse, reason: 'nothing to back up');
    expect(await link.plan(account), isA<AlreadyLinked>());
  });

  test("combining keeps both devices' work, with one profile and one fallback timetable", () async {
    final laptopWorkspace = await laptopClaims();
    final phoneWorkspace = await launch(phone);
    await addTask(phone, phoneWorkspace, 'Written on the phone');
    final phoneFallback = await CapacityRepository(
      phone.writer,
    ).ensureFallbackSchedule(phoneWorkspace);
    await CapacityRepository(phone.writer).addCommitment(
      workspaceId: phoneWorkspace,
      scheduleId: phoneFallback.id,
      title: 'Gym',
      weekdays: {1},
      startMin: 7 * 60,
      durationMin: 60,
    );
    final link = linkFor(phone);

    final plan = await link.plan(account) as AdoptAccount;
    expect(plan.needsChoice, isTrue);
    await link.adopt(account, plan, LinkChoice.combine);
    await phone.sync();
    await laptop.sync();

    for (final device in [laptop, phone]) {
      final db = device.db;
      final tasks = await (db.select(db.tasks)
            ..where((t) => t.workspaceId.equals(laptopWorkspace)))
          .get();
      expect(tasks.map((t) => t.title), contains('Written on the phone'), reason: device.name);
      expect(await db.select(db.capacityProfiles).get(), hasLength(1), reason: device.name);

      final fallbacks =
          await (db.select(db.schedules)..where((s) => s.isFallback.equals(true))).get();
      expect(fallbacks, hasLength(1), reason: device.name);
      final gym =
          await (db.select(db.commitments)..where((c) => c.title.equals('Gym'))).getSingle();
      expect(gym.scheduleId, fallbacks.single.id, reason: device.name);
      expect(gym.workspaceId, laptopWorkspace, reason: device.name);
      expect((await db.select(db.workspaces).get()).map((w) => w.id), [laptopWorkspace]);
    }
  });

  test("replacing removes this device's work, keeping a backup of it first", () async {
    await laptopClaims();
    final phoneWorkspace = await launch(phone);
    await addTask(phone, phoneWorkspace, 'Written on the phone');
    final link = linkFor(phone);

    final plan = await link.plan(account) as AdoptAccount;
    await link.adopt(account, plan, LinkChoice.replace);

    expect(await phone.db.select(phone.db.tasks).get(), isEmpty);
    final backup = AppDatabase(NativeDatabase(File(backupOf(phone))));
    addTearDown(backup.close);
    expect(
      (await backup.select(backup.tasks).get()).map((t) => t.title),
      ['Written on the phone'],
    );
  });

  test('a dropped connection while taking on an account leaves this device as it was', () async {
    await laptopClaims();
    final phoneWorkspace = await launch(phone);
    await addTask(phone, phoneWorkspace, 'Written on the phone');
    final link = linkFor(phone);
    final plan = await link.plan(account) as AdoptAccount;

    server.failNextPull = true;
    await expectLater(
      link.adopt(account, plan, LinkChoice.combine),
      throwsA(isA<SyncTransportException>()),
    );

    expect((await WorkspaceRepository(phone.writer).ensureSeeded()).id, phoneWorkspace);
    expect(await link.linkedAccount(), isNull);
    expect(
      (await phone.db.select(phone.db.tasks).get()).map((t) => t.title),
      ['Written on the phone'],
    );
  });

  test('a device already syncing with one account is not linked to another', () async {
    await launch(phone);
    final link = linkFor(phone);
    await link.claim('first-account');

    expect(await link.plan('second-account'), isA<LinkedElsewhere>());
  });
}
