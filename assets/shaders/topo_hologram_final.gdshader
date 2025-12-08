shader_type spatial;

render_mode unshaded, depth_draw_never, cull_back, blend_add;

uniform sampler2D heightmap;
uniform float global_time : hint_range(0.0, 1000.0);
uniform float glow_intensity : hint_range(0.0, 10.0) = 4.5;

varying float v_height;

void vertex() {
    v_height = texture(heightmap, UV).r;
    VERTEX.y += v_height * 35.0;
}

void fragment() {
    float h = v_height;
    
    // Thick, bright cyan contour lines
    float contour = abs(fract(h * 22.0 + 0.5) - 0.5) * 2.0;
    contour = 1.0 - smoothstep(0.45, 0.55, contour);
    vec3 contours = vec3(0.0, 1.8, 2.5) * contour;
    
    // Dense holographic wireframe
    vec2 grid = abs(fract(UV * 120.0) - 0.5) / max(fwidth(UV * 120.0), 0.0001);
    float wire = 1.0 - min(grid.x, grid.y);
    wire = smoothstep(0.0, 0.9, wire);
    vec3 wires = vec3(0.0, 0.9, 2.0) * wire;
    
    // Pulsing rivers in valleys
    float river_mask = smoothstep(0.15, 0.05, h) * (1.0 - smoothstep(0.35, 0.45, h));
    float river_pulse = 0.7 + 0.3 * sin(global_time * 4.0 + UV.x * 15.0 + UV.y * 8.0);
    vec3 rivers = vec3(0.1, 1.4, 3.5) * river_mask * river_pulse;
    
    // City lights / settlement clusters - using procedural noise
    vec2 city_uv = UV * 280.0 + vec2(global_time * 0.3, 0.0);
    float city_noise = fract(sin(dot(city_uv, vec2(12.9898, 78.233))) * 43758.5453);
    float cities = pow(max(0.0, city_noise), 9.0);
    cities *= smoothstep(0.1, 0.7, h);
    vec3 lights = vec3(0.9, 1.6, 3.0) * cities * 25.0;
    
    // Combine with proper brightness
    vec3 final_glow = contours + wires + rivers + lights;
    
    ALBEDO = vec3(0.0);
    EMISSION = final_glow * glow_intensity;
    ALPHA = dot(final_glow, vec3(0.33)) * 0.8; // ensures visibility even when very bright
}
