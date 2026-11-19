// What was searched for before, newest first, for the Up arrow to bring back as macOS's
// Spotlight does. Pure, so it is tested outside the shell; the extension keeps the list in
// the user's state directory.

export const MOST = 30;

/**
 * [list] with [query] at its front, once: searching for something again moves it up rather
 * than listing it twice.
 *
 * @param {string[]} list
 * @param {string} query
 * @returns {string[]}
 */
export function remember(list, query) {
    const q = (query ?? '').trim();
    if (!q)
        return list;
    return [q, ...list.filter(item => item !== q)].slice(0, MOST);
}

/**
 * Where the Up and Down arrows go in [list] from [at] (-1 is the line being typed), or null
 * when there is nowhere further to go.
 *
 * @param {string[]} list
 * @param {number} at
 * @param {number} by +1 for older (Up), -1 for newer (Down)
 * @returns {number|null}
 */
export function step(list, at, by) {
    const next = at + by;
    if (next < -1 || next >= list.length)
        return null;
    return next;
}
