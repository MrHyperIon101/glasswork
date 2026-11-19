// Files and folders: found in GNOME's own index (LocalSearch), ranked by how well the name
// matches and then by how recently it changed; and, before anything is typed, the files
// opened lately — the same Recent list Files shows. Enter opens one; Alt+Enter shows it in
// Files, and holding Alt shows where it is.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';
import Tsparql from 'gi://Tsparql?version=3.0';

import {kindOf, passes} from '../file_kinds.js';
import {normal, score} from '../ranking.js';

Gio._promisify(Tsparql.SparqlConnection, 'bus_new_async', 'bus_new_finish');
Gio._promisify(Tsparql.SparqlStatement.prototype, 'execute_async', 'execute_finish');
Gio._promisify(Tsparql.SparqlCursor.prototype, 'next_async', 'next_finish');

const QUERY = `
SELECT ?url ?name ?modified ?folder WHERE {
  ?file a nfo:FileDataObject ;
        nie:url ?url ;
        nfo:fileName ?name ;
        fts:match ~words .
  OPTIONAL { ?file nfo:fileLastModified ?modified }
  BIND (EXISTS { ?file a nfo:Folder } AS ?folder)
}
ORDER BY DESC(?modified)
LIMIT 120`;

const DAY = 24 * 60 * 60;

export class FilesSource {
    constructor() {
        this._home = GLib.get_home_dir();
        this._statement = null;
    }

    async _connect(cancellable) {
        if (this._statement)
            return this._statement;
        const connection = await Tsparql.SparqlConnection.bus_new_async(
            'org.freedesktop.LocalSearch3', null, null, cancellable);
        this._statement = connection.query_statement(QUERY, cancellable);
        return this._statement;
    }

    /** Files whose names match [query], of the kinds [filter] lets through. */
    async search(query, cancellable, {filter = 'all', most = 12} = {}) {
        // Whole words, each as a prefix: what full-text search can match, and nothing it
        // would read as syntax.
        const words = normal(query).split(/[^\p{L}\p{N}]+/u).filter(w => w);
        if (!words.length)
            return [];

        const statement = await this._connect(cancellable);
        statement.bind_string('words', words.map(w => `${w}*`).join(' '));
        const cursor = await statement.execute_async(cancellable);
        const now = GLib.DateTime.new_now_local().to_unix();

        const found = new Map();
        while (await cursor.next_async(cancellable)) {
            const url = cursor.get_string(0)[0];
            if (found.has(url))
                continue;
            const name = cursor.get_string(1)[0];
            const path = Gio.File.new_for_uri(url).get_path();
            // Nothing hidden, and nothing that only matched inside its folder's name.
            if (!path || this._hidden(path))
                continue;
            const matched = score(query, name);
            if (matched === null)
                continue;
            const folder = cursor.get_boolean(3);
            const kind = kindOf(folder ? null : Gio.content_type_guess(name, null)[0], folder);
            if (!passes(filter, kind))
                continue;
            const modified = cursor.is_bound(2)
                ? GLib.DateTime.new_from_iso8601(cursor.get_string(2)[0], null)?.to_unix() ?? 0
                : 0;
            const age = now - modified;
            found.set(url, {
                url, name, path, folder, kind, modified,
                score: matched + (age < DAY ? 40 : age < 7 * DAY ? 20 : 0),
            });
        }
        cursor.close();
        return [...found.values()]
            .sort((a, b) => b.score - a.score)
            .slice(0, most)
            .map(file => this._result(file));
    }

    /**
     * The files opened lately, newest first: GNOME's own list of recent files, which every
     * app adds to as it opens one. Only those still there, and of the kinds [filter] lets
     * through.
     */
    recent({filter = 'all', most = 30} = {}) {
        const list = new GLib.BookmarkFile();
        try {
            list.load_from_file(GLib.build_filenamev([GLib.get_user_data_dir(), 'recently-used.xbel']));
        } catch {
            return [];
        }
        const uris = list.get_uris();
        const dated = [];
        for (const url of uris ?? []) {
            if (!url.startsWith('file://'))
                continue;
            const when = list.get_visited_date_time(url) ?? list.get_modified_date_time(url);
            dated.push({url, at: when?.to_unix() ?? 0, type: list.get_mime_type(url)});
        }
        dated.sort((a, b) => b.at - a.at);

        const found = [];
        for (const {url, at, type} of dated) {
            const file = Gio.File.new_for_uri(url);
            const path = file.get_path();
            if (!path || this._hidden(path) || !file.query_exists(null))
                continue;
            const folder = type === 'inode/directory';
            const kind = kindOf(type, folder);
            if (!passes(filter, kind))
                continue;
            found.push(this._result({url, name: file.get_basename(), path, folder, kind, modified: at, score: 0}));
            if (found.length >= most)
                break;
        }
        return found;
    }

    _hidden(path) {
        return path.split('/').some(part => part.startsWith('.'));
    }

    _result(file) {
        return {
            key: `file:${file.url}`,
            section: 'files',
            title: file.name,
            subtitle: this._where(file.path),
            path: file.path,
            kind: file.kind,
            score: file.score,
            icon: size => new St.Icon({gicon: this._icon(file), icon_size: size}),
            activate: ({alternate} = {}) => alternate ? this._showInFiles(file.url) : this._open(file.url),
        };
    }

    _where(path) {
        const folder = GLib.path_get_dirname(path);
        return folder.startsWith(this._home) ? `~${folder.slice(this._home.length)}` : folder;
    }

    _icon(file) {
        if (file.folder)
            return Gio.ThemedIcon.new('folder');
        const [type] = Gio.content_type_guess(file.name, null);
        return Gio.content_type_get_icon(type);
    }

    _open(url) {
        Gio.AppInfo.launch_default_for_uri(url, global.create_app_launch_context(0, -1));
    }

    _showInFiles(url) {
        Gio.DBus.session.call(
            'org.freedesktop.FileManager1', '/org/freedesktop/FileManager1',
            'org.freedesktop.FileManager1', 'ShowItems',
            new GLib.Variant('(ass)', [[url], '']), null,
            Gio.DBusCallFlags.NONE, -1, null, null);
    }

    destroy() {
        this._statement = null;
    }
}
