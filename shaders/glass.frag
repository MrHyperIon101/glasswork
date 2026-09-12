#version 460 core
#include <flutter/runtime_effect.glsl>
#include "mesh_common.glsl"

// A single glass surface sitting directly on the mesh backdrop.
//
// Rather than sampling the backdrop (Impeller-only, throws on Skia/Linux), this
// reconstructs it: the widget passes its own origin within the backdrop, and the shader
// evaluates meshColour() at a UV displaced along the surface's edge normal. That
// displacement is what reads as thick glass rather than frosted plastic.
//
// Uniform float layout (must match GlassPainter in glass_surface.dart):
//   0,1  uSize           widget size, px
//   2,3  uOrigin         widget top-left within the backdrop, px
//   4,5  uBackdropSize   full backdrop size, px
//   6    uTime           seconds
//   7    uRadius         corner radius, px
//   8,9  uPointer        pointer position in widget-local px, or (-1,-1) for none
//   10   uRefract        0 disables refraction (GlassQuality.blurOnly / flat)

uniform vec2  uSize;
uniform vec2  uOrigin;
uniform vec2  uBackdropSize;
uniform float uTime;
uniform float uRadius;
uniform vec2  uPointer;
uniform float uRefract;

out vec4 fragColor;

const float kEdgeWidth  = 18.0; // refraction reaches this far in from the edge
const float kRefractPx  = 26.0; // peak UV displacement at the edge
const float kSaturation = 1.6;

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2  local    = FlutterFragCoord().xy;
    vec2  halfSize = uSize * 0.5;
    vec2  p        = local - halfSize;
    float r        = min(uRadius, min(halfSize.x, halfSize.y));
    float d        = sdRoundBox(p, halfSize, r);

    // Outward normal, by central difference on the SDF.
    vec2 n = normalize(vec2(
        sdRoundBox(p + vec2(1.0, 0.0), halfSize, r) - sdRoundBox(p - vec2(1.0, 0.0), halfSize, r),
        sdRoundBox(p + vec2(0.0, 1.0), halfSize, r) - sdRoundBox(p - vec2(0.0, 1.0), halfSize, r)
    ) + vec2(1e-6));

    // 1 at the edge, falling to 0 by kEdgeWidth inside. This is the thickness profile.
    float edge = smoothstep(-kEdgeWidth, 0.0, d);

    // Reconstruct the backdrop at a displaced coordinate.
    vec2 backdropPx = uOrigin + local - n * edge * kRefractPx * uRefract;
    float aspect    = uBackdropSize.x / uBackdropSize.y;
    vec3 col        = meshColour(backdropPx / uBackdropSize, uTime, aspect);

    // Saturation boost, then a faint veil so the surface reads as a material.
    float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(lum), col, kSaturation);
    col += vec3(0.035);

    // 1px inner stroke, brightest on the top-left arc, fading toward bottom-right.
    float stroke = 1.0 - smoothstep(0.0, 1.4, abs(d + 1.0));
    float facing = clamp(dot(n, normalize(vec2(-1.0, -1.0))), 0.0, 1.0);
    col += vec3(0.26) * stroke * mix(0.22, 1.0, facing);

    // Specular sweep tracking the pointer on desktop.
    if (uPointer.x >= 0.0) {
        vec2 toPointer = normalize(uPointer - local + vec2(1e-6));
        col += vec3(pow(clamp(dot(n, toPointer), 0.0, 1.0), 24.0) * edge * 0.35);
    }

    float alpha = 1.0 - smoothstep(-1.0, 1.0, d);
    fragColor = vec4(col * alpha, alpha); // premultiplied
}
