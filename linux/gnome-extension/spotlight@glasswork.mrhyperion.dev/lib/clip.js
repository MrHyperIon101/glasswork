// The clipboard history's pure parts: what an entry is, how it reads in the list, and how
// long it is kept. Tested outside the shell; lib/clipboard.js does the watching.

/** How long entries are kept, by the clipboard-keep setting: Tahoe's three choices. */
export const KEEP = {'30m': 30 * 60, '8h': 8 * 60 * 60, '7d': 7 * 24 * 60 * 60};

export const MOST = 200;

/**
 * Copied text that is a single web or mail address is a link; everything else is text.
 *
 * @param {string} text
 * @returns {'link'|'text'}
 */
export function textKind(text) {
    return /^(https?:\/\/|mailto:|www\.)\S+$/i.test((text ?? '').trim()) ? 'link' : 'text';
}

/**
 * [items] with [item] at the front. Copying what is already in the history moves it up
 * rather than listing it twice.
 *
 * @param {Array<{key: string}>} items
 * @param {{key: string}} item
 * @returns {Array<{key: string}>}
 */
export function push(items, item) {
    return [item, ...items.filter(i => i.key !== item.key)].slice(0, MOST);
}

/** [items] without what is older than [keep] seconds at [now] (both in seconds). */
export function prune(items, now, keep) {
    return items.filter(i => now - i.at <= keep);
}

/** "Just now", "4 min ago", "3 h ago", "Yesterday", "5 days ago". */
export function ago(seconds) {
    if (seconds < 60)
        return 'Just now';
    if (seconds < 60 * 60)
        return `${Math.floor(seconds / 60)} min ago`;
    if (seconds < 24 * 60 * 60)
        return `${Math.floor(seconds / 3600)} h ago`;
    const days = Math.floor(seconds / 86400);
    return days === 1 ? 'Yesterday' : `${days} days ago`;
}

/** How big something is, as Files says it: "812 bytes", "34 KB", "2.1 MB". */
export function size(bytes) {
    if (bytes < 1000)
        return `${bytes} bytes`;
    if (bytes < 1000 * 1000)
        return `${Math.round(bytes / 1000)} KB`;
    return `${(bytes / 1000 / 1000).toFixed(1)} MB`;
}

/**
 * What an entry shows: its first line, and what it is and when it was copied.
 *
 * @param {{kind: string, text?: string, uris?: string[], bytes?: number, at: number}} item
 * @param {number} now seconds
 * @returns {{title: string, subtitle: string}}
 */
export function describe(item, now) {
    const when = ago(now - item.at);
    switch (item.kind) {
    case 'image':
        return {title: 'Image', subtitle: `${size(item.bytes ?? 0)} · ${when}`};
    case 'files': {
        const names = item.uris.map(u => decodeURIComponent(u.replace(/\/+$/, '').split('/').pop()));
        const title = names.length === 1 ? names[0] : `${names[0]} and ${names.length - 1} more`;
        return {title, subtitle: `${names.length === 1 ? 'File' : `${names.length} files`} · ${when}`};
    }
    case 'link':
        return {title: item.text.trim(), subtitle: `Link · ${when}`};
    default: {
        const lines = item.text.split('\n').map(l => l.trim()).filter(l => l);
        const first = lines[0] ?? '';
        const chars = item.text.length;
        const more = lines.length > 1 ? `${lines.length} lines` : `${chars} character${chars === 1 ? '' : 's'}`;
        return {title: first.length > 120 ? `${first.slice(0, 119)}…` : first, subtitle: `Text · ${more} · ${when}`};
    }
    }
}
