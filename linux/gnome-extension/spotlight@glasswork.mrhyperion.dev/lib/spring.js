// The spring Spotlight moves on, the way Apple describes one: how long it takes to respond,
// and how much of its bounce is damped away. Pure, so it is tested outside the shell.
//
// A response of 0.26 s with 0.86 of the bounce damped arrives quickly and settles with the
// faintest overshoot — under 2% — which is what makes macOS's Spotlight feel placed rather
// than slid.

export const OPEN = {response: 0.26, damping: 0.86};

/**
 * The browse buttons budding out of the bar: a little slower and a little looser than the
 * bar's own spring, so they read as drops leaving it rather than as icons sliding in.
 */
export const BUD = {response: 0.34, damping: 0.74};

/** The results growing and shrinking to fit what is in them. */
export const FIT = {response: 0.3, damping: 0.9};

/**
 * How far along a spring from 0 to 1 is, [seconds] after it was let go. Overshoots 1 a
 * little before settling there, when [damping] is below 1.
 *
 * @param {number} seconds
 * @param {{response: number, damping: number}} spring
 * @returns {number}
 */
export function progress(seconds, {response, damping}) {
    if (seconds <= 0)
        return 0;
    const omega = (2 * Math.PI) / response;
    if (damping >= 1)
        return 1 - Math.exp(-omega * seconds) * (1 + omega * seconds);
    const decay = damping * omega;
    const ringing = omega * Math.sqrt(1 - damping * damping);
    const envelope = Math.exp(-decay * seconds);
    return 1 - envelope * (Math.cos(ringing * seconds) + (decay / ringing) * Math.sin(ringing * seconds));
}

/**
 * How long until it is still: within [tolerance] of 1 and staying there.
 *
 * @param {{response: number, damping: number}} spring
 * @param {number} tolerance
 * @returns {number} seconds
 */
export function settles(spring, tolerance = 0.001) {
    const step = 1 / 240;
    let last = 0;
    for (let t = step; t < 5; t += step) {
        if (Math.abs(1 - progress(t, spring)) > tolerance)
            last = t;
    }
    return last + step;
}

/**
 * The most it passes 1 by, as a share of the distance.
 *
 * @param {{response: number, damping: number}} spring
 * @returns {number}
 */
export function overshoot(spring) {
    let most = 0;
    for (let t = 0; t < 3; t += 1 / 480)
        most = Math.max(most, progress(t, spring) - 1);
    return most;
}
