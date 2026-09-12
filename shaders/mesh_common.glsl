// Shared procedural backdrop gradient.
//
// This function is the whole reason the glass effect works on Linux. Live backdrop
// sampling (ui.ImageFilter.shader) is Impeller-only and throws on Skia, so instead of
// sampling what sits behind a glass surface, the glass shader evaluates THIS function at
// a refracted coordinate. Both shaders therefore agree on the backdrop by construction.
//
// Canonical space: uv is 0..1 across the full backdrop. Blob centres are expressed in
// that same unit square; aspect is applied to the distance only, so centres stay
// meaningful while blobs stay circular on any window shape.

const vec3 kBase   = vec3(0.02745, 0.03137, 0.04706); // #07080C
const vec3 kViolet = vec3(0.16471, 0.10588, 0.36863); // #2A1B5E
const vec3 kTeal   = vec3(0.04314, 0.30980, 0.42353); // #0B4F6C
const vec3 kPlum   = vec3(0.41961, 0.17647, 0.36078); // #6B2D5C

// Soft radial falloff. The exponent shapes the shoulder so blobs read as light rather
// than as discs with a visible rim.
float blob(vec2 uv, vec2 centre, float radius, float aspect) {
    vec2 d = uv - centre;
    d.x *= aspect;
    return pow(1.0 - clamp(length(d) / radius, 0.0, 1.0), 2.4);
}

// uv:     normalised backdrop coordinate (0..1).
// t:      seconds. Centres drift at ~0.02 units/sec.
// aspect: backdropWidth / backdropHeight.
vec3 meshColour(vec2 uv, float t, float aspect) {
    vec2 c1 = vec2(0.26 + 0.17 * sin(t * 0.11),       0.30 + 0.13 * cos(t * 0.09));
    vec2 c2 = vec2(0.79 + 0.14 * cos(t * 0.07 + 0.9), 0.34 + 0.16 * sin(t * 0.13));
    vec2 c3 = vec2(0.53 + 0.15 * sin(t * 0.05 + 1.7), 0.83 + 0.12 * cos(t * 0.10 + 0.6));

    vec3 c = kBase;
    c += kViolet * blob(uv, c1, 0.85, aspect) * 1.20;
    c += kTeal   * blob(uv, c2, 0.78, aspect) * 1.05;
    c += kPlum   * blob(uv, c3, 0.72, aspect) * 0.90;
    return c;
}
