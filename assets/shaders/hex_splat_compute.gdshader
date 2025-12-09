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

// Simple layered noise placeholder (full 7-layer GPU noise in Phase 4)
float get_height(vec2 world_pos) {
    float n = sin(world_pos.x * 0.002 + float(params.seed)) * 0.5 + 0.5;
    n += sin(world_pos.y * 0.003) * 0.3;
    n = n * 0.5 + 0.5;
    return (n - 0.5) * HEX_HEIGHT * 2.0;
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
