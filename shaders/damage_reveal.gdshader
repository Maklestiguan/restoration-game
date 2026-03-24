shader_type canvas_item;

// Маска повреждения: белый = повреждено (видно), чёрный = восстановлено (скрыто)
uniform sampler2D mask_texture : hint_default_white;

// Текстура чистого предмета — повреждения видны ТОЛЬКО там, где предмет непрозрачный
uniform sampler2D item_shape_texture : hint_default_white;

// Интенсивность слоя повреждения (0.0-1.0)
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

// Цвет оттенка повреждения
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 overlay = texture(TEXTURE, UV) * tint_color;
	float mask_value = texture(mask_texture, UV).r;
	float item_alpha = texture(item_shape_texture, UV).a;
	overlay.a *= mask_value * intensity * item_alpha;
	COLOR = overlay;
}
