shader_type spatial;

#include "spritesheet.gdshaderinc"

render_mode cull_back;
render_mode depth_draw_opaque;
render_mode vertex_lighting;

void fragment() {
	ALBEDO = get_color(UV, UV2, false).rgb;
}