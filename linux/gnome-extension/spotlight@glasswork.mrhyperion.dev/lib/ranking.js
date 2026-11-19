// How Spotlight orders what it finds. Pure, so it is tested outside the shell.
//
// Each source scores its own results the same way — the whole name, then the name starting
// with the query, then a word in it, then every word of the query, then anywhere, then its
// letters in order — so results from different sources compare, and the best of them all
// is the top hit. The scale is the one Glasswork's own index uses
// (lib/search/spotlight_index.dart), so its results sit among the rest at their true rank.

/** The order sections appear in, below the top hit, and how many each shows. */
export const SECTIONS = [
    {id: 'glasswork', title: 'Glasswork', most: 5},
    {id: 'apps', title: 'Applications', most: 6},
    {id: 'files', title: 'Files & Folders', most: 5},
    {id: 'settings', title: 'Settings', most: 4},
    {id: 'providers', title: 'Suggestions', most: 4},
    {id: 'actions', title: 'Actions', most: 3},
    {id: 'web', title: 'Web', most: 1},
];

/** Below this, a result is listed but never the top hit: it matched, just not well. */
export const TOP_HIT_FROM = 600;

const BREAKS = /[^\p{L}\p{N}]+/u;
const JOINS = /[^\p{L}\p{N}]+/gu;

/** Lower case, single spaces, no accents: "Café  Notes" and "cafe notes" are the same. */
export function normal(text) {
    return (text ?? '')
        .normalize('NFD')
        .replace(/\p{M}/gu, '')
        .toLowerCase()
        .replace(/\s+/g, ' ')
        .trim();
}

/**
 * How well [query] matches [text], or null when it does not.
 *
 * @param {string} query
 * @param {string} text
 * @returns {number|null}
 */
export function score(query, text) {
    const q = normal(query);
    const t = normal(text);
    if (!q || !t)
        return null;
    if (t === q)
        return 1000;
    // Shorter names first among equals: "Files" before "Files and Folders" for "files".
    const shortness = -0.5 * Math.min(Math.max(t.length - q.length, 0), 100);
    if (t.startsWith(q))
        return 900 + shortness;
    // The same letters, written together or apart: "wifi" is "Wi-Fi", "app store" "AppStore".
    const joinedQ = q.replace(JOINS, '');
    const joinedT = t.replace(JOINS, '');
    if (joinedQ && (joinedQ !== q || joinedT !== t)) {
        if (joinedT === joinedQ)
            return 950;
        if (joinedT.startsWith(joinedQ))
            return 850 + shortness;
    }
    const words = t.split(BREAKS).filter(w => w);
    if (words.some(w => w.startsWith(q)))
        return 700 + shortness;
    const parts = q.split(' ').filter(p => p);
    if (parts.length > 1 && parts.every(p => words.some(w => w.startsWith(p))))
        return 600 + shortness;
    if (t.includes(q))
        return 500 + shortness;
    // Its letters in order, fewer gaps better: "gwk" finds "Glasswork".
    if (q.length < 2)
        return null;
    let at = 0;
    let gaps = 0;
    let last = -1;
    for (const char of q.replace(/ /g, '')) {
        const found = t.indexOf(char, at);
        if (found < 0)
            return null;
        if (last >= 0 && found !== last + 1)
            gaps++;
        last = found;
        at = found + 1;
    }
    return 300 - 8 * gaps + shortness;
}

/**
 * The best of [results] across every source, if one is good enough, and the rest grouped
 * into sections in order, each its best first and cut to its size.
 *
 * @param {Array<{key: string, section: string, score: number, title: string}>} results
 * @returns {{top: object|null, sections: Array<{id: string, title: string, results: object[]}>}}
 */
export function arrange(results) {
    const byScore = [...results].sort((a, b) =>
        b.score - a.score || a.title.localeCompare(b.title) || a.key.localeCompare(b.key));
    const top = byScore.find(r => r.score >= TOP_HIT_FROM && r.section !== 'web') ?? null;
    const sections = [];
    for (const section of SECTIONS) {
        const inSection = byScore
            .filter(r => r.section === section.id && r !== top)
            .slice(0, section.most);
        if (inSection.length)
            sections.push({id: section.id, title: section.title, results: inSection});
    }
    return {top, sections};
}

/**
 * Every result in the order they are drawn, top hit first: what the arrow keys walk.
 *
 * @param {{top: object|null, sections: Array<{results: object[]}>}} arranged
 * @returns {object[]}
 */
export function walk({top, sections}) {
    return [...(top ? [top] : []), ...sections.flatMap(s => s.results)];
}
