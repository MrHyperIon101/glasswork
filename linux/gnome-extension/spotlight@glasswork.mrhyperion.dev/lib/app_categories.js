// The categories Spotlight's Applications sorts apps into — Tahoe's, read from the
// categories each app's desktop file declares. Pure, so it is tested outside the shell.

/** In the order the chips show them. The first that claims an app has it. */
export const CATEGORIES = [
    {id: 'games', title: 'Games', from: ['Game']},
    {id: 'developer', title: 'Developer Tools', from: ['Development', 'IDE', 'Debugger', 'RevisionControl']},
    {id: 'creativity', title: 'Creativity', from: ['Graphics', '2DGraphics', '3DGraphics', 'Photography',
        'RasterGraphics', 'VectorGraphics', 'AudioVideoEditing', 'Midi', 'Mixer', 'Sequencer']},
    {id: 'productivity', title: 'Productivity', from: ['Office', 'Calendar', 'ContactManagement',
        'Finance', 'ProjectManagement', 'WordProcessor', 'Spreadsheet', 'Presentation']},
    {id: 'social', title: 'Social', from: ['Chat', 'InstantMessaging', 'Email', 'IRCClient',
        'VideoConference', 'Telephony']},
    {id: 'entertainment', title: 'Entertainment', from: ['AudioVideo', 'Audio', 'Video', 'Player',
        'TV', 'Music']},
    {id: 'reading', title: 'Information & Reading', from: ['Education', 'Science', 'Viewer',
        'Documentation', 'News', 'Maps', 'Dictionary', 'Literature', 'WebBrowser', 'Network']},
    {id: 'utilities', title: 'Utilities', from: ['Utility', 'System', 'Settings', 'Accessories',
        'FileManager', 'TerminalEmulator', 'Monitor', 'Archiving', 'Security', 'Accessibility']},
];

/**
 * The category an app belongs in, from its desktop file's Categories line
 * ("GTK;Development;IDE;"), or 'other'.
 *
 * @param {string|null} declared
 * @returns {string}
 */
export function categoryOf(declared) {
    const has = new Set((declared ?? '').split(';').filter(c => c));
    return CATEGORIES.find(c => c.from.some(name => has.has(name)))?.id ?? 'other';
}
