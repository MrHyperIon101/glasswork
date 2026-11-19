// Moving through a grid of apps with the arrow keys. Pure, so it is tested outside the shell.

/**
 * Where the selection goes from [index] in [count] cells, [columns] to a row. Left and right
 * run on across rows; up and down stay in the column, and stop at the edges.
 *
 * @param {number} index
 * @param {number} count
 * @param {number} columns
 * @param {'left'|'right'|'up'|'down'} direction
 * @returns {number}
 */
export function step(index, count, columns, direction) {
    if (count <= 0)
        return 0;
    switch (direction) {
    case 'left':
        return Math.max(index - 1, 0);
    case 'right':
        return Math.min(index + 1, count - 1);
    case 'up':
        return index - columns >= 0 ? index - columns : index;
    case 'down':
        if (index + columns < count)
            return index + columns;
        // From a full row to a shorter last one: its last cell, when there is a row below.
        return Math.floor(index / columns) < Math.floor((count - 1) / columns) ? count - 1 : index;
    }
    return index;
}
