// The last line of every list: the words sent to the web, in the default browser.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

export class WebSource {
    constructor(settings) {
        this._settings = settings;
    }

    async search(query) {
        const address = this._settings.get_string('web-search');
        const host = GLib.Uri.parse(address.replace('%s', ''), GLib.UriFlags.NONE)?.get_host() ?? '';
        return [{
            key: 'web',
            section: 'web',
            title: `Search the web for “${query}”`,
            subtitle: host.replace(/^www\./, ''),
            score: 1,
            icon: size => new St.Icon({icon_name: 'web-browser-symbolic', icon_size: size}),
            activate: () => Gio.AppInfo.launch_default_for_uri(
                address.replace('%s', encodeURIComponent(query)),
                global.create_app_launch_context(0, -1)),
        }];
    }

    destroy() {}
}
