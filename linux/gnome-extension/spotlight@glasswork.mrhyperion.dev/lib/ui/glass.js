// Liquid glass in the shell: shapes whose backdrop is the desktop itself.
//
// A blur effect in background mode cannot be given rounded corners — it draws a rectangle
// under the actor — so the desktop comes in as a clone of the window group, blurred as this
// surface's own content, and GlassEffect then cuts the shapes out of it, bends that blurred
// desktop along a band inside each edge the way a lens's rim does, splits its colours
// slightly there, lights the rim from the top left and lays a soft shadow under it all.
//
// Shapes near each other melt together, as Liquid Glass does: their distances are joined
// with a smooth minimum rather than a plain one, so a button leaving the bar draws out of it
// like a drop and only parts from it once it is clear. It is the same glass as Glasswork's
// cards (shaders/liquid_glass.frag), made by the compositor over everything on screen.

import Clutter from 'gi://Clutter';
import Cogl from 'gi://Cogl';
import GObject from 'gi://GObject';
import Shell from 'gi://Shell';
import St from 'gi://St';

/** As many shapes as one glass holds: the bar and its four buttons. */
const SHAPES = 5;

const DECLARATIONS = `
uniform sampler2D tex;
uniform vec2 size;
${Array.from({length: SHAPES}, (_, i) => `uniform vec4 shape${i};\nuniform float round${i};`).join('\n')}
uniform float blend;
uniform float rim;
uniform float bend_by;
uniform float light;
uniform float shadow;

float glass_box(vec2 p, vec4 s, float r) {
  if (s.z <= 0.0 || s.w <= 0.0)
    return 10000.0;
  vec2 half_size = s.zw * 0.5;
  r = min(r, min(half_size.x, half_size.y));
  vec2 q = abs(p - s.xy - half_size) - half_size + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float glass_join(float a, float b) {
  if (blend <= 0.0)
    return min(a, b);
  float h = max(blend - abs(a - b), 0.0) / blend;
  return min(a, b) - h * h * blend * 0.25;
}

float glass_shape(vec2 p) {
  float d = glass_box(p, shape0, round0);
${Array.from({length: SHAPES - 1}, (_, i) => `  d = glass_join(d, glass_box(p, shape${i + 1}, round${i + 1}));`).join('\n')}
  return d;
}
`;

const CODE = `
vec2 uv = cogl_tex_coord_in[0].xy;
vec2 p = uv * size;
float d = glass_shape(p);

// Which way is out: the slope of the distance, so it follows the joins between shapes too.
vec2 slope = vec2(glass_shape(p + vec2(1.0, 0.0)) - glass_shape(p - vec2(1.0, 0.0)),
                  glass_shape(p + vec2(0.0, 1.0)) - glass_shape(p - vec2(0.0, 1.0)));
vec2 n = length(slope) > 0.0001 ? normalize(slope) : vec2(0.0, -1.0);

float depth = -d;
float bend = clamp(1.0 - depth / rim, 0.0, 1.0);
bend = bend * bend * (3.0 - 2.0 * bend);
vec2 pull = -n * bend_by * bend / size;

vec4 colour = texture2D(tex, uv + pull);
colour.r = texture2D(tex, uv + pull * 1.08).r;
colour.b = texture2D(tex, uv + pull * 0.92).b;

float glint = smoothstep(1.5, 0.0, depth) * 0.9 + bend * 0.1;
float facing = dot(n, normalize(vec2(-1.0, -1.4)));
colour.rgb += vec3(light * glint * (0.35 + 0.65 * max(facing, 0.0) + 0.3 * max(-facing, 0.0))) * colour.a;

float cover = clamp(0.5 - d, 0.0, 1.0);
float below = glass_shape(p - vec2(0.0, 8.0));
float fall = 1.0 - clamp(below / 26.0, 0.0, 1.0);
float shade = shadow * fall * fall * (1.0 - cover);
cogl_color_out = (colour * cover + vec4(0.0, 0.0, 0.0, shade)) * cogl_color_in;
`;

/** How far the blur reaches, in pixels; the backdrop extends this far past the glass. */
const BLUR = 40;

/** Room around the shapes for the shadow under them. */
export const MARGIN = 28;

const GlassEffect = GObject.registerClass(
class GlassEffect extends Clutter.ShaderEffect {
    _init({shapes, blend}) {
        super._init();
        this._shapes = shapes;
        this._blend = blend;
    }

    vfunc_get_static_snippet() {
        const snippet = Cogl.Snippet.new(Cogl.SnippetHook.FRAGMENT, DECLARATIONS, null);
        snippet.set_replace(CODE);
        return snippet;
    }

    // Everything in logical pixels: the texture's own coordinates run 0 to 1 whatever its
    // scale, so the shapes are placed by the same measure the actors are.
    vfunc_paint_target(node, paintContext) {
        const actor = this.get_actor();
        this.set_uniform_float('size', 2, [actor.width, actor.height]);
        const shapes = this._shapes();
        for (let i = 0; i < SHAPES; i++) {
            const s = shapes[i];
            this.set_uniform_float(`shape${i}`, 4, s ? [s.x, s.y, s.width, s.height] : [0, 0, 0, 0]);
            this.set_uniform_float(`round${i}`, 1, [s?.radius ?? 0]);
        }
        this.set_uniform_float('blend', 1, [this._blend]);
        this.set_uniform_float('rim', 1, [16]);
        this.set_uniform_float('bend_by', 1, [14]);
        this.set_uniform_float('light', 1, [0.2]);
        this.set_uniform_float('shadow', 1, [0.3]);
        super.vfunc_paint_target(node, paintContext);
    }
});

/**
 * Holds what reaches past the glass without the glass growing to hold it: it asks for no
 * size of its own, so the glass is as big as it is set to be, and the overhang is clipped.
 */
const Overhang = GObject.registerClass(
class Overhang extends Clutter.Actor {
    vfunc_get_preferred_width() {
        return [0, 0];
    }

    vfunc_get_preferred_height() {
        return [0, 0];
    }
});

/**
 * Glass: the blurred desktop, cut to [shapes] — a function giving, each frame, the shapes in
 * this actor's own logical pixels, as {x, y, width, height, radius} — under a tint, with
 * what is added to it on top. Shapes within [blend] pixels of each other melt together.
 *
 * Its size is set by whoever places it, MARGIN larger on every side than the shapes need,
 * for the shadow. Nothing on it is bent: an icon near the edge stays an icon.
 */
export const Glass = GObject.registerClass(
class Glass extends St.Widget {
    _init({styleClass, shapes, blend = 0}) {
        super._init({
            style_class: styleClass,
            layout_manager: new Clutter.FixedLayout(),
        });

        this._surface = new St.Widget({
            layout_manager: new Clutter.FixedLayout(),
            clip_to_allocation: true,
        });

        // The desktop: wallpaper and windows alike, since the wallpaper is inside the
        // window group. Never Spotlight itself, which is above that group. It reaches a
        // blur's width past the glass on every side, so the blur always has real desktop to
        // draw on rather than running out of picture at the edges.
        const holder = new Overhang({layout_manager: new Clutter.FixedLayout()});
        this._backdrop = new Clutter.Actor({layout_manager: new Clutter.FixedLayout()});
        this._clone = new Clutter.Clone({source: global.window_group});
        this._backdrop.add_child(this._clone);
        this._backdrop.add_effect(new Shell.BlurEffect({
            mode: Shell.BlurMode.ACTOR,
            radius: BLUR,
            brightness: 0.82,
        }));
        holder.add_child(this._backdrop);
        this._surface.add_child(holder);

        this._tint = new St.Widget({style_class: 'gw-glass-tint'});
        this._surface.add_child(this._tint);
        this._backdrop.set_position(-BLUR, -BLUR);

        this._effect = new GlassEffect({shapes, blend});
        this._surface.add_effect(this._effect);
        this.add_child(this._surface);
    }

    /**
     * Sizes the glass, and everything in it that is its size: set by whoever places it,
     * never worked out from its content.
     */
    setSize(width, height) {
        this.set_size(width, height);
        this._surface.set_size(width, height);
        this._tint.set_size(width, height);
        this._backdrop.set_size(width + 2 * BLUR, height + 2 * BLUR);
    }

    /** Draws the glass again: its shapes have moved, though nothing under it has. */
    refresh() {
        this._effect.queue_repaint();
    }

    /** Lines the desktop up behind this glass, given where its corner sits on the stage. */
    alignBackdrop(stageX, stageY) {
        // The clone sits inside a backdrop that starts a blur's width before the glass.
        this._clone.set_position(-stageX + BLUR, -stageY + BLUR);
    }

    /** Sizes, for the tests that read Spotlight back over D-Bus. */
    describeLayout() {
        const size = a => [Math.round(a.width), Math.round(a.height)];
        return {glass: size(this), surface: size(this._surface), clone: [this._clone.x, this._clone.y]};
    }
});
