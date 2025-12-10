# ╔═══════════════════════════════════════════════════════════
# ║ Terrain3DManager.gd
# ║ Desc: Manages procedural world terrain using Terrain3D (parser-safe)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends Node3D
class_name Terrain3DManager

const TERRAIN_CONFIG_PATH: String = "res://config/terrain_config.json"

@export var data_directory: String = "res://terrain_data/"
@export var assets_resource: Resource

var terrain = null  # Intentionally untyped – required for parser compatibility

func _ready() -> void:
	load_config()
	create_terrain()
	configure_terrain()

func load_config() -> void:
	if ResourceLoader.exists(TERRAIN_CONFIG_PATH):
		var file := FileAccess.open(TERRAIN_CONFIG_PATH, FileAccess.READ)
		var json_text := file.get_as_text()
		var parsed := JSON.parse_string(json_text)
		if parsed is Dictionary:
			data_directory = parsed.get("data_dir", data_directory)
	else:
		DirAccess.make_dir_recursive_absolute("res://config")
		var default := { "data_dir": data_directory }
		var file := FileAccess.open(TERRAIN_CONFIG_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(default, "  "))

func create_terrain() -> void:
	if terrain:
		terrain.queue_free()

	terrain = ClassDB.instantiate("Terrain3D")
	if not terrain:
		push_error("FATAL: Terrain3D GDExtension failed to load!")
		return

	add_child(terrain)
	terrain.name = "WorldTerrain"
	# Optional: set owner for editor visibility if you ever open it elsewhere
	if Engine.is_editor_hint():
		terrain.owner = get_tree().edited_scene_root

func configure_terrain() -> void:
	if not terrain:
		return

	terrain.vertex_spacing = 1.0
	terrain.region_size = 1024

	if data_directory:
		DirAccess.make_dir_recursive_absolute(data_directory)
		terrain.data_directory = data_directory

	if assets_resource:
		terrain.assets = assets_resource

func generate_initial_terrain() -> void:
	if terrain:
		# Example – replace with your actual procedural generation later
		if ResourceLoader.exists("res://assets/heightmap.png"):
			var img := load("res://assets/heightmap.png") as Image
			if img:
				terrain.create_from_heightmap_image(img)


func generate_from_noise(seed_value: int, frequency: float, min_height: float, max_height: float) -> void:
	"""Generate terrain from noise parameters."""
	if not terrain:
		push_warning("Terrain3DManager: No terrain instance available")
		return
	
	# Create FastNoiseLite for procedural generation
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Generate heightmap image
	var size: int = 2048  # Heightmap resolution
	var height_image: Image = Image.create(size, size, false, Image.FORMAT_RF)
	
	# Sample noise into heightmap
	for x in range(size):
		for y in range(size):
			var noise_value: float = noise.get_noise_2d(x, y)
			# Normalize from -1..1 to 0..1, then scale to height range
			var normalized: float = (noise_value + 1.0) / 2.0
			var height: float = lerp(min_height, max_height, normalized)
			# Store height in red channel (RF format)
			height_image.set_pixel(x, y, Color(height, 0.0, 0.0, 1.0))
	
	# Import heightmap into terrain
	# Terrain3D uses import_images with position offset and height range
	if terrain.has_method("data") and terrain.data != null:
		terrain.data.import_images([height_image, null, null], Vector3(-size/2, 0, -size/2), min_height, max_height)
		terrain.update_maps()
	else:
		# Fallback: try create_from_heightmap_image if available
		if terrain.has_method("create_from_heightmap_image"):
			terrain.create_from_heightmap_image(height_image)
	
	print("Terrain3DManager: Generated terrain from noise (seed: ", seed_value, ", frequency: ", frequency, ")")
