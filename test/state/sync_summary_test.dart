import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/state/sync_summary.dart';
import 'package:glasswork/sync/account_link.dart';
import 'package:glasswork/sync/sync_auth.dart';
import 'package:glasswork/sync/sync_transport.dart';
import 'package:supabase/supabase.dart';

void main() {
  final now = DateTime(2026, 9, 13, 14, 30);
  const account = SyncAccount(userId: 'u', email: 'me@example.com');

  SyncSummary on({
    bool syncing = false,
    DateTime? lastSynced,
    SyncProblem? problem,
    int pending = 0,
  }) => summarizeSync(
    SyncOn(
      account: account,
      syncing: syncing,
      lastSynced: lastSynced,
      problem: problem,
      pending: pending,
    ),
    now,
  );

  group('synced', () {
    test('says when, the way a person would', () {
      expect(on(lastSynced: now.subtract(const Duration(seconds: 20))).detail, 'Just now');
      expect(on(lastSynced: now.subtract(const Duration(minutes: 5))).detail, '5 min ago');
      expect(on(lastSynced: DateTime(2026, 9, 13, 9, 5)).detail, 'Today at 09:05');
      expect(on(lastSynced: DateTime(2026, 9, 12, 18, 0)).detail, '12 Sep at 18:00');
    });

    test('reads as good, with nothing waiting', () {
      final summary = on(lastSynced: now);
      expect(summary.title, 'Synced');
      expect(summary.tone, SyncTone.good);
    });
  });

  group('offline', () {
    test('counts what is waiting to go', () {
      expect(on(problem: SyncProblem.offline, pending: 1).detail, '1 change waiting');
      expect(on(problem: SyncProblem.offline, pending: 3).detail, '3 changes waiting');
    });

    test('with nothing waiting, says when it last got through', () {
      expect(
        on(
          problem: SyncProblem.offline,
          lastSynced: now.subtract(const Duration(minutes: 12)),
        ).detail,
        'Last synced 12 min ago',
      );
      expect(on(problem: SyncProblem.offline).detail, 'Syncs when you reconnect');
    });

    test('is a warning, not a failure', () {
      expect(on(problem: SyncProblem.offline).tone, SyncTone.warning);
    });
  });

  test('a clock problem says whose clock', () {
    expect(on(problem: SyncProblem.deviceClock).detail, "This device's clock is wrong");
    expect(on(problem: SyncProblem.otherDeviceClock).title, "Another device's clock is wrong");
    expect(on(problem: SyncProblem.deviceClock).tone, SyncTone.problem);
  });

  test('syncing reads as syncing, even with a problem from the last attempt', () {
    final summary = on(syncing: true, problem: SyncProblem.offline, pending: 2);
    expect(summary.title, 'Syncing…');
    expect(summary.detail, '2 changes waiting');
  });

  test('before syncing, each step reads as itself', () {
    expect(summarizeSync(const SyncSignedOut(), now).title, 'Sync is off');
    // A build with no project behind it says why, rather than offering a sign-in.
    expect(
      summarizeSync(const SyncUnconfigured(), now).detail,
      'This build has no server set up',
    );
    expect(summarizeSync(const SyncLinking(account: account), now).tone, SyncTone.active);
    expect(
      summarizeSync(const SyncLinking(account: account, error: 'offline'), now).tone,
      SyncTone.warning,
    );
    expect(
      summarizeSync(const SyncLinkedElsewhere(account: account), now).tone,
      SyncTone.problem,
    );
  });

  test("describes what a device holds, leaving out what it doesn't have", () {
    expect(
      describeDeviceContent(
        const DeviceContent(tasks: 14, projects: 2, blocks: 5, labels: 1),
      ),
      '14 tasks · 2 projects · 5 timetable blocks · 1 label',
    );
    expect(
      describeDeviceContent(
        const DeviceContent(tasks: 1, projects: 1, blocks: 0, labels: 0),
      ),
      '1 task · 1 project',
    );
  });

  group('errors, in plain words', () {
    test('a wrong password', () {
      expect(
        describeSyncError(
          const AuthApiException('Invalid login credentials', code: 'invalid_credentials'),
        ),
        "That email and password don't match.",
      );
    });

    test('an account that already exists', () {
      expect(
        describeSyncError(
          const AuthApiException('User already registered', code: 'user_already_exists'),
        ),
        contains('Sign in instead'),
      );
    });

    test('a password too short says how long it must be', () {
      expect(
        describeSyncError(
          const AuthApiException('Password should be longer', code: 'weak_password'),
        ),
        contains('at least ${SyncAuth.minimumPasswordLength} characters'),
      );
    });

    test('no connection, however it surfaced', () {
      const offline = "Couldn't reach the server. Check your connection and try again.";
      expect(describeSyncError(AuthRetryableFetchException(message: 'SocketException')), offline);
      expect(describeSyncError(const SyncOfflineException('timed out')), offline);
    });

    test("this device's clock", () {
      expect(
        describeSyncError(const DeviceClockAheadException('clock ahead')),
        contains('date or time is wrong'),
      );
    });
  });
}
