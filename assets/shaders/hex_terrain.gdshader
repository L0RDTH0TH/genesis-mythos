shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

void fragment() {
    float h = VERTEX.y;
   
    vec3 deep_ocean = vec3(0.04, 0.08, 0.18);
    vec3 shallow = vec3(0.07, 0.18, 0.25);
    vec3 beach = vec3(0.35, 0.32, 0.25);
    vec3 grass = vec3(0.15, 0.28, 0.15);
    vec3 forest = vec3(0.08, 0.20, 0.09);
    vec3 rock = vec3(0.28, 0.26, 0.24);
    vec3 snow = vec3(0.92, 0.94, 0.96);
   
    vec3 col = deep_ocean;
    col = mix(col, shallow, smoothstep(-80.0, -10.0, h));
    col = mix(col, beach, smoothstep(-10.0, 0.0, h));
    col = mix(col, grass, smoothstep(0.0, 40.0, h));
    col = mix(col, forest, smoothstep(30.0, 120.0, h));
    col = mix(col, rock, smoothstep(100.0, 200.0, h));
    col = mix(col, snow, smoothstep(180.0, 300.0, h));
   
    ALBEDO = col;
    ROUGHNESS = clamp(1.0 - smoothstep(0.0, 200.0, h), 0.05, 1.0);
}
