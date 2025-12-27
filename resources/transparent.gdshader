shader_type spatial;

#include "spritesheet.gdshaderinc"

render_mode cull_disabled;
render_mode vertex_lighting;

void fragment() {
	vec4 color = get_color(UV, UV2, false);
	ALBEDO = color.rgb;
	ALPHA = color.a;

	// TODO: move out of shader
	SPECULAR = 1.0f;
	ROUGHNESS = 0.0f;
}