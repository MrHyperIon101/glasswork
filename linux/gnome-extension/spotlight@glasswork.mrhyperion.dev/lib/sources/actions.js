// Actions: things to do rather than things to open, as Tahoe's Spotlight has them.
//
// Glasswork's own (New Task, New Note, its places); the system's (Lock Screen, Take a
// Screenshot, Record the Screen, Sleep, Log Out, Restart, Shut Down — each only where the
// system offers it, and the ones that end the session asking first, as GNOME's own do); the
// desktop's controls (Wi-Fi, Bluetooth, Airplane Mode, Night Light, Dark Style, Do Not
// Disturb), each named for what it will do from where things are now; and Spotlight's own.
// Some have a quick key — "nt" is a new task — and some have fields, filled in in the bar.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as SystemActions from 'resource:///org/gnome/shell/misc/systemActions.js';
import * as Screenshot from 'resource:///org/gnome/shell/ui/screenshot.js';

import {QUICK_KEYS, SYSTEM_ACTIONS, line, matchAction} from '../quick_keys.js';

/** The groups Actions lists them under, in order. */
export const GROUPS = ['Glasswork', 'System', 'Controls', 'Spotlight'];

/** A D-Bus service's properties, read as it changes; null until it answers, or if it never does. */
function watch(busType, name, path, iface, cancellable, onReady) {
    Gio.DBusProxy.new_for_bus(busType, Gio.DBusProxyFlags.DO_NOT_AUTO_START, null,
        name, path, iface, cancellable, (_, result) => {
            try {
                onReady(Gio.DBusProxy.new_for_bus_finish(result));
            } catch {
                // Not on this system: its actions are simply not offered.
            }
        });
}

function settingsIfInstalled(schemaId) {
    const schema = Gio.SettingsSchemaSource.get_default()?.lookup(schemaId, true);
    return schema ? new Gio.Settings({settings_schema: schema}) : null;
}

export class ActionsSource {
    constructor({glasswork, clipboard, settings}) {
        this._glasswork = glasswork;
        this._clipboard = clipboard;
        this._settings = settings;
        this._system = SystemActions.getDefault();
        this._interface = new Gio.Settings({schema_id: 'org.gnome.desktop.interface'});
        this._notifications = new Gio.Settings({schema_id: 'org.gnome.desktop.notifications'});
        this._color = settingsIfInstalled('org.gnome.settings-daemon.plugins.color');
        this._fromGlasswork = [];

        this._cancellable = new Gio.Cancellable();
        watch(Gio.BusType.SYSTEM, 'org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager',
            'org.freedesktop.NetworkManager', this._cancellable, proxy => {
                this._network = proxy;
            });
        watch(Gio.BusType.SESSION, 'org.gnome.SettingsDaemon.Rfkill', '/org/gnome/SettingsDaemon/Rfkill',
            'org.gnome.SettingsDaemon.Rfkill', this._cancellable, proxy => {
                this._rfkill = proxy;
            });
    }

    /**
     * Asks Glasswork again what it can do: it may only now have started, or been updated.
     * Resolves true when that is different from what was known.
     */
    async refresh() {
        try {
            const list = (await this._glasswork.actions()).map(action => this._glassworkAction(action));
            const changed = list.map(a => a.key).join() !== this._fromGlasswork.map(a => a.key).join();
            this._fromGlasswork = list;
            return changed;
        } catch {
            return false;
        }
    }

    /** Every action there is, in its group's order. */
    all() {
        return [...this._fromGlasswork, ...this._systemActions(), ...this._controls(), ...this._own()];
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

    _action(key, group, fields) {
        return {
            key,
            section: 'actions',
            group,
            score: 0,
            quickKey: QUICK_KEYS[key],
            badge: QUICK_KEYS[key],
            ...fields,
            icon: size => new St.Icon({icon_name: fields.iconName, icon_size: size}),
        };
    }

    /** The system's, in SYSTEM_ACTIONS' order, each only where the system offers it now. */
    _systemActions() {
        const actions = [];
        for (const [id, named] of Object.entries(SYSTEM_ACTIONS)) {
            let words = named;
            let available;
            let iconName;
            let activate;
            if (id === 'record-screen') {
                available = !!Main.screenshotUI;
                iconName = 'media-record-symbolic';
                activate = () => Screenshot.showScreenRecordingUI();
            } else {
                const known = this._system._actions?.get(id);
                available = !!known?.available;
                iconName = known ? this._system.getIconName(id) : '';
                activate = () => this._system.activateAction(id);
                words = {...words, keywords: [...words.keywords, ...known?.keywords ?? []]};
            }
            if (!available)
                continue;
            actions.push(this._action(`system:${id}`, 'System', {...words, iconName, activate}));
        }
        return actions;
    }

    /** The desktop's switches, each named for what choosing it will do. */
    _controls() {
        const controls = [];
        const toggle = (id, {on, name, keywords, iconName, subtitle, set}) => {
            controls.push(this._action(`spotlight:${id}`, 'Controls', {
                title: `${on ? 'Turn Off' : 'Turn On'} ${name}`,
                subtitle,
                keywords: [name, ...keywords],
                iconName,
                activate: () => set(!on),
            }));
        };

        const wifi = this._network?.get_cached_property('WirelessEnabled')?.unpack();
        if (wifi !== undefined) {
            toggle('wifi', {
                on: wifi, name: 'Wi-Fi', iconName: 'network-wireless-symbolic', subtitle: 'Network',
                keywords: ['wifi', 'wireless', 'internet', 'network'],
                set: on => this._setProperty(this._network, 'WirelessEnabled', on),
            });
        }
        // GNOME turns Bluetooth off by putting it, alone, in airplane mode.
        const bluetoothOff = this._rfkill?.get_cached_property('BluetoothAirplaneMode')?.unpack();
        if (bluetoothOff !== undefined && this._rfkill.get_cached_property('BluetoothHasAirplaneMode')?.unpack()) {
            toggle('bluetooth', {
                on: !bluetoothOff, name: 'Bluetooth', iconName: 'bluetooth-active-symbolic', subtitle: 'Bluetooth',
                keywords: ['bluetooth', 'headphones', 'earbuds', 'wireless'],
                set: on => this._setProperty(this._rfkill, 'BluetoothAirplaneMode', !on),
            });
        }
        const airplane = this._rfkill?.get_cached_property('AirplaneMode')?.unpack();
        if (airplane !== undefined && this._rfkill.get_cached_property('HasAirplaneMode')?.unpack()) {
            toggle('airplane-mode', {
                on: airplane, name: 'Airplane Mode', iconName: 'airplane-mode-symbolic', subtitle: 'Network',
                keywords: ['flight mode', 'airplane', 'aeroplane', 'offline', 'radios'],
                set: on => this._setProperty(this._rfkill, 'AirplaneMode', on),
            });
        }
        if (this._color) {
            toggle('night-light', {
                on: this._color.get_boolean('night-light-enabled'), name: 'Night Light',
                iconName: 'night-light-symbolic', subtitle: 'Displays',
                keywords: ['night shift', 'blue light', 'warm', 'evening'],
                set: on => this._color.set_boolean('night-light-enabled', on),
            });
        }
        toggle('dark-style', {
            on: this._interface.get_string('color-scheme') === 'prefer-dark', name: 'Dark Style',
            iconName: 'weather-clear-night-symbolic', subtitle: 'Appearance',
            keywords: ['dark mode', 'light mode', 'appearance', 'theme'],
            set: on => this._interface.set_string('color-scheme', on ? 'prefer-dark' : 'default'),
        });
        toggle('do-not-disturb', {
            on: !this._notifications.get_boolean('show-banners'), name: 'Do Not Disturb',
            iconName: 'notifications-disabled-symbolic', subtitle: 'Notifications',
            keywords: ['notifications', 'focus', 'quiet', 'silence', 'dnd'],
            set: on => this._notifications.set_boolean('show-banners', !on),
        });
        return controls;
    }

    /** Spotlight's own. */
    _own() {
        const own = [];
        if (this._settings.get_boolean('search-web')) {
            const address = this._settings.get_string('web-search');
            const host = (GLib.Uri.parse(address.replace('%s', ''), GLib.UriFlags.NONE)?.get_host() ?? '')
                .replace(/^www\./, '');
            const search = words => Gio.AppInfo.launch_default_for_uri(
                address.replace('%s', encodeURIComponent(words)), global.create_app_launch_context(0, -1));
            own.push(this._action('spotlight:web', 'Spotlight', {
                title: 'Search the Web',
                subtitle: host,
                keywords: ['internet', 'browser', 'google', 'look up'],
                iconName: 'web-browser-symbolic',
                fields: [{name: 'Search', hint: 'What to search the web for'}],
                preview: values => Promise.resolve(line(values)
                    ? {title: `Search the web for “${line(values)}”`, subtitle: host}
                    : null),
                run: values => line(values) && search(line(values)),
            }));
        }
        if (this._clipboard?.enabled) {
            own.push(this._action('spotlight:clipboard-clear', 'Spotlight', {
                title: 'Clear Clipboard History',
                subtitle: 'Forget everything copied',
                keywords: ['clipboard', 'forget', 'history'],
                iconName: 'edit-clear-all-symbolic',
                activate: () => this._clipboard.clear(),
            }));
        }
        return own;
    }

    _setProperty(proxy, name, value) {
        proxy.call('org.freedesktop.DBus.Properties.Set',
            new GLib.Variant('(ssv)', [proxy.g_interface_name, name, new GLib.Variant('b', value)]),
            Gio.DBusCallFlags.NONE, -1, null, (source, result) => {
                try {
                    source.call_finish(result);
                } catch (error) {
                    console.warn(`Glasswork Spotlight: could not set ${name}: ${error.message}`);
                }
            });
    }

    destroy() {
        this._cancellable.cancel();
        this._network = null;
        this._rfkill = null;
    }
}
