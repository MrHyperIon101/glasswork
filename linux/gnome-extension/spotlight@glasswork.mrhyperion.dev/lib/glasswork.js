// Glasswork over its own bus name: dev.mrhyperion.glasswork.Spotlight, served by the app's
// runner (linux/runner/spotlight_service.cc). Shared by the Glasswork source and by the
// window glass, which both talk to the app.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export const BUS_NAME = 'dev.mrhyperion.glasswork';
const PATH = '/dev/mrhyperion/glasswork/Spotlight';
const INTERFACE = 'dev.mrhyperion.glasswork.Spotlight';

/**
 * Calls [method]. With [wake], a Glasswork that is not running is started for it — in the
 * background, by D-Bus activation — and the call waits for it; without, a call to an app
 * that is not there fails at once, so typing never waits on a cold start.
 */
export function call(method, parameters, replyType, {wake = false, timeout = 2500, cancellable = null} = {}) {
    return new Promise((resolve, reject) => {
        Gio.DBus.session.call(
            BUS_NAME, PATH, INTERFACE, method, parameters,
            replyType ? new GLib.VariantType(replyType) : null,
            wake ? Gio.DBusCallFlags.NONE : Gio.DBusCallFlags.NO_AUTO_START,
            timeout, cancellable,
            (connection, result) => {
                try {
                    resolve(connection.call_finish(result).recursiveUnpack());
                } catch (error) {
                    reject(error);
                }
            });
    });
}

/** Glasswork's windows: the app's, by its application id. */
export function windows() {
    return global.get_window_actors()
        .map(actor => actor.meta_window)
        .filter(isGlasswork);
}

export function isGlasswork(window) {
    return window?.get_gtk_application_id?.() === BUS_NAME ||
        window?.get_wm_class?.() === BUS_NAME;
}

/**
 * Brings Glasswork's window forward with focus, which on Wayland only the shell itself may
 * give. A window coming out of the tray takes a moment to be mapped, so it is waited for.
 */
export function focus(timestamp, attempts = 20) {
    const [window] = windows();
    if (window) {
        Main.activateWindow(window, timestamp || global.get_current_time());
        return;
    }
    if (attempts > 0) {
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
            focus(timestamp, attempts - 1);
            return GLib.SOURCE_REMOVE;
        });
    }
}

/** Calls [onAppeared] whenever Glasswork comes onto the bus. Returns the watch, to end it. */
export function watchName(onAppeared) {
    return Gio.bus_watch_name(Gio.BusType.SESSION, BUS_NAME, Gio.BusNameWatcherFlags.NONE,
        () => onAppeared(), null);
}

export function unwatchName(watch) {
    if (watch)
        Gio.bus_unwatch_name(watch);
}
