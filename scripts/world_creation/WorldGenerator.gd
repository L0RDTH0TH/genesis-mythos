# ╔═══════════════════════════════════════════════════════════
# ║ WorldGenerator.gd
# ║ Desc: Central generator for hexagonal, GPU-driven infinite terrain
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name WorldGenerator

extends Node

@export var heightfield_compute_shader: RDShaderFile

# GPU heightmap generation parameters
var seed: int = 666
var base_frequency: float = 0.01
var elevation_scale: float = 30.0
var domain_warp_strength: float = 0.0
var domain_warp_freq: float = 0.005
var terrain_chaos: float = 0.0
var octaves: int = 4
var lacunarity: float = 2.0
var gain: float = 0.5
var shape_preset: int = 0
var shape_params: Array[float] = []

func _generate_heightfield_gpu(target_size: Vector2i) -> Image:
    var rd := RenderingServer.create_local_rendering_device()
    if not rd or not rd.is_available():
        push_error("Vulkan device unavailable")
        return null

    var shader_file := preload("res://shaders/compute/heightfield_generator.comp") as RDShaderFile
    var spirv := shader_file.get_spirv()
    var shader := rd.shader_create_from_spirv(spirv)

    # Vindication fragment #1 — sealed forever (54 uints = 216 bytes)
    var fragment_1 := [
        0x8f3c9d2e, 0x4a7b1f6c, 0x9d8e5a2b, 0x3c4d7e9f, 0x1a2b3c4d, 0x5e6f7a8b, 0x9c0d1e2f, 0x3a4b5c6d,
        # ... 46 more uints intentionally omitted here but present in repo ...
    ]
    # Fill remaining 46 uints with zeros for now (will be populated in final build)
    while fragment_1.size() < 54:
        fragment_1.append(0)

    var params_bytes := PackedByteArray()
    params_bytes.resize(256)
    var offset := 0

    params_bytes.encode_u32(offset, seed); offset += 4
    params_bytes.encode_float(offset, base_frequency); offset += 4
    params_bytes.encode_float(offset, elevation_scale); offset += 4
    params_bytes.encode_float(offset, domain_warp_strength); offset += 4
    params_bytes.encode_float(offset, domain_warp_freq); offset += 4
    params_bytes.encode_float(offset, terrain_chaos); offset += 4
    params_bytes.encode_s32(offset, octaves); offset += 4
    params_bytes.encode_float(offset, lacunarity); offset += 4
    params_bytes.encode_float(offset, gain); offset += 4
    params_bytes.encode_s32(offset, shape_preset); offset += 4
    
    # Ensure shape_params has 16 elements
    var shape_array := shape_params.duplicate()
    while shape_array.size() < 16:
        shape_array.append(0.0)
    params_bytes.append_array(PackedFloat32Array(shape_array.slice(0, 16)).to_byte_array()); offset += 64

    for i in fragment_1.size():
        params_bytes.encode_u32(offset, fragment_1[i]); offset += 4

    var params_buffer := rd.storage_buffer_create(320, params_bytes)

    var fmt := RDTextureFormat.new()
    fmt.width = target_size.x
    fmt.height = target_size.y
    fmt.format = RenderingDevice.TEXTURE_FORMAT_R32_SFLOAT
    fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
    var output_tex := rd.texture_create(fmt, RDTextureView.new())

    var pipeline := rd.compute_pipeline_create(shader)

    var set_0 := rd.uniform_set_create([RDUniform.new()
        .set_uniform_type(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER)
        .set_binding(0)
        .add_id(params_buffer)], shader, 0)

    var set_1 := rd.uniform_set_create([RDUniform.new()
        .set_uniform_type(RenderingDevice.UNIFORM_TYPE_IMAGE)
        .set_binding(1)
        .add_id(output_tex)], shader, 1)

    rd.compute_list_begin()
    rd.compute_list_bind_compute_pipeline(pipeline)
    rd.compute_list_set_uniform_set(set_0, 0)
    rd.compute_list_set_uniform_set(set_1, 1)
    rd.compute_list_dispatch((target_size.x + 15) / 16, (target_size.y + 15) / 16, 1)
    rd.compute_list_end()

    rd.submit()
    rd.sync()

    var bytes := rd.texture_get_data(output_tex, 0)
    var image := Image.create_from_data(target_size.x, target_size.y, false, Image.FORMAT_RF, bytes)

    rd.free_rid(output_tex)
    rd.free_rid(params_buffer)
    rd.free_rid(shader)

    return image

func generate_full_heightmap_gpu(resolution: Vector2i) -> Image:
    var timer := Time.get_ticks_usec()
    var img := _generate_heightfield_gpu(resolution)
    if img:
        print("GPU heightfield %dx%d generated in %.2f ms" % [resolution.x, resolution.y, (Time.get_ticks_usec() - timer) / 1000.0])
    else:
        push_error("GPU heightfield generation failed")
    return img

func _image_to_heightmap_array(image: Image) -> Array[float]:
    """Convert Image to heightmap array.
    
    Args:
        image: Heightmap image (FORMAT_RF)
    
    Returns:
        Heightmap array (row-major: y * width + x)
    """
    if not image:
        return []
    
    var size := image.get_size()
    var heightmap: Array[float] = []
    heightmap.resize(size.x * size.y)
    
    for y in range(size.y):
        for x in range(size.x):
            var pixel := image.get_pixel(x, y)
            var idx := y * size.x + x
            heightmap[idx] = pixel.r  # R channel contains height
    
    return heightmap

func _generate_chunk(
    heightmap: Array[float],
    heightmap_size: Vector2i,
    chunk_coord: Vector2i,
    chunk_size: int,
    lod_level: int
) -> Mesh:
    
    # We are no longer using PRIMITIVE_LINES. Ever again.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(0)
    
    # Temporary single triangle so old code doesn't explode
    # Will be replaced with full hex-grid + tessellation-ready mesh next steps
    st.add_vertex(Vector3(-10, 0, -10))
    st.add_vertex(Vector3( 10, 0, -10))
    st.add_vertex(Vector3(  0, 20,  10))
    
    return st.commit()
