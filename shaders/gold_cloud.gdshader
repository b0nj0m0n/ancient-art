shader_type canvas_item;
// A gold-leaf cloud from a folding screen: pale gold with scattered brighter
// flecks of leaf, a faint pattern of leaf squares, and a darker rim.
// UV.y is 0 at the rim and 1 at the centre.

uniform vec4 gold : source_color = vec4(0.886, 0.792, 0.545, 1.0);
uniform vec4 fleck : source_color = vec4(0.933, 0.855, 0.62, 1.0);
uniform vec4 rim : source_color = vec4(0.70, 0.58, 0.34, 1.0);
uniform float rim_width = 0.08;
uniform float dot_spacing_px = 9.0;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

varying vec2 world;

void vertex() {
	world = VERTEX;
}

void fragment() {
	vec3 fine = texture(noise_tex, world / 23.0).rgb;
	vec3 broad = texture(noise_tex, world / 200.0).rgb;
	vec3 col = gold.rgb * (0.94 + 0.12 * broad.r);
	// Gold leaf is laid in squares; their seams show faintly.
	// Raised gold dots (moriage), in offset rows, as on the screens.
	vec2 g = world / dot_spacing_px;
	g.x += 0.5 * mod(floor(g.y), 2.0);
	float d = length(fract(g) - 0.5);
	float dot_ring = smoothstep(0.30, 0.26, d) - smoothstep(0.22, 0.18, d);
	col = mix(col, rim.rgb, dot_ring * 0.35);
	col = mix(col, fleck.rgb, smoothstep(0.72, 0.8, fine.r) * 0.8);
	float r = 1.0 - smoothstep(0.0, rim_width, UV.y);
	col = mix(col, rim.rgb, r * 0.85);
	COLOR = vec4(col, 1.0);
}
