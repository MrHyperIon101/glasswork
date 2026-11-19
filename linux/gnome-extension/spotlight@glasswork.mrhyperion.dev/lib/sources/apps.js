// Applications, found exactly as the overview finds them — GNOME's own AppSearchProvider,
// with its ranking, its usage ordering and its parental controls — and listed whole for
// Spotlight's Applications, sorted into Tahoe's categories.
//
// The system actions the overview also answers for (Lock, Power Off and the rest) come from
// the actions source instead, beside every other action.

import Shell from 'gi://Shell';
import St from 'gi://St';

import {AppSearchProvider} from 'resource:///org/gnome/shell/ui/appDisplay.js';

import {categoryOf} from '../app_categories.js';
import {score} from '../ranking.js';

/** How much less an app counts found by what it is rather than by its name. */
const BY_WHAT_IT_IS = 100;

export class AppsSource {
    constructor() {
        this._provider = new AppSearchProvider();
        this._apps = Shell.AppSystem.get_default();
    }

    async search(query, cancellable) {
        const terms = query.split(/\s+/).filter(t => t);
        const ids = (await this._provider.getInitialResultSet(terms, cancellable))
            .filter(id => id.endsWith('.desktop'));
        const metas = await this._provider.getResultMetas(ids.slice(0, 12), cancellable);
        return metas.map((meta, i) => {
            const app = this._apps.lookup_app(meta.id);
            // GNOME's own order breaks ties; how well the name matches places it among the
            // other sources. Found by what it is — "term" finding Ptyxis, a terminal — it
            // ranks a little below its name matching, and above a stranger's name that does.
            const matched = score(query, meta.name) ?? this._byWhatItIs(query, app) ?? 350;
            return this._result(app, {score: matched - i * 0.01, icon: size => meta.createIcon(size)});
        }).filter(r => r);
    }

    /** How well [query] matches what [app] is — its generic name and keywords — or null. */
    _byWhatItIs(query, app) {
        const info = app?.get_app_info();
        const words = [info?.get_generic_name?.(), ...(info?.get_keywords?.() ?? [])].filter(w => w);
        const scores = words.map(w => score(query, w)).filter(s => s !== null);
        return scores.length ? Math.max(...scores) - BY_WHAT_IT_IS : null;
    }

    /**
     * Every app there is to open, by name, each with its category: what Spotlight's
     * Applications lists. Matched against [query] when there is one, best first.
     */
    all(query = '') {
        const seen = new Set();
        const apps = [];
        for (const info of this._apps.get_installed()) {
            const id = info.get_id();
            if (!info.should_show() || seen.has(id))
                continue;
            seen.add(id);
            const app = this._apps.lookup_app(id);
            if (!app)
                continue;
            let matched = 0;
            if (query) {
                const words = [info.get_generic_name?.(), ...(info.get_keywords?.() ?? [])].filter(w => w);
                const byWord = words.map(w => score(query, w)).filter(s => s !== null).map(s => s - BY_WHAT_IT_IS);
                matched = Math.max(score(query, app.get_name()) ?? -Infinity, ...byWord);
                if (matched === -Infinity)
                    continue;
            }
            const result = this._result(app, {score: matched});
            result.category = categoryOf(info.get_categories?.() ?? null);
            apps.push(result);
        }
        return apps.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));
    }

    _result(app, {score: s, icon}) {
        if (!app)
            return null;
        return {
            key: `app:${app.get_id()}`,
            section: 'apps',
            title: app.get_name(),
            subtitle: app.get_description() ?? '',
            score: s,
            icon: icon ?? (size => app.create_icon_texture(size) ??
                new St.Icon({icon_name: 'application-x-executable', icon_size: size})),
            // A running app is brought forward rather than started again.
            activate: () => app.activate(),
        };
    }

    destroy() {}
}
