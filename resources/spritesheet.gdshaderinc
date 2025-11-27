uniform sampler2DArray spritesheet : filter_nearest_mipmap, repeat_disable;

vec4 get_color(vec2 uv1, vec2 uv2) {
	float index = uv1.y * 16.0f + uv1.x;
	return texture(spritesheet, vec3(uv2, index));
}