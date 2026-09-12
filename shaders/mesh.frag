#version 460 core
#include <flutter/runtime_effect.glsl>
#include "mesh_common.glsl"

// Fullscreen procedural backdrop. Everything else in the app is glass floating over this.
//
// Uniform float layout (must match MeshBackdropPainter in mesh_backdrop.dart):
//   0,1  uSize
//   2    uTime

uniform vec2  uSize;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec3 c = meshColour(uv, uTime, uSize.x / uSize.y);
    fragColor = vec4(c, 1.0);
}
