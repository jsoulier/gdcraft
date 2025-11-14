shader_type spatial;

render_mode cull_disabled;
render_mode depth_draw_opaque;

uniform sampler2DArray spritesheet : filter_nearest_mipmap, repeat_disable;

const float amplitude = 0.1;
const float speed = 1.0;
const float frequency = 1.0;
const float phase = 0.0;
const float offset = 0.2;

void vertex() {
	float x = sin(VERTEX.x * frequency + TIME * speed + phase);
	float z = cos(VERTEX.z * frequency + TIME * speed + phase);
	VERTEX.y += (x + z) * amplitude;
	VERTEX.y -= offset;
}

void fragment() {
	float index = UV.y * 16.0 + UV.x;
	vec3 tex_color = texture(spritesheet, vec3(UV2, index)).xyz;
	ALBEDO = tex_color;
	METALLIC = 1.0;
	ROUGHNESS = 0.0;
	SPECULAR = 0.5;
}