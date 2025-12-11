shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D parchment_texture : source_color, filter_linear;
uniform float curl_strength : hint_range(0.0, 0.15) = 0.06;
uniform float stain_intensity : hint_range(0.0, 1.0) = 0.65;
uniform float edge_darken : hint_range(0.0, 1.0) = 0.5;
uniform float time_scale : hint_range(0.0, 0.2) = 0.05;

void fragment() {
    vec2 uv = UV;
    
    // Subtle animated curl
    uv.x += sin(uv.y * 12.0 + TIME * 0.8) * curl_strength * (1.0 - uv.y);
    uv.y += cos(uv.x * 12.0 + TIME * 0.6) * curl_strength * (1.0 - uv.x);
    
    // Animated subtle crumple noise
    float noise = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(TIME * time_scale, TIME * time_scale * 0.7)).r;
    
    // Parchment base
    vec4 parchment = texture(parchment_texture, uv);
    
    // Edge darkening vignette
    float vignette = 1.0 - smoothstep(0.0, 0.8, length(uv - 0.5) * 1.4);
    
    COLOR = texture(TEXTURE, UV);
    COLOR.rgb *= parchment.rgb;
    COLOR.rgb *= 1.0 - noise * stain_intensity;
    COLOR.rgb *= 1.0 - edge_darken * vignette;
}
