// Everything else the overview can search: Settings, Calculator, Characters, Clocks, Weather,
// Calendar, Contacts, Software — every installed search provider, as the user has them
// enabled. Files' own provider is left out: files come from the index directly, so they are
// not listed twice.

import Gio from 'gi://Gio';
import St from 'gi://St';

import {loadRemoteSearchProviders} from 'resource:///org/gnome/shell/ui/remoteSearch.js';

import {score} from '../ranking.js';

const SKIP = new Set(['org.gnome.Nautilus.desktop']);
const SETTINGS = 'org.gnome.Settings.desktop';
const CALCULATOR = 'org.gnome.Calculator.desktop';
/** How much less another app's suggestion counts than the same match elsewhere. */
const SUGGESTION = 150;

export class ProvidersSource {
    constructor() {
        this._settings = new Gio.Settings({schema_id: 'org.gnome.desktop.search-providers'});
        this._providers = loadRemoteSearchProviders(this._settings)
            .filter(p => !SKIP.has(p.appInfo.get_id()));
    }

    /** One list per provider, each as it answers: a slow provider never holds up the rest. */
    searchEach(query, cancellable) {
        const terms = query.split(/\s+/).filter(t => t);
        return this._providers.map(provider => this._ask(provider, query, terms, cancellable));
    }

    async _ask(provider, query, terms, cancellable) {
        const ids = provider.filterResults(
            await provider.getInitialResultSet(terms, cancellable), 3);
        if (!ids.length)
            return [];
        const metas = await provider.getResultMetas(ids, cancellable);
        const id = provider.appInfo.get_id();
        return metas.map((meta, i) => ({
            key: `provider:${id}:${meta.id}`,
            section: id === SETTINGS ? 'settings' : 'providers',
            title: meta.name,
            subtitle: meta.description || provider.appInfo.get_name(),
            // A calculator's answer matches nothing literally, but it is what was asked for.
            // Settings panels count as they match; what other apps suggest — a character, a
            // city's weather — a little less, so an app or a setting by that name comes first.
            score: (id === CALCULATOR ? 980
                : id === SETTINGS ? score(query, meta.name) ?? 520
                    : (score(query, meta.name) ?? 520) - SUGGESTION) - i,
            icon: size => meta.createIcon(size) ??
                new St.Icon({gicon: provider.appInfo.get_icon(), icon_size: size}),
            activate: () => provider.activateResult(meta.id, terms),
        }));
    }

    destroy() {}
}
