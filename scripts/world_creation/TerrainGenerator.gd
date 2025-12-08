# ╔═══════════════════════════════════════════════════════════
# ║ TerrainGenerator.gd
# ║ Desc: Generates procedural 3D topographic map with lines and nodes
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends MeshInstance3D

@export var seed_value: int = 0
@export var world_size: Vector2i = Vector2i(512, 512)
@export var grid_resolution: int = 64  # Points per side
@export var height_scale: float = 10.0
@export var noise_frequency: float = 0.01
@export var line_material: Material = preload("res://materials/blue_glow.tres")

var noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	"""Initialize and generate terrain."""
	print("TerrainGenerator: Starting generation with seed ", seed_value, " size ", world_size)
	generate_terrain()
	print("TerrainGenerator: Generation complete, mesh surfaces: ", mesh.get_surface_count() if mesh else "No mesh")

func generate_terrain() -> void:
	"""Generate procedural 3D topographic map with interconnected lines."""
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_frequency
	print("TerrainGenerator: Noise setup complete")
	
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	# Lines surface
	var st_lines: SurfaceTool = SurfaceTool.new()
	st_lines.begin(Mesh.PRIMITIVE_LINES)
	
	var points: Array[Vector3] = []
	var half_size: Vector2 = world_size / 2.0
	var step: Vector2 = world_size / (grid_resolution - 1.0)
	print("TerrainGenerator: Step size ", step, " half_size ", half_size)
	
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			var pos_2d: Vector2 = Vector2(x * step.x, y * step.y) - half_size
			var height: float = noise.get_noise_2d(pos_2d.x, pos_2d.y) * height_scale
			points.append(Vector3(pos_2d.x, height, pos_2d.y))
	
	print("TerrainGenerator: Generated ", points.size(), " points")
	
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			var idx: int = x * grid_resolution + y
			if y < grid_resolution - 1:
				st_lines.add_vertex(points[idx])
				st_lines.add_vertex(points[idx + 1])
			if x < grid_resolution - 1:
				st_lines.add_vertex(points[idx])
				st_lines.add_vertex(points[idx + grid_resolution])
	
	var arrays: Array = st_lines.commit_to_arrays()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	array_mesh.surface_set_material(0, line_material)
	
	# Points surface for nodes
	var st_points: SurfaceTool = SurfaceTool.new()
	st_points.begin(Mesh.PRIMITIVE_POINTS)
	for p in points:
		st_points.add_vertex(p)
	
	arrays = st_points.commit_to_arrays()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	array_mesh.surface_set_material(1, line_material)  # Same material for glowing dots
	
	mesh = array_mesh
	material_override = null  # Not needed since per surface
	print("TerrainGenerator: Mesh created with 2 surfaces")
