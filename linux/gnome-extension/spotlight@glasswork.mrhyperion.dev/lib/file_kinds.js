// What kind of file something is, and the filters Spotlight's Files offers by kind. Read
// from the content type, so a file is sorted the same wherever it was found. Pure, so it is
// tested outside the shell.

export const FILE_FILTERS = [
    {id: 'all', title: 'All'},
    {id: 'documents', title: 'Documents', kinds: ['document', 'pdf', 'spreadsheet', 'presentation', 'text']},
    {id: 'pdf', title: 'PDFs', kinds: ['pdf']},
    {id: 'images', title: 'Images', kinds: ['image']},
    {id: 'folders', title: 'Folders', kinds: ['folder']},
    {id: 'media', title: 'Music & Videos', kinds: ['audio', 'video']},
];

const OFFICE = [
    [/spreadsheet|ms-excel|\.sheet|csv/, 'spreadsheet'],
    [/presentation|ms-powerpoint|\.slide/, 'presentation'],
    [/opendocument|msword|officedocument|rtf|epub|x-tex/, 'document'],
];

/**
 * @param {string|null} contentType a MIME type, as GIO guesses or reads it
 * @param {boolean} folder
 * @returns {string} folder, pdf, image, audio, video, spreadsheet, presentation, document,
 *   text, archive, or other
 */
export function kindOf(contentType, folder = false) {
    const type = (contentType ?? '').toLowerCase();
    if (folder || type === 'inode/directory')
        return 'folder';
    if (type === 'application/pdf')
        return 'pdf';
    for (const [pattern, kind] of OFFICE) {
        if (pattern.test(type))
            return kind;
    }
    const [major] = type.split('/');
    if (major === 'image' || major === 'audio' || major === 'video')
        return major;
    if (major === 'text')
        return 'text';
    if (/zip|tar|compressed|archive|x-7z|rar|xz|bzip|gzip/.test(type))
        return 'archive';
    return 'other';
}

/** Whether a file of [kind] belongs under the filter [id]. */
export function passes(filterId, kind) {
    const filter = FILE_FILTERS.find(f => f.id === filterId);
    return !filter?.kinds || filter.kinds.includes(kind);
}
