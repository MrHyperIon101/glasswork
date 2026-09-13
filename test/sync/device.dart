import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/sync/hlc.dart';
import 'package:glasswork/sync/sync_engine.dart';
import 'package:glasswork/sync/sync_transport.dart';
import 'package:glasswork/sync/sync_writer.dart';
import 'package:glasswork/sync/synced_tables.dart';

/// One simulated device: its own database, its own clock identity, its own engine.
///
/// [now] is shared with the server and every other device in a test, so a test can move
/// time forward by days and every clock agrees about when it is.
class Device {
  Device(this.name, SyncTransport server, {required int Function() now}) {
    // Two devices means two databases in one isolate, deliberately. Each has its own
    // in-memory executor, so the race drift warns about when one is shared cannot occur.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    writer = SyncWriter(db, clientId: name, nowMs: now);
    engine = SyncEngine(
      db: db,
      writer: writer,
      transport: server,
      tables: db.syncedTables,
    );
  }

  final String name;
  late final AppDatabase db;
  late final SyncWriter writer;
  late final SyncEngine engine;

  Future<Task?> task(String id) =>
      (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> dirtyCount() async => (await db.select(db.outbox).get()).length;

  Future<void> rename(String id, String title) =>
      writer.update(db.tasks, id, TasksCompanion(title: Value(title)));

  /// Syncs, failing the test on anything but the failures sync is built to expect.
  Future<SyncReport> sync() async {
    final report = await engine.syncOnce();
    if (report.error case final e? when e is! SyncTransportException &&
        e is! ClockDriftException) {
      // Surface anything unexpected instead of letting an assertion on stale data fail
      // somewhere confusing later.
      fail('sync on $name failed: $e');
    }
    return report;
  }

  Future<void> close() => db.close();
}
