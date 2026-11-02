shader_type canvas_item;
// Bildschirm-Nachbearbeitung: Filmkorn, Vignette, leichte chromatische Aberration.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float grain_strength = 0.045;
uniform float vignette_strength = 0.45;
uniform float aberration = 0.0012;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - vec2(0.5);
	// Farbkanäle zum Rand hin leicht auseinanderziehen
	vec2 shift = from_center * aberration * length(from_center) * 4.0;
	vec3 col;
	col.r = texture(screen_tex, uv + shift).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - shift).b;

	float vignette = smoothstep(0.85, 0.25, length(from_center * vec2(1.1, 1.0)));
	col *= mix(1.0 - vignette_strength, 1.0, vignette);

	float noise = hash(uv * 1000.0 + fract(TIME * 13.7)) - 0.5;
	col += noise * grain_strength;

	COLOR = vec4(col, 1.0);
}
