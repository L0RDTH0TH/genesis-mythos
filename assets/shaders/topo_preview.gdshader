shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D heightmap;
uniform float scale_y = 20.0;
uniform float emission_intensity = 1.2;
uniform float noise_scale = 0.15;
uniform float noise_strength = 0.08;
uniform float line_thickness = 0.5;
uniform float time_scale = 0.5;
uniform vec3 tint_color = vec3(0.4, 0.8, 1.0);
uniform bool invert_normals = false;

// Color constants for network style
const vec3 DEEP_BLUE = vec3(0.0, 0.1, 0.4);
const vec3 CYAN_EDGE = vec3(0.0, 0.8, 1.0);
const vec3 ORANGE_HIGHLIGHT = vec3(1.0, 0.5, 0.0);

// Perlin-like noise function for organic waviness
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

void vertex() {
    // Apply height displacement
    VERTEX.y += texture(heightmap, UV).r * scale_y;
    
    // Add organic wavy variation using noise with TIME for animation
    vec2 world_pos = VERTEX.xz;
    vec2 noise_uv = world_pos * noise_scale + TIME * time_scale;
    
    // Multi-octave noise for smoother, more organic waves
    float wave_x = fbm(noise_uv, 3) - 0.5;
    float wave_z = fbm(noise_uv + vec2(100.0, 100.0), 3) - 0.5;
    
    // Apply wavy displacement
    VERTEX.xz += vec2(wave_x, wave_z) * noise_strength;
}

void fragment() {
    float h = texture(heightmap, UV).r;
    
    // Base color: deep blue for network lines
    vec3 col = DEEP_BLUE;
    
    // Simulate line thickness using screen-space derivatives
    // Create a falloff effect that makes lines appear thicker
    vec2 screen_uv = SCREEN_UV;
    float line_distance = length(dFdx(screen_uv) + dFdy(screen_uv));
    float thickness_factor = smoothstep(line_thickness, 0.0, line_distance);
    
    // Add cyan edge glow based on height variation
    float height_variation = abs(dFdx(h)) + abs(dFdy(h));
    float edge_factor = smoothstep(0.0, 0.1, height_variation);
    col = mix(col, CYAN_EDGE, edge_factor * 0.7);
    
    // Add noise-based variation for wavy appearance with TIME
    vec2 world_pos = VERTEX.xz;
    vec2 noise_uv = world_pos * noise_scale + TIME * time_scale;
    float noise_value = fbm(noise_uv, 2);
    col = mix(col, CYAN_EDGE, noise_value * 0.4);
    
    // Height-based intensity variation (cyan for higher areas)
    float height_intensity = smoothstep(0.3, 0.9, h);
    col = mix(col, CYAN_EDGE, height_intensity * 0.5);
    
    // Add orange highlights using noise (random factor per fragment)
    float orange_noise = fbm(noise_uv * 2.0 + vec2(200.0, 200.0), 2);
    float orange_factor = smoothstep(0.85, 1.0, orange_noise); // ~15% chance for orange
    vec3 final_col = mix(col, ORANGE_HIGHLIGHT, orange_factor * 0.3);
    
    // Apply thickness simulation (emission falloff)
    float emission = emission_intensity * (1.0 + thickness_factor * 0.5);
    
    // Apply style tint color
    final_col *= tint_color;
    
    // Invert normals for nightmare look (Dark Fantasy)
    if (invert_normals) {
        NORMAL = -NORMAL;  // flips lighting feel even if unshaded
    }
    
    ALBEDO = final_col;
    EMISSION = final_col * emission; // Enhanced glow with thickness falloff
    ALPHA = 1.0;
}
