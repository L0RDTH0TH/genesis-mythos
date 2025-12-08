shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// Preview mode enum: 0=Network, 1=Topographic, 2=Biome Color, 3=Foliage Density, 4=Full Render
uniform int preview_mode = 0;

// Heightmap and splatmap
uniform sampler2D heightmap;
uniform sampler2D splatmap : source_color;  // RGBA = 4 biome channels
uniform sampler2D normal_map : hint_normal;

// Biome textures (up to 8 for splatting)
uniform sampler2D biome_texture_0 : source_color;
uniform sampler2D biome_texture_1 : source_color;
uniform sampler2D biome_texture_2 : source_color;
uniform sampler2D biome_texture_3 : source_color;
uniform sampler2D biome_texture_4 : source_color;
uniform sampler2D biome_texture_5 : source_color;
uniform sampler2D biome_texture_6 : source_color;
uniform sampler2D biome_texture_7 : source_color;

// Normal maps for biomes
uniform sampler2D biome_normal_0 : hint_normal;
uniform sampler2D biome_normal_1 : hint_normal;
uniform sampler2D biome_normal_2 : hint_normal;
uniform sampler2D biome_normal_3 : hint_normal;

// Foliage density map
uniform sampler2D foliage_density_map : source_color;

// River data (blue tint where rivers exist)
uniform sampler2D river_map : source_color;

// Material properties
uniform float scale_y = 20.0;
uniform float emission_intensity = 1.2;
uniform float parallax_scale = 0.02;
uniform float normal_strength = 1.0;
uniform vec3 tint_color = vec3(1.0, 1.0, 1.0);
uniform bool use_texture_splatting = true;
uniform bool use_normal_mapping = true;
uniform bool use_parallax = false;

// Network mode (preview_mode = 0) properties
uniform float noise_scale = 0.15;
uniform float noise_strength = 0.08;
uniform float line_thickness = 0.5;
uniform float time_scale = 0.5;

// Topographic mode (preview_mode = 1) properties
uniform float contour_spacing = 0.1;
uniform float contour_width = 0.002;

// Color constants
const vec3 DEEP_BLUE = vec3(0.0, 0.1, 0.4);
const vec3 CYAN_EDGE = vec3(0.0, 0.8, 1.0);
const vec3 ORANGE_HIGHLIGHT = vec3(1.0, 0.5, 0.0);
const vec3 RIVER_COLOR = vec3(0.2, 0.5, 1.0);

// Perlin-like noise function
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// Calculate normal from heightmap
vec3 calculate_normal_from_heightmap(vec2 uv) {
	float h = texture(heightmap, uv).r;
	float hx = texture(heightmap, uv + vec2(0.001, 0.0)).r;
	float hz = texture(heightmap, uv + vec2(0.0, 0.001)).r;
	
	vec3 normal = normalize(vec3((h - hx) * scale_y, 1.0, (h - hz) * scale_y));
	return normal;
}

// Parallax offset mapping
vec2 parallax_offset(vec2 uv, vec3 view_dir) {
	if (!use_parallax) {
		return uv;
	}
	
	float height = texture(heightmap, uv).r;
	vec2 offset = view_dir.xy * (height * parallax_scale);
	return uv - offset;
}

void vertex() {
	// Apply height displacement
	float h = texture(heightmap, UV).r;
	VERTEX.y += h * scale_y;
	
	// Add organic wavy variation for network mode
	if (preview_mode == 0) {
		vec2 world_pos = VERTEX.xz;
		vec2 noise_uv = world_pos * noise_scale + TIME * time_scale;
		
		float wave_x = fbm(noise_uv, 3) - 0.5;
		float wave_z = fbm(noise_uv + vec2(100.0, 100.0), 3) - 0.5;
		
		VERTEX.xz += vec2(wave_x, wave_z) * noise_strength;
	}
}

void fragment() {
	float h = texture(heightmap, UV).r;
	vec2 uv = UV;
	
	// Apply parallax offset if enabled
	if (use_parallax) {
		vec3 view_dir = normalize(VIEW - VERTEX);
		uv = parallax_offset(uv, view_dir);
	}
	
	vec3 final_color = vec3(0.0);
	vec3 final_normal = vec3(0.0, 1.0, 0.0);
	float final_emission = 0.0;
	float final_alpha = 1.0;
	
	// Preview Mode 0: Network (wireframe style)
	if (preview_mode == 0) {
		vec3 col = DEEP_BLUE;
		
		// Simulate line thickness
		vec2 screen_uv = SCREEN_UV;
		float line_distance = length(dFdx(screen_uv) + dFdy(screen_uv));
		float thickness_factor = smoothstep(line_thickness, 0.0, line_distance);
		
		// Cyan edge glow
		float height_variation = abs(dFdx(h)) + abs(dFdy(h));
		float edge_factor = smoothstep(0.0, 0.1, height_variation);
		col = mix(col, CYAN_EDGE, edge_factor * 0.7);
		
		// Noise-based variation
		vec2 world_pos = VERTEX.xz;
		vec2 noise_uv = world_pos * noise_scale + TIME * time_scale;
		float noise_value = fbm(noise_uv, 2);
		col = mix(col, CYAN_EDGE, noise_value * 0.4);
		
		// Height-based intensity
		float height_intensity = smoothstep(0.3, 0.9, h);
		col = mix(col, CYAN_EDGE, height_intensity * 0.5);
		
		// Orange highlights
		float orange_noise = fbm(noise_uv * 2.0 + vec2(200.0, 200.0), 2);
		float orange_factor = smoothstep(0.85, 1.0, orange_noise);
		final_color = mix(col, ORANGE_HIGHLIGHT, orange_factor * 0.3);
		
		final_emission = emission_intensity * (1.0 + thickness_factor * 0.5);
		final_normal = calculate_normal_from_heightmap(uv);
	}
	
	// Preview Mode 1: Topographic (contour lines)
	else if (preview_mode == 1) {
		// Create contour lines
		float contour = mod(h, contour_spacing);
		float contour_line = smoothstep(contour_width, 0.0, abs(contour - contour_spacing * 0.5));
		
		// Base color: height-based gradient
		vec3 base_color = mix(vec3(0.1, 0.3, 0.6), vec3(0.8, 0.6, 0.3), h);
		
		// Add contour lines
		final_color = mix(base_color, vec3(0.0, 0.0, 0.0), contour_line * 0.8);
		final_normal = calculate_normal_from_heightmap(uv);
	}
	
	// Preview Mode 2: Biome Color (texture splatting)
	else if (preview_mode == 2) {
		if (use_texture_splatting && texture(splatmap, uv).a > 0.0) {
			// Get splat weights
			vec4 splat = texture(splatmap, uv);
			
			// Sample biome textures
			vec3 tex0 = texture(biome_texture_0, uv * 10.0).rgb;
			vec3 tex1 = texture(biome_texture_1, uv * 10.0).rgb;
			vec3 tex2 = texture(biome_texture_2, uv * 10.0).rgb;
			vec3 tex3 = texture(biome_texture_3, uv * 10.0).rgb;
			
			// Blend textures based on splat weights
			final_color = tex0 * splat.r + tex1 * splat.g + tex2 * splat.b + tex3 * splat.a;
			
			// Blend normals if available
			if (use_normal_mapping) {
				vec3 n0 = texture(biome_normal_0, uv * 10.0).rgb * 2.0 - 1.0;
				vec3 n1 = texture(biome_normal_1, uv * 10.0).rgb * 2.0 - 1.0;
				vec3 n2 = texture(biome_normal_2, uv * 10.0).rgb * 2.0 - 1.0;
				vec3 n3 = texture(biome_normal_3, uv * 10.0).rgb * 2.0 - 1.0;
				
				vec3 blended_normal = normalize(n0 * splat.r + n1 * splat.g + n2 * splat.b + n3 * splat.a);
				final_normal = normalize(mix(calculate_normal_from_heightmap(uv), blended_normal, normal_strength));
			} else {
				final_normal = calculate_normal_from_heightmap(uv);
			}
		} else {
			// Fallback: height-based color
			final_color = mix(vec3(0.1, 0.3, 0.6), vec3(0.8, 0.6, 0.3), h);
			final_normal = calculate_normal_from_heightmap(uv);
		}
		
		// Add river overlay
		if (texture(river_map, uv).r > 0.5) {
			final_color = mix(final_color, RIVER_COLOR, 0.6);
		}
	}
	
	// Preview Mode 3: Foliage Density
	else if (preview_mode == 3) {
		float foliage = texture(foliage_density_map, uv).r;
		final_color = mix(vec3(0.2, 0.2, 0.2), vec3(0.1, 0.6, 0.2), foliage);
		final_normal = calculate_normal_from_heightmap(uv);
	}
	
	// Preview Mode 4: Full Render (texture splatting + lighting)
	else if (preview_mode == 4) {
		if (use_texture_splatting && texture(splatmap, uv).a > 0.0) {
			vec4 splat = texture(splatmap, uv);
			
			vec3 tex0 = texture(biome_texture_0, uv * 10.0).rgb;
			vec3 tex1 = texture(biome_texture_1, uv * 10.0).rgb;
			vec3 tex2 = texture(biome_texture_2, uv * 10.0).rgb;
			vec3 tex3 = texture(biome_texture_3, uv * 10.0).rgb;
			
			final_color = tex0 * splat.r + tex1 * splat.g + tex2 * splat.b + tex3 * splat.a;
			
			if (use_normal_mapping) {
				vec3 n0 = texture(biome_normal_0, uv * 10.0).rgb * 2.0 - 1.0;
				vec3 n1 = texture(biome_normal_1, uv * 10.0).rgb * 2.0 - 1.0;
				vec3 n2 = texture(biome_normal_2, uv * 10.0).rgb * 2.0 - 1.0;
				vec3 n3 = texture(biome_normal_3, uv * 10.0).rgb * 2.0 - 1.0;
				
				vec3 blended_normal = normalize(n0 * splat.r + n1 * splat.g + n2 * splat.b + n3 * splat.a);
				final_normal = normalize(mix(calculate_normal_from_heightmap(uv), blended_normal, normal_strength));
			} else {
				final_normal = calculate_normal_from_heightmap(uv);
			}
			
			// Add river overlay
			if (texture(river_map, uv).r > 0.5) {
				final_color = mix(final_color, RIVER_COLOR, 0.6);
			}
			
			// Height-based emission for magic areas
			float magic_emission = smoothstep(0.7, 1.0, h) * 0.3;
			final_emission = magic_emission;
		} else {
			// Fallback
			final_color = mix(vec3(0.1, 0.3, 0.6), vec3(0.8, 0.6, 0.3), h);
			final_normal = calculate_normal_from_heightmap(uv);
		}
	}
	
	// Apply tint color
	final_color *= tint_color;
	
	// Set outputs
	ALBEDO = final_color;
	NORMAL = final_normal;
	EMISSION = final_color * final_emission;
	ALPHA = final_alpha;
}
