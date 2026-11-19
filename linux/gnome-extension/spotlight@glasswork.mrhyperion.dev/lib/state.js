// What Spotlight keeps between sessions — only the searches the Up arrow brings back — in
// the user's state directory, readable by the user alone.

import GLib from 'gi://GLib';

const DIRECTORY = GLib.build_filenamev([GLib.get_user_state_dir(), 'glasswork-spotlight']);

export function read(name, fallback) {
    try {
        const [, bytes] = GLib.file_get_contents(GLib.build_filenamev([DIRECTORY, name]));
        return JSON.parse(new TextDecoder().decode(bytes));
    } catch {
        return fallback;
    }
}

export function write(name, value) {
    try {
        GLib.mkdir_with_parents(DIRECTORY, 0o700);
        GLib.file_set_contents_full(GLib.build_filenamev([DIRECTORY, name]),
            JSON.stringify(value), GLib.FileSetContentsFlags.CONSISTENT, 0o600);
    } catch (error) {
        console.warn(`Glasswork Spotlight: could not save ${name}: ${error.message}`);
    }
}

