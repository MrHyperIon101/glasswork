// Glasswork Spotlight: Spotlight for the whole desktop, on Super+Space.
//
// Apps and system actions, files and folders, every installed search provider, the web,
// and Glasswork's own tasks, notes and projects — ranked together, the best of them first.
// And Glasswork's window turned to frosted glass over the desktop, which only the shell can
// do on Wayland. See docs/architecture.md, "Spotlight".

import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

import {ClipboardHistory} from './lib/clipboard.js';
import {ActionsSource} from './lib/sources/actions.js';
import {AppsSource} from './lib/sources/apps.js';
import {FilesSource} from './lib/sources/files.js';
import {GlassworkSource} from './lib/sources/glasswork.js';
import {ProvidersSource} from './lib/sources/providers.js';
import {WebSource} from './lib/sources/web.js';
import {SpotlightPanel} from './lib/ui/panel.js';
import {WindowGlass} from './lib/window_glass.js';

// Glasswork's Ctrl+K and the search field open this Spotlight, rather than one of its own;
// Describe is what the tests read back.
const INTERFACE = `
<node>
  <interface name="dev.mrhyperion.GlassworkSpotlight">
    <method name="Open"><arg type="s" name="query" direction="in"/></method>
    <method name="Close"/>
    <method name="Describe"><arg type="s" name="state" direction="out"/></method>
  </interface>
</node>`;
const PATH = '/dev/mrhyperion/GlassworkSpotlight';

export default class GlassworkSpotlight extends Extension {
    enable() {
        this._settings = this.getSettings();

        this._glasswork = new GlassworkSource({
            onAdded: text => Main.notify('Glasswork', `Added “${text}”`),
        });
        this._clipboard = new ClipboardHistory(this._settings);
        this._apps = new AppsSource();
        this._files = new FilesSource();
        this._actions = new ActionsSource({
            glasswork: this._glasswork,
            clipboard: this._clipboard,
            settings: this._settings,
        });
        // What everything is searched in when no browse mode is chosen.
        this._sources = [this._apps, this._glasswork, new ProvidersSource(), this._actions];
        if (this._settings.get_boolean('search-files'))
            this._sources.push(this._files);
        if (this._settings.get_boolean('search-web'))
            this._sources.push(new WebSource(this._settings));

        this._panel = new SpotlightPanel({
            sources: this._sources,
            apps: this._apps,
            files: this._files,
            actions: this._actions,
            glasswork: this._glasswork,
            clipboard: this._clipboard,
        });
        Main.uiGroup.add_child(this._panel);

        Main.wm.addKeybinding('open-spotlight', this._settings,
            Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW | Shell.ActionMode.POPUP,
            () => this._panel.toggle());

        this._windowGlass = new WindowGlass(this._settings);

        this._dbus = Gio.DBusExportedObject.wrapJSObject(INTERFACE, {
            Open: query => this._panel.open(query),
            Close: () => this._panel.close(),
            Describe: () => JSON.stringify({
                ...this._panel.describe(),
                frostedWindows: this._windowGlass.count,
            }),
        });
        this._dbus.export(Gio.DBus.session, PATH);
    }

    disable() {
        this._dbus?.unexport();
        this._dbus = null;
        Main.wm.removeKeybinding('open-spotlight');
        this._windowGlass?.destroy();
        this._windowGlass = null;
        this._panel?.destroy();
        this._panel = null;
        for (const source of new Set([...this._sources ?? [], this._files].filter(s => s)))
            source.destroy();
        this._sources = null;
        this._apps = null;
        this._files = null;
        this._actions = null;
        this._clipboard?.destroy();
        this._clipboard = null;
        this._glasswork = null;
        this._settings = null;
    }
}
