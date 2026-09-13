import 'package:supabase/supabase.dart' show AuthException, AuthRetryableFetchException;

import '../sync/account_link.dart';
import '../sync/sync_auth.dart';
import '../sync/sync_transport.dart';
import '../ui/format.dart';
import 'sync_controller.dart';

/// How sync should read at a glance.
enum SyncTone { quiet, active, good, warning, problem }

/// Sync in two short lines: what is happening, and the detail that matters.
class SyncSummary {
  const SyncSummary({
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String title;
  final String detail;
  final SyncTone tone;
}

/// The sidebar's account of sync.
///
/// A pure function of the state and the time, so every phrase — "Just now", "3 changes
/// waiting", "Offline" — is checked by a test rather than assembled inside a widget.
SyncSummary summarizeSync(SyncState state, DateTime now) {
  switch (state) {
    case SyncStarting():
      return const SyncSummary(
        title: 'Sync',
        detail: 'Checking…',
        tone: SyncTone.quiet,
      );
    case SyncSignedOut():
      return const SyncSummary(
        title: 'Sync is off',
        detail: 'Sign in to use your other devices',
        tone: SyncTone.quiet,
      );
    case SyncLinking(error: null):
      return const SyncSummary(
        title: 'Setting up sync…',
        detail: 'Getting your account ready',
        tone: SyncTone.active,
      );
    case SyncLinking():
      return const SyncSummary(
        title: "Sync isn't set up yet",
        detail: 'Open to try again',
        tone: SyncTone.warning,
      );
    case SyncChoosing():
      return const SyncSummary(
        title: 'Choose what to keep',
        detail: 'Your account already has data',
        tone: SyncTone.warning,
      );
    case SyncLinkedElsewhere():
      return const SyncSummary(
        title: 'A different account',
        detail: 'This device syncs with another one',
        tone: SyncTone.problem,
      );
    case final SyncOn on:
      return _summarizeOn(on, now);
  }
}

SyncSummary _summarizeOn(SyncOn state, DateTime now) {
  final waiting = _waiting(state.pending);

  if (state.syncing) {
    return SyncSummary(
      title: 'Syncing…',
      detail: waiting ?? state.account.email ?? 'Signed in',
      tone: SyncTone.active,
    );
  }

  switch (state.problem) {
    case SyncProblem.offline:
      final last = _ago(state.lastSynced, now);
      return SyncSummary(
        title: 'Offline',
        detail:
            waiting ??
            (last == null ? 'Syncs when you reconnect' : 'Last synced $last'),
        tone: SyncTone.warning,
      );
    case SyncProblem.deviceClock:
      return const SyncSummary(
        title: 'Check date & time',
        detail: "This device's clock is wrong",
        tone: SyncTone.problem,
      );
    case SyncProblem.otherDeviceClock:
      return const SyncSummary(
        title: "Another device's clock is wrong",
        detail: 'Its changes are held back',
        tone: SyncTone.problem,
      );
    case SyncProblem.failed:
      return SyncSummary(
        title: 'Sync paused',
        detail: waiting ?? 'Trying again shortly',
        tone: SyncTone.problem,
      );
    case null:
      return SyncSummary(
        title: 'Synced',
        detail: _capitalised(_ago(state.lastSynced, now)) ?? 'Up to date',
        tone: SyncTone.good,
      );
  }
}

/// "3 changes waiting", or null when nothing is.
String? _waiting(int pending) => switch (pending) {
  0 => null,
  1 => '1 change waiting',
  _ => '$pending changes waiting',
};

/// When, as a person would say it: "just now", "5 min ago", "today at 09:30".
String? _ago(DateTime? at, DateTime now) {
  if (at == null) return null;

  final ago = now.difference(at);
  if (ago < const Duration(minutes: 1)) return 'just now';
  if (ago < const Duration(hours: 1)) return '${ago.inMinutes} min ago';

  final time =
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  final today = at.year == now.year && at.month == now.month && at.day == now.day;
  return today ? 'today at $time' : '${Format.shortDate(at)} at $time';
}

String? _capitalised(String? text) => text == null || text.isEmpty
    ? text
    : '${text[0].toUpperCase()}${text.substring(1)}';

/// What this device holds, in one line: "14 tasks · 2 projects · 5 timetable blocks".
String describeDeviceContent(DeviceContent content) {
  String count(int n, String one, String many) => n == 1 ? '1 $one' : '$n $many';

  return [
    count(content.tasks, 'task', 'tasks'),
    count(content.projects, 'project', 'projects'),
    if (content.blocks > 0)
      count(content.blocks, 'timetable block', 'timetable blocks'),
    if (content.labels > 0) count(content.labels, 'label', 'labels'),
  ].join(' · ');
}

/// What went wrong, in words for the person who was trying.
String describeSyncError(Object error) {
  if (error is AuthRetryableFetchException || error is SyncOfflineException) {
    return "Couldn't reach the server. Check your connection and try again.";
  }
  if (error is AuthException) {
    return switch (error.code) {
      'invalid_credentials' => "That email and password don't match.",
      'user_already_exists' ||
      'email_exists' => 'There is already an account for that email. Sign in instead.',
      'weak_password' =>
        'Choose a longer password: at least ${SyncAuth.minimumPasswordLength} characters.',
      'email_not_confirmed' => 'Confirm your email address, then sign in.',
      'email_address_invalid' ||
      'validation_failed' => "That doesn't look like an email address.",
      'over_request_rate_limit' =>
        'Too many tries. Wait a few minutes, then try again.',
      'signup_disabled' =>
        'New accounts are turned off. Sign in with the account you already have.',
      _ => error.message,
    };
  }
  if (error is DeviceClockAheadException) {
    return "This device's date or time is wrong. Correct it, then try again.";
  }
  if (error is SyncTransportException) return error.message;
  return '$error';
}
