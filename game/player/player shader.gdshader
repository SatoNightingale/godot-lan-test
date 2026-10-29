shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_width : hint_range(0.0, 8.0) = 1.0;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	if (original_color.a > alpha_threshold) {
		COLOR = original_color;
	} else {
		vec2 texel_size = TEXTURE_PIXEL_SIZE * outline_width;
		float alpha_up = texture(TEXTURE, UV + vec2(0.0, -texel_size.y)).a;
		float alpha_down = texture(TEXTURE, UV + vec2(0.0, texel_size.y)).a;
		float alpha_left = texture(TEXTURE, UV + vec2(-texel_size.x, 0.0)).a;
		float alpha_right = texture(TEXTURE, UV + vec2(texel_size.x, 0.0)).a;
		if (alpha_up > alpha_threshold || alpha_down > alpha_threshold ||
		alpha_left > alpha_threshold || alpha_right > alpha_threshold) {
			COLOR = outline_color;
		} else {
			COLOR = original_color;
		}
	}
}