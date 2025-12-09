shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 color_low : hint_color = vec3(0.11, 0.15, 0.22);
uniform vec3 color_mid : hint_color = vec3(0.18, 0.25, 0.35);
uniform vec3 color_high : hint_color = vec3(0.65, 0.78, 0.82);
uniform vec3 color_peak : hint_color = vec3(0.95, 0.95, 0.98);

void fragment() {
    float height = VERTEX.y;
    vec3 col = mix(color_low, color_mid, smoothstep(-8.0, 4.0, height));
    col = mix(col, color_high, smoothstep(4.0, 12.0, height));
    col = mix(col, color_peak, smoothstep(12.0, 16.0, height));
    
    ALBEDO = col;
    METALLIC = 0.0;
    ROUGHNESS = clamp(1.0 - height * 0.04, 0.1, 1.0);
    SPECULAR = 0.5;
}
