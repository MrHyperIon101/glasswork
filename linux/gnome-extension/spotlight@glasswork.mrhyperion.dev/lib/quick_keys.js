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
    'spotlight:web': 'ws',
    'spotlight:dark-style': 'ds',
    'spotlight:do-not-disturb': 'dnd',
};

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
    const found = scores.filter(s => s !== null);
    return found.length ? Math.max(...found) : null;
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
