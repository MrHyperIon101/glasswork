// Actions: things to do rather than things to open, as Tahoe's Spotlight has them. Glasswork's
// own (New task, New note, its places), the system's (Lock Screen, Take a Screenshot, Power
// Off and the rest, as the overview offers them) and a few of Spotlight's (search the web,
// Dark Style, Do Not Disturb, clearing the clipboard history). Some have a quick key — "nt"
// is a new task — and some have fields, filled in in the bar itself, Tab moving between them.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import * as SystemActions from 'resource:///org/gnome/shell/misc/systemActions.js';

import {QUICK_KEYS, line, matchAction} from '../quick_keys.js';

/** The system's actions, in the order Actions lists them; each only where it is available. */
const SYSTEM = ['lock-screen', 'open-screenshot-ui', 'suspend', 'switch-user', 'logout', 'restart', 'power-off'];

/** The groups Actions lists them under, in order. */
export const GROUPS = ['Glasswork', 'System', 'Desktop'];

export class ActionsSource {
    constructor({glasswork, clipboard, settings}) {
        this._glasswork = glasswork;
        this._clipboard = clipboard;
        this._settings = settings;
        this._system = SystemActions.getDefault();
        this._interface = new Gio.Settings({schema_id: 'org.gnome.desktop.interface'});
        this._notifications = new Gio.Settings({schema_id: 'org.gnome.desktop.notifications'});
        this._fromGlasswork = [];
    }

    /** Asks Glasswork again what it can do: it may only now have started, or been updated. */
    refresh() {
        this._glasswork?.actions()
            .then(list => {
                this._fromGlasswork = list.map(action => this._glassworkAction(action));
            })
            .catch(() => {});
    }

    /** Every action there is, in its group's order. */
    all() {
        return [...this._fromGlasswork, ...this._systemActions(), ...this._own()];
    }

    async search(query) {
        const found = [];
        for (const action of this.all()) {
            const s = matchAction(query, action);
            if (s !== null)
                found.push({...action, score: s});
        }
        return found;
    }

    _glassworkAction(action) {
        const quickKey = QUICK_KEYS[action.key];
        const result = {...action, section: 'actions', group: 'Glasswork', quickKey, badge: quickKey};
        if (action.key === 'glasswork:action:new-task') {
            // Filled in in the bar: what to do, then optionally when. Read as one line, as the
            // composer reads one, so "Call mum" and "tomorrow 5pm" is due tomorrow at five.
            result.fields = [
                {name: 'Task', hint: 'What to do'},
                {name: 'When', hint: 'When — tomorrow 5pm, Friday, in 3 days'},
            ];
            result.preview = async (values, cancellable) => {
                const previewed = await this._glasswork.preview(line(values), cancellable);
                if (!previewed?.title)
                    return null;
                const read = (previewed.chips ?? []).join(' · ');
                return {
                    title: `Add “${previewed.title}”`,
                    subtitle: [read, previewed.sentence].filter(s => s).join(' — '),
                };
            };
            result.run = values => this._glasswork.add(line(values));
        }
        return result;
    }

    _systemActions() {
        const actions = [];
        for (const id of SYSTEM) {
            const known = this._system._actions?.get(id);
            if (!known?.available)
                continue;
            const key = `system:${id}`;
            actions.push({
                key,
                section: 'actions',
                group: 'System',
                title: this._system.getName(id),
                subtitle: 'System',
                keywords: known.keywords ?? [],
                quickKey: QUICK_KEYS[key],
                badge: QUICK_KEYS[key],
                score: 0,
                icon: size => new St.Icon({icon_name: this._system.getIconName(id), icon_size: size}),
                activate: () => this._system.activateAction(id),
            });
        }
        return actions;
    }

    _own() {
        const own = [];
        const add = (id, fields) => {
            const key = `spotlight:${id}`;
            own.push({key, section: 'actions', group: 'Desktop', score: 0, quickKey: QUICK_KEYS[key],
                badge: QUICK_KEYS[key], ...fields});
        };

        if (this._settings.get_boolean('search-web')) {
            const address = this._settings.get_string('web-search');
            const host = GLib.Uri.parse(address.replace('%s', ''), GLib.UriFlags.NONE)?.get_host() ?? '';
            const search = words => Gio.AppInfo.launch_default_for_uri(
                address.replace('%s', encodeURIComponent(words)), global.create_app_launch_context(0, -1));
            add('web', {
                title: 'Search the Web',
                subtitle: host.replace(/^www\./, ''),
                keywords: ['internet', 'browser', 'google', 'look up'],
                icon: size => new St.Icon({icon_name: 'web-browser-symbolic', icon_size: size}),
                fields: [{name: 'Search', hint: 'What to search the web for'}],
                preview: values => Promise.resolve(line(values)
                    ? {title: `Search the web for “${line(values)}”`, subtitle: host.replace(/^www\./, '')}
                    : null),
                run: values => line(values) && search(line(values)),
            });
        }

        const dark = this._interface.get_string('color-scheme') === 'prefer-dark';
        add('dark-style', {
            title: dark ? 'Turn Off Dark Style' : 'Turn On Dark Style',
            subtitle: 'Appearance',
            keywords: ['dark mode', 'light mode', 'appearance', 'theme', 'night'],
            icon: size => new St.Icon({icon_name: 'weather-clear-night-symbolic', icon_size: size}),
            activate: () => this._interface.set_string('color-scheme', dark ? 'default' : 'prefer-dark'),
        });

        const quiet = !this._notifications.get_boolean('show-banners');
        add('do-not-disturb', {
            title: quiet ? 'Turn Off Do Not Disturb' : 'Turn On Do Not Disturb',
            subtitle: 'Notifications',
            keywords: ['notifications', 'focus', 'quiet', 'silence', 'dnd'],
            icon: size => new St.Icon({icon_name: 'notifications-disabled-symbolic', icon_size: size}),
            activate: () => this._notifications.set_boolean('show-banners', quiet),
        });

        if (this._clipboard?.enabled) {
            add('clipboard-clear', {
                title: 'Clear Clipboard History',
                subtitle: 'Spotlight',
                keywords: ['clipboard', 'forget', 'history'],
                icon: size => new St.Icon({icon_name: 'edit-clear-all-symbolic', icon_size: size}),
                activate: () => this._clipboard.clear(),
            });
        }
        return own;
    }

    destroy() {}
}
