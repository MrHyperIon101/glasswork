// Glasswork's window as frosted glass over the desktop.
//
// A window on Wayland cannot see what is behind it; only the compositor can. So behind each
// of Glasswork's windows this keeps a blur of whatever lies beneath — wallpaper and other
// windows — heavy enough that nothing behind it reads as a shape, and tells Glasswork over
// D-Bus, which only then lets its own ground thin to a tint over that frost. Glasswork never
// turns see-through on its own: without this, it draws exactly as it always has.

import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Shell from 'gi://Shell';

import * as Glasswork from './glasswork.js';

/** A frost, not a smear: what is behind is light and colour, never edges. */
const BLUR_RADIUS = 72;
const BLUR_BRIGHTNESS = 0.62;

export class WindowGlass {
    constructor(settings) {
        this._settings = settings;
        this._frosts = new Map();
        this._settingsId = settings.connect('changed::glass-window', () => this._sync());
        this._createdId = global.display.connect('window-created', (_, window) => this._add(window));
        this._restackedId = global.display.connect('restacked', () => this._restack());
        this._watchOwner();
        this._sync();
    }

    /** How many of Glasswork's windows are frosted now. */
    get count() {
        return this._frosts.size;
    }

    _sync() {
        if (this._settings.get_boolean('glass-window')) {
            for (const window of Glasswork.windows())
                this._add(window);
        } else {
            for (const window of [...this._frosts.keys()])
                this._remove(window);
        }
        this._tell();
    }

    _add(window) {
        if (!this._settings.get_boolean('glass-window') || this._frosts.has(window))
            return;
        if (!Glasswork.isGlasswork(window)) {
            // A new window has its application id once it is mapped; look again then.
            if (window.get_window_type() === 0 && !window.get_gtk_application_id?.()) {
                const id = window.connect('shown', () => {
                    window.disconnect(id);
                    this._add(window);
                });
            }
            return;
        }
        const actor = window.get_compositor_private();
        if (!actor)
            return;

        const frost = new Clutter.Actor({reactive: false});
        frost.add_effect(new Shell.BlurEffect({
            mode: Shell.BlurMode.BACKGROUND,
            radius: BLUR_RADIUS,
            brightness: BLUR_BRIGHTNESS,
        }));
        global.window_group.insert_child_below(frost, actor);

        const ids = [
            window.connect('position-changed', () => this._place(window, frost)),
            window.connect('size-changed', () => this._place(window, frost)),
            window.connect('notify::minimized', () => this._show(window, actor, frost)),
            window.connect('unmanaged', () => this._remove(window)),
            actor.connect('notify::visible', () => this._show(window, actor, frost)),
            actor.connect('notify::opacity', () => (frost.opacity = actor.opacity)),
        ];
        this._frosts.set(window, {frost, actor, ids});
        this._place(window, frost);
        this._show(window, actor, frost);
        this._tell();
    }

    /** Exactly under the window's frame, not its shadow, which would show as a pale halo. */
    _place(window, frost) {
        const rect = window.get_frame_rect();
        frost.set_position(rect.x, rect.y);
        frost.set_size(rect.width, rect.height);
    }

    _show(window, actor, frost) {
        frost.visible = actor.visible && !window.minimized;
    }

    _restack() {
        for (const {frost, actor} of this._frosts.values()) {
            if (frost.get_parent() === actor.get_parent())
                global.window_group.set_child_below_sibling(frost, actor);
        }
    }

    _remove(window) {
        const entry = this._frosts.get(window);
        if (!entry)
            return;
        for (const id of entry.ids.slice(0, 4))
            window.disconnect(id);
        for (const id of entry.ids.slice(4))
            entry.actor.disconnect(id);
        entry.frost.destroy();
        this._frosts.delete(window);
        this._tell();
    }

    /** Glasswork's ground thins only while there is a frost behind it to thin over. */
    _tell() {
        const on = this._frosts.size > 0;
        Glasswork.call('SetDesktopGlass', new GLib.Variant('(b)', [on]), null).catch(() => {});
    }

    /** When Glasswork starts again, it starts opaque: tell it again once it is on the bus. */
    _watchOwner() {
        this._nameWatch = Glasswork.watchName(() => GLib.timeout_add(GLib.PRIORITY_DEFAULT, 400, () => {
            this._tell();
            return GLib.SOURCE_REMOVE;
        }));
    }

    destroy() {
        this._settings.disconnect(this._settingsId);
        global.display.disconnect(this._createdId);
        global.display.disconnect(this._restackedId);
        Glasswork.unwatchName(this._nameWatch);
        for (const window of [...this._frosts.keys()])
            this._remove(window);
        // Back to opaque before the frost goes: never see-through over nothing.
        Glasswork.call('SetDesktopGlass', new GLib.Variant('(b)', [false]), null).catch(() => {});
    }
}
