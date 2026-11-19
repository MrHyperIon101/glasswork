// Glasswork Spotlight's settings: each says what it does.

import Adw from 'gi://Adw';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';

import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class GlassworkSpotlightPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();
        const page = new Adw.PreferencesPage();
        window.add(page);

        const opening = new Adw.PreferencesGroup({title: 'Opening Spotlight'});
        page.add(opening);
        const shortcut = new Adw.EntryRow({
            title: 'Shortcut',
            text: settings.get_strv('open-spotlight')[0] ?? '',
            show_apply_button: true,
        });
        shortcut.connect('apply', () => {
            const [ok] = Gtk.accelerator_parse(shortcut.text);
            if (ok)
                settings.set_strv('open-spotlight', [shortcut.text]);
            else
                shortcut.text = settings.get_strv('open-spotlight')[0] ?? '';
        });
        opening.add(shortcut);

        const finding = new Adw.PreferencesGroup({
            title: 'What it finds',
            description: 'Apps, system actions, Glasswork and every search provider you have ' +
                'turned on in Settings are always searched.',
        });
        page.add(finding);
        finding.add(this._switch(settings, 'search-files', 'Files and folders',
            "From GNOME's own index of your files. Takes effect the next time the extension starts."));
        finding.add(this._switch(settings, 'search-web', 'Search the web',
            '"Search the web for …", last in every list.'));
        const web = new Adw.EntryRow({
            title: 'Web search address (%s is the words)',
            text: settings.get_string('web-search'),
            show_apply_button: true,
        });
        web.connect('apply', () => {
            if (web.text.includes('%s'))
                settings.set_string('web-search', web.text);
            else
                web.text = settings.get_string('web-search');
        });
        finding.add(web);

        const clipboard = new Adw.PreferencesGroup({
            title: 'Clipboard',
            description: 'What you copy, listed in Spotlight’s Clipboard (Ctrl+4) to copy again.',
        });
        page.add(clipboard);
        clipboard.add(this._switch(settings, 'clipboard-history', 'Clipboard history',
            'Held in memory only — never written to disk — and forgotten when you log out. ' +
            'Nothing a password manager marks as secret is kept. Off, the history is cleared.'));
        const keeps = [['30m', '30 minutes'], ['8h', '8 hours'], ['7d', '7 days']];
        const keep = new Adw.ComboRow({
            title: 'Keep for',
            subtitle: 'Older entries are forgotten. Shorter keeps less of what you copied around.',
            model: Gtk.StringList.new(keeps.map(([, label]) => label)),
            selected: Math.max(keeps.findIndex(([id]) => id === settings.get_string('clipboard-keep')), 0),
        });
        keep.connect('notify::selected', () => settings.set_string('clipboard-keep', keeps[keep.selected][0]));
        settings.bind('clipboard-history', keep, 'sensitive', Gio.SettingsBindFlags.GET);
        clipboard.add(keep);

        const glass = new Adw.PreferencesGroup({title: 'Glasswork'});
        page.add(glass);
        glass.add(this._switch(settings, 'glass-window', 'Frosted window',
            "Blurs the desktop behind Glasswork's window and lets it show through, frosted. " +
            'Off, Glasswork draws its own backdrop instead.'));
    }

    _switch(settings, key, title, subtitle) {
        const row = new Adw.SwitchRow({title, subtitle});
        settings.bind(key, row, 'active', Gio.SettingsBindFlags.DEFAULT);
        return row;
    }
}
