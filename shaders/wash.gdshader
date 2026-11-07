shader_type canvas_item;
// A watercolour wash for one paper layer of land.
// UV.y is the distance in pixels below the layer's cut edge.
// The edge colour fades into the body colour (bokashi), the wash is uneven
// and grainy, and an ink line of varying width runs along the edge.

uniform vec4 body_colour : source_color = vec4(0.42, 0.53, 0.49, 1.0);
uniform vec4 edge_colour : source_color = vec4(0.28, 0.38, 0.36, 1.0);
uniform float fade_px = 50.0;
uniform vec4 ink_colour : source_color = vec4(0.216, 0.212, 0.216, 1.0);
uniform float ink_px = 2.2;
uniform float ink_strength = 0.8;
uniform float unevenness = 0.07;
uniform float granulation = 0.10;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

varying vec2 world;

void vertex() {
	world = VERTEX;
}

void fragment() {
	float depth = UV.y;
	vec3 broad = texture(noise_tex, world / 340.0).rgb;
	vec3 fine = texture(noise_tex, world / 41.0).rgb;
	// Bokashi: edge pigment fading into the body, its reach varying like a hand-wiped block.
	float fade = smoothstep(0.0, fade_px * (0.6 + 0.8 * broad.g), depth);
	vec3 col = mix(edge_colour.rgb, body_colour.rgb, fade);
	col *= 1.0 + (broad.r - 0.5) * unevenness;
	col *= 1.0 - (fine.b - 0.5) * granulation;
	// Brush ink along the edge: thicker and thinner as the brush moves.
	float w = ink_px * (0.45 + 1.1 * texture(noise_tex, vec2(world.x / 160.0, 0.37)).b);
	float ink = (1.0 - smoothstep(w * 0.5, w, depth)) * ink_strength;
	col = mix(col, ink_colour.rgb, ink);
	COLOR = vec4(col, 1.0);
}
