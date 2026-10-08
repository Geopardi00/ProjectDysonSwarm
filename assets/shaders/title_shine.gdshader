shader_type canvas_item;

// Diagonal light sweep across the title logo, masked by the logo's alpha.
uniform float progress = -0.3;
uniform float band_width = 0.1;
uniform float intensity = 0.85;
uniform vec3 shine_color : source_color = vec3(0.85, 0.93, 1.0);


void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float x = UV.x + (UV.y - 0.5) * 0.12;
	float band = 1.0 - smoothstep(0.0, band_width, abs(x - progress));
	color.rgb += shine_color * band * intensity * color.a;
	COLOR = color;
}
