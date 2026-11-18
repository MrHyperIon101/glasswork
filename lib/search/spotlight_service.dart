import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../data/db/database.dart';
import '../data/db/tables.dart';
import '../data/note_text.dart';
import '../data/preferences.dart';
import '../data/quick_add_parser.dart';
import '../data/recents.dart';
import '../state/providers.dart';
import '../state/quick_add.dart';
import '../ui/format.dart';
import 'spotlight_index.dart';

/// A Spotlight result as it travels: to the GNOME Shell extension over D-Bus, or to the
/// app's own Spotlight. Plain values only, so it crosses a method channel unchanged.
typedef SpotlightResult = Map<String, Object?>;

/// Glasswork's side of Spotlight: what it can find, what a typed line would add, and doing
/// what was chosen.
///
/// The OS Spotlight asks this through the runner's D-Bus service
/// (`linux/runner/spotlight_service.cc`); the phone's Spotlight asks it directly. Either way
/// the same items, the same ranking ([SpotlightIndex]) and the same way a line becomes a task
/// ([addTaskFromLine]).
class SpotlightService {
  SpotlightService(this._ref);

  final Ref _ref;

  /// The places and things to do that Spotlight offers by name.
  static const actions = [
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'new-task',
      title: 'New task',
      subtitle: 'Add something to do',
      keywords: ['add', 'create', 'todo'],
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'new-note',
      title: 'New note',
      subtitle: 'Write something down',
      keywords: ['write', 'jot'],
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'today',
      title: 'Today',
      subtitle: 'Go to Today',
      keywords: ['home', 'dashboard'],
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'upcoming',
      title: 'Next 7 days',
      subtitle: 'Go to the week ahead',
      keywords: ['upcoming', 'week'],
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'all',
      title: 'All open work',
      subtitle: 'Go to everything still to do',
      keywords: ['tasks', 'open'],
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'completed',
      title: 'Completed',
      subtitle: 'Go to what is done',
      keywords: ['done', 'finished'],
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'notes',
      title: 'Notes',
      subtitle: 'Go to your notes',
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'time-budget',
      title: 'Time budget',
      subtitle: 'Your timetable, sleep and free time',
      keywords: ['timetable', 'schedule', 'capacity', 'sleep', 'classes'],
    ),
    SpotlightItem(
      kind: SpotlightKind.action,
      id: 'settings',
      title: 'Glasswork settings',
      subtitle: 'How Glasswork works for you',
      keywords: ['preferences', 'settings'],
    ),
  ];

  /// Everything findable right now, built from the live data.
  ///
  /// Awaited rather than read: a Glasswork the OS Spotlight woke in the background has no
  /// screen watching its data yet, so nothing has loaded until something asks for it.
  Future<List<SpotlightItem>> items(DateTime now) async {
    final projects = {for (final p in await _load<List<Board>>(projectsProvider)) p.id: p};
    final sections = {for (final s in await _load<List<BoardList>>(allSectionsProvider)) s.id: s};
    final tasks = await _load<List<Task>>(allTasksProvider);
    final notes = await _load<List<Note>>(notesProvider);

    String where(Task task) {
      final project = projects[sections[task.listId]?.boardId]?.name;
      final due = Format.due(task, now)?.label;
      return [?project, ?due].join(' · ');
    }

    return [
      for (final task in tasks)
        SpotlightItem(
          kind: SpotlightKind.task,
          id: task.id,
          title: task.title,
          subtitle: where(task),
          done: task.status == TaskStatus.done,
        ),
      for (final note in notes)
        SpotlightItem(
          kind: SpotlightKind.note,
          id: note.id,
          title: NoteText.heading(note),
          subtitle: NoteText.preview(note),
          keywords: [note.bodyMd],
        ),
      for (final project in projects.values)
        SpotlightItem(
          kind: SpotlightKind.project,
          id: project.id,
          title: project.name,
          subtitle: project.purpose ?? 'Project',
        ),
      ...actions,
    ];
  }

  Future<List<SpotlightResult>> query(String text, {int limit = 20, DateTime? now}) async {
    final at = now ?? DateTime.now();
    final hits = SpotlightIndex.search(
      text,
      await items(at),
      recents: await _load<List<Recent>>(recentsProvider),
      now: at,
      limit: limit,
    );
    return [for (final hit in hits) _result(hit.item, score: hit.score)];
  }

  /// What was opened lately, newest first, as results — the empty query's answer. Anything
  /// since deleted is simply not there.
  Future<List<SpotlightResult>> recents({int limit = 8, DateTime? now}) async {
    final byKey = {for (final item in await items(now ?? DateTime.now())) item.key: item};
    return [
      for (final recent in await _load<List<Recent>>(recentsProvider))
        if (byKey['${_kind(recent.kind).name}:${recent.id}'] case final item?) _result(item),
    ].take(limit).toList();
  }

  /// What adding [text] as a task would do: its title, what was read out of it as chips,
  /// and a sentence saying when.
  Future<SpotlightResult> previewAdd(String text, {DateTime? now}) async {
    final parsed = QuickAddParser.parse(
      text,
      now: now ?? DateTime.now(),
      morningMin: await _morning(),
    );
    return {
      'title': parsed.title,
      'chips': [for (final span in parsed.spans) span.label],
      'sentence': parsed.title.isEmpty ? '' : 'Adds “${parsed.title}” to ${await _captureName()}',
    };
  }

  /// Adds [text] as a task, read as the composer reads a line. Returns its id, or null when
  /// nothing was left to call it.
  Future<String?> addTask(String text) async {
    final scope = await _load<AppScope>(appScopeProvider);
    final project = await _captureProject();
    if (project == null) return null;
    final sections = [
      for (final section in await _load<List<BoardList>>(allSectionsProvider))
        if (section.boardId == project.id) section,
    ];
    if (sections.isEmpty) return null;
    final task = await addTaskFromLine(
      scope,
      text,
      sectionId: sections.first.id,
      now: DateTime.now(),
      morningMin: await _morning(),
    );
    return task?.id;
  }

  /// Opens what [key] names. True when it was something Glasswork has, so the window should
  /// come forward to show it.
  Future<bool> activate(String key) async {
    final colon = key.indexOf(':');
    if (colon < 0) return false;
    final kind = key.substring(0, colon);
    final id = key.substring(colon + 1);
    final destinations = _ref.read(destinationProvider.notifier);

    switch (kind) {
      case 'task':
        final tasks = await _load<List<Task>>(allTasksProvider);
        if (!tasks.any((t) => t.id == id)) return false;
        _ref.read(openTaskProvider.notifier).open(id);
      case 'note':
        final note = (await _load<List<Note>>(notesProvider)).where((n) => n.id == id).firstOrNull;
        if (note == null) return false;
        destinations.go(const NotesDestination());
        _ref.read(openNoteProvider.notifier).edit(note);
      case 'project':
        final projects = await _load<List<Board>>(projectsProvider);
        if (!projects.any((p) => p.id == id)) return false;
        destinations.go(ProjectDestination(id));
      case 'action':
        switch (id) {
          case 'new-task':
            _ref.read(composerOpenProvider.notifier).open();
          case 'new-note':
            _ref.read(openNoteProvider.notifier).create();
          case 'today':
            destinations.go(const TodayDestination());
          case 'upcoming':
            destinations.go(const UpcomingDestination());
          case 'all':
            destinations.go(const AllDestination());
          case 'completed':
            destinations.go(const DoneDestination());
          case 'notes':
            destinations.go(const NotesDestination());
          case 'time-budget':
            destinations.go(const CapacityDestination());
          case 'settings':
            destinations.go(const SettingsDestination());
          default:
            return false;
        }
      default:
        return false;
    }
    return true;
  }

  /// What [provider] holds now, or its first value when it has none yet.
  ///
  /// Not `provider.future`: for a stream that answers with the first value it ever had until
  /// the provider rebuilds, which is how a task added a moment ago went missing. And held by
  /// a listener while it waits, since Riverpod pauses a provider nothing listens to.
  Future<T> _load<T>(ProviderListenable<AsyncValue<T>> provider) {
    final done = Completer<T>();
    final subscription = _ref.listen<AsyncValue<T>>(provider, (_, value) {
      if (done.isCompleted) return;
      if (value.hasValue) {
        done.complete(value.requireValue);
      } else if (value.hasError) {
        done.completeError(value.error!, value.stackTrace);
      }
    }, fireImmediately: true);
    return done.future.whenComplete(subscription.close);
  }

  Future<int> _morning() async => (await _load<Preferences>(preferencesProvider)).morningMin;

  /// Where a task added from outside any project goes: the one chosen in Settings, or else
  /// the first — as `captureProjectIdProvider` says for the composer.
  Future<Board?> _captureProject() async {
    final projects = await _load<List<Board>>(projectsProvider);
    final chosen = (await _load<Preferences>(preferencesProvider)).captureProjectId;
    return projects.where((p) => p.id == chosen).firstOrNull ?? projects.firstOrNull;
  }

  Future<String> _captureName() async =>
      (await _captureProject())?.name ?? 'your first project';

  static SpotlightKind _kind(RecentKind kind) => switch (kind) {
    RecentKind.task => SpotlightKind.task,
    RecentKind.note => SpotlightKind.note,
    RecentKind.project => SpotlightKind.project,
  };

  /// A freedesktop icon name the shell has, so the extension can draw it as any other.
  static String icon(SpotlightItem item) => switch (item.kind) {
    SpotlightKind.task => item.done ? 'checkbox-checked-symbolic' : 'checkbox-symbolic',
    SpotlightKind.note => 'document-edit-symbolic',
    SpotlightKind.project || SpotlightKind.area => 'folder-symbolic',
    SpotlightKind.action => switch (item.id) {
      'new-task' => 'list-add-symbolic',
      'new-note' => 'document-new-symbolic',
      'time-budget' => 'x-office-calendar-symbolic',
      'settings' => 'emblem-system-symbolic',
      _ => 'go-next-symbolic',
    },
  };

  static SpotlightResult _result(SpotlightItem item, {double score = 0}) => {
    'id': item.key,
    'kind': item.kind.name,
    'title': item.title,
    'subtitle': item.subtitle,
    'icon': icon(item),
    'score': score,
  };
}

/// Spotlight's data is listened to for as long as the service exists, which is as long as
/// the app runs. Riverpod pauses a provider nothing listens to, and one read after a pause
/// answers with what it held before it — a task opened a moment ago missing from Recents.
final spotlightServiceProvider = Provider<SpotlightService>((ref) {
  void keep(ProviderListenable<Object?> provider) => ref.listen(provider, (_, _) {});
  keep(projectsProvider);
  keep(allSectionsProvider);
  keep(allTasksProvider);
  keep(notesProvider);
  keep(recentsProvider);
  keep(preferencesProvider);
  return SpotlightService(ref);
});
