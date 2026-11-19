// Glasswork's own tasks, notes, projects and places, ranked by the app itself on the same
// scale as everything else — and the line typed, offered as a task to add.

import GLib from 'gi://GLib';
import St from 'gi://St';

import * as Glasswork from '../glasswork.js';

export class GlassworkSource {
    constructor({onAdded} = {}) {
        this._onAdded = onAdded;
    }

    /**
     * Wakes Glasswork if it is not running, as Spotlight opens, so it is there by the time
     * the first words are typed. Never waited on.
     */
    wake() {
        Glasswork.call('Recents', new GLib.Variant('(u)', [1]), '(aa{sv})', {wake: true, timeout: 10000})
            .catch(() => {});
    }

    async recents(cancellable) {
        try {
            const [results] = await Glasswork.call(
                'Recents', new GLib.Variant('(u)', [6]), '(aa{sv})', {cancellable});
            return results.map(r => this._result(r, 'glasswork'));
        } catch {
            return [];
        }
    }

    async search(query, cancellable) {
        let found = [];
        let preview = null;
        try {
            const [[results], [previewed]] = await Promise.all([
                Glasswork.call('Query', new GLib.Variant('(su)', [query, 8]), '(aa{sv})', {cancellable}),
                Glasswork.call('PreviewAdd', new GLib.Variant('(s)', [query]), '(a{sv})', {cancellable}),
            ]);
            // Glasswork's actions are listed with every other action, by the actions source.
            found = results.filter(r => r.kind !== 'action').map(r => this._result(r, 'glasswork'));
            preview = previewed;
        } catch {
            return [];
        }
        if (preview?.title)
            found.push(this._addRow(query, preview));
        return found;
    }

    /**
     * What Glasswork can do from Spotlight, as it describes itself. Wakes it if it has to:
     * the Actions mode asks once, as it opens.
     */
    async actions() {
        const [results] = await Glasswork.call('Actions', null, '(aa{sv})', {wake: true, timeout: 10000});
        return results.map(r => this._result(r, 'actions'));
    }

    /** What [line] would add, read as Glasswork reads it, or null when it cannot say. */
    async preview(line, cancellable) {
        try {
            const [previewed] = await Glasswork.call(
                'PreviewAdd', new GLib.Variant('(s)', [line]), '(a{sv})', {cancellable});
            return previewed;
        } catch {
            return null;
        }
    }

    /** The line as a task: what it will be called, and what was read out of it. */
    _addRow(query, preview) {
        const read = (preview.chips ?? []).join(' · ');
        return {
            key: 'glasswork:add',
            section: 'glasswork',
            title: `Add “${preview.title}”`,
            subtitle: [read, preview.sentence].filter(s => s).join(' — '),
            badge: 'Ctrl ↵',
            // Last in Glasswork's list, and never the top hit: a task is added on purpose.
            score: 0,
            isAdd: true,
            icon: size => new St.Icon({icon_name: 'list-add-symbolic', icon_size: size}),
            activate: () => this.add(query),
        };
    }

    async add(query) {
        try {
            const [id] = await Glasswork.call(
                'AddTask', new GLib.Variant('(s)', [query]), '(s)', {wake: true, timeout: 10000});
            if (id)
                this._onAdded?.(query);
        } catch (error) {
            console.warn(`Glasswork Spotlight: could not add a task: ${error.message}`);
        }
    }

    _result(r, section) {
        return {
            key: `glasswork:${r.id}`,
            section,
            title: r.title,
            subtitle: r.subtitle,
            score: r.score ?? 0,
            icon: size => new St.Icon({icon_name: r.icon, icon_size: size}),
            activate: async ({timestamp} = {}) => {
                try {
                    const [opened] = await Glasswork.call(
                        'Activate', new GLib.Variant('(su)', [r.id, timestamp ?? 0]), '(b)',
                        {wake: true, timeout: 10000});
                    if (opened)
                        Glasswork.focus(timestamp);
                } catch (error) {
                    console.warn(`Glasswork Spotlight: could not open ${r.id}: ${error.message}`);
                }
            },
        };
    }

    destroy() {}
}
