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

  test('the window has no bar of its own, and keeps its frame', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    // The buttons are drawn in the app (lib/ui/widgets/window_controls.dart). A header bar
    // here would put a second set above them, in the desktop's theme rather than this
    // one — which is what the Flutter template does, so this reads the runner for it.
    expect(source, isNot(contains('gtk_header_bar')));

    // An empty title bar, not an undecorated window: that keeps GTK's own frame, and with
    // it the shadow, the resize edges and the desktop's snapping.
    expect(source, contains('gtk_window_set_titlebar('));
    expect(source, isNot(contains('gtk_window_set_decorated(')));

    // The switcher and the taskbar still read the title.
    expect(source, contains('gtk_window_set_title('));
  });
}
