#version 460 core
#include <flutter/runtime_effect.glsl>

// Liquid glass, run as a backdrop filter over what is behind one surface.
//
// The engine hands this the backdrop — already blurred by the filter composed inside it —
// in the window's own pixels, so the surface says where it is (u_rect, in the same pixels)
// and everything is worked out relative to that. Inside a band along the edge, what is
// behind is drawn from further in, the way the thick rim of a lens bends it; the three
// colours bend by slightly different amounts there; and the rim catches a light from the
// top left. Away from the edge it is the blur and the tint and nothing else.

uniform vec2 u_size;        // set by the engine: the backdrop's size
uniform vec4 u_rect;        // the surface: left, top, width, height
uniform float u_radius;     // its corner radius
uniform float u_rim;        // how far in from the edge the glass bends
uniform float u_refract;    // how far, at the very edge, what is behind is pulled
uniform float u_light;      // how bright the rim's highlight is
uniform vec4 u_tint;        // laid over everything, premultiplied
uniform sampler2D u_input;

out vec4 frag;

// Distance to the rounded rectangle's edge: negative inside.
float edge(vec2 p, vec2 half_size, float r) {
  vec2 q = abs(p) - half_size + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Which way is out, at p.
vec2 outward(vec2 p, vec2 half_size, float r) {
  vec2 q = abs(p) - half_size + r;
  vec2 s = vec2(p.x < 0.0 ? -1.0 : 1.0, p.y < 0.0 ? -1.0 : 1.0);
  if (q.x > 0.0 && q.y > 0.0) {
    return normalize(q) * s;
  }
  return q.x > q.y ? vec2(s.x, 0.0) : vec2(0.0, s.y);
}

// What is behind, at a point in the window. The backdrop arrives the right way up on every
// backend this runs on — the documented flip for OpenGL ES mirrors it here, drawing the top
// of the window at the bottom of every surface — so there is none.
vec4 behind(vec2 px) {
  return texture(u_input, clamp(px / u_size, vec2(0.0), vec2(1.0)));
}

void main() {
  vec2 px = FlutterFragCoord().xy;
  vec2 half_size = u_rect.zw * 0.5;
  vec2 p = px - (u_rect.xy + half_size);
  float r = min(u_radius, min(half_size.x, half_size.y));

  float depth = -edge(p, half_size, r);           // 0 at the edge, more inside
  float bend = clamp(1.0 - depth / u_rim, 0.0, 1.0);
  bend = bend * bend * (3.0 - 2.0 * bend);         // eased, so the bend has no seam
  vec2 n = outward(p, half_size, r);

  // Drawn from further in: what sits just inside the rim appears at the rim.
  vec2 pull = -n * u_refract * bend;
  vec3 colour = vec3(
    behind(px + pull * 1.06).r,
    behind(px + pull).g,
    behind(px + pull * 0.94).b
  );

  // What shows through is a little richer than it is behind, the way Apple's materials lift
  // the colour of what they cover rather than greying it.
  float luma = dot(colour, vec3(0.2126, 0.7152, 0.0722));
  colour = mix(vec3(luma), colour, 1.35);

  // The tint over it, as a colour laid on glass.
  colour = colour * (1.0 - u_tint.a) + u_tint.rgb;

  // Light from the top left catches the rim facing it, and a little of the far one.
  float rim = smoothstep(2.5, 0.0, depth) * 0.9 + bend * 0.12;
  float facing = dot(n, normalize(vec2(-1.0, -1.4)));
  colour += vec3(u_light) * rim * (0.35 + 0.65 * max(facing, 0.0) + 0.25 * max(-facing, 0.0));

  frag = vec4(colour, 1.0);
}
