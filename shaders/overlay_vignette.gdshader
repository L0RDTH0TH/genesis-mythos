shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.7;
uniform float center_radius : hint_range(0.0, 1.0) = 0.4;
uniform float edge_falloff : hint_range(0.0, 1.0) = 0.3;
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);
	
	// Create vignette: transparent in center, dark at edges
	float vignette = smoothstep(center_radius, center_radius + edge_falloff, dist);
	vignette = pow(vignette, 1.0 / (1.0 + vignette_strength));
	
	// Apply overlay color with vignette alpha
	COLOR = overlay_color;
	COLOR.a *= vignette;
}
