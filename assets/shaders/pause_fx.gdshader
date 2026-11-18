shader_type canvas_item;
render_mode unshaded;

// Экранный эффект паузы: сканлайны + лёгкая хроматическая аберрация.
// Шейдер висит на ColorRect внутри игрового SubViewport, поэтому читает
// именно отрисованный кадр игры, а не весь UI приложения.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aberration_px : hint_range(0.0, 12.0) = 3.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.22;
uniform float scanline_count : hint_range(40.0, 1600.0) = 540.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float darken_strength : hint_range(0.0, 1.0) = 0.28;
uniform vec4 tint : source_color = vec4(0.55, 0.68, 0.9, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	vec2 dir = centered / max(length(centered), 0.0001);
	vec2 offset = dir * SCREEN_PIXEL_SIZE * aberration_px * intensity;

	vec3 color;
	color.r = texture(screen_texture, uv + offset).r;
	color.g = texture(screen_texture, uv).g;
	color.b = texture(screen_texture, uv - offset).b;

	float scan = 0.5 + 0.5 * sin((uv.y * scanline_count + TIME * 6.0) * 6.28318);
	color *= 1.0 - scanline_strength * scan * intensity;
	color = mix(color, color * tint.rgb, intensity * 0.18);

	float vignette = 1.0 - smoothstep(0.22, 0.95, length(centered));
	color *= mix(1.0, vignette, intensity * vignette_strength);
	color *= mix(1.0, 0.72, intensity * darken_strength);

	COLOR = vec4(color, intensity);
}
