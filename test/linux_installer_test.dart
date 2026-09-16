@TestOn('linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Linux installer, built for real and run against a home folder of its own.
///
/// It installs, updates and removes a stand-in for the app the way it does the real one,
/// and these check what lands where, what is kept, and that a damaged installer changes
/// nothing. Building it needs a C compiler and GTK's headers, as building the app does.
void main() {
  const id = 'dev.mrhyperion.glasswork';

  final canBuild =
      Process.runSync('sh', [
        '-c',
        'command -v cc && pkg-config --exists gtk+-3.0',
      ]).exitCode ==
      0;
  final skip = canBuild
      ? false
      : 'Building the installer needs cc and GTK 3 headers';
  const timeout = Timeout(Duration(minutes: 3));

  late Directory root;
  late String home;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('glasswork-installer');
    home = '${root.path}/home';
    Directory(home).createSync();
  });
  tearDown(() => root.delete(recursive: true));

  String inHome(String path) => '$home/$path';

  /// A stand-in for the release build: a program, and a file saying which version it is.
  ///
  /// The program is [program] when given, copied in, so that running it looks to the
  /// installer like the app running.
  String bundle(String version, {String? program}) {
    final dir = Directory('${root.path}/bundle-$version')..createSync();
    if (program == null) {
      File('${dir.path}/glasswork').writeAsStringSync('#!/bin/sh\nexit 0\n');
    } else {
      File(program).copySync('${dir.path}/glasswork');
    }
    Process.runSync('chmod', ['+x', '${dir.path}/glasswork']);
    File('${dir.path}/data/which')
      ..createSync(recursive: true)
      ..writeAsStringSync(version);
    return dir.path;
  }

  Future<String> build(String version, {String? program}) async {
    final output = '${root.path}/setup-$version';
    final result = await Process.run('linux/packaging/build_installer.sh', [
      '--bundle',
      bundle(version, program: program),
      '--version',
      version,
      '--output',
      output,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    return output;
  }

  /// [program] run as if [home] were the home folder.
  Future<ProcessResult> run(String program, List<String> arguments) =>
      Process.run(
        program,
        arguments,
        includeParentEnvironment: false,
        environment: {
          'HOME': home,
          'XDG_DATA_HOME': inHome('.local/share'),
          'XDG_CONFIG_HOME': inHome('.config'),
          'PATH': Platform.environment['PATH']!,
        },
      );

  void expectOk(ProcessResult result) =>
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');

  test(
    'installs, then updates in place, keeping what is stored',
    () async {
      final first = await build('0.1.0+1');
      expect((await run(first, ['--version'])).stdout, '0.1.0+1\n');
      expectOk(await run(first, ['--install']));

      final app = inHome('.local/opt/$id');
      expect(File('$app/glasswork').existsSync(), isTrue);
      expect(File('$app/VERSION').readAsStringSync(), '0.1.0+1\n');
      expect(File('$app/uninstall').statSync().modeString(), startsWith('rwx'));
      final entry = File(inHome('.local/share/applications/$id.desktop'))
          .readAsStringSync();
      expect(entry, contains('\nExec="$app/glasswork"\n'));
      expect(entry, contains('\nExec="$app/uninstall" --uninstall\n'));
      expect(
        File(inHome('.local/share/icons/hicolor/256x256/apps/$id.png'))
            .existsSync(),
        isTrue,
      );

      // The person's own tasks, which an update must never touch.
      final tasks = File(inHome('.local/share/$id/app.sqlite'))
        ..createSync(recursive: true)
        ..writeAsStringSync('tasks');

      final second = await build('0.2.0+2');
      final updated = await run(second, ['--install']);
      expectOk(updated);
      expect(updated.stdout, contains('is updated'));
      expect(File('$app/VERSION').readAsStringSync(), '0.2.0+2\n');
      expect(File('$app/data/which').readAsStringSync(), '0.2.0+2');
      expect(tasks.readAsStringSync(), 'tasks');
      expect(
        Directory(inHome('.local/opt'))
            .listSync()
            .map((e) => e.path.split('/').last),
        isNot(contains(startsWith('.'))),
        reason: 'nothing left over from unpacking or swapping',
      );
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    'closes the app for an update only when asked to',
    () async {
      final sleep =
          (Process.runSync('sh', ['-c', 'command -v sleep']).stdout as String)
              .trim();
      final first = await build('0.1.0+1', program: sleep);
      expectOk(await run(first, ['--install']));

      final app = await Process.start(inHome('.local/opt/$id/glasswork'), [
        '300',
      ]);
      addTearDown(app.kill);
      // Until it has started, it is not yet the app running.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final second = await build('0.2.0+2', program: sleep);
      final refused = await run(second, ['--install']);
      expect(refused.exitCode, isNot(0));
      expect(refused.stderr, contains('Glasswork is open'));
      expect(
        File(inHome('.local/opt/$id/VERSION')).readAsStringSync(),
        '0.1.0+1\n',
      );

      expectOk(await run(second, ['--install', '--close-running']));
      expect(
        await app.exitCode.timeout(const Duration(seconds: 5)),
        -ProcessSignal.sigterm.signalNumber,
      );
      expect(
        File(inHome('.local/opt/$id/VERSION')).readAsStringSync(),
        '0.2.0+2\n',
      );
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    'uninstalls, keeping the tasks unless told not to',
    () async {
      final setup = await build('0.2.0+2');
      expectOk(await run(setup, ['--install']));
      final tasks = File(inHome('.local/share/$id/app.sqlite'))
        ..createSync(recursive: true);

      expectOk(
        await run(inHome('.local/opt/$id/uninstall'), ['--uninstall', '--yes']),
      );
      expect(Directory(inHome('.local/opt/$id')).existsSync(), isFalse);
      expect(
        File(inHome('.local/share/applications/$id.desktop')).existsSync(),
        isFalse,
      );
      expect(
        File(inHome('.local/share/icons/hicolor/256x256/apps/$id.png'))
            .existsSync(),
        isFalse,
      );
      expect(tasks.existsSync(), isTrue);

      expectOk(await run(setup, ['--install']));
      expectOk(
        await run(inHome('.local/opt/$id/uninstall'), [
          '--uninstall',
          '--yes',
          '--remove-data',
        ]),
      );
      expect(Directory(inHome('.local/share/$id')).existsSync(), isFalse);
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    'a damaged installer leaves the installed app as it was',
    () async {
      final setup = await build('0.2.0+2');
      expectOk(await run(setup, ['--install']));

      // The packed app with a stretch near its end wiped, its length and marker intact.
      final bytes = File(setup).readAsBytesSync();
      final damaged = File('${root.path}/damaged')
        ..writeAsBytesSync([
          ...bytes.sublist(0, bytes.length - 3016),
          ...List.filled(3000, 0),
          ...bytes.sublist(bytes.length - 16),
        ]);
      Process.runSync('chmod', ['+x', damaged.path]);

      final result = await run(damaged.path, ['--install']);
      expect(result.exitCode, isNot(0));
      expect(
        Directory(inHome('.local/opt'))
            .listSync()
            .map((e) => e.path.split('/').last),
        [id],
        reason: 'what was unpacked before the damage was found is cleared away',
      );
      expect(result.stderr, contains('could not be unpacked'));
      expect(
        File(inHome('.local/opt/$id/VERSION')).readAsStringSync(),
        '0.2.0+2\n',
      );
      expect(File(inHome('.local/opt/$id/glasswork')).existsSync(), isTrue);
    },
    skip: skip,
    timeout: timeout,
  );
}
