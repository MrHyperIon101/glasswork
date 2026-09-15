import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/data/db/tables.dart';
import 'package:glasswork/data/project_filter.dart';
import 'package:glasswork/data/repository/capacity_repository.dart';
import 'package:glasswork/data/repository/label_repository.dart';
import 'package:glasswork/data/repository/project_repository.dart';
import 'package:glasswork/data/repository/subtask_repository.dart';
import 'package:glasswork/data/repository/task_repository.dart';
import 'package:glasswork/data/repository/workspace_repository.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/state/undo_controller.dart';
import 'package:glasswork/sync/sync_writer.dart';
import 'package:glasswork/theme/tokens.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/screens/capacity_screen.dart';
import 'package:glasswork/ui/screens/list_screen.dart';
import 'package:glasswork/ui/screens/today_screen.dart';
import 'package:glasswork/ui/widgets/block_dialog.dart';
import 'package:glasswork/ui/widgets/content_header.dart';

/// Every screen and sheet, rendered with realistic data on a phone and on a desktop.
///
/// Fails on anything Flutter reports while laying out — overflow above all — and on text
/// squeezed into a sliver, which reports nothing and is exactly how "Good evening" once
/// became a ladder of single letters on a phone.
///
/// Run with `--dart-define=SCREENSHOTS=<directory>` to also save each state as a PNG.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await (FontLoader(AppFont.ui)
          ..addFont(rootBundle.load('fonts/InterVariable.ttf')))
        .load();
    try {
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    } on Object {
      // Icons draw as boxes without it; layout is unaffected.
    }
  });

  for (final device in _devices) {
    for (final state in _states) {
      if (state.drawerOnly && device.size.width >= 900) continue;

      testWidgets(
        '${device.name}: ${state.name}',
        (tester) => _check(tester, device, state),
        variant: TargetPlatformVariant.only(device.platform),
      );
    }
  }

  // The first letter typed replaces the screen with its results, and the header holding
  // the field with a new one. The query has to survive that: on a phone, where search
  // opens from a button, and on a desktop, where the field is always there.
  for (final device in [_devices.first, _devices.last]) {
    testWidgets(
      '${device.name}: search keeps its text when the results replace the screen',
      (tester) => _searchKeepsItsText(tester, device),
      variant: TargetPlatformVariant.only(device.platform),
    );
  }
}

const _screenshots = String.fromEnvironment('SCREENSHOTS');

class _Device {
  const _Device(
    this.name,
    this.size,
    this.pixelRatio,
    this.platform, {
    this.insets = EdgeInsets.zero,
    this.textScale = 1,
  });

  final String name;

  /// Logical size.
  final Size size;
  final double pixelRatio;
  final TargetPlatform platform;

  /// Status bar and gesture bar, in logical pixels.
  final EdgeInsets insets;

  /// The system font size setting, as a multiple of the default.
  final double textScale;
}

const _devices = [
  // A Galaxy S24 at its default display size.
  _Device(
    'phone',
    Size(360, 780),
    3,
    TargetPlatform.android,
    insets: EdgeInsets.only(top: 30, bottom: 20),
  ),
  // The same phone with its font size turned up, which is where fixed heights and
  // one-line rows give out first.
  _Device(
    'phone, larger text',
    Size(360, 780),
    3,
    TargetPlatform.android,
    insets: EdgeInsets.only(top: 30, bottom: 20),
    textScale: 1.3,
  ),
  // Narrow enough for the sidebar to become a drawer, wide enough not to be a phone.
  _Device('narrow window', Size(820, 900), 1, TargetPlatform.linux),
  _Device('desktop', Size(1440, 900), 1, TargetPlatform.linux),
];

class _State {
  const _State(this.name, this.apply, {this.drawerOnly = false});

  final String name;
  final Future<void> Function(WidgetTester tester, ProviderContainer app, _Seeded data) apply;

  /// Only where the sidebar is a drawer.
  final bool drawerOnly;
}

final _states = <_State>[
  _State('today', (tester, app, data) async {}),
  // A lazily built list only builds what is near the screen, so anything further down is
  // never laid out, and never checked, until it is scrolled to.
  _State('today, scrolled to the end', (tester, app, data) async {
    await _scrollToEnd(tester, find.byType(TodayScreen));
  }),
  _State('next 7 days', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const UpcomingDestination());
  }),
  _State('all open work', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const AllDestination());
  }),
  _State('completed', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const DoneDestination());
  }),
  _State('search', (tester, app, data) async {
    app.read(searchQueryProvider.notifier).set('lab');
  }),
  for (final view in BoardView.values)
    _State('project, ${view.name} view', (tester, app, data) async {
      app.read(destinationProvider.notifier).go(ProjectDestination(data.courseworkId));
      app.read(projectViewModeProvider.notifier).set(data.courseworkId, view);
    }),
  _State('project, filtered', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(ProjectDestination(data.courseworkId));
    app.read(projectViewModeProvider.notifier).set(data.courseworkId, BoardView.list);
    app.read(projectFilterProvider.notifier)
      ..setHideCompleted(true)
      ..togglePriority(3);
  }),
  _State('project, choosing filters', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(ProjectDestination(data.courseworkId));
    app.read(projectViewModeProvider.notifier).set(data.courseworkId, BoardView.list);
    app.read(projectFilterProvider.notifier).togglePriority(3);
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.filter_list).first);
  }),
  _State('time budget', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const CapacityDestination());
  }),
  _State('time budget, scrolled to the end', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const CapacityDestination());
    await _settle(tester);
    await _scrollToEnd(tester, find.byType(CapacityScreen));
  }),
  _State('time budget, profile', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const CapacityDestination());
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.text('Shortest usable gap'),
      300,
      scrollable: _pageScrollable(find.byType(CapacityScreen)),
    );
  }),
  _State('time budget, sleep', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const CapacityDestination());
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.text('Set several days'),
      300,
      scrollable: _pageScrollable(find.byType(CapacityScreen)),
    );
  }),
  _State('setting sleep for several days', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const CapacityDestination());
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.text('Set several days'),
      300,
      scrollable: _pageScrollable(find.byType(CapacityScreen)),
    );
    await _settle(tester);
    await tester.tap(find.text('Set several days'));
  }),
  _State('adding a block', (tester, app, data) => _openAddBlock(tester, app)),
  _State('adding a block that clashes', (tester, app, data) async {
    await _openAddBlock(tester, app);
    await _settle(tester);
    final dialog = find.byType(BlockDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)).first,
      'Tutorial',
    );
    await tester.tap(find.descendant(of: dialog, matching: find.text('M')));
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('block-start')),
        matching: find.byType(TextField),
      ),
      '9:30',
    );
  }),
  _State('editing a block', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(const CapacityDestination());
    await _settle(tester);
    // By its days and times: its name is also on the week's timelines.
    final row = find.text('Mon Wed Fri · 09:00–10:30');
    await tester.scrollUntilVisible(
      row,
      300,
      scrollable: _pageScrollable(find.byType(CapacityScreen)),
    );
    await _settle(tester);
    await tester.tap(row);
  }),
  _State('time budget, a block while asleep', (tester, app, data) async {
    final scope = app.read(appScopeProvider).value!;
    await tester.runAsync(
      () => scope.capacity.addCommitment(
        workspaceId: scope.workspace.id,
        scheduleId: data.semesterId,
        title: 'Night study',
        weekdays: {1, 2, 3, 4, 5},
        startMin: 0,
        durationMin: 60,
      ),
    );
    app.read(destinationProvider.notifier).go(const CapacityDestination());
  }),
  _State('new task', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(ProjectDestination(data.courseworkId));
    app.read(composerOpenProvider.notifier).open();
  }),
  _State('a task with a reminder', (tester, app, data) async {
    final scope = app.read(appScopeProvider).value!;
    await tester.runAsync(
      () => scope.tasks.setReminder(
        data.longTaskId,
        DateTime.now().add(const Duration(days: 3, hours: 2)),
      ),
    );
    app.read(openTaskProvider.notifier).open(data.longTaskId);
  }),
  _State('task detail', (tester, app, data) async {
    app.read(openTaskProvider.notifier).open(data.longTaskId);
  }),
  _State('new project', (tester, app, data) async {
    app.read(newProjectOpenProvider.notifier).open();
  }),
  _State('project settings', (tester, app, data) async {
    app.read(destinationProvider.notifier).go(ProjectDestination(data.courseworkId));
    app.read(projectSettingsOpenProvider.notifier).open(data.courseworkId);
  }),
  _State('sync', (tester, app, data) async {
    app.read(syncSheetOpenProvider.notifier).open();
  }),
  _State('undo', (tester, app, data) async {
    app.read(undoProvider.notifier).offer(
      'Deleted "Write the normalisation section of the DBMS project report, '
      'with worked examples"',
      () async {},
    );
  }),
  _State(
    'sidebar',
    (tester, app, data) async => tester.tap(find.byIcon(Icons.menu).first),
    drawerOnly: true,
  ),
];

Future<void> _check(WidgetTester tester, _Device device, _State state) async {
  _useDevice(tester, device);

  final problems = <String>[];
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    final location = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch('$details')?.group(0);
    problems.add('${details.exceptionAsString().split('\n').first}  [${location ?? '?'}]');
  };

  final db = AppDatabase(NativeDatabase.memory());
  final boundary = GlobalKey();
  try {
    final data = (await tester.runAsync(() => _seed(db)))!;

    await tester.pumpWidget(_app(db, boundary: boundary));
    await _settle(tester);

    final app = ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    await state.apply(tester, app, data);
    await _settle(tester);

    problems.addAll(_squeezedText(tester));

    if (_screenshots.isNotEmpty) {
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: device.pixelRatio >= 2 ? 2 : 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final name = '${device.name} - ${state.name}'.replaceAll(RegExp(r'[^\w -]'), '');
        File('$_screenshots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  } finally {
    FlutterError.onError = reportError;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  expect(problems.toSet().toList(), isEmpty);
}

Future<void> _searchKeepsItsText(WidgetTester tester, _Device device) async {
  _useDevice(tester, device);

  final db = AppDatabase(NativeDatabase.memory());
  try {
    await tester.runAsync(() => _seed(db));
    await tester.pumpWidget(_app(db));
    await _settle(tester);

    if (device.size.width < AppBreakpoint.compact) {
      await tester.tap(find.byTooltip('Search'));
      await _settle(tester);
    }
    final field = find.descendant(
      of: find.byType(SearchField),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'lab');
    await _settle(tester);

    expect(find.byType(ListScreen), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'lab');
  } finally {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }
}

void _useDevice(WidgetTester tester, _Device device) {
  tester.view
    ..physicalSize = device.size * device.pixelRatio
    ..devicePixelRatio = device.pixelRatio
    ..padding = FakeViewPadding(
      top: device.insets.top * device.pixelRatio,
      bottom: device.insets.bottom * device.pixelRatio,
    );
  addTearDown(tester.view.reset);

  tester.platformDispatcher.textScaleFactorTestValue = device.textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// The whole app over [db], signed out of sync.
Widget _app(AppDatabase db, {Key? boundary}) => ProviderScope(
  overrides: [
    databaseProvider.overrideWith((ref) => db),
    syncProvider.overrideWith(() => _Held(const SyncSignedOut())),
  ],
  child: RepaintBoundary(key: boundary, child: const GlassworkApp()),
);

/// Opens the add-block dialog from the Time budget screen.
Future<void> _openAddBlock(WidgetTester tester, ProviderContainer app) async {
  app.read(destinationProvider.notifier).go(const CapacityDestination());
  await _settle(tester);
  // The button ends a lazily built list, so it exists only once scrolled to.
  await tester.scrollUntilVisible(
    find.text('Add block'),
    300,
    scrollable: _pageScrollable(find.byType(CapacityScreen)),
  );
  await _settle(tester);
  await tester.tap(find.text('Add block'));
}

/// The first vertical scroll view in [screen]: the page, and not a search field, which
/// scrolls sideways and comes first wherever the header shows one.
Finder _pageScrollable(Finder screen) => find
    .descendant(
      of: screen,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
      ),
    )
    .first;

/// Scrolls [screen]'s page to its end. In steps, because a lazily built list only learns
/// how long it is as it builds what is near its end.
Future<void> _scrollToEnd(WidgetTester tester, Finder screen) async {
  final scrollable = _pageScrollable(screen);
  if (scrollable.evaluate().isEmpty) return;

  for (var i = 0; i < 20; i++) {
    final position = tester.state<ScrollableState>(scrollable).position;
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
  }
}

/// Lets queries, streams and animations finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Paragraphs of several characters laid out narrower than two characters of their own
/// font, and so wrapped into a column.
List<String> _squeezedText(WidgetTester tester) => [
  for (final paragraph in tester.allRenderObjects.whereType<RenderParagraph>())
    if (paragraph.hasSize)
      if (paragraph.text.toPlainText().replaceAll(RegExp(r'\s'), '') case final visible
          when visible.length >= 4)
        if ((paragraph.text.style?.fontSize ?? 14) case final size
            when paragraph.size.width < size * 2 && paragraph.size.height > size * 3)
          '"${paragraph.text.toPlainText()}" squeezed to '
              '${paragraph.size.width.toStringAsFixed(1)}px wide',
];

class _Held extends SyncController {
  _Held(this._state);

  final SyncState _state;

  @override
  SyncState build() => _state;
}

class _Seeded {
  const _Seeded({
    required this.courseworkId,
    required this.longTaskId,
    required this.semesterId,
  });

  final String courseworkId;
  final String longTaskId;
  final String semesterId;
}

/// A student's week: a timetable in force, two projects, tasks overdue, due today, due
/// soon and undated, with labels, fields, steps and long titles.
Future<_Seeded> _seed(AppDatabase db) async {
  final writer = SyncWriter(db, clientId: 'seed');
  final workspace = await WorkspaceRepository(writer).ensureSeeded();
  final ws = workspace.id;
  final capacity = CapacityRepository(writer);
  final projects = ProjectRepository(writer);
  final tasks = TaskRepository(writer);
  final labels = LabelRepository(writer);
  final steps = SubtaskRepository(writer);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  String day(int offset) {
    final d = today.add(Duration(days: offset));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  await capacity.ensureProfile(ws);
  final everyday = await capacity.ensureFallbackSchedule(ws);
  await capacity.addCommitment(
    workspaceId: ws,
    scheduleId: everyday.id,
    title: 'Gym',
    weekdays: {1, 3, 5},
    startMin: 7 * 60,
    durationMin: 60,
  );
  final semester = await capacity.addSchedule(
    workspaceId: ws,
    name: 'Sem V',
    startsOn: today.subtract(const Duration(days: 30)),
    endsOn: today.add(const Duration(days: 60)),
  );
  for (final (title, weekdays, start, length) in [
    ('DBMS lecture', {1, 3, 5}, 9 * 60, 90),
    ('Operating systems lab', {2, 4}, 14 * 60, 180),
    ('Computer networks', {1, 2, 3, 4, 5}, 11 * 60, 60),
  ]) {
    await capacity.addCommitment(
      workspaceId: ws,
      scheduleId: semester.id,
      title: title,
      weekdays: weekdays,
      startMin: start,
      durationMin: length,
    );
  }

  final coursework = await projects.createProject(
    workspaceId: ws,
    name: 'Sem V — DBMS coursework',
    purpose: 'Labs, assignments and the end-of-term project for DBMS',
    icon: '◆',
    colour: 0xFFBF5AF2,
    sections: const ['To do', 'In progress', 'Review', 'Done'],
    fields: const [
      FieldDefSpec(
        name: 'Stage',
        type: FieldType.select,
        options: [
          FieldOption(label: 'Draft', colour: 0xFFFF9F0A),
          FieldOption(label: 'Final', colour: 0xFF30D158),
        ],
      ),
      FieldDefSpec(name: 'Worth %', type: FieldType.number),
    ],
  );
  final portfolio = await projects.createProject(
    workspaceId: ws,
    name: 'Portfolio site rebuild',
    purpose: 'New case studies and a faster homepage',
    icon: '▲',
    colour: 0xFF0A84FF,
  );

  final courseSections = await projects.watchSections(coursework.id).first;
  final portfolioSections = await projects.watchSections(portfolio.id).first;
  final personal = (await WorkspaceRepository(writer).watchLists(ws).first).first;

  final uni = await labels.ensure(workspaceId: ws, name: 'uni');
  final writing = await labels.ensure(workspaceId: ws, name: 'writing');
  final reading = await labels.ensure(workspaceId: ws, name: 'reading');

  Future<Task> add(
    BoardList section,
    String title, {
    int? due,
    int? estimate,
    int priority = 0,
    List<Label> tags = const [],
  }) async {
    final task = await tasks.create(
      listId: section.id,
      workspaceId: ws,
      title: title,
      dueDate: due == null ? null : day(due),
      estimateMin: estimate,
      priority: priority,
    );
    for (final tag in tags) {
      await labels.attach(workspaceId: ws, taskId: task.id, labelId: tag.id);
    }
    return task;
  }

  final report = await add(
    courseSections[0],
    'Write the normalisation section of the DBMS project report, with worked examples',
    due: 0,
    estimate: 120,
    priority: 3,
    tags: [uni, writing],
  );
  final fields = await projects.watchFields(coursework.id).first;
  await projects.setFieldValue(workspaceId: ws, taskId: report.id, fieldId: fields[0].id, value: 'Draft');
  await projects.setFieldValue(workspaceId: ws, taskId: report.id, fieldId: fields[1].id, value: '20');
  for (final (i, title) in ['Outline 1NF to BCNF', 'Worked example: library system', 'Proofread'].indexed) {
    final step = await steps.create(taskId: report.id, workspaceId: ws, title: title);
    if (i == 0) await steps.setDone(step.id, done: true);
  }

  await add(courseSections[1], 'ER diagram for the library system', due: 1, estimate: 60, priority: 2, tags: [uni]);
  await add(courseSections[0], 'Lab 6: triggers and stored procedures', due: -3, estimate: 90, priority: 2, tags: [uni]);
  await add(courseSections[0], 'Read chapter 7 on transactions', due: 5, estimate: 45, tags: [reading]);
  await add(courseSections[0], 'Revise for the mid-semester exam', due: 9, estimate: 900, priority: 3);
  await add(courseSections[2], 'Collect feedback on the report draft');
  final done = await add(courseSections[3], 'Set up the project repository');
  await tasks.setDone(done.id, done: true);

  await add(portfolioSections[0], 'Redesign the hero section', due: 6, estimate: 240, priority: 1);
  await add(portfolioSections[0], 'Fix contact form validation', due: -1, estimate: 30, priority: 3);
  await add(portfolioSections[1], 'Write the case study for the task app', estimate: 120);

  await add(personal, 'Call the bank about the card', due: 0, estimate: 15);
  await add(personal, 'Groceries for the week', due: 1);

  await projects.addView(
    workspaceId: ws,
    boardId: coursework.id,
    name: 'What I owe this week',
    kind: ViewKind.board,
    filter: ProjectFilter.empty.copyWith(hideCompleted: true),
  );

  return _Seeded(
    courseworkId: coursework.id,
    longTaskId: report.id,
    semesterId: semester.id,
  );
}
