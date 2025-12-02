shader_type spatial;

#include "spritesheet.gdshaderinc"

render_mode cull_back;
render_mode depth_draw_always;
render_mode vertex_lighting;

void fragment() {
	vec4 color = get_color(UV, UV2, true);
	ALBEDO = color.rgb;
	if (color.a < 0.001f)
	{
		discard;
	}
}