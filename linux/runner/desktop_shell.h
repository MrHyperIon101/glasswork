#ifndef RUNNER_DESKTOP_SHELL_H_
#define RUNNER_DESKTOP_SHELL_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// The window's life outside Flutter: an icon in the tray, whether closing the window quits
// the app or leaves it running there, and the window's own buttons — the window has no bar
// of its own, so minimise, maximise, close and dragging it about are asked for by the app's
// header over the dev.mrhyperion.glasswork/desktop channel. The tray's menu and the
// window's maximised state answer back over the same channel.
typedef struct _DesktopShell DesktopShell;

// Made before the window has a Flutter view, because it answers the window's close button
// and has to be asked first. The Flutter view, once realised, stops a close request at its
// own handler and asks Dart to exit, so a handler connected after it never runs.
DesktopShell* desktop_shell_new(GtkApplication* application, GtkWindow* window);

// Opens the channel to Dart, once the window's Flutter view exists.
void desktop_shell_attach(DesktopShell* shell, FlView* view);

// Shows the window again, from the tray or from a second launch.
void desktop_shell_present(DesktopShell* shell);

void desktop_shell_free(DesktopShell* shell);

#endif  // RUNNER_DESKTOP_SHELL_H_
