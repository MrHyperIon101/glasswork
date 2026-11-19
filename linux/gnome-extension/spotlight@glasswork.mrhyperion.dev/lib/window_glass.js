// Glasswork's window as frosted glass over the desktop, with rounded corners.
//
// A window on Wayland cannot see what is behind it; only the compositor can. So behind each
// of Glasswork's windows this keeps a frost of whatever lies beneath — the wallpaper, and the
// windows stacked under it — and tells Glasswork over D-Bus, which only then lets its own
// ground thin to Spotlight's tint over that frost. Glasswork never turns see-through on its
// own: without this, it draws exactly as it always has.
//
// The frost is Spotlight's glass (ui/glass.js): copies of what is beneath, blurred, then cut
// to the window's rounded shape. GNOME's own background blur would be simpler, but it is
// always a rectangle, and its square corners would show past the window's round ones. What is
// copied is only what is under the window — the wallpaper and the windows below it — never
// the window itself, so it is never frosted over its own content.

import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import * as Glasswork from './glasswork.js';
import {Glass} from './ui/glass.js';

/** A frost, not a smear: what is behind is light and colour, never edges. */
const BLUR_RADIUS = 72;
/** As bright as Spotlight's glass, so the window and Spotlight are the same material. */
const BLUR_BRIGHTNESS = 0.82;
/**
 * The window's corners, the same as Glasswork rounds its own content to (AppRadius.xlarge in
 * lib/theme/tokens.dart, "outer window chrome"). Square when it fills the screen.
 */
export const CORNER_RADIUS = 28;

/** Everything a window covers on screen: the wallpaper, and each window stacked below it. */
class Beneath {
    constructor(windowActor) {
        this._windowActor = windowActor;
        this.actor = new Clutter.Actor({layout_manager: new Clutter.FixedLayout()});
        this._background = new Clutter.Clone({source: Main.layoutManager._backgroundGroup});
        this.actor.add_child(this._background);
        this._clones = new Map();
        this.update();
    }

    /** The windows below, again: after any restacking, mapping or moving of windows. */
    update() {
        const below = [];
        for (const child of global.window_group.get_children()) {
            if (child === this._windowActor)
                break;
            if (child instanceof Meta.WindowActor && child.visible && !child.meta_window?.minimized)
                below.push(child);
        }
        for (const [source, clone] of this._clones) {
            if (!below.includes(source)) {
                clone.destroy();
                this._clones.delete(source);
            }
        }
        for (const source of below) {
            let clone = this._clones.get(source);
            if (!clone) {
                clone = new Clutter.Clone({source});
                this._clones.set(source, clone);
                // A closed window's actor goes, and its copy with it; one that moves, hides or
                // is minimised is followed.
                source.connectObject(
                    'destroy', () => {
                        this._clones.get(source)?.destroy();
                        this._clones.delete(source);
                    },
                    'notify::x', () => clone.set_position(source.x, source.y),
                    'notify::y', () => clone.set_position(source.x, source.y),
                    'notify::visible', () => this.update(),
                    clone);
            }
            clone.set_position(source.x, source.y);
            // In stacking order, the lowest first, the wallpaper under all.
            this.actor.set_child_above_sibling(clone, null);
        }
    }

    /** Its copies go with it, and their signals with them. */
    destroy() {
        this._clones.clear();
        this.actor.destroy();
    }
}

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

        const beneath = new Beneath(actor);
        const entry = {actor, beneath, radius: CORNER_RADIUS};
        const frost = new Glass({
            styleClass: 'gw-window-glass',
            content: beneath.actor,
            blur: BLUR_RADIUS,
            brightness: BLUR_BRIGHTNESS,
            // The window draws its own edge and GTK its shadow: the frost is only the frost.
            rim: 1,
            bendBy: 0,
            light: 0,
            shadow: 0,
            shapes: () => [{x: 0, y: 0, width: frost.width, height: frost.height, radius: entry.radius}],
        });
        frost.reactive = false;
        entry.frost = frost;
        global.window_group.insert_child_below(frost, actor);

        // Tied to the frost: destroying it lets go of all of these, and never touches a
        // window or actor that is already gone — a closed window's actor often is, by the
        // time its window says it has been unmanaged.
        const place = () => this._place(window, entry);
        window.connectObject(
            'position-changed', place,
            'size-changed', place,
            'notify::maximized-horizontally', place,
            'notify::maximized-vertically', place,
            'notify::fullscreen', place,
            'notify::minimized', () => this._show(window, entry),
            'unmanaged', () => this._remove(window),
            frost);
        actor.connectObject(
            'notify::visible', () => this._show(window, entry),
            'notify::opacity', () => (frost.opacity = actor.opacity),
            'destroy', () => this._remove(window),
            frost);
        this._frosts.set(window, entry);
        place();
        this._show(window, entry);
        this._tell();
    }

    /**
     * Exactly under the window's frame, not its shadow, which would show as a pale halo; and
     * rounded as the window is, unless it fills the screen.
     */
    _place(window, entry) {
        const rect = window.get_frame_rect();
        entry.frost.set_position(rect.x, rect.y);
        entry.frost.setSize(rect.width, rect.height);
        entry.frost.alignBackdrop(rect.x, rect.y);
        const fills = window.is_fullscreen() ||
            (window.maximized_horizontally && window.maximized_vertically);
        entry.radius = fills ? 0 : CORNER_RADIUS;
        entry.beneath.update();
        entry.frost.refresh();
    }

    _show(window, entry) {
        entry.frost.visible = entry.actor.visible && !window.minimized;
    }

    _restack() {
        for (const entry of this._frosts.values()) {
            const {frost, actor, beneath} = entry;
            if (actor.get_parent() && frost.get_parent() === actor.get_parent())
                global.window_group.set_child_below_sibling(frost, actor);
            beneath.update();
        }
    }

    _remove(window) {
        const entry = this._frosts.get(window);
        if (!entry)
            return;
        this._frosts.delete(window);
        // What it copies first, while the frost that holds it is still there to leave.
        entry.beneath.destroy();
        entry.frost.destroy();
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
