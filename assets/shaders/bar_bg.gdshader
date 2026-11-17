shader_type canvas_item;
render_mode unshaded;

// Фон окна: размытый кадр игры, растянутый по принципу cover с небольшим
// дополнительным зумом. Виден только в полосах вокруг игрового 9:16.
uniform vec2 window_size = vec2(1080.0, 1920.0);
uniform float game_aspect : hint_range(0.1, 10.0) = 0.5625;
uniform float extra_zoom : hint_range(1.0, 3.0) = 1.3;
uniform float darken : hint_range(0.0, 1.0) = 0.55;
uniform float saturation : hint_range(0.0, 1.5) = 0.8;

void fragment() {
	float win_aspect = window_size.x / max(window_size.y, 1.0);
	vec2 crop = vec2(
		min(1.0, win_aspect / game_aspect),
		min(1.0, game_aspect / win_aspect)
	);
	vec2 uv = 0.5 + (UV - 0.5) * crop / extra_zoom;

	vec3 color = texture(TEXTURE, uv).rgb;
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luma), color, saturation) * darken;

	vec2 centered = UV - 0.5;
	float vignette = 1.0 - smoothstep(0.25, 0.82, length(centered * vec2(1.0, 0.85)));
	color *= mix(0.72, 1.0, vignette);

	COLOR = vec4(color, 1.0);
}
