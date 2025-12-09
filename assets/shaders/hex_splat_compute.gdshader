shader_type compute;

[compute]
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Params {
    uint seed;
    float hex_size;
    float chunk_radius;
    vec2 camera_pos_axial;
    float padding[2];
} params;

layout(set = 0, binding = 1, std430) restrict writeonly buffer InstanceTransforms {
    mat4 transforms[];
} instance_transforms;

layout(set = 0, binding = 2, std430) restrict writeonly buffer InstanceCustomData {
    vec4 custom_data[];
} instance_custom;

const float SQRT_3 = 1.73205080757;
const float HEX_HEIGHT = 8.0;  // Max terrain height

// Axial to world position
vec3 axial_to_world(vec2 axial) {
    float x = params.hex_size * (SQRT_3 * axial.x + SQRT_3/2.0 * axial.y);
    float z = params.hex_size * (3.0/2.0 * axial.y);
    return vec3(x, 0.0, z);
}

// ──────────────────────────────────────────────────────────────
// Eryndor 4.0 Final – 7-Layer Continental Noise Stack (GPU)
// This is the crown jewel. Do not touch unless you want to burn.
// ──────────────────────────────────────────────────────────────
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
   
    float a = hash11(dot(i + vec2(0.,0.), vec2(1.,1.)));
    float b = hash11(dot(i + vec2(1.,0.), vec2(1.,1.)));
    float c = hash11(dot(i + vec2(0.,1.), vec2(1.,1.)));
    float d = hash11(dot(i + vec2(1.,1.), vec2(1.,1.)));
   
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

const mat2 m2 = mat2(0.8, -0.6, 0.6, 0.8);

float fbm(vec2 p, int octaves) {
    float amp = 0.5;
    float tot = 0.0;
    for (int i = 0; i < octaves; i++) {
        tot += amp * noise(p);
        p = m2 * p * 2.02;
        amp *= 0.51;
    }
    return tot;
}

float continent_shape(vec2 pos) {
    float continental = fbm(pos * 0.00008, 6);
    continental = continental * 2.2 - 0.7;
    continental = smoothstep(0.0, 1.0, continental);
    continental = pow(continental, 2.2);
    return continental;
}

float get_height(vec2 world_pos) {
    vec2 p = world_pos * 0.0005; // Continental scale
   
    // Layer 1 – Continents
    float continents = continent_shape(p);
   
    // Layer 2 – Mountain ranges (ridged)
    float mountains = abs(fbm(p * 2.3 + vec2(12.0, 7) * 2.0 - 1.0));
    mountains = pow(mountains, 3.0) * continents;
   
    // Layer 3 – Erosion / valleys
    float erosion = fbm(p * 8.0 + mountains * 3.0, 5);
   
    // Layer 4 – Detail
    float detail = fbm(p * 32.0, 4);
   
    // Final height
    float h = continents * 0.3;
    h += mountains * 18.0;
    h -= erosion * 2.5;
    h += detail * 0.8;
   
    // Ocean floor below 0
    h = h - 4.0;
   
    return h * 20.0; // final world height scale
}

void main() {
    uint index = gl_GlobalInvocationID.x;
    if (index >= instance_transforms.transforms.length()) return;

    // Spiral out from camera in axial coordinates
    vec2 center = params.camera_pos_axial;
    int ring = 0;
    int pos_in_ring = int(index);
    
    vec2 axial = center;
    bool found = false;
    
    // Spiral enumeration: find axial coord for this instance index
    for (int r = 1; r <= 512; ++r) {
        if (pos_in_ring < 6 * r) {
            ring = r;
            int side = pos_in_ring / r;
            int offset = pos_in_ring % r;
            
            axial = center;
            axial += vec2(0, r);  // Start north
            for (int s = 0; s < side; ++s) {
                axial += vec2(1, 0);
                if (s >= 2) axial += vec2(0, -1);
                if (s >= 4) axial += vec2(-1, 0);
            }
            axial += vec2(offset, -offset);
            found = true;
            break;
        }
        pos_in_ring -= 6 * r;
    }
    
    if (!found) {
        instance_transforms.transforms[index] = mat4(0.0);
        return;
    }

    // Distance culling
    float dist = length(axial - center);
    if (dist > params.chunk_radius) {
        instance_transforms.transforms[index] = mat4(0.0);
        return;
    }

    vec3 world_pos = axial_to_world(axial);
    float height = get_height(world_pos.xz);

    mat4 transform = mat4(
        vec4(params.hex_size, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, params.hex_size, 0.0),
        vec4(world_pos.x, height, world_pos.z, 1.0)
    );

    instance_transforms.transforms[index] = transpose(transform);
    instance_custom.custom_data[index] = vec4(0.0, 0.0, 0.0, 1.0);  // biome ID placeholder
}
