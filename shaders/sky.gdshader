shader_type canvas_item;
// Woodblock-print sky: a dark indigo band at the top of the screen fading into
// the paper, and a warm glow low down near the horizon. UV.y is the field y.

uniform vec4 paper_colour : source_color = vec4(0.914, 0.863, 0.753, 1.0);
uniform vec4 band_colour : source_color = vec4(0.204, 0.322, 0.420, 1.0);
uniform float screen_top = 0.0;
uniform float band_solid_px = 8.0;
uniform float band_fade_px = 95.0;
uniform vec4 glow_colour : source_color = vec4(0.85, 0.62, 0.53, 1.0);
uniform float glow_y = 420.0;
uniform float glow_reach_px = 120.0;
uniform float glow_strength = 0.35;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

varying vec2 world;

void vertex() {
	world = VERTEX;
}

void fragment() {
	float y = UV.y - screen_top;
	vec3 n = texture(noise_tex, world / 420.0).rgb;
	float band = 1.0 - smoothstep(band_solid_px, band_solid_px + band_fade_px * (0.96 + 0.08 * n.r), y);
	vec3 col = mix(paper_colour.rgb, band_colour.rgb, band);
	float glow = (1.0 - smoothstep(0.0, glow_reach_px, abs(UV.y - glow_y))) * glow_strength;
	col = mix(col, glow_colour.rgb, glow * (0.7 + 0.6 * n.g));
	COLOR = vec4(col, 1.0);
}
