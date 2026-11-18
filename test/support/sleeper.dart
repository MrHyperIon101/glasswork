import 'dart:io';

/// Builds, into [dir], a program that sleeps for the seconds it is given — whatever name it
/// is run under — and returns its path.
///
/// Tests stand it in for a running Glasswork, which is found by its name or its executable.
/// Copying `sleep` used to do, until coreutils became one multicall binary that works out
/// what it is from the name it runs as: renamed `glasswork`, it exits at once, and the "app"
/// a test thought was open never was.
String sleeper(Directory dir) {
  final source = File('${dir.path}/sleeper.c')
    ..writeAsStringSync(
      '#include <stdlib.h>\n'
      '#include <unistd.h>\n'
      'int main(int argc, char **argv) {\n'
      '  sleep(argc > 1 ? (unsigned) atoi(argv[1]) : 30);\n'
      '  return 0;\n'
      '}\n',
    );
  final program = '${dir.path}/sleeper';
  final built = Process.runSync('cc', ['-O0', '-o', program, source.path]);
  if (built.exitCode != 0) {
    throw StateError('Could not build the sleeper: ${built.stderr}');
  }
  return program;
}
