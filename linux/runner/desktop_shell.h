#ifndef RUNNER_DESKTOP_SHELL_H_
#define RUNNER_DESKTOP_SHELL_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// The window's life outside Flutter: an icon in the tray, and whether closing the window
// quits the app or leaves it running there. Dart turns it on and off over the
// dev.mrhyperion.glasswork/desktop channel; the tray's menu answers over the same channel.
typedef struct _DesktopShell DesktopShell;

DesktopShell* desktop_shell_new(GtkApplication* application,
                                GtkWindow* window,
                                FlView* view);

// Shows the window again, from the tray or from a second launch.
void desktop_shell_present(DesktopShell* shell);

void desktop_shell_free(DesktopShell* shell);

#endif  // RUNNER_DESKTOP_SHELL_H_
