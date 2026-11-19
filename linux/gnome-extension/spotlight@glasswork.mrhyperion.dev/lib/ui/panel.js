// Spotlight itself, laid out and moving as macOS Tahoe's does.
//
// A capsule of glass a little under a quarter of the way down the screen; beside it, once
// the pointer moves, four round buttons — Applications, Files, Actions, Clipboard — that bud
// out of the bar's end like drops leaving it and draw back in when typing starts. Under it,
// what was found: the categories it falls into as chips to narrow it by, then the top hit and
// a section for each kind, the highlight sliding from row to row. Each browse mode lists its
// own: every app in a grid, sorted by category; recent files, by kind; every action, with
// its quick key; everything copied lately. An action with fields is filled in in the bar
// itself, Tab moving between them.
//
// It opens on a spring — fading in and growing from 94% to its size, settling with the
// faintest overshoot — and nothing behind it dims. The results grow to fit what arrives,
// rows fading in as they come. It leaves faster than it came. All of it is off when the
// desktop asks for less motion.

import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Pango from 'gi://Pango';
import Shell from 'gi://Shell';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import {CATEGORIES} from '../app_categories.js';
import * as clip from '../clip.js';
import {FILE_FILTERS} from '../file_kinds.js';
import * as grid from '../grid.js';
import * as history from '../history.js';
import {MODES, mode as modeById, slash} from '../modes.js';
import * as ranking from '../ranking.js';
import * as spring from '../spring.js';
import * as state from '../state.js';
import {GROUPS} from '../sources/actions.js';
import {Glass, MARGIN} from './glass.js';

const WIDTH = 680;
const BAR = 56;
// The buttons are as tall as the bar, nearly, and share its width: as they come out, the bar
// draws its right end in to make room for them, as Tahoe's does, and stretches back as they
// go. Everything — bar, buttons and the results under them — is WIDTH across, centred.
const BUTTON = 54;
const BUTTON_GAP = 10;
const BAR_GAP = 12;
const BUTTONS_WIDTH = BAR_GAP + MODES.length * BUTTON + (MODES.length - 1) * BUTTON_GAP;
const SHORT_BAR = WIDTH - BUTTONS_WIDTH;
// How far apart, in pixels, the bar's shapes still melt together: at rest the gaps between
// them are wider than half of this, so they stand apart.
const BLEND_AT_REST = 8;
const BLEND_MOVING = 26;
const ICONS = GLib.build_filenamev([
    GLib.path_get_dirname(GLib.filename_from_uri(import.meta.url)[0]), '..', '..', 'icons']);

/** An icon by name: the theme's, or Spotlight's own for a name starting gw-. */
function gicon(name) {
    return name.startsWith('gw-')
        ? Gio.FileIcon.new(Gio.File.new_for_path(GLib.build_filenamev([ICONS, `${name}.svg`])))
        : Gio.ThemedIcon.new(name);
}
const GAP = 10;
const MOST_HEIGHT = 540;
const INSET = 6;
const COLUMNS = 6;
const CELL = Math.floor((WIDTH - 2 * INSET) / COLUMNS);
const CELL_HEIGHT = 104;
const SEARCH_DELAY_MS = 30;
const CLOSE_MS = 140;
const STAGGER = 0.035;

const SECTION_TITLES = Object.fromEntries(ranking.SECTIONS.map(s => [s.id, s.title]));

function animations() {
    return St.Settings.get().enable_animations;
}

function clamp(value, low, high) {
    return Math.min(Math.max(value, low), high);
}

export const SpotlightPanel = GObject.registerClass({
    Signals: {'closed': {}},
}, class SpotlightPanel extends St.Widget {
    _init({sources, apps, files, actions, glasswork, clipboard}) {
        super._init({
            reactive: true,
            visible: false,
            layout_manager: new Clutter.FixedLayout(),
        });
        this._sources = sources;
        this._apps = apps;
        this._files = files;
        this._actions = actions;
        this._glasswork = glasswork;
        this._clipboard = clipboard;

        this._mode = null;
        this._filter = null;
        this._form = null;
        this._found = [];
        this._walk = [];
        this._rows = [];
        this._chipList = [];
        this._selected = 0;
        this._chosen = false;
        this._grab = null;
        this._cancellable = null;
        this._searchId = 0;
        this._history = state.read('history.json', []);
        this._historyAt = -1;
        this._appsView = 'grid';
        this._alt = false;

        // A click on nothing — not the bar, its buttons or the results — closes it.
        this.connect('button-press-event', (_, event) => {
            if (global.stage.get_event_actor(event) === this)
                this.close();
            return Clutter.EVENT_STOP;
        });
        // Keys are read as they reach Spotlight, before the field has them: the field moves
        // its cursor on Left and Right before it ever emits a key press, and those are the
        // grid's arrows. What Spotlight does not use goes on to the field as before.
        //
        // With an input method running, every key goes to it first and comes back marked as
        // having been through it, and it is that copy that is read — so a Tab typed right
        // after a word is read after the word, not before letters still on their way back.
        this.connect('captured-event', (_, event) => {
            const type = event.type();
            if (type !== Clutter.EventType.KEY_PRESS && type !== Clutter.EventType.KEY_RELEASE)
                return Clutter.EVENT_PROPAGATE;
            const returned = (event.get_flags() & Clutter.EventFlags.FLAG_INPUT_METHOD) !== 0;
            if (!returned && this._inputMethodTakes(event))
                return Clutter.EVENT_PROPAGATE;
            return type === Clutter.EventType.KEY_PRESS ? this._key(event) : this._keyUp(event);
        });
        // The browse buttons come out once the pointer moves, as they do in Tahoe.
        this.connect('motion-event', (_, event) => {
            const [x, y] = event.get_coords();
            const [x0, y0] = this._pointerAtOpen ?? [x, y];
            if (!this._pointerMoved && Math.hypot(x - x0, y - y0) > 3) {
                this._pointerMoved = true;
                this._updateBuds();
            }
            return Clutter.EVENT_PROPAGATE;
        });

        // The column is the bar's own size, so it grows from the bar's top centre; the
        // glass around it overhangs for its buttons and its shadow.
        this._column = new St.Widget({layout_manager: new Clutter.FixedLayout(), width: WIDTH, height: BAR});
        this._column.set_pivot_point(0.5, 0);
        this.add_child(this._column);

        this._buildBar();
        this._buildResults();
    }

    // --- building it ---------------------------------------------------------------------

    _buildBar() {
        this._barGlass = new Glass({
            styleClass: 'gw-bar-glass',
            // Melting together strongly while the buttons travel, so each leaves the bar
            // like a drop, and less as they arrive, so they part into separate circles at
            // rest and pinch off rather than snap apart.
            blend: () => {
                const settled = Math.min(...(this._buttons ?? []).map(b => clamp(b._bud, 0, 1)));
                return BLEND_AT_REST + (BLEND_MOVING - BLEND_AT_REST) * (1 - settled);
            },
            shapes: () => this._barShapes(),
        });
        this._barGlass.set_position(-MARGIN, -MARGIN);
        this._barGlass.setSize(WIDTH + 2 * MARGIN, BAR + 2 * MARGIN);
        this._column.add_child(this._barGlass);

        this._bar = new St.BoxLayout({
            style_class: 'gw-bar',
            reactive: true,
            x: MARGIN,
            y: MARGIN,
            width: WIDTH,
            height: BAR,
        });
        const centred = {y_align: Clutter.ActorAlign.CENTER};
        this._lead = new St.Icon({icon_name: 'edit-find-symbolic', style_class: 'gw-lead', ...centred});
        this._token = new St.Label({style_class: 'gw-token', visible: false, ...centred});
        this._before = new St.BoxLayout({style_class: 'gw-segments', ...centred});
        this._entry = new St.Entry({
            style_class: 'gw-entry',
            hint_text: 'Spotlight Search',
            can_focus: true,
            x_expand: true,
            ...centred,
        });
        this._after = new St.BoxLayout({style_class: 'gw-segments', ...centred});
        for (const child of [this._lead, this._token, this._before, this._entry, this._after])
            this._bar.add_child(child);
        this._barGlass.add_child(this._bar);

        this._text = this._entry.clutter_text;
        this._text.connect('text-changed', () => this._changed());
        this._text.connect('activate', () => this._activate());

        this._buttons = MODES.map((m, i) => {
            const button = new St.Button({
                style_class: 'gw-mode',
                can_focus: false,
                reactive: false,
                opacity: 0,
                width: BUTTON,
                height: BUTTON,
                accessible_name: m.title,
                child: new St.Icon({gicon: gicon(m.icon), style_class: 'gw-mode-icon'}),
            });
            button.set_pivot_point(0.5, 0.5);
            button._mode = m.id;
            button._rest = {
                x: MARGIN + SHORT_BAR + BAR_GAP + i * (BUTTON + BUTTON_GAP),
                y: MARGIN + (BAR - BUTTON) / 2,
            };
            button.set_position(button._rest.x, button._rest.y);
            button.connect('clicked', () => this._setMode(this._mode === m.id ? null : m.id));
            this._barGlass.add_child(button);
            return button;
        });
        this._placeBuds(this._buttons.map(() => 0));
        this._budsOut = false;
    }

    _buildResults() {
        this._resultsGlass = new Glass({
            styleClass: 'gw-results-glass',
            shapes: () => this._clip.height > 0.5
                ? [{x: MARGIN, y: MARGIN, width: WIDTH, height: this._clip.height, radius: 26}]
                : [],
        });
        this._resultsGlass.set_position(-MARGIN, BAR + GAP - MARGIN);
        this._resultsGlass.setSize(WIDTH + 2 * MARGIN, MOST_HEIGHT + 2 * MARGIN);
        this._column.add_child(this._resultsGlass);

        // What is shown is clipped to a height that springs to fit it.
        this._clip = new St.Widget({
            layout_manager: new Clutter.FixedLayout(),
            clip_to_allocation: true,
            reactive: true,
            x: MARGIN,
            y: MARGIN,
            width: WIDTH,
            height: 0,
        });
        this._clip.connect('notify::height', () => this._resultsGlass.refresh());
        this._resultsGlass.add_child(this._clip);

        this._results = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            style_class: 'gw-results',
            width: WIDTH,
        });
        this._clip.add_child(this._results);

        // The chips scroll sideways, their ends fading, when there are more than fit — as
        // Applications' categories are — rather than each being cut short.
        this._chipRow = new St.BoxLayout({style_class: 'gw-chip-row', x_expand: true, visible: false});
        this._chipScroll = new St.ScrollView({
            style_class: 'gw-chip-scroll',
            hscrollbar_policy: St.PolicyType.EXTERNAL,
            vscrollbar_policy: St.PolicyType.NEVER,
            x_expand: true,
        });
        this._chips = new St.Viewport({
            style_class: 'gw-chips',
            layout_manager: new Clutter.BoxLayout({spacing: 6}),
        });
        this._chipScroll.set_child(this._chips);
        this._tools = new St.BoxLayout({style_class: 'gw-tools', y_align: Clutter.ActorAlign.CENTER});
        this._chipRow.add_child(this._chipScroll);
        this._chipRow.add_child(this._tools);
        this._results.add_child(this._chipRow);

        this._scroll = new St.ScrollView({
            style_class: 'gw-scroll',
            hscrollbar_policy: St.PolicyType.NEVER,
            vscrollbar_policy: St.PolicyType.AUTOMATIC,
            overlay_scrollbars: true,
            x_expand: true,
            y_expand: true,
        });
        this._layered = new St.Viewport({layout_manager: new Clutter.FixedLayout()});
        this._highlight = new St.Widget({style_class: 'gw-highlight', opacity: 0});
        this._content = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            style_class: 'gw-list',
            width: WIDTH - 2 * INSET,
        });
        this._layered.add_child(this._highlight);
        this._layered.add_child(this._content);
        this._scroll.set_child(this._layered);
        this._results.add_child(this._scroll);

        this._footer = new St.Label({style_class: 'gw-footer', visible: false});
        this._footer.clutter_text.ellipsize = Pango.EllipsizeMode.MIDDLE;
        this._results.add_child(this._footer);
    }

    // --- opening and closing ----------------------------------------------------------------

    get isOpen() {
        return this.visible;
    }

    toggle() {
        if (this.isOpen)
            this.close();
        else
            this.open();
    }

    /** Opens on the monitor in use, with [query] already typed. */
    open(query = '') {
        if (this.isOpen) {
            this._text.set_text(query || this._text.get_text());
            return;
        }
        const monitor = Main.layoutManager.focusMonitor ?? Main.layoutManager.primaryMonitor;
        this.set_position(monitor.x, monitor.y);
        this.set_size(monitor.width, monitor.height);
        // Where macOS puts it: the bar centred, a little under a quarter of the way down.
        const x = Math.round((monitor.width - WIDTH) / 2);
        const y = Math.round(monitor.height * 0.22);
        this._column.set_position(x, y);
        this._barGlass.alignBackdrop(monitor.x + x - MARGIN, monitor.y + y - MARGIN);
        this._resultsGlass.alignBackdrop(monitor.x + x - MARGIN, monitor.y + y + BAR + GAP - MARGIN);

        this._mode = null;
        this._filter = null;
        this._form = null;
        this._historyAt = -1;
        this._alt = false;
        this._pointerMoved = false;
        const [px, py] = global.get_pointer();
        this._pointerAtOpen = [px, py];
        this._placeBuds(this._buttons.map(() => 0));
        this._budsOut = false;
        this._clip.height = 0;
        this._resultsGlass.opacity = 0;

        Main.uiGroup.set_child_above_sibling(this, null);
        this.show();
        this._grab = Main.pushModal(this, {actionMode: Shell.ActionMode.POPUP});
        this._entry.grab_key_focus();
        this._glasswork?.wake();
        // Glasswork's actions come a moment later, from the app; shown as they arrive.
        this._actions?.refresh().then(changed => {
            if (changed && this.isOpen && !this._form && (this._mode === 'actions' || this._query()))
                this._search();
        });

        this._updateBar();
        this._settingText = true;
        this._text.set_text(query);
        this._settingText = false;
        this._text.set_selection(0, query.length);
        this._changed({now: true});
        this._spring();
    }

    close({then} = {}) {
        if (!this.isOpen)
            return;
        this._cancellable?.cancel();
        if (this._searchId) {
            GLib.source_remove(this._searchId);
            this._searchId = 0;
        }
        if (this._grab) {
            Main.popModal(this._grab);
            this._grab = null;
        }
        this._timeline?.stop();
        this._budTimeline?.stop();
        this._fitTimeline?.stop();
        const done = () => {
            this.hide();
            this._column.set_scale(1, 1);
            this._column.opacity = 255;
            this._settingText = true;
            this._text.set_text('');
            this._settingText = false;
            this._content.destroy_all_children();
            this._rows = [];
            this.emit('closed');
            then?.();
        };
        if (!animations()) {
            done();
            return;
        }
        // Leaves faster than it came, and without the spring.
        this._column.ease({
            opacity: 0,
            scale_x: 0.98,
            scale_y: 0.98,
            duration: CLOSE_MS,
            mode: Clutter.AnimationMode.EASE_IN_QUAD,
            onComplete: done,
        });
    }

    /** The spring it opens on: a fade over its first 120 ms, and growing into place. */
    _spring() {
        this._timeline?.stop();
        if (!animations()) {
            this._column.set_scale(1, 1);
            this._column.opacity = 255;
            return;
        }
        const duration = Math.round(spring.settles(spring.OPEN) * 1000);
        this._timeline = new Clutter.Timeline({actor: this._column, duration});
        const step = ms => {
            const s = 0.94 + 0.06 * spring.progress(ms / 1000, spring.OPEN);
            this._column.set_scale(s, s);
            this._column.opacity = Math.round(255 * Math.min(1, ms / 120));
        };
        this._timeline.connect('new-frame', (_, ms) => step(ms));
        this._timeline.connect('completed', () => step(duration));
        step(0);
        this._timeline.start();
    }

    // --- the browse buttons -----------------------------------------------------------------

    /**
     * Places the buttons [progress] of the way out of the bar, one figure each, and the bar
     * around them. At 0 a button is a small drop at the centre of the bar's rounded end,
     * inside it and unseen; at 1 it is in its place, and the bar has drawn its end in to make
     * room. The bar follows the first button, the one nearest it: it is the first to leave
     * and the last back.
     */
    _placeBuds(progress) {
        const first = clamp(progress[0], 0, 1);
        this._barWidth = WIDTH - (WIDTH - SHORT_BAR) * first;
        this._bar.width = this._barWidth;
        const cap = MARGIN + this._barWidth - BAR / 2;
        this._buttons.forEach((button, i) => {
            const p = progress[i];
            const rest = button._rest.x + BUTTON / 2;
            button.translation_x = (cap - rest) * (1 - p);
            const s = Math.max(0.35 + 0.65 * p, 0.01);
            button.set_scale(s, s);
            button.opacity = Math.round(255 * clamp((p - 0.4) / 0.45, 0, 1));
            button.reactive = p > 0.6;
            button._bud = p;
        });
    }

    /** The glass's shapes: the bar, and each button that is out of it, or on its way. */
    _barShapes() {
        const shapes = [{x: MARGIN, y: MARGIN, width: this._barWidth ?? WIDTH, height: BAR, radius: BAR / 2}];
        for (const button of this._buttons ?? []) {
            if (!(button._bud > 0.001))
                continue;
            const r = (BUTTON / 2) * button.scale_x;
            const cx = button._rest.x + BUTTON / 2 + button.translation_x;
            const cy = button._rest.y + BUTTON / 2;
            shapes.push({x: cx - r, y: cy - r, width: 2 * r, height: 2 * r, radius: r});
        }
        return shapes;
    }

    /** Out while browsing, or once the pointer has moved over an empty bar; in otherwise. */
    _updateBuds() {
        const out = !this._form && (this._mode !== null || (!!this._pointerMoved && !this._query()));
        if (out === this._budsOut)
            return;
        this._budsOut = out;
        this._budTimeline?.stop();
        const from = this._buttons.map(b => b._bud);
        if (!animations()) {
            this._placeBuds(this._buttons.map(() => out ? 1 : 0));
            this._barGlass.refresh();
            return;
        }
        // Out, each leaves a little after the one before it, on a loose spring. In, the far
        // one first, quickly, as if drawn back.
        const last = MODES.length - 1;
        const seconds = out ? spring.settles(spring.BUD, 0.002) + STAGGER * last : 0.18 + 0.03 * last;
        const step = ms => {
            const t = ms / 1000;
            this._placeBuds(this._buttons.map((_, i) => {
                if (out)
                    return from[i] + (1 - from[i]) * spring.progress(t - i * STAGGER, spring.BUD);
                const k = clamp((t - (last - i) * 0.03) / 0.18, 0, 1);
                return from[i] * (1 - k * k);
            }));
            this._barGlass.refresh();
        };
        this._budTimeline = new Clutter.Timeline({actor: this._barGlass, duration: Math.round(seconds * 1000)});
        this._budTimeline.connect('new-frame', (_, ms) => step(ms));
        this._budTimeline.connect('completed', () => step(seconds * 1000));
        this._budTimeline.start();
    }

    // --- modes, filters and forms -----------------------------------------------------------

    _setMode(id) {
        this._mode = id;
        this._filter = id ? 'all' : null;
        this._form = null;
        this._selected = 0;
        this._chosen = false;
        this._chipIds = null;
        this._updateBar();
        this._updateBuds();
        this._search();
    }

    _setFilter(id) {
        this._filter = id;
        this._selected = 0;
        this._chosen = false;
        if (this._mode === 'files')
            this._search();
        else
            this._render();
    }

    /** The next or previous chip, round to the first. Without a mode, round to none. */
    _cycleFilter(back) {
        const ids = this._chipList.map(c => c.id);
        if (!this._mode)
            ids.unshift(null);
        if (ids.length < 2)
            return;
        const at = Math.max(ids.indexOf(this._filter), 0);
        this._setFilter(ids[(at + (back ? ids.length - 1 : 1)) % ids.length]);
    }

    /** Starts filling in [action]'s fields in the bar; what was typed to find it goes. */
    _startForm(action) {
        this._form = {action, values: action.fields.map(() => ''), at: 0};
        this._chipIds = null;
        this._updateBuds();
        this._updateBar();
        this._setText('');
    }

    /** To the next field, or the one before. False when there is none that way. */
    _moveField(by) {
        const form = this._form;
        form.values[form.at] = this._text.get_text();
        const next = form.at + by;
        if (next < 0 || next >= form.action.fields.length)
            return false;
        form.at = next;
        this._updateBar();
        this._setText(form.values[next]);
        return true;
    }

    _leaveForm() {
        this._form = null;
        this._chipIds = null;
        this._updateBar();
        this._setText('');
        this._updateBuds();
    }

    /** The bar: what it leads with, what it asks for, and the fields of an action. */
    _updateBar() {
        const form = this._form;
        const m = modeById(this._mode);
        this._lead.gicon = gicon(form ? this._iconName(form.action) : m?.icon ?? 'edit-find-symbolic');
        if (form || m)
            this._lead.add_style_class_name('gw-lead-active');
        else
            this._lead.remove_style_class_name('gw-lead-active');

        this._token.visible = !!form;
        this._before.destroy_all_children();
        this._after.destroy_all_children();
        if (form) {
            this._token.text = form.action.title;
            form.action.fields.forEach((field, i) => {
                if (i === form.at)
                    return;
                const value = form.values[i];
                const segment = new St.Label({
                    text: value || field.name,
                    style_class: value ? 'gw-segment' : 'gw-segment gw-segment-empty',
                    y_align: Clutter.ActorAlign.CENTER,
                });
                (i < form.at ? this._before : this._after).add_child(segment);
            });
            this._entry.hint_text = form.action.fields[form.at].hint;
        } else {
            this._entry.hint_text = m?.hint ?? 'Spotlight Search';
        }
        for (const button of this._buttons) {
            if (button._mode === this._mode)
                button.add_style_pseudo_class('checked');
            else
                button.remove_style_pseudo_class('checked');
        }
    }

    _iconName(result) {
        const icon = result.icon?.(16);
        const name = icon?.icon_name ?? 'system-run-symbolic';
        icon?.destroy();
        return name;
    }

    // --- typing -----------------------------------------------------------------------------

    _query() {
        return this._text.get_text().trim();
    }

    /** Puts [text] in the field as Spotlight's own doing, not the user's typing. */
    _setText(text) {
        this._settingText = true;
        this._text.set_text(text);
        this._settingText = false;
        this._changed({now: true});
    }

    _changed({now = false} = {}) {
        if (!this._settingText && this._historyAt >= 0 && this._text.get_text() !== this._history[this._historyAt])
            this._historyAt = -1;
        // Nothing typed and nothing being browsed: nothing to narrow, either.
        if (!this._mode && !this._form && !this._text.get_text().trim())
            this._filter = null;
        // "/pdf " and the like narrow Spotlight, and are taken out of what is searched for.
        const filter = this._form ? null : slash(this._text.get_text());
        if (filter) {
            this._mode = filter.mode;
            this._filter = filter.filter ?? 'all';
            this._selected = 0;
            this._chosen = false;
            this._chipIds = null;
            this._updateBar();
            this._settingText = true;
            this._text.set_text(filter.rest);
            this._settingText = false;
            now = true;
        }
        this._updateBuds();
        if (this._searchId) {
            GLib.source_remove(this._searchId);
            this._searchId = 0;
        }
        if (now) {
            this._search();
            return;
        }
        this._searchId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, SEARCH_DELAY_MS, () => {
            this._searchId = 0;
            this._search();
            return GLib.SOURCE_REMOVE;
        });
    }

    // --- searching --------------------------------------------------------------------------

    _search() {
        if (this._searchId) {
            GLib.source_remove(this._searchId);
            this._searchId = 0;
        }
        this._cancellable?.cancel();
        const cancellable = new Gio.Cancellable();
        this._cancellable = cancellable;
        this._chosen = false;
        this._found = [];
        this._scroll.vadjustment.value = 0;
        const query = this._query();

        const take = list => {
            if (cancellable.is_cancelled())
                return;
            this._found.push(...list);
            this._render();
        };
        const ask = promise => promise.then(take).catch(error => {
            if (!error?.matches?.(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                console.debug(`Glasswork Spotlight: a source failed: ${error?.message ?? error}`);
        });

        if (this._form) {
            const {action, values, at} = this._form;
            const filled = values.map((v, i) => i === at ? this._text.get_text() : v);
            if (action.preview) {
                ask(action.preview(filled, cancellable).then(row => row ? [{
                    key: 'form', section: 'form', title: row.title, subtitle: row.subtitle,
                    score: 0, icon: size => action.icon(size), activate: () => this._runForm(),
                }] : []));
            }
            this._render();
            return;
        }

        switch (this._mode) {
        case 'apps':
            this._found = this._apps.all(query);
            break;
        case 'files':
            if (query) {
                ask(this._files.search(query, cancellable, {filter: this._filter, most: 30}));
            } else {
                if (this._filter === 'all' && this._glasswork)
                    ask(this._glasswork.recents(cancellable));
                this._found = this._files.recent({filter: this._filter});
            }
            break;
        case 'actions':
            ask(query ? this._actions.search(query) : Promise.resolve(this._actions.all()));
            break;
        case 'clipboard':
            this._found = this._clipboardResults(query);
            break;
        default:
            if (!query)
                break;
            for (const source of this._sources) {
                if (source.searchEach)
                    source.searchEach(query, cancellable).forEach(ask);
                else
                    ask(source.search(query, cancellable));
            }
        }
        this._render();
    }

    _clipboardResults(query) {
        const now = Math.floor(GLib.get_real_time() / 1000000);
        const q = ranking.normal(query);
        const icons = {text: 'text-x-generic-symbolic', link: 'insert-link-symbolic'};
        return this._clipboard.items
            .filter(item => !q || ranking.normal(item.text ?? (item.uris ?? []).join(' ')).includes(q))
            .map(item => {
                const {title, subtitle} = clip.describe(item, now);
                return {
                    key: `clip:${item.key}`,
                    section: 'clipboard',
                    kind: item.kind,
                    title,
                    subtitle,
                    score: 0,
                    copyable: true,
                    icon: size => {
                        if (item.kind === 'image')
                            return new St.Icon({gicon: Gio.BytesIcon.new(item.data), icon_size: size});
                        if (item.kind === 'files') {
                            const [type] = Gio.content_type_guess(item.uris[0], null);
                            return new St.Icon({gicon: Gio.content_type_get_icon(type), icon_size: size});
                        }
                        return new St.Icon({icon_name: icons[item.kind], icon_size: size});
                    },
                    activate: () => this._clipboard.copy(item),
                };
            });
    }

    // --- arranging what was found ---------------------------------------------------------

    /** The chips, the sections in order, and whether they are a list or a grid. */
    _arrange() {
        const found = this._found;
        const filter = this._filter;
        const by = (list, field) => !filter || filter === 'all' ? list : list.filter(r => r[field] === filter);

        if (this._form) {
            return {chips: [], top: null, layout: 'list',
                sections: found.length ? [{id: 'form', title: this._form.action.title, results: found}] : []};
        }

        switch (this._mode) {
        case 'apps': {
            const present = new Set(found.map(a => a.category));
            const chips = [
                {id: 'all', title: 'All'},
                ...CATEGORIES.filter(c => present.has(c.id)),
                ...present.has('other') ? [{id: 'other', title: 'Other'}] : [],
            ];
            const shown = by(found, 'category');
            const title = this._appsView === 'list'
                ? chips.find(c => c.id === filter && c.id !== 'all')?.title ?? 'Applications'
                : null;
            return {chips, top: null, layout: this._appsView,
                sections: shown.length ? [{id: 'apps', title, results: shown}] : []};
        }
        case 'files': {
            const glasswork = found.filter(r => r.section === 'glasswork');
            const files = found.filter(r => r.section === 'files');
            const sections = [];
            if (glasswork.length)
                sections.push({id: 'glasswork', title: 'Glasswork', results: glasswork});
            if (files.length)
                sections.push({id: 'files', title: this._query() ? 'Files & Folders' : 'Recent Files', results: files});
            return {chips: FILE_FILTERS, top: null, layout: 'list', sections};
        }
        case 'actions': {
            const groups = GROUPS.filter(g => found.some(a => a.group === g));
            const chips = [{id: 'all', title: 'All'}, ...groups.map(g => ({id: g, title: g}))];
            const ordered = this._query() ? [...found].sort((a, b) => b.score - a.score) : found;
            const sections = groups
                .filter(g => !filter || filter === 'all' || filter === g)
                .map(g => ({id: g, title: g, results: ordered.filter(a => a.group === g)}));
            return {chips, top: null, layout: 'list', sections};
        }
        case 'clipboard': {
            const chips = [
                {id: 'all', title: 'All'},
                {id: 'text', title: 'Text'},
                {id: 'link', title: 'Links'},
                {id: 'image', title: 'Images'},
                {id: 'files', title: 'Files'},
            ];
            const shown = by(found, 'kind');
            return {chips, top: null, layout: 'list',
                sections: shown.length ? [{id: 'clipboard', title: null, results: shown}] : []};
        }
        }

        // Everything: the top hit, then a section for each kind, and a chip for each of
        // those kinds to narrow it to just that one.
        const arranged = ranking.arrange(found);
        const chips = arranged.sections
            .filter(s => s.id !== 'web')
            .map(s => ({id: s.id, title: SECTION_TITLES[s.id]}));
        const topSection = arranged.top?.section;
        if (topSection && !chips.some(c => c.id === topSection))
            chips.unshift({id: topSection, title: SECTION_TITLES[topSection]});
        if (filter) {
            const only = found.filter(r => r.section === filter).sort((a, b) => b.score - a.score).slice(0, 20);
            return {chips, top: null, layout: 'list',
                sections: only.length ? [{id: filter, title: SECTION_TITLES[filter], results: only}] : []};
        }
        return {chips, top: arranged.top, layout: 'list', sections: arranged.sections};
    }

    // --- drawing what was found ---------------------------------------------------------

    _render() {
        // What is selected stays selected as results arrive, once the arrow keys or the
        // pointer have chosen it; until then, the first.
        const selectedKey = this._chosen ? this._walk[this._selected]?.key : null;
        const arranged = this._arrange();
        this._arranged = arranged;
        this._walk = ranking.walk(arranged);
        const kept = this._walk.findIndex(r => r.key === selectedKey);
        this._selected = kept >= 0 ? kept : 0;

        this._renderChips(arranged.chips);

        const before = new Set(this._rows.map(row => row.result.key));
        this._content.destroy_all_children();
        this._rows = [];
        this._layout = arranged.layout;

        if (arranged.layout === 'grid') {
            this._renderGrid(arranged.sections[0]?.results ?? [], before);
        } else {
            if (arranged.top)
                this._addRow(arranged.top, {top: true, isNew: !before.has(arranged.top.key)});
            for (const section of arranged.sections) {
                if (section.title)
                    this._content.add_child(new St.Label({text: section.title, style_class: 'gw-section'}));
                for (const result of section.results)
                    this._addRow(result, {isNew: !before.has(result.key)});
            }
        }
        if (!this._rows.length && this._showsSomething()) {
            this._content.add_child(new St.Label({
                text: this._emptyText(),
                style_class: 'gw-empty',
                x_align: Clutter.ActorAlign.CENTER,
            }));
        }

        this._updateFooter();
        this._fit();
        this._moveHighlight(false);
    }

    /** Whether the results show at all: anything typed, a mode, or an action's form. */
    _showsSomething() {
        return !!(this._query() || this._mode || this._form);
    }

    _emptyText() {
        if (this._mode === 'clipboard' && !this._clipboard.enabled)
            return 'Clipboard history is off. Turn it on in Glasswork Spotlight’s settings.';
        if (this._mode === 'clipboard' && !this._query())
            return 'Nothing copied yet';
        if (this._form)
            return this._form.action.fields[this._form.at].hint;
        return 'No Results';
    }

    _renderChips(chips) {
        this._chipList = chips;
        const ids = `${this._mode}:${this._appsView}:${chips.map(c => c.id).join()}`;
        if (ids !== this._chipIds) {
            this._chipIds = ids;
            this._chips.destroy_all_children();
            for (const chip of chips) {
                // Never cut short: the row scrolls instead, and it lays chips out at the
                // least width they will take.
                const label = new St.Label({text: chip.title});
                label.clutter_text.ellipsize = Pango.EllipsizeMode.NONE;
                const button = new St.Button({
                    child: label,
                    style_class: 'gw-chip',
                    can_focus: false,
                    y_align: Clutter.ActorAlign.CENTER,
                });
                button._id = chip.id;
                button.connect('clicked', () => {
                    if (this._filter !== chip.id)
                        this._setFilter(chip.id);
                    else if (!this._mode)
                        this._setFilter(null);
                });
                this._chips.add_child(button);
            }
            this._renderTools();
        }
        for (const button of this._chips.get_children()) {
            if (button._id === this._filter) {
                button.add_style_pseudo_class('checked');
                this._showChip(button);
            } else {
                button.remove_style_pseudo_class('checked');
            }
        }
        const shown = chips.length > 0;
        if (shown !== this._chipRow.visible) {
            this._chipRow.visible = shown;
            if (shown && animations()) {
                this._chipRow.opacity = 0;
                this._chipRow.ease({opacity: 255, duration: 180, mode: Clutter.AnimationMode.EASE_OUT_QUAD});
            }
        }
    }

    /** Scrolls the chips so [chip] is in view, with a little of its neighbours. */
    _showChip(chip) {
        const show = () => {
            const adjustment = this._chipScroll.hadjustment;
            const box = chip.get_allocation_box();
            const page = this._chipScroll.get_allocation_box().get_width();
            if (page <= 0)
                return;
            const value = box.x1 < adjustment.value + 24
                ? box.x1 - 24
                : box.x2 > adjustment.value + page - 24 ? box.x2 - page + 24 : adjustment.value;
            const clamped = Math.max(0, Math.min(value, adjustment.upper - page));
            if (animations())
                adjustment.ease(clamped, {duration: 200, mode: Clutter.AnimationMode.EASE_OUT_QUAD});
            else
                adjustment.value = clamped;
        };
        if (chip.get_allocation_box().get_width() > 0) {
            show();
        } else {
            const id = chip.connect('notify::allocation', () => {
                chip.disconnect(id);
                show();
            });
        }
    }

    /** At the end of the chips: grid or list for Applications, Clear History for Clipboard. */
    _renderTools() {
        this._tools.destroy_all_children();
        const tool = ({icon, label, name, onClick}) => {
            const button = new St.Button({
                style_class: label ? 'gw-tool gw-tool-label' : 'gw-tool',
                can_focus: false,
                accessible_name: name,
            });
            if (label)
                button.label = label;
            else
                button.child = new St.Icon({icon_name: icon, style_class: 'gw-tool-icon'});
            button.connect('clicked', onClick);
            this._tools.add_child(button);
        };
        if (this._mode === 'apps') {
            const grid_ = this._appsView === 'grid';
            tool({
                icon: grid_ ? 'view-list-symbolic' : 'view-grid-symbolic',
                name: grid_ ? 'Show as a list' : 'Show as a grid',
                onClick: () => {
                    this._appsView = grid_ ? 'list' : 'grid';
                    this._render();
                },
            });
        } else if (this._mode === 'clipboard' && this._clipboard.enabled) {
            tool({
                label: 'Clear History',
                name: 'Clear History',
                onClick: () => {
                    this._clipboard.clear();
                    this._search();
                },
            });
        }
    }

    _addRow(result, {top = false, isNew = false}) {
        const index = this._rows.length;
        const row = new St.Button({
            style_class: top ? 'gw-row gw-top' : 'gw-row',
            x_expand: true,
            can_focus: false,
            reactive: true,
            track_hover: true,
        });
        const box = new St.BoxLayout({x_expand: true, style_class: 'gw-row-box'});
        const size = top ? 40 : 28;
        const icon = result.icon?.(size) ?? new St.Icon({icon_name: 'image-missing', icon_size: size});
        icon.add_style_class_name?.('gw-row-icon');
        icon.y_align = Clutter.ActorAlign.CENTER;
        box.add_child(icon);
        const words = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            x_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        });
        const title = new St.Label({text: result.title, style_class: 'gw-title'});
        title.clutter_text.ellipsize = Pango.EllipsizeMode.END;
        words.add_child(title);
        if (result.subtitle) {
            const subtitle = new St.Label({text: result.subtitle, style_class: 'gw-subtitle'});
            subtitle.clutter_text.ellipsize = Pango.EllipsizeMode.END;
            words.add_child(subtitle);
        }
        box.add_child(words);
        if (result.badge)
            box.add_child(new St.Label({text: result.badge, style_class: 'gw-badge', y_align: Clutter.ActorAlign.CENTER}));
        if (result.copyable) {
            // Copy shows on the row that is selected, as in Tahoe.
            const copy = new St.Button({
                label: 'Copy',
                style_class: 'gw-copy',
                can_focus: false,
                y_align: Clutter.ActorAlign.CENTER,
                opacity: 0,
            });
            copy.connect('clicked', () => {
                this._selected = index;
                this._activate();
            });
            box.add_child(copy);
            row._copy = copy;
        }
        row.set_child(box);
        this._wireCell(row, index);
        this._content.add_child(row);
        this._rows.push({actor: row, result});

        // What arrives fades in, a little after what arrived before it.
        if (isNew && animations()) {
            row.opacity = 0;
            row.ease({
                opacity: 255,
                delay: Math.min(index, 8) * 20,
                duration: 160,
                mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            });
        }
    }

    /** Every app, six to a row, as Launchpad had them and Tahoe's Applications has them. */
    _renderGrid(results, before) {
        let line = null;
        results.forEach((result, i) => {
            if (i % COLUMNS === 0) {
                line = new St.BoxLayout({style_class: 'gw-grid-row'});
                this._content.add_child(line);
            }
            const cell = new St.Button({
                style_class: 'gw-cell',
                can_focus: false,
                reactive: true,
                track_hover: true,
                width: CELL,
                height: CELL_HEIGHT,
            });
            const box = new St.BoxLayout({
                orientation: Clutter.Orientation.VERTICAL,
                style_class: 'gw-cell-box',
                x_expand: true,
                y_align: Clutter.ActorAlign.CENTER,
            });
            const icon = result.icon(56);
            icon.x_align = Clutter.ActorAlign.CENTER;
            box.add_child(icon);
            const label = new St.Label({
                text: result.title,
                style_class: 'gw-cell-title',
                x_align: Clutter.ActorAlign.CENTER,
            });
            label.clutter_text.ellipsize = Pango.EllipsizeMode.END;
            box.add_child(label);
            cell.set_child(box);
            this._wireCell(cell, i);
            line.add_child(cell);
            this._rows.push({actor: cell, result});
            if (!before.has(result.key) && animations() && i < 36) {
                cell.opacity = 0;
                cell.set_pivot_point(0.5, 0.5);
                cell.set_scale(0.9, 0.9);
                cell.ease({
                    opacity: 255,
                    scale_x: 1,
                    scale_y: 1,
                    delay: Math.min(i, 24) * 12,
                    duration: 220,
                    mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                });
            }
        });
    }

    _wireCell(actor, index) {
        actor.connect('clicked', () => {
            this._selected = index;
            this._activate();
        });
        actor.connect('notify::hover', () => {
            if (actor.hover && this._selected !== index) {
                this._selected = index;
                this._chosen = true;
                this._moveHighlight(true);
            }
        });
    }

    /** The results spring to the height of what is in them, and away when there is nothing. */
    _fit() {
        const shown = this._showsSomething();
        this._results.height = -1;
        const [, natural] = this._results.get_preferred_height(WIDTH);
        const height = shown ? Math.min(natural, MOST_HEIGHT) : 0;
        this._results.height = Math.max(height, 1);

        this._fitTimeline?.stop();
        const from = this._clip.height;
        const opacity = shown ? 255 : 0;
        if (!animations() || Math.abs(from - height) < 1) {
            this._clip.height = height;
            this._resultsGlass.opacity = opacity;
            return;
        }
        if (this._resultsGlass.opacity !== opacity)
            this._resultsGlass.ease({opacity, duration: 160, mode: Clutter.AnimationMode.EASE_OUT_QUAD});
        const seconds = spring.settles(spring.FIT, 0.002);
        this._fitTimeline = new Clutter.Timeline({actor: this._clip, duration: Math.round(seconds * 1000)});
        const step = ms => {
            this._clip.height = Math.max(from + (height - from) * spring.progress(ms / 1000, spring.FIT), 0);
        };
        this._fitTimeline.connect('new-frame', (_, ms) => step(ms));
        this._fitTimeline.connect('completed', () => {
            this._clip.height = height;
        });
        this._fitTimeline.start();
    }

    /** Where [actor] is inside the scrolled content, from the allocations up to it. */
    _offset(actor) {
        let x = 0;
        let y = 0;
        for (let a = actor; a && a !== this._layered; a = a.get_parent()) {
            const box = a.get_allocation_box();
            x += box.x1;
            y += box.y1;
        }
        return {x, y};
    }

    /** The highlight slides to what is selected, rather than jumping there. */
    _moveHighlight(animate) {
        const entry = this._rows[this._selected];
        for (const [i, row] of this._rows.entries()) {
            if (row.actor._copy)
                row.actor._copy.opacity = i === this._selected ? 255 : 0;
        }
        this._updateFooter();
        if (!entry) {
            this._highlight.opacity = 0;
            return;
        }
        const place = ease => {
            const {x, y} = this._offset(entry.actor);
            const target = {x, y, width: entry.actor.width, height: entry.actor.height, opacity: 255};
            this._highlight.remove_all_transitions();
            if (ease && animations())
                this._highlight.ease({...target, duration: 160, mode: Clutter.AnimationMode.EASE_OUT_QUAD});
            else
                this._highlight.set(target);
            this._scrollTo(y, entry.actor.height);
        };
        // Placed where the row is now, if it has been laid out; and again once it is laid
        // out afresh, when that is still to come — a row is laid out a frame after it is added.
        const laidOut = entry.actor.get_allocation_box().get_height() > 0;
        if (laidOut)
            place(animate);
        if (!laidOut || !entry.actor.has_allocation()) {
            const id = entry.actor.connect('notify::allocation', () => {
                entry.actor.disconnect(id);
                if (this._rows[this._selected] === entry)
                    place(laidOut && animate);
            });
        }
    }

    /**
     * Scrolls [y] to [y + height] into view. Measured by the scroll view's own height, which
     * is final before its rows are laid out, rather than by the adjustment's page, which is
     * only brought up to date after them.
     */
    _scrollTo(y, height) {
        const adjustment = this._scroll.vadjustment;
        const page = this._scroll.get_allocation_box().get_height();
        if (page <= 0)
            return;
        if (y < adjustment.value)
            adjustment.value = y;
        else if (y + height > adjustment.value + page)
            adjustment.value = y + height - page;
    }

    /** Holding Alt shows where the selected file is, at the foot of the results. */
    _updateFooter() {
        const path = this._alt ? this._walk[this._selected]?.path : null;
        const shown = !!path;
        if (shown)
            this._footer.text = path;
        if (shown !== this._footer.visible) {
            this._footer.visible = shown;
            this._fit();
        }
    }

    // --- keys -------------------------------------------------------------------------------

    _key(event) {
        const symbol = event.get_key_symbol();
        const state_ = event.get_state();
        const control = (state_ & Clutter.ModifierType.CONTROL_MASK) !== 0;
        const alt = (state_ & Clutter.ModifierType.MOD1_MASK) !== 0;
        const shift = (state_ & Clutter.ModifierType.SHIFT_MASK) !== 0;
        const superKey = (state_ & (Clutter.ModifierType.SUPER_MASK | Clutter.ModifierType.MOD4_MASK)) !== 0;
        const empty = this._text.get_text() === '';

        // Ctrl+1 to Ctrl+4 (or Super): the browse modes, as Command+1 to 4 are in Tahoe.
        const digit = [Clutter.KEY_1, Clutter.KEY_2, Clutter.KEY_3, Clutter.KEY_4].indexOf(symbol);
        if (digit >= 0 && (control || superKey)) {
            const id = MODES[digit].id;
            this._setMode(this._mode === id ? null : id);
            return Clutter.EVENT_STOP;
        }

        switch (symbol) {
        case Clutter.KEY_Alt_L:
        case Clutter.KEY_Alt_R:
            this._alt = true;
            this._updateFooter();
            return Clutter.EVENT_PROPAGATE;
        case Clutter.KEY_Escape:
            // One step back at a time: what was typed, then the action, then the mode; then away.
            if (!empty)
                this._setText('');
            else if (this._form)
                this._leaveForm();
            else if (this._mode)
                this._setMode(null);
            else
                this.close();
            return Clutter.EVENT_STOP;
        case Clutter.KEY_BackSpace:
            if (!empty || control)
                return Clutter.EVENT_PROPAGATE;
            if (this._form) {
                if (!this._moveField(-1))
                    this._leaveForm();
                return Clutter.EVENT_STOP;
            }
            if (this._mode) {
                this._setMode(null);
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        case Clutter.KEY_space:
            if (superKey) {
                this.close();
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        case Clutter.KEY_Down:
            this._move(this._layout === 'grid' ? 'down' : 1);
            return Clutter.EVENT_STOP;
        case Clutter.KEY_Up:
            if (this._recall())
                return Clutter.EVENT_STOP;
            this._move(this._layout === 'grid' ? 'up' : -1);
            return Clutter.EVENT_STOP;
        case Clutter.KEY_Left:
        case Clutter.KEY_Right: {
            const right = symbol === Clutter.KEY_Right;
            if (control && this._mode) {
                this._cycleFilter(!right);
                return Clutter.EVENT_STOP;
            }
            if (this._layout === 'grid' && !control) {
                this._move(right ? 'right' : 'left');
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        }
        case Clutter.KEY_Tab:
        case Clutter.KEY_ISO_Left_Tab: {
            const back = shift || symbol === Clutter.KEY_ISO_Left_Tab;
            if (this._form) {
                if (this._moveField(back ? -1 : 1))
                    this._search();
                return Clutter.EVENT_STOP;
            }
            const selected = this._walk[this._selected];
            if (!back && selected?.fields) {
                this._startForm(selected);
                return Clutter.EVENT_STOP;
            }
            this._cycleFilter(back);
            return Clutter.EVENT_STOP;
        }
        case Clutter.KEY_Return:
        case Clutter.KEY_KP_Enter:
            if (control && !this._mode && !this._form) {
                this._addAsTask();
                return Clutter.EVENT_STOP;
            }
            this._activate({alternate: alt});
            return Clutter.EVENT_STOP;
        }
        return Clutter.EVENT_PROPAGATE;
    }

    /**
     * Whether the input method will take [event] and send it back: as GNOME's own input
     * method decides (ui/inputMethod.js), when it has an input context and a source, for a
     * key not marked to be ignored, into the field it is focused on.
     */
    _inputMethodTakes(event) {
        const im = Main.inputMethod;
        const IGNORED = 1 << 25; // IBus.ModifierType.IGNORED_MASK
        return !!(im?._context && im?._currentSource) &&
            global.stage.get_key_focus() === this._text &&
            (event.get_state() & IGNORED) === 0;
    }

    _keyUp(event) {
        const symbol = event.get_key_symbol();
        if (symbol === Clutter.KEY_Alt_L || symbol === Clutter.KEY_Alt_R) {
            this._alt = false;
            this._updateFooter();
        }
        return Clutter.EVENT_PROPAGATE;
    }

    /**
     * Up, before anything else is chosen, brings back what was searched for before — each
     * press one further back, as in macOS. True when it did.
     */
    _recall() {
        if (this._form || this._mode || (this._chosen && this._selected > 0))
            return false;
        const text = this._text.get_text();
        const recalling = this._historyAt >= 0 && text === this._history[this._historyAt];
        if (text && !recalling)
            return false;
        const next = history.step(this._history, this._historyAt, 1);
        if (next === null)
            return recalling;
        this._historyAt = next;
        this._setText(this._history[next]);
        this._text.set_cursor_position(-1);
        return true;
    }

    _move(by) {
        if (!this._walk.length)
            return;
        if (typeof by === 'string')
            this._selected = grid.step(this._selected, this._walk.length, COLUMNS, by);
        else
            this._selected = (this._selected + by + this._walk.length) % this._walk.length;
        this._chosen = true;
        this._moveHighlight(true);
    }

    _remember() {
        const query = this._form ? '' : this._query();
        if (!query)
            return;
        this._history = history.remember(this._history, query);
        state.write('history.json', this._history);
    }

    _activate({alternate = false} = {}) {
        if (this._form) {
            this._runForm();
            return;
        }
        const result = this._walk[this._selected];
        if (!result)
            return;
        if (result.fields) {
            this._startForm(result);
            return;
        }
        this._remember();
        const timestamp = global.get_current_time();
        // Closed first, so what opens gets the focus Spotlight had.
        this.close({then: () => result.activate({alternate, timestamp})});
    }

    _runForm() {
        const {action, values, at} = this._form;
        const filled = values.map((v, i) => i === at ? this._text.get_text() : v);
        if (!filled.some(v => v.trim()))
            return;
        this.close({then: () => action.run(filled)});
    }

    /** Ctrl+Return: the line as a Glasswork task, whatever else it matched. */
    _addAsTask() {
        const query = this._query();
        if (!query || !this._glasswork)
            return;
        this._remember();
        this.close({then: () => this._glasswork.add(query)});
    }

    // --- for the tests -----------------------------------------------------------------------

    /** What is on screen, for the tests that drive Spotlight over D-Bus. */
    describe() {
        const round = v => Math.round(v * 100) / 100;
        return {
            open: this.isOpen,
            query: this._text.get_text(),
            hint: this._entry.hint_text,
            mode: this._mode,
            filter: this._filter,
            form: this._form ? {
                action: this._form.action.title,
                field: this._form.action.fields[this._form.at].name,
                values: this._form.values,
            } : null,
            buttons: this._buttons.map(b => round(b._bud)),
            barWidth: Math.round(this._barWidth),
            chips: this._chipList.map(c => c.id === this._filter ? `[${c.title}]` : c.title),
            view: this._layout,
            top: this._arranged?.top?.title ?? null,
            sections: (this._arranged?.sections ?? []).map(s => ({
                title: s.title,
                results: s.results.slice(0, 8).map(r => r.badge ? `${r.title} (${r.badge})` : r.title),
                count: s.results.length,
            })),
            selected: this._walk[this._selected]?.title ?? null,
            selectedSubtitle: this._walk[this._selected]?.subtitle ?? null,
            footer: this._footer.visible ? this._footer.text : null,
            history: this._history.length,
            clipboard: this._clipboard?.items.length ?? 0,
            layout: {
                bar: this._barGlass.describeLayout(),
                results: this._resultsGlass.describeLayout(),
                shown: Math.round(this._clip.height),
                highlight: [this._highlight.x, this._highlight.y, this._highlight.width,
                    this._highlight.height, this._highlight.opacity],
            },
        };
    }

    /** Gone at once, as the extension is turned off: no closing animation on what is going. */
    destroy() {
        this._cancellable?.cancel();
        if (this._searchId) {
            GLib.source_remove(this._searchId);
            this._searchId = 0;
        }
        if (this._grab) {
            Main.popModal(this._grab);
            this._grab = null;
        }
        this._timeline?.stop();
        this._budTimeline?.stop();
        this._fitTimeline?.stop();
        super.destroy();
    }
});
