shader_type spatial;

#include "spritesheet.gdshaderinc"

render_mode cull_back;
render_mode depth_draw_opaque;

void fragment() {
	ALBEDO = get_color(UV, UV2).rgb;
}