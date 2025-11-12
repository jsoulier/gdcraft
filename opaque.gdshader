shader_type spatial;

render_mode cull_back;
render_mode depth_draw_opaque;

uniform sampler2DArray spritesheet : filter_nearest_mipmap, repeat_disable;

void fragment() {
	float index = UV.y * 16.0f + UV.x;
	ALBEDO = texture(spritesheet, vec3(UV2, index)).xyz;
}