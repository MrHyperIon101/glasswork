import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads the Linux runner, because the order it wires the window in is invisible to any
/// widget test, and getting it wrong breaks "Keep in the tray" without a sound.
void main() {
  test("the tray answers the window's close button before the Flutter view can", () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    // A Flutter view, once realised, stops a close request at its own handler and asks Dart
    // to exit. The tray's handler, which hides the window instead, has to be connected
    // before that, or it never runs and closing the window quits the app.
    final shell = source.indexOf('desktop_shell_new(');
    final view = source.indexOf('fl_view_new(');
    final realise = source.indexOf('gtk_widget_realize(');
    expect(shell, isNonNegative, reason: 'the runner makes the desktop shell');
    expect(view, isNonNegative);
    expect(realise, isNonNegative);
    expect(shell, lessThan(view), reason: 'the shell connects its close handler first');
    expect(shell, lessThan(realise));
  });
}
