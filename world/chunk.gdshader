shader_type spatial;

render_mode cull_back;
render_mode depth_draw_always;

uniform sampler2DArray spritesheet : filter_nearest_mipmap;

void fragment() {
	float index = UV.y * 16.0f + UV.x;
	ALBEDO = texture(spritesheet, vec3(UV2, index)).xyz;
	ALPHA = 1.0f;
}