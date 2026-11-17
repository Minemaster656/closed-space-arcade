shader_type canvas_item;
render_mode unshaded;

// Размытие кадра игры в маленьком SubViewport. Дешёвое за счёт низкого
// разрешения цели и биномиального ядра 5x5.
uniform float spread : hint_range(0.0, 12.0) = 4.0;

void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * spread;
	vec3 color = vec3(0.0);
	float weight_sum = 0.0;

	for (int y = -2; y <= 2; y++) {
		float wy = 6.0 - 2.0 * abs(float(y)) - step(1.5, abs(float(y)));
		for (int x = -2; x <= 2; x++) {
			float wx = 6.0 - 2.0 * abs(float(x)) - step(1.5, abs(float(x)));
			float weight = wx * wy;
			vec2 offset = vec2(float(x), float(y)) * step_uv;
			color += texture(TEXTURE, UV + offset).rgb * weight;
			weight_sum += weight;
		}
	}

	COLOR = vec4(color / weight_sum, 1.0);
}
