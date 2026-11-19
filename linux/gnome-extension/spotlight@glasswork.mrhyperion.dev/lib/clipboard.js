// The clipboard history Spotlight's Clipboard lists: text, links, images and files, as they
// are copied, for as long as the setting keeps them — and never past logging out, since it
// is only ever held in memory. Nothing a password manager marks as secret is kept.

import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import St from 'gi://St';

import * as clip from './clip.js';

/** What password managers mark a copied secret with. */
const SECRET = new Set(['x-kde-passwordManagerHint', 'application/x-kde-passwordManagerHint']);
const FILES = 'text/uri-list';
const IMAGES = ['image/png', 'image/jpeg', 'image/webp'];
const TEXT = ['text/plain;charset=utf-8', 'UTF8_STRING', 'text/plain', 'STRING', 'TEXT'];
const MOST_IMAGE = 8 * 1000 * 1000;
const MOST_TEXT = 200 * 1000;

export class ClipboardHistory {
    constructor(settings) {
        this._settings = settings;
        this._items = [];
        this._clipboard = St.Clipboard.get_default();
        this._selection = global.display.get_selection();
        this._ownerId = this._selection.connect('owner-changed', (_, type) => {
            if (type === Meta.SelectionType.SELECTION_CLIPBOARD)
                this._capture();
        });
        this._settingId = settings.connect('changed::clipboard-history', () => {
            if (!this.enabled)
                this.clear();
        });
    }

    get enabled() {
        return this._settings.get_boolean('clipboard-history');
    }

    /** What is kept, newest first. */
    get items() {
        const keep = clip.KEEP[this._settings.get_string('clipboard-keep')] ?? clip.KEEP['8h'];
        this._items = clip.prune(this._items, this._now(), keep);
        return this._items;
    }

    _now() {
        return Math.floor(GLib.get_real_time() / 1000000);
    }

    _keep(item) {
        this._items = clip.push(this._items, {...item, at: this._now()});
    }

    _capture() {
        if (!this.enabled)
            return;
        const types = this._clipboard.get_mimetypes(St.ClipboardType.CLIPBOARD);
        if (types.some(t => SECRET.has(t)))
            return;

        if (types.includes(FILES)) {
            this._clipboard.get_content(St.ClipboardType.CLIPBOARD, FILES, (_, bytes) => {
                const text = bytes ? new TextDecoder().decode(bytes.get_data()) : '';
                const uris = text.split(/\r?\n/).map(l => l.trim()).filter(l => l && !l.startsWith('#'));
                if (uris.length)
                    this._keep({kind: 'files', key: `files:${uris.join(' ')}`, uris});
            });
            return;
        }
        const image = IMAGES.find(t => types.includes(t));
        if (image) {
            this._clipboard.get_content(St.ClipboardType.CLIPBOARD, image, (_, bytes) => {
                const size = bytes?.get_size() ?? 0;
                if (!size || size > MOST_IMAGE)
                    return;
                const sum = GLib.compute_checksum_for_bytes(GLib.ChecksumType.SHA1, bytes);
                this._keep({kind: 'image', key: `image:${sum}`, mimetype: image, data: bytes, bytes: size});
            });
            return;
        }
        if (types.some(t => TEXT.includes(t) || t.startsWith('text/'))) {
            this._clipboard.get_text(St.ClipboardType.CLIPBOARD, (_, text) => {
                if (!text?.trim() || text.length > MOST_TEXT)
                    return;
                this._keep({kind: clip.textKind(text), key: `text:${text}`, text});
            });
        }
    }

    /** Puts [item] back on the clipboard, to be pasted. */
    copy(item) {
        const board = St.ClipboardType.CLIPBOARD;
        switch (item.kind) {
        case 'image':
            this._clipboard.set_content(board, item.mimetype, item.data);
            break;
        case 'files':
            this._clipboard.set_content(board, FILES, new GLib.Bytes(new TextEncoder().encode(item.uris.join('\r\n'))));
            break;
        default:
            this._clipboard.set_text(board, item.text);
        }
    }

    clear() {
        this._items = [];
    }

    destroy() {
        this._selection.disconnect(this._ownerId);
        this._settings.disconnect(this._settingId);
        this._items = [];
    }
}
