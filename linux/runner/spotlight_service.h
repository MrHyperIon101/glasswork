#ifndef RUNNER_SPOTLIGHT_SERVICE_H_
#define RUNNER_SPOTLIGHT_SERVICE_H_

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>

#include "desktop_shell.h"

// What the OS Spotlight — the GNOME Shell extension in linux/gnome-extension — asks
// Glasswork: dev.mrhyperion.glasswork.Spotlight, at /dev/mrhyperion/glasswork/Spotlight on
// the app's own bus name. Each call is handed to Dart over the
// dev.mrhyperion.glasswork/spotlight channel (lib/search/spotlight_channel.dart) and
// answered when Dart replies.
//
// Calls that arrive before Dart can answer — the extension woke Glasswork through D-Bus
// activation and it is still starting — wait until Dart says it is ready, or until a
// deadline, rather than failing.
typedef struct _SpotlightService SpotlightService;

SpotlightService* spotlight_service_new();

// Exports the interface. From GApplication's dbus_register, so it is there before the
// app owns its name and a waiting call can be delivered.
gboolean spotlight_service_register(SpotlightService* service,
                                    GDBusConnection* connection,
                                    GError** error);
void spotlight_service_unregister(SpotlightService* service);

// Opens the channel to Dart once the Flutter view exists. [shell] brings the window
// forward when something has been opened.
void spotlight_service_attach(SpotlightService* service,
                              FlView* view,
                              DesktopShell* shell);

void spotlight_service_free(SpotlightService* service);

#endif  // RUNNER_SPOTLIGHT_SERVICE_H_
