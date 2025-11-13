shader_type spatial;

render_mode cull_back;
render_mode depth_draw_always;

uniform sampler2DArray spritesheet : filter_nearest_mipmap, repeat_disable;

void fragment() {
	float index = UV.y * 16.0f + UV.x;
	vec4 color = texture(spritesheet, vec3(UV2, index));
	ALBEDO = color.rgb;
	ALPHA = color.a;
	// TODO: you're not allowed to write to ALPHA if you want SSR
}