shader_type canvas_item;

// Map rendering shader for 2D map display
// Supports heightmap visualization with hillshading, biome coloring, and river overlays

uniform sampler2D heightmap_texture : hint_default_white, filter_linear;
uniform sampler2D biome_texture : hint_default_white, filter_linear;
uniform sampler2D rivers_texture : hint_default_white, filter_linear;

uniform bool show_heightmap : hint_default_white = false;
uniform bool show_biomes : hint_default_white = true;
uniform bool show_rivers : hint_default_white = true;

uniform float sea_level : hint_range(0.0, 1.0) = 0.4;
uniform float hillshade_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec2 light_direction : hint_default = vec2(0.5, 0.5);

uniform vec4 water_color : hint_color = vec4(0.1, 0.2, 0.4, 1.0);

void fragment() {
	vec2 uv = UV;
	
	// Sample heightmap (red channel = height, 0-1)
	float height = texture(heightmap_texture, uv).r;
	
	// Calculate hillshading
	vec2 texel_size = 1.0 / vec2(textureSize(heightmap_texture, 0));
	float height_left = texture(heightmap_texture, uv - vec2(texel_size.x, 0.0)).r;
	float height_right = texture(heightmap_texture, uv + vec2(texel_size.x, 0.0)).r;
	float height_up = texture(heightmap_texture, uv - vec2(0.0, texel_size.y)).r;
	float height_down = texture(heightmap_texture, uv + vec2(0.0, texel_size.y)).r;
	
	// Normal vector from height gradients
	vec3 normal = normalize(vec3(
		(height_left - height_right) * 100.0,
		(height_up - height_down) * 100.0,
		1.0
	));
	
	// Light direction (normalized)
	vec3 light_dir = normalize(vec3(light_direction - 0.5, 0.5));
	
	// Calculate diffuse lighting (hillshading)
	float diffuse = max(dot(normal, light_dir), 0.0);
	diffuse = mix(0.3, 1.0, diffuse); // Ambient + diffuse
	diffuse = pow(diffuse, hillshade_strength);
	
	vec4 final_color = vec4(0.0);
	
	// Show heightmap grayscale mode
	if (show_heightmap) {
		vec3 heightmap_color = vec3(height);
		final_color = vec4(heightmap_color * diffuse, 1.0);
	}
	// Show biome coloring mode
	else if (show_biomes) {
		vec4 biome_color = texture(biome_texture, uv);
		final_color = biome_color * diffuse;
		
		// Apply water color for underwater areas
		if (height < sea_level) {
			final_color = mix(water_color, final_color, height / sea_level);
		}
	}
	else {
		// Default: just heightmap with shading
		vec3 heightmap_color = vec3(height);
		final_color = vec4(heightmap_color * diffuse, 1.0);
	}
	
	// Overlay rivers (blue lines)
	if (show_rivers) {
		float river = texture(rivers_texture, uv).r;
		if (river > 0.1) {
			vec4 river_color = vec4(0.2, 0.4, 0.8, 1.0);
			final_color = mix(final_color, river_color, river * 0.7);
		}
	}
	
	COLOR = final_color;
}