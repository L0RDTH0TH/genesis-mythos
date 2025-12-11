shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.7;
uniform float center_radius : hint_range(0.0, 1.0) = 0.4;
uniform float edge_falloff : hint_range(0.0, 1.0) = 0.3;
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 0.65);

void fragment() {
	// Use UV coordinates relative to the ColorRect
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);
	
	// Create vignette: transparent in center, dark at edges
	// Inverted: 0 at center (transparent), 1 at edges (opaque)
	float vignette = smoothstep(center_radius, center_radius + edge_falloff, dist);
	vignette = pow(vignette, 1.0 / (1.0 + vignette_strength));
	
	// Apply overlay color with vignette alpha
	COLOR = overlay_color;
	COLOR.a *= vignette;
}
