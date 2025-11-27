shader_type spatial;

#include "spritesheet.gdshaderinc"

render_mode cull_back;

void fragment() {
	vec4 color = get_color(UV, UV2);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}