// The extension's pure parts, tested with gjs: `gjs -m linux/gnome-extension/tests/run.js`.
// The shell itself cannot run here, so anything that needs it is tested by loading the
// extension into a nested GNOME Shell instead.

import GLib from 'gi://GLib';

import * as ranking from '../spotlight@glasswork.mrhyperion.dev/lib/ranking.js';
import * as spring from '../spotlight@glasswork.mrhyperion.dev/lib/spring.js';
import * as modes from '../spotlight@glasswork.mrhyperion.dev/lib/modes.js';
import * as categories from '../spotlight@glasswork.mrhyperion.dev/lib/app_categories.js';
import * as kinds from '../spotlight@glasswork.mrhyperion.dev/lib/file_kinds.js';
import * as history from '../spotlight@glasswork.mrhyperion.dev/lib/history.js';
import * as grid from '../spotlight@glasswork.mrhyperion.dev/lib/grid.js';
import * as clip from '../spotlight@glasswork.mrhyperion.dev/lib/clip.js';
import * as quick from '../spotlight@glasswork.mrhyperion.dev/lib/quick_keys.js';

let failed = 0;
let passed = 0;

function test(name, body) {
    try {
        body();
        passed++;
        print(`ok   ${name}`);
    } catch (error) {
        failed++;
        print(`FAIL ${name}\n     ${error.message}`);
    }
}

function equal(actual, expected, what = '') {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a !== e)
        throw new Error(`${what} expected ${e}, got ${a}`);
}

function truthy(value, what) {
    if (!value)
        throw new Error(what);
}

// --- ranking ---------------------------------------------------------------------------

test('the whole name, then its start, then a word, then anywhere, then letters in order', () => {
    const names = ['Collaborate', 'DBMS lab', 'Lab report', 'Lab', 'Lxaxb'];
    const ranked = names
        .map(name => ({name, s: ranking.score('lab', name)}))
        .sort((a, b) => b.s - a.s)
        .map(r => r.name);
    equal(ranked, ['Lab', 'Lab report', 'DBMS lab', 'Collaborate', 'Lxaxb']);
});

test('no match is no score', () => {
    equal(ranking.score('zq', 'Files'), null);
    equal(ranking.score('', 'Files'), null);
});

test('accents and case do not matter', () => {
    equal(ranking.score('cafe', 'Café'), 1000);
    equal(ranking.score('FILES', 'files'), 1000);
});

test('the same scale as Glasswork, so its results sit among the rest at their true rank', () => {
    // lib/search/spotlight_index.dart scores a title starting with the query at 900 less
    // half its extra length — "Lab report" for "lab" is 896.5 in both.
    equal(ranking.score('lab', 'Lab report'), 896.5);
});

test('words written together or apart are the same words, as in Glasswork', () => {
    equal(ranking.score('wifi', 'Wi-Fi'), 950);
    equal(ranking.score('wifi', 'Wi-Fi password'), 850 - 0.5 * 10);
    equal(ranking.score('app store', 'AppStore'), 950);
    truthy(ranking.score('wifi', 'Wi-Fi') < ranking.score('wi-fi', 'Wi-Fi'), 'the same spelling first');
    truthy(ranking.score('wifi', 'Wi-Fi') >= ranking.TOP_HIT_FROM, 'good enough to be a top hit');
});

test('the top hit is the best result from any source, but never the web', () => {
    const arranged = ranking.arrange([
        {key: 'a', section: 'apps', score: 700, title: 'Files'},
        {key: 'w', section: 'web', score: 2000, title: 'Search the web'},
        {key: 'g', section: 'glasswork', score: 950, title: 'File the report'},
    ]);
    equal(arranged.top.key, 'g');
    equal(arranged.sections.map(s => s.id), ['apps', 'web'], 'the top hit is not listed twice');
});

test('a weak match is listed, but is not made the top hit', () => {
    const arranged = ranking.arrange([{key: 'x', section: 'files', score: 300, title: 'x'}]);
    equal(arranged.top, null);
    equal(arranged.sections[0].results.length, 1);
});

test('each section keeps its own few, best first, in the sections own order', () => {
    const results = [];
    for (let i = 0; i < 9; i++)
        results.push({key: `f${i}`, section: 'files', score: 500 + i, title: `f${i}`});
    results.push({key: 'a', section: 'apps', score: 100, title: 'a'});
    const {top, sections} = ranking.arrange(results);
    equal(top, null, 'nothing matched well enough to lead');
    equal(sections.map(s => s.id), ['apps', 'files']);
    equal(sections[1].results.map(r => r.key), ['f8', 'f7', 'f6', 'f5', 'f4']);
});

test('the top hit leads, and its section lists the next best after it', () => {
    const results = [];
    for (let i = 0; i < 9; i++)
        results.push({key: `f${i}`, section: 'files', score: 600 + i, title: `f${i}`});
    const {top, sections} = ranking.arrange(results);
    equal(top.key, 'f8');
    equal(sections[0].results.map(r => r.key), ['f7', 'f6', 'f5', 'f4', 'f3']);
});

test('the arrow keys walk the top hit, then every section in order', () => {
    const arranged = ranking.arrange([
        {key: 'a1', section: 'apps', score: 900, title: 'a1'},
        {key: 'a2', section: 'apps', score: 400, title: 'a2'},
        {key: 'w', section: 'web', score: 1, title: 'w'},
    ]);
    equal(ranking.walk(arranged).map(r => r.key), ['a1', 'a2', 'w']);
});

// --- spring ----------------------------------------------------------------------------

test('it starts at rest and ends where it was sent', () => {
    equal(spring.progress(0, spring.OPEN), 0);
    truthy(Math.abs(spring.progress(2, spring.OPEN) - 1) < 1e-4, 'settled by two seconds');
});

test('Spotlight opens with the faintest overshoot, not a bounce', () => {
    const most = spring.overshoot(spring.OPEN);
    truthy(most > 0, 'some, or it would feel slid rather than placed');
    truthy(most < 0.02, `under 2%, was ${(most * 100).toFixed(2)}%`);
});

test('and is still well inside half a second', () => {
    const t = spring.settles(spring.OPEN);
    truthy(t < 0.5, `settled at ${t.toFixed(3)} s`);
});

test('fully damped, it never passes where it is going', () => {
    equal(spring.overshoot({response: 0.3, damping: 1}), 0);
});

test('the browse buttons bud out with a little more give than the bar opens with', () => {
    const bud = spring.overshoot(spring.BUD);
    truthy(bud > spring.overshoot(spring.OPEN), 'looser than the bar');
    truthy(bud < 0.05, `but under 5%, was ${(bud * 100).toFixed(2)}%`);
    truthy(spring.settles(spring.BUD) < 0.7, 'and settled inside 0.7 s');
});

// --- modes and slash filters -----------------------------------------------------------

test('four modes, in Tahoe order, so Ctrl+1 is Applications and Ctrl+4 Clipboard', () => {
    equal(modes.MODES.map(m => m.id), ['apps', 'files', 'actions', 'clipboard']);
});

test('a slash filter takes effect once its word is finished', () => {
    equal(modes.slash('/pdf report'), {mode: 'files', filter: 'pdf', rest: 'report'});
    equal(modes.slash('/apps '), {mode: 'apps', filter: null, rest: ''});
    equal(modes.slash('kind:images cat'), {mode: 'files', filter: 'images', rest: 'cat'});
    equal(modes.slash('/app'), null, 'half typed');
});

test('a slash that names nothing is left as typed: a path stays a path', () => {
    equal(modes.slash('/usr/lib'), null);
    equal(modes.slash('/nothing here'), null);
    equal(modes.slash('report /pdf'), null);
});

// --- app categories --------------------------------------------------------------------

test('an app goes in the first category that claims it', () => {
    equal(categories.categoryOf('GNOME;GTK;Development;IDE;'), 'developer');
    equal(categories.categoryOf('Game;ArcadeGame;'), 'games');
    equal(categories.categoryOf('Network;WebBrowser;'), 'reading');
    equal(categories.categoryOf('GTK;Utility;TextEditor;'), 'utilities');
    equal(categories.categoryOf('Graphics;Development;'), 'developer', 'developer tools come first');
});

test('an app that declares nothing Spotlight sorts by is Other', () => {
    equal(categories.categoryOf(''), 'other');
    equal(categories.categoryOf(null), 'other');
    equal(categories.categoryOf('GTK;GNOME;'), 'other');
});

// --- file kinds ------------------------------------------------------------------------

test('files are sorted by what they are', () => {
    equal(kinds.kindOf('application/pdf'), 'pdf');
    equal(kinds.kindOf('image/png'), 'image');
    equal(kinds.kindOf('application/vnd.oasis.opendocument.text'), 'document');
    equal(kinds.kindOf('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'), 'spreadsheet');
    equal(kinds.kindOf('application/vnd.ms-powerpoint'), 'presentation');
    equal(kinds.kindOf('text/plain'), 'text');
    equal(kinds.kindOf('application/zip'), 'archive');
    equal(kinds.kindOf('inode/directory'), 'folder');
    equal(kinds.kindOf('application/octet-stream', true), 'folder');
    equal(kinds.kindOf(null), 'other');
});

test('Documents holds PDFs and office files and text; All holds everything', () => {
    truthy(kinds.passes('documents', 'pdf'), 'a PDF is a document');
    truthy(kinds.passes('documents', 'spreadsheet'), 'so is a spreadsheet');
    truthy(!kinds.passes('documents', 'image'), 'an image is not');
    truthy(kinds.passes('all', 'archive'), 'All holds everything');
    truthy(kinds.passes('media', 'video') && kinds.passes('media', 'audio'), 'music and videos');
});

// --- search history --------------------------------------------------------------------

test('searching again moves a search to the front rather than listing it twice', () => {
    equal(history.remember(['b', 'a'], 'a'), ['a', 'b']);
    equal(history.remember(['a'], '  '), ['a'], 'nothing typed is not a search');
    equal(history.remember([], ' lab '), ['lab']);
});

test('history keeps the newest few', () => {
    let list = [];
    for (let i = 0; i < history.MOST + 5; i++)
        list = history.remember(list, `q${i}`);
    equal(list.length, history.MOST);
    equal(list[0], `q${history.MOST + 4}`);
});

test('Up goes back through history, Down comes forward, and both stop at the ends', () => {
    const list = ['newest', 'older'];
    equal(history.step(list, -1, 1), 0);
    equal(history.step(list, 0, 1), 1);
    equal(history.step(list, 1, 1), null, 'nothing older');
    equal(history.step(list, 0, -1), -1, 'back to the line being typed');
    equal(history.step(list, -1, -1), null);
});

// --- the apps grid ---------------------------------------------------------------------

test('the arrow keys move through the grid and stop at its edges', () => {
    // 10 cells in rows of 4: 0-3, 4-7, 8-9.
    equal(grid.step(5, 10, 4, 'right'), 6);
    equal(grid.step(3, 10, 4, 'right'), 4, 'right runs on into the next row');
    equal(grid.step(9, 10, 4, 'right'), 9);
    equal(grid.step(0, 10, 4, 'left'), 0);
    equal(grid.step(5, 10, 4, 'up'), 1);
    equal(grid.step(1, 10, 4, 'up'), 1, 'the top row stays put');
    equal(grid.step(1, 10, 4, 'down'), 5);
    equal(grid.step(7, 10, 4, 'down'), 9, 'onto a shorter last row, its last cell');
    equal(grid.step(9, 10, 4, 'down'), 9);
});

// --- clipboard -------------------------------------------------------------------------

test('a lone address is a link, anything else is text', () => {
    equal(clip.textKind('https://example.com/a?b=1'), 'link');
    equal(clip.textKind('  www.example.com  '), 'link');
    equal(clip.textKind('see https://example.com'), 'text');
    equal(clip.textKind('hello'), 'text');
});

test('copying something again moves it up rather than listing it twice', () => {
    const items = clip.push([{key: 'a'}, {key: 'b'}], {key: 'b'});
    equal(items.map(i => i.key), ['b', 'a']);
});

test('entries older than the setting keeps are forgotten', () => {
    const now = 100000;
    const items = [{key: 'new', at: now - 60}, {key: 'old', at: now - 2 * 60 * 60}];
    equal(clip.prune(items, now, clip.KEEP['30m']).map(i => i.key), ['new']);
    equal(clip.prune(items, now, clip.KEEP['8h']).map(i => i.key), ['new', 'old']);
});

test('an entry reads as its first line, what it is and when', () => {
    const now = 10000;
    equal(clip.describe({kind: 'text', text: 'Buy milk\nand eggs', at: now - 30}, now),
        {title: 'Buy milk', subtitle: 'Text · 2 lines · Just now'});
    equal(clip.describe({kind: 'text', text: 'x', at: now - 300}, now),
        {title: 'x', subtitle: 'Text · 1 character · 5 min ago'});
    equal(clip.describe({kind: 'link', text: 'https://a.dev ', at: now - 7200}, now),
        {title: 'https://a.dev', subtitle: 'Link · 2 h ago'});
    equal(clip.describe({kind: 'image', bytes: 34500, at: now}, now),
        {title: 'Image', subtitle: '35 KB · Just now'});
    equal(clip.describe({kind: 'files', uris: ['file:///a/My%20Notes.txt', 'file:///b/c/'], at: now}, now),
        {title: 'My Notes.txt and 1 more', subtitle: '2 files · Just now'});
});

test('how long ago, in words', () => {
    equal(clip.ago(5), 'Just now');
    equal(clip.ago(3 * 3600 + 5), '3 h ago');
    equal(clip.ago(86400 + 5), 'Yesterday');
    equal(clip.ago(5 * 86400), '5 days ago');
});

// --- actions ---------------------------------------------------------------------------

test('an action\'s quick key goes straight to it, above any other match', () => {
    const task = {title: 'New Task', quickKey: 'nt'};
    equal(quick.matchAction('nt', task), quick.QUICK_KEY_SCORE);
    equal(quick.matchAction('NT', task), quick.QUICK_KEY_SCORE, 'in any case');
    truthy(quick.QUICK_KEY_SCORE > 1000, 'above even a whole-name match');
});

test('actions are found by name, and for less by their keywords', () => {
    const lock = {title: 'Lock Screen', keywords: ['security']};
    equal(quick.matchAction('lock', lock), ranking.score('lock', 'Lock Screen'));
    equal(quick.matchAction('security', lock), 1000 - 150);
    equal(quick.matchAction('zz', lock), null);
});

test('an action\'s fields are read as one line', () => {
    equal(quick.line(['Call mum', ' tomorrow 5pm ']), 'Call mum tomorrow 5pm');
    equal(quick.line(['Call mum', '']), 'Call mum');
});

test('nothing that ends the session has a quick key', () => {
    for (const id of ['system:power-off', 'system:restart', 'system:logout', 'system:suspend'])
        equal(quick.QUICK_KEYS[id], undefined, id);
});

// --- the extension itself --------------------------------------------------------------

test('it says it runs on GNOME 51, the shell it is written for', () => {
    const here = GLib.path_get_dirname(GLib.filename_from_uri(import.meta.url)[0]);
    const path = GLib.build_filenamev([here, '..', 'spotlight@glasswork.mrhyperion.dev', 'metadata.json']);
    const metadata = JSON.parse(new TextDecoder().decode(GLib.file_get_contents(path)[1]));
    equal(metadata['shell-version'], ['51']);
    equal(metadata.uuid, 'spotlight@glasswork.mrhyperion.dev');
    equal(metadata['settings-schema'], 'org.gnome.shell.extensions.glasswork-spotlight');
});

print(`\n${passed} passed, ${failed} failed`);
if (failed)
    imports.system.exit(1);
