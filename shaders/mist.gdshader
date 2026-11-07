shader_type canvas_item;
// A Hiroshige mist band: strongest along its top edge, fading downward,
// drifting slowly sideways. UV.y runs 0 (top) to 1 (bottom).

uniform vec4 tint : source_color = vec4(0.85, 0.55, 0.48, 1.0);
uniform float strength = 0.6;
uniform float drift_px_per_s = 3.0;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

varying vec2 world;

void vertex() {
	world = VERTEX;
}

void fragment() {
	vec2 p = world + vec2(TIME * drift_px_per_s, 0.0);
	float n = texture(noise_tex, p / 260.0).g;
	float top_soft = smoothstep(0.0, 0.06, UV.y);
	float fade = 1.0 - smoothstep(0.0, 0.85 + 0.3 * n, UV.y);
	COLOR = vec4(tint.rgb, strength * top_soft * fade * (0.75 + 0.5 * n));
}
