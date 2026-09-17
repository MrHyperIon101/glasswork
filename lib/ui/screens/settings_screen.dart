import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app_config.dart';
import '../../desktop/desktop_shell.dart';
import '../../data/db/database.dart';
import '../../data/preferences.dart';
import '../../data/repository/capacity_repository.dart';
import '../../state/providers.dart';
import '../../state/reminders_controller.dart';
import '../../state/sync_controller.dart';
import '../../state/sync_summary.dart';
import '../../sync/sync_auth.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../layout.dart';
import '../project_icon.dart';
import '../motion.dart';
import '../settings_text.dart';
import '../surface.dart';
import '../time_entry.dart';
import '../widgets/content_header.dart';
import '../widgets/field_controls.dart';
import '../widgets/sync_status.dart';
import '../widgets/value_stepper.dart';

/// Everything that can be set, in one place, each setting saying what it does.
///
/// Sleep, meals and focus stay on Time budget, beside the figures they change; this screen
/// sums them up and leads there, rather than keeping a second copy of them apart from what
/// they explain.
///
/// On a wide window the groups sit side by side in columns, rather than one narrow column
/// with the rest of the window empty beside it.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({this.onMenu, super.key});

  final VoidCallback? onMenu;

  /// Room for two columns of groups, and for three.
  static const _twoColumnsFrom = 900.0;
  static const _threeColumnsFrom = 1400.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = AppLayout.compact(context);
    final gutter = AppLayout.gutter(context);
    // A window and its keys: neither on a phone.
    final desktop = !AppLayout.touch;

    const account = _Account();
    const reminders = _Reminders();
    const newTasks = _NewTasks();
    const timeBudget = _TimeBudget();
    const about = _About();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpace.sm : AppSpace.xl,
        gutter,
        compact ? 0 : AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentHeader(
            title: 'Settings',
            subtitle: 'How Glasswork works for you',
            onMenu: onMenu,
            showNewTask: false,
          ),
          SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                // Groups placed so the columns come out about as tall as each other.
                final columns = width >= _threeColumnsFrom
                    ? [
                        [account, newTasks, if (desktop) const _Desktop()],
                        [reminders],
                        [timeBudget, if (desktop) const _Shortcuts(), about],
                      ]
                    : width >= _twoColumnsFrom
                    ? [
                        [account, reminders, if (desktop) const _Desktop()],
                        [newTasks, timeBudget, if (desktop) const _Shortcuts(), about],
                      ]
                    : [
                        [
                          account,
                          reminders,
                          newTasks,
                          timeBudget,
                          if (desktop) ...[const _Desktop(), const _Shortcuts()],
                          about,
                        ],
                      ];

                return SingleChildScrollView(
                  // On a phone the page runs to the bottom edge, so its end needs room to
                  // clear it.
                  padding: EdgeInsets.only(bottom: compact ? AppSpace.xxl : AppSpace.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (c, groups) in columns.indexed) ...[
                        if (c > 0) const SizedBox(width: AppSpace.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, group) in groups.indexed) ...[
                                if (i > 0) const SizedBox(height: AppSpace.lg),
                                FadeSlideIn(
                                  delay: Duration(milliseconds: 40 * (c + i)),
                                  child: group,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A card of settings: its name, what the settings in it are for, and the settings.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.about, required this.children});

  final String title;
  final String about;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.caption),
        const SizedBox(height: AppSpace.xs),
        Text(about, style: AppText.footnote),
        for (final child in children) ...[
          const SizedBox(height: AppSpace.lg),
          child,
        ],
      ],
    ),
  );
}

/// A setting that is not a number to step: its name and where it stands, a control, what it
/// means, what it does now, and anything to be done about it.
class _Setting extends StatelessWidget {
  const _Setting({
    required this.label,
    this.value,
    this.valueColour,
    this.trailing,
    this.control,
    this.explanation,
    this.effect,
    this.actions = const [],
  });

  final String label;
  final String? value;
  final Color? valueColour;

  /// A control beside the label, such as a switch.
  final Widget? trailing;
  final Widget? control;
  final String? explanation;
  final String? effect;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppText.body)),
          if (value case final text?) ...[
            const SizedBox(width: AppSpace.md),
            Text(
              text,
              style: AppText.body.copyWith(color: valueColour ?? AppColour.labelSecondary),
            ),
          ],
          if (trailing case final widget?) ...[
            const SizedBox(width: AppSpace.md),
            widget,
          ],
        ],
      ),
      if (control case final widget?) ...[
        const SizedBox(height: AppSpace.sm),
        widget,
      ],
      if (explanation case final text?)
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs),
          child: Text(text, style: AppText.footnote),
        ),
      if (effect case final text?)
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs),
          child: Text(text, style: AppText.footnote.copyWith(color: AppColour.label)),
        ),
      if (actions.isNotEmpty) ...[
        const SizedBox(height: AppSpace.md),
        Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: actions),
      ],
    ],
  );
}

// --- account --------------------------------------------------------------------------

class _Account extends ConsumerStatefulWidget {
  const _Account();

  @override
  ConsumerState<_Account> createState() => _AccountState();
}

class _AccountState extends ConsumerState<_Account> {
  /// Keeps "5 min ago" true while nothing else changes.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncProvider);
    final sync = ref.read(syncProvider.notifier);
    final summary = summarizeSync(state, DateTime.now());
    void openSheet() => ref.read(syncSheetOpenProvider.notifier).open();

    final (about, actions) = switch (state) {
      SyncSignedOut() => (
        'Everything is kept on this device. Sign in to keep it in your account as well, and '
            'on your other devices.',
        <Widget>[PrimaryButton(label: 'Sign in…', enabled: true, onTap: openSheet)],
      ),
      final SyncOn on => (
        'Tasks, projects, your time budget and reminders sync to every device signed in to '
            'this account. Signing out stops syncing, and everything stays on this device.',
        <Widget>[
          GhostButton(label: 'Sign out', onTap: sync.signOut),
          PrimaryButton(
            label: on.syncing ? 'Syncing…' : 'Sync now',
            enabled: !on.syncing,
            onTap: sync.syncNow,
          ),
        ],
      ),
      _ => (
        'Sync is part way set up. Open it to finish.',
        <Widget>[PrimaryButton(label: 'Open sync', enabled: true, onTap: openSheet)],
      ),
    };

    return _Group(
      title: 'Account',
      about: about,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(syncIcon(state), size: 17, color: syncToneColour(summary.tone)),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.title, style: AppText.body),
                  Text(summary.detail, style: AppText.footnote),
                  if (state case SyncOn(account: SyncAccount(:final email?)))
                    Text('Signed in as $email', style: AppText.footnote),
                ],
              ),
            ),
          ],
        ),
        Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: actions),
      ],
    );
  }
}

// --- reminders ------------------------------------------------------------------------

class _Reminders extends ConsumerStatefulWidget {
  const _Reminders();

  @override
  ConsumerState<_Reminders> createState() => _RemindersState();
}

class _RemindersState extends ConsumerState<_Reminders> {
  /// What became of the last sample, until another is sent.
  String? _sampleResult;
  bool _sending = false;

  Future<void> _allow() async {
    await ref.read(reminderServiceProvider).requestPermission();
    ref.invalidate(reminderPermissionProvider);
  }

  Future<void> _sendSample() async {
    setState(() {
      _sending = true;
      _sampleResult = null;
    });
    final shown = await ref.read(reminderServiceProvider).showSample();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sampleResult = SettingsText.sampleResult(shown: shown);
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider).value ?? const Preferences();
    final repo = ref.watch(appScopeProvider).value?.preferences;
    final permitted = ref.watch(reminderPermissionProvider).value ?? false;
    final platform = defaultTargetPlatform;
    final status = SettingsText.notifications(permitted: permitted, platform: platform);
    final sleep = CapacityMapping.settings(ref.watch(capacityProfileProvider).value);

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // A time of day, stepped a quarter of an hour at a time or typed.
    ValueStepper time({
      required String label,
      required int value,
      required void Function(int minutes) save,
      required String explanation,
      required String effect,
    }) => ValueStepper(
      label: label,
      text: Format.clock(value),
      keyboardType: TextInputType.datetime,
      explanation: explanation,
      effect: effect,
      onStep: (direction) => save(value + direction * 15),
      onSubmit: (text) {
        final typed = TimeEntry.clock(text);
        if (typed == null) return false;
        save(typed);
        return true;
      },
    );

    return _Group(
      title: 'Reminders',
      about:
          'How reminders reach you on this device, and when the quick choices for a '
          'reminder are.',
      children: [
        _Setting(
          label: 'Notifications',
          value: status.value,
          valueColour: permitted ? AppColour.green : AppColour.orange,
          explanation: status.detail,
          effect: _sampleResult,
          actions: [
            if (!permitted && platform == TargetPlatform.android)
              PrimaryButton(label: 'Allow notifications', enabled: true, onTap: _allow),
            GhostButton(
              label: _sending ? 'Sending…' : 'Send a test reminder',
              onTap: _sending ? () {} : _sendSample,
            ),
          ],
        ),
        time(
          label: 'Mornings',
          value: preferences.morningMin,
          save: (minutes) => repo?.setMorning(minutes),
          explanation:
              'When "Tomorrow morning" and "The morning it is due" remind you, and when a '
              'typed "remind fri" gives no time.',
          effect: SettingsText.morningEffect(
            preferences.morningMin,
            sleep.sleepOn(tomorrow.weekday),
          ),
        ),
        time(
          label: 'Evenings',
          value: preferences.eveningMin,
          save: (minutes) => repo?.setEvening(minutes),
          explanation: 'When "This evening" and "The evening before" remind you.',
          effect: SettingsText.eveningEffect(
            preferences.eveningMin,
            sleep.sleepOn(now.weekday),
          ),
        ),
        ValueStepper(
          label: 'Snooze',
          text: Format.estimate(preferences.snoozeMin),
          keyboardType: TextInputType.datetime,
          explanation:
              'How long Snooze on a reminder waits before reminding you again. Its button '
              'says how long.',
          effect: SettingsText.snoozeEffect(preferences.snoozeMin, now),
          onStep: (direction) =>
              repo?.setSnooze(Preferences.stepSnooze(preferences.snoozeMin, direction)),
          onSubmit: (text) {
            final typed = TimeEntry.duration(text, bareMinutes: true);
            if (typed == null) return false;
            repo?.setSnooze(typed);
            return true;
          },
        ),
      ],
    );
  }
}

// --- new tasks ------------------------------------------------------------------------

class _NewTasks extends ConsumerWidget {
  const _NewTasks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider).value ?? const <Board>[];
    final preferences = ref.watch(preferencesProvider).value ?? const Preferences();
    final repo = ref.watch(appScopeProvider).value?.preferences;

    // Settings is not a project, so this is where a task added outside one goes.
    final target =
        projects.where((p) => p.id == preferences.captureProjectId).firstOrNull ??
        projects.firstOrNull;
    final sections = target == null
        ? const <BoardList>[]
        : ref.watch(sectionsProvider(target.id)).value ?? const <BoardList>[];

    return _Group(
      title: 'New tasks',
      about:
          'Inside a project, a new task goes to that project. Added anywhere else, it goes '
          'to the project chosen here. Either way, the new task sheet shows where, and '
          'lets you change it.',
      children: [
        if (target == null)
          Text('There are no projects yet.', style: AppText.footnote)
        else
          _Setting(
            label: 'Add to',
            control: Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final project in projects)
                  ComposerChip(
                    label: project.name,
                    leading: ProjectGlyph(
                      icon: project.icon,
                      colour: project.colour == null
                          ? AppColour.accent
                          : Color(project.colour!),
                      size: 14,
                    ),
                    selected: project.id == target.id,
                    tint: project.colour == null ? null : Color(project.colour!),
                    onTap: () => repo?.setCaptureProject(project.id),
                  ),
              ],
            ),
            effect: SettingsText.captureEffect(
              project: target.name,
              section: sections.firstOrNull?.name,
            ),
          ),
      ],
    );
  }
}

// --- time budget ----------------------------------------------------------------------

class _TimeBudget extends ConsumerWidget {
  const _TimeBudget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = CapacityMapping.settings(ref.watch(capacityProfileProvider).value);

    return _Group(
      title: 'Time budget',
      about:
          'Sleep, meals, buffer and focus decide how much of each day the planner counts as '
          'time to work. They sync with your tasks, and are changed on Time budget, beside '
          'the figures they change.',
      children: [
        _Setting(
          label: SettingsText.sleepSummary(settings.sleep),
          explanation: SettingsText.profileSummary(settings),
          actions: [
            GhostButton(
              label: 'Change on Time budget',
              onTap: () => ref
                  .read(destinationProvider.notifier)
                  .go(const CapacityDestination()),
            ),
          ],
        ),
      ],
    );
  }
}

// --- desktop --------------------------------------------------------------------------

class _Desktop extends ConsumerWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider).value ?? const Preferences();
    final repo = ref.watch(appScopeProvider).value?.preferences;
    final available = ref.watch(trayAvailableProvider).value ?? false;
    final on = available && preferences.keepInTray;
    final tray = SettingsText.tray(available: available, on: on);

    return _Group(
      title: 'Desktop',
      about: 'How Glasswork behaves as a window on this computer.',
      children: [
        _Setting(
          label: 'Keep in the tray',
          trailing: AppSwitch(
            key: const ValueKey('keep-in-tray'),
            value: on,
            onChanged: available ? (keep) => repo?.setKeepInTray(keep) : null,
          ),
          explanation: tray.explanation,
          effect: tray.effect,
        ),
      ],
    );
  }
}

// --- keyboard -------------------------------------------------------------------------

class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  static const _shortcuts = [
    ('Ctrl+N', 'New task'),
    ('Ctrl+Shift+N', 'New note'),
    ('Ctrl+,', 'Settings'),
    ('Return', 'Add the task you are writing'),
    ('Ctrl+Return', 'Add a list of tasks, or create a project'),
    ('Esc', 'Close the sheet or note that is open'),
  ];

  @override
  Widget build(BuildContext context) => _Group(
    title: 'Keyboard',
    about: 'Shortcuts that work anywhere in Glasswork.',
    children: [
      Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (final (keys, action) in _shortcuts)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.md, bottom: AppSpace.sm),
                  child: Align(alignment: Alignment.centerLeft, child: _Keys(keys)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: Text(action, style: AppText.callout.copyWith(color: AppColour.label)),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

/// Keys to press, drawn as keys.
class _Keys extends StatelessWidget {
  const _Keys(this.keys);

  final String keys;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
    decoration: const BoxDecoration(
      color: AppColour.fill,
      borderRadius: AppRadius.smallAll,
    ),
    child: Text(keys, style: AppText.numeric.copyWith(color: AppColour.label)),
  );
}

// --- about ----------------------------------------------------------------------------

/// Where the tasks are kept on this device, in the words a person reads a path in. Null
/// where there is no folder worth naming, or none could be found.
final _dataFolderProvider = FutureProvider<String?>((ref) async {
  if (defaultTargetPlatform != TargetPlatform.linux) return null;
  try {
    final folder = (await getApplicationSupportDirectory()).path;
    return SettingsText.homeRelative(folder, Platform.environment['HOME'] ?? '');
  } on Object {
    return null;
  }
});

class _About extends ConsumerWidget {
  const _About();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = defaultTargetPlatform;
    final installed = platform == TargetPlatform.linux
        ? SettingsText.installedAt(
            Platform.resolvedExecutable,
            Platform.environment['HOME'] ?? '',
          )
        : null;

    return _Group(
      title: 'About',
      about: '${AppConfig.name} ${AppConfig.versionLabel}',
      children: [
        _Setting(
          label: 'Your tasks',
          explanation: SettingsText.dataLocation(
            platform: platform,
            folder: ref.watch(_dataFolderProvider).value,
          ),
        ),
        if (installed != null)
          _Setting(
            label: 'Installed',
            explanation:
                'In $installed. To remove Glasswork, right-click it among your apps and '
                'choose Uninstall Glasswork. Your tasks stay unless you choose to delete '
                'them too.',
          ),
        _Setting(
          label: 'Licences',
          explanation: 'The open-source software Glasswork is built with, and its terms.',
          actions: [
            GhostButton(
              label: 'Show licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppConfig.name,
                applicationVersion: AppConfig.versionLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
