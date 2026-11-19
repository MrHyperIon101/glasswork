// Actions found by name, and by quick key: a few letters that go straight to one, as Tahoe's
// Spotlight has them — "nt" is a new task. Pure, so it is tested outside the shell.

import {normal, score} from './ranking.js';

/** Each action's quick key, by its key. Nothing that ends the session has one. */
export const QUICK_KEYS = {
    'glasswork:action:new-task': 'nt',
    'glasswork:action:new-note': 'nn',
    'glasswork:action:today': 'td',
    'glasswork:action:upcoming': 'wk',
    'glasswork:action:time-budget': 'tb',
    'system:lock-screen': 'lk',
    'system:open-screenshot-ui': 'ss',
    'system:record-screen': 'rs',
    'spotlight:web': 'ws',
    'spotlight:wifi': 'wf',
    'spotlight:bluetooth': 'bt',
    'spotlight:airplane-mode': 'am',
    'spotlight:night-light': 'nl',
    'spotlight:dark-style': 'ds',
    'spotlight:do-not-disturb': 'dnd',
};

/** Words that say "this computer", which the power actions answer to. */
const COMPUTER = ['computer', 'pc', 'laptop', 'machine', 'system', 'device'];

/**
 * The system's actions as Spotlight shows them, in the order it lists them: Tahoe's names,
 * what each does, and the words people use for it — "turn off pc" is Shut Down. GNOME's own
 * keywords for each are added to these.
 */
export const SYSTEM_ACTIONS = {
    'lock-screen': {title: 'Lock Screen', subtitle: 'Lock this computer',
        keywords: ['lock', 'lock screen', ...COMPUTER]},
    'open-screenshot-ui': {title: 'Take a Screenshot', subtitle: 'The whole screen, a window or part of it',
        keywords: ['screenshot', 'screen shot', 'capture', 'snip', 'print screen']},
    'record-screen': {title: 'Record the Screen', subtitle: 'A video of the screen, a window or part of it',
        keywords: ['screencast', 'screen recording', 'record', 'video', 'capture']},
    'suspend': {title: 'Sleep', subtitle: 'Put this computer to sleep',
        keywords: ['suspend', 'sleep', 'standby', ...COMPUTER]},
    'switch-user': {title: 'Switch User', subtitle: 'Let someone else sign in',
        keywords: ['user', 'account', 'switch account']},
    'logout': {title: 'Log Out', subtitle: 'End this session, closing your apps',
        keywords: ['log out', 'logout', 'log off', 'sign out', 'end session']},
    'restart': {title: 'Restart', subtitle: 'Turn this computer off and on again',
        keywords: ['restart', 'reboot', 'reset', ...COMPUTER]},
    'power-off': {title: 'Shut Down', subtitle: 'Turn this computer off',
        keywords: ['shut down', 'shutdown', 'power off', 'turn off', 'switch off', 'halt', ...COMPUTER]},
};

/** Below a match on the name, above one on a single keyword: every word said found. */
const EVERY_WORD = 650;
const EVERY_WORD_WHOLE = 700;

const BREAKS = /[^\p{L}\p{N}]+/u;

/** Above every other match: typing an action's quick key means that action. */
export const QUICK_KEY_SCORE = 1100;

/** A keyword match counts for less than the name matching. */
const KEYWORD_PENALTY = 150;

/**
 * How well [query] finds [action], or null.
 *
 * @param {string} query
 * @param {{title: string, keywords?: string[], quickKey?: string}} action
 * @returns {number|null}
 */
export function matchAction(query, {title, keywords = [], quickKey}) {
    if (quickKey && normal(query) === quickKey)
        return QUICK_KEY_SCORE;
    const scores = [score(query, title)];
    for (const keyword of keywords) {
        const s = score(query, keyword);
        if (s !== null)
            scores.push(s - KEYWORD_PENALTY);
    }
    // Said in other words: every word of the query is a word of the name or the keywords,
    // in any order — "turn off pc", "wifi off". More when each is a whole word.
    const said = normal(query).split(BREAKS).filter(w => w);
    if (said.length > 1) {
        const known = [title, ...keywords].flatMap(t => normal(t).split(BREAKS)).filter(w => w);
        if (said.every(w => known.includes(w)))
            scores.push(EVERY_WORD_WHOLE);
        else if (said.every(w => known.some(k => k.startsWith(w))))
            scores.push(EVERY_WORD);
    }
    const found = scores.filter(s => s !== null);
    return found.length ? Math.max(...found) : null;
}

const SMALL = new Set(['a', 'an', 'and', 'at', 'for', 'in', 'of', 'on', 'or', 'the', 'to']);

/**
 * [text] in title case, as actions are named on a Mac: "Next 7 days" is "Next 7 Days",
 * "Take a screenshot" "Take a Screenshot".
 */
export function titleCase(text) {
    return (text ?? '').split(' ').map((word, i) =>
        i > 0 && SMALL.has(word.toLowerCase()) ? word.toLowerCase()
            : word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
}

/**
 * An action's fields as one line, in order, the empty ones left out: a new task's "Call mum"
 * and "tomorrow 5pm" are read as "Call mum tomorrow 5pm".
 *
 * @param {string[]} values
 * @returns {string}
 */
export function line(values) {
    return values.map(v => (v ?? '').trim()).filter(v => v).join(' ');
}
