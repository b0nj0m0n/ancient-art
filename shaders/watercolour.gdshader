shader_type canvas_item;
// The full-screen watercolour pass, applied once over the whole battlefield.
// - boil: the picture shifts by under a pixel a few times a second, like a
//   hand-painted animation, rather than sliding smoothly
// - pigment pooling: colour darkens where one wash meets another
// - paper: the rice-paper grain shows through every colour

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform sampler2D paper_tex : repeat_enable, filter_linear;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float boil_px = 0.7;
uniform float boil_fps = 6.0;
uniform float pooling = 0.9;
uniform float paper_strength = 0.55;
// Size of the game's canvas in game units, set by the script. Keeps grain and
// offsets the same size on any screen resolution.
uniform vec2 canvas_size = vec2(1300.0, 600.0);

void fragment() {
	vec2 px = 1.0 / canvas_size;
	float step_t = floor(TIME * boil_fps);
	vec2 jitter = (texture(noise_tex, SCREEN_UV * 2.5 + vec2(step_t * 0.137, step_t * 0.291)).rg - 0.5) * 2.0;
	vec2 uv = SCREEN_UV + jitter * boil_px * px;
	vec3 c = texture(screen, uv).rgb;
	vec3 around = (texture(screen, uv + vec2(px.x * 2.0, 0.0)).rgb
		+ texture(screen, uv - vec2(px.x * 2.0, 0.0)).rgb
		+ texture(screen, uv + vec2(0.0, px.y * 2.0)).rgb
		+ texture(screen, uv - vec2(0.0, px.y * 2.0)).rgb) * 0.25;
	float edge = clamp(length(c - around) * 2.5, 0.0, 1.0);
	c *= 1.0 - pooling * 0.22 * edge;
	float grain = texture(paper_tex, SCREEN_UV * canvas_size / 512.0).r;
	c *= mix(1.0, grain / 0.92, paper_strength);
	COLOR = vec4(c, 1.0);
}
