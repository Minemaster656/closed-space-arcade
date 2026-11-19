shader_type canvas_item;
render_mode unshaded;

// Постоянная лёгкая виньетка для игровых сцен.
// Не читает screen texture: это дешёвый радиальный градиент поверх кадра.

uniform float strength : hint_range(0.0, 1.0) = 0.22;
uniform float inner_radius : hint_range(0.0, 1.5) = 0.40;
uniform float outer_radius : hint_range(0.0, 1.5) = 1.0;
uniform vec4 vignette_color : source_color = vec4(0.015, 0.02, 0.045, 1.0);

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float distance = length(centered) * 1.41421356;
	float amount = smoothstep(inner_radius, outer_radius, distance);
	COLOR = vec4(vignette_color.rgb, amount * strength * vignette_color.a);
}
