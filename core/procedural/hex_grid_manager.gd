# ╔═══════════════════════════════════════════════════════════
# ║ hex_grid_manager.gd
# ║ Desc: Orchestrates GPU hex splatting and world chunk streaming
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

@export var hex_size: float = 50.0
@export var visible_radius_chunks: float = 18.0

@onready var multi_mesh_instance: MultiMeshInstance3D = get_node("/root/WorldRoot/ProceduralWorld/HexTerrain")

var rd: RenderingDevice
var pipeline: RID
var uniform_set: RID
var params_buffer: RID
var transform_buffer: RID
var custom_buffer: RID

var shader: RID
var use_gpu: bool = false

class Params extends RefCounted:
	var world_seed: int = 1337
	var hex_size: float = 50.0
	var chunk_radius: float = 64.0
	var camera_pos_axial: Vector2 = Vector2.ZERO

var params := Params.new()

const SQRT_3: float = 1.73205080757
const HEX_HEIGHT: float = 8.0

func _ready() -> void:
	_init_compute()

func _init_compute() -> void:
	rd = RenderingServer.create_local_rendering_device()
	if not rd:
		push_warning("Compute shaders not supported - using CPU fallback")
		use_gpu = false
		return

	# Try to load compute shader - will implement full GPU path in next iteration
	# For now, use CPU generation
	use_gpu = false
	push_warning("Using CPU-based hex grid generation (GPU compute coming in Phase 3)")

func _process(_delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
	
	var cam_pos = cam.global_position
	params.camera_pos_axial = world_to_axial(cam_pos)
	params.hex_size = hex_size
	params.chunk_radius = visible_radius_chunks

	_generate_hex_grid_cpu()

func _generate_hex_grid_cpu() -> void:
	var center: Vector2 = params.camera_pos_axial
	var instance_count: int = multi_mesh_instance.multimesh.instance_count
	var visible_count: int = 0
	
	for i in range(instance_count):
		var axial: Vector2 = _index_to_axial(i, center)
		var dist: float = axial.distance_to(center)
		
		if dist > params.chunk_radius:
			multi_mesh_instance.multimesh.set_instance_transform(i, Transform3D())
			continue
		
		var world_pos: Vector3 = axial_to_world(axial)
		var height: float = get_height_cpu(Vector2(world_pos.x, world_pos.z))
		
		var transform = Transform3D(
			Basis(Vector3(hex_size, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, hex_size)),
			Vector3(world_pos.x, height, world_pos.z)
		)
		
		multi_mesh_instance.multimesh.set_instance_transform(i, transform)
		multi_mesh_instance.multimesh.set_instance_custom_data(i, Color(0, 0, 0, 1))
		visible_count += 1
	
	multi_mesh_instance.multimesh.visible_instance_count = visible_count

func _index_to_axial(index: int, center: Vector2) -> Vector2:
	var pos_in_ring = index
	var axial = center
	
	for r in range(1, 512):
		if pos_in_ring < 6 * r:
			var side: int = pos_in_ring / r
			var offset = pos_in_ring % r
			
			axial = center
			axial += Vector2(0, r)
			for s in range(side):
				axial += Vector2(1, 0)
				if s >= 2:
					axial += Vector2(0, -1)
				if s >= 4:
					axial += Vector2(-1, 0)
			axial += Vector2(offset, -offset)
			break
		pos_in_ring -= 6 * r
	
	return axial

func axial_to_world(axial: Vector2) -> Vector3:
	var x = hex_size * (SQRT_3 * axial.x + SQRT_3/2.0 * axial.y)
	var z = hex_size * (3.0/2.0 * axial.y)
	return Vector3(x, 0.0, z)

func get_height_cpu(world_pos: Vector2) -> float:
	# Match terrain shader height ranges: -80 (deep ocean) to 400 (snow peaks)
	# Scale to match continental terrain system (20x multiplier)
	var n = sin(world_pos.x * 0.002 + float(params.world_seed)) * 0.5 + 0.5
	n += sin(world_pos.y * 0.003) * 0.3
	n = n * 0.5 + 0.5
	# Scale to continental range: -80 to 400
	# Normalize to -1 to 1, then map to -80 to 400
	var normalized = (n - 0.5) * 2.0  # -1 to 1
	var height = normalized * 240.0 + 160.0  # Maps -1→-80, 1→400
	return height

func world_to_axial(world: Vector3) -> Vector2:
	var q = (SQRT_3/3.0 * world.x - 1.0/3.0 * world.z) / hex_size
	var r = (2.0/3.0 * world.z) / hex_size
	return Vector2(q, r).round()
