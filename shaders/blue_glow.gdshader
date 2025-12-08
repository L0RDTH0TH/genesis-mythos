shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 line_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float point_size : hint_range(1.0, 10.0) = 3.0;

void vertex() {
	POINT_SIZE = point_size;
}

void fragment() {
	ALBEDO = line_color.rgb;
	EMISSION = line_color.rgb * 0.8;
}
