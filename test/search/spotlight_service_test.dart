import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/search/spotlight_service.dart';
import 'package:glasswork/state/providers.dart';

/// What the OS Spotlight is told, and what it can do, against a real database.
void main() {
  late AppDatabase db;
  late ProviderContainer app;
  late SpotlightService spotlight;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    app = ProviderContainer(overrides: [databaseProvider.overrideWith((ref) => db)]);
    // Listened to as the shell does: read alone, the service and its data would be paused.
    spotlight = app.listen(spotlightServiceProvider, (_, _) {}).read();
  });
  tearDown(() async {
    app.dispose();
    await db.close();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 120));

  test('a line added from Spotlight is a task in the capture project, found straight after', () async {
    final id = await spotlight.addTask('submit dbms lab tmrw 5pm ~2h #uni');
    expect(id, isNotNull);
    await settle();

    final task = (await db.select(db.tasks).get()).single;
    expect(task.title, 'submit dbms lab');
    expect(task.estimateMin, 120);
    final firstSection = (await db.select(db.lists).get()).first;
    expect(task.listId, firstSection.id, reason: 'the first project, its first section');

    final found = await spotlight.query('dbms');
    expect(found.single['id'], 'task:$id');
    expect(found.single['subtitle'], startsWith('Personal · Tomorrow'));
  });

  test('the preview shows what a line will be read as, before anything is added', () async {
    final preview = await spotlight.previewAdd('read chapter 7 fri !high');
    expect(preview['title'], 'read chapter 7');
    expect(preview['chips'], containsAll(['high']));
    expect(preview['sentence'], startsWith('Adds “read chapter 7” to Personal. '));
    expect(preview['sentence'], anyOf(contains('Fits'), contains('Tight'), contains("Won't fit")),
        reason: 'and whether it fits before Friday');
    expect(await db.select(db.tasks).get(), isEmpty);
  });

  test('@ sends a task to the project it names, in the preview and when added', () async {
    final scope = await app.read(appScopeProvider.future);
    final glasswork = await scope.projects.createProject(
      workspaceId: scope.workspace.id,
      name: 'Glasswork',
      sections: const ['Backlog', 'Shipped'],
    );
    await settle();

    final preview = await spotlight.previewAdd('fix the bug @glass');
    expect(preview['title'], 'fix the bug');
    expect(preview['sentence'], 'Adds “fix the bug” to Glasswork');

    final id = await spotlight.addTask('fix the bug @glass');
    await settle();
    final task = (await db.select(db.tasks).get()).singleWhere((t) => t.id == id);
    final backlog = (await db.select(db.lists).get())
        .singleWhere((l) => l.boardId == glasswork.id && l.name == 'Backlog');
    expect(task.listId, backlog.id, reason: 'its first section');
  });

  test('opening something puts it in Recents, and Recents answers the empty query', () async {
    final id = await spotlight.addTask('Lab report');
    await settle();
    expect(await spotlight.recents(), isEmpty);

    expect(await spotlight.activate('task:$id'), isTrue);
    await settle();
    expect([for (final r in await spotlight.recents()) r['id']], ['task:$id']);
    expect(app.read(openTaskProvider), id, reason: 'and its sheet is open');
  });

  test('only something that exists can be opened', () async {
    expect(await spotlight.activate('task:no-such-task'), isFalse);
    expect(await spotlight.activate('project:no-such-project'), isFalse);
    expect(await spotlight.activate('nonsense'), isFalse);
    expect(app.read(openTaskProvider), isNull);
  });

  test('Actions lists everything Glasswork can do, and each of them does something', () async {
    final listed = spotlight.actionResults();
    final ids = [for (final r in listed) r['id']];
    // The extension gives these their quick keys by id (lib/quick_keys.js): they must not move.
    expect(ids, containsAll(['action:new-task', 'action:new-note', 'action:today', 'action:upcoming',
      'action:time-budget']));
    for (final result in listed) {
      expect(result['kind'], 'action');
      expect(result['icon'], isNotEmpty, reason: '${result['id']} is drawn with an icon');
      expect(await spotlight.activate(result['id']! as String), isTrue, reason: '${result['id']}');
    }
    // What opening them started — a new note, the places loading — finishes before the
    // database closes.
    await settle();
  });

  test('actions take you where they say', () async {
    expect(await spotlight.activate('action:time-budget'), isTrue);
    expect(app.read(destinationProvider), isA<CapacityDestination>());
    expect(await spotlight.activate('action:new-task'), isTrue);
    expect(app.read(composerOpenProvider), isTrue);
  });
}
