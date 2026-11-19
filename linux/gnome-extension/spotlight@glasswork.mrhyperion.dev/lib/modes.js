// Spotlight's four ways to browse, as macOS Tahoe has them: Applications, Files, Actions and
// Clipboard — a round button each beside the bar, and Ctrl+1 to Ctrl+4 (or Super+1 to
// Super+4). And the slash filters, which jump to one from the keyboard: "/pdf report"
// searches PDFs for "report". Pure, so it is tested outside the shell.

export const MODES = [
    {id: 'apps', title: 'Applications', hint: 'Search Apps', icon: 'view-app-grid-symbolic'},
    {id: 'files', title: 'Files', hint: 'Search Files', icon: 'folder-symbolic'},
    {id: 'actions', title: 'Actions', hint: 'Search Actions', icon: 'system-run-symbolic'},
    {id: 'clipboard', title: 'Clipboard', hint: 'Search Clipboard', icon: 'edit-paste-symbolic'},
];

export function mode(id) {
    return MODES.find(m => m.id === id) ?? null;
}

/** What each word after a slash, or after "kind:", narrows Spotlight to. */
const FILTERS = {
    apps: {mode: 'apps'},
    app: {mode: 'apps'},
    applications: {mode: 'apps'},
    files: {mode: 'files'},
    file: {mode: 'files'},
    documents: {mode: 'files', filter: 'documents'},
    document: {mode: 'files', filter: 'documents'},
    docs: {mode: 'files', filter: 'documents'},
    pdf: {mode: 'files', filter: 'pdf'},
    pdfs: {mode: 'files', filter: 'pdf'},
    images: {mode: 'files', filter: 'images'},
    image: {mode: 'files', filter: 'images'},
    photos: {mode: 'files', filter: 'images'},
    pictures: {mode: 'files', filter: 'images'},
    folders: {mode: 'files', filter: 'folders'},
    folder: {mode: 'files', filter: 'folders'},
    music: {mode: 'files', filter: 'media'},
    videos: {mode: 'files', filter: 'media'},
    media: {mode: 'files', filter: 'media'},
    actions: {mode: 'actions'},
    action: {mode: 'actions'},
    clipboard: {mode: 'clipboard'},
};

/**
 * "/pdf report" or "kind:pdf report": the mode and filter the first word names, and the rest
 * of the line. Null until that word is finished with a space, so "/app" is not taken for
 * "/apps" half-typed; and null for a word that names nothing, so a path stays a path.
 *
 * @param {string} text
 * @returns {{mode: string, filter: string|null, rest: string}|null}
 */
export function slash(text) {
    const match = /^\s*(?:\/|kind:)([\p{L}]+)\s(.*)$/iu.exec(text ?? '');
    if (!match)
        return null;
    const found = FILTERS[match[1].toLowerCase()];
    if (!found)
        return null;
    return {mode: found.mode, filter: found.filter ?? null, rest: match[2]};
}
