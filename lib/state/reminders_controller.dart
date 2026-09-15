import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../reminders/android_reminders.dart';
import '../reminders/linux_reminders.dart';
import '../reminders/reminders.dart';
import '../ui/format.dart';

/// The platform's notifications, or none where there are none to use — which includes
/// running under test, where there is no platform at all.
final reminderGatewayProvider = Provider<ReminderGateway>((ref) {
  if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
    return const NoReminders();
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidReminders(),
    TargetPlatform.linux => LinuxReminders(
      dataDir: () async => (await getApplicationSupportDirectory()).path,
      configHome:
          Platform.environment['XDG_CONFIG_HOME'] ??
          '${Platform.environment['HOME']}/.config',
      runtimeDir: Platform.environment['XDG_RUNTIME_DIR'],
    ),
    _ => const NoReminders(),
  };
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = ReminderService(
    ref.watch(reminderGatewayProvider),
    describe: (task) => Format.due(task, DateTime.now())?.label ?? '',
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Whether this device shows reminders. Checked again after asking.
final reminderPermissionProvider = FutureProvider<bool>(
  (ref) => ref.watch(reminderServiceProvider).permitted(),
);
