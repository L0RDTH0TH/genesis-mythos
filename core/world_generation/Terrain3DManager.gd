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
	Logger.verbose("World/Terrain", "_ready() called")
	load_config()
	create_terrain()
	configure_terrain()
	Logger.info("World/Terrain", "Terrain3DManager initialized")

func load_config() -> void:
	Logger.verbose("World/Terrain", "load_config() called", {"path": TERRAIN_CONFIG_PATH})
	if ResourceLoader.exists(TERRAIN_CONFIG_PATH):
		var file: FileAccess = FileAccess.open(TERRAIN_CONFIG_PATH, FileAccess.READ)
		if file:
			var json_text: String = file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(json_text)
			if parsed is Dictionary:
				data_directory = parsed.get("data_dir", data_directory)
				Logger.debug("World/Terrain", "Config loaded", {"data_directory": data_directory})
			else:
				Logger.warn("World/Terrain", "Config file exists but contains invalid JSON")
		else:
			Logger.warn("World/Terrain", "Failed to open config file for reading")
	else:
		Logger.debug("World/Terrain", "Config file not found, creating default")
		DirAccess.make_dir_recursive_absolute("res://config")
		var default := { "data_dir": data_directory }
		var file := FileAccess.open(TERRAIN_CONFIG_PATH, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(default, "  "))
			file.close()
			Logger.info("World/Terrain", "Created default config file")
		else:
			Logger.error("World/Terrain", "Failed to create default config file")

func create_terrain() -> void:
	Logger.verbose("World/Terrain", "create_terrain() called")
	if terrain:
		Logger.debug("World/Terrain", "Existing terrain found, freeing")
		terrain.queue_free()

	terrain = ClassDB.instantiate("Terrain3D")
	if not terrain:
		Logger.error("World/Terrain", "FATAL: Terrain3D GDExtension failed to load!")
		return

	add_child(terrain)
	terrain.name = "WorldTerrain"
	# Optional: set owner for editor visibility if you ever open it elsewhere
	if Engine.is_editor_hint():
		terrain.owner = get_tree().edited_scene_root
	Logger.info("World/Terrain", "Terrain instance created", {"name": terrain.name})

func configure_terrain() -> void:
	Logger.verbose("World/Terrain", "configure_terrain() called")
	if not terrain:
		Logger.warn("World/Terrain", "Cannot configure terrain - terrain instance is null")
		return

	terrain.vertex_spacing = 1.0
	terrain.region_size = 1024
	Logger.debug("World/Terrain", "Terrain configured", {
		"vertex_spacing": terrain.vertex_spacing,
		"region_size": terrain.region_size
	})

	if data_directory:
		DirAccess.make_dir_recursive_absolute(data_directory)
		terrain.data_directory = data_directory
		Logger.debug("World/Terrain", "Data directory set", {"path": data_directory})

	if assets_resource:
		terrain.assets = assets_resource
		Logger.debug("World/Terrain", "Assets resource assigned")

func generate_initial_terrain() -> void:
	Logger.verbose("World/Terrain", "generate_initial_terrain() called")
	if terrain:
		# Example – replace with your actual procedural generation later
		if ResourceLoader.exists("res://assets/heightmap.png"):
			var img := load("res://assets/heightmap.png") as Image
			if img:
				Logger.info("World/Terrain", "Generating terrain from heightmap image", {"size": img.get_size()})
				terrain.create_from_heightmap_image(img)
			else:
				Logger.warn("World/Terrain", "Failed to load heightmap image")
		else:
			Logger.debug("World/Terrain", "Heightmap image not found at res://assets/heightmap.png")
	else:
		Logger.warn("World/Terrain", "Cannot generate initial terrain - terrain instance is null")


func generate_from_noise(seed_value: int, frequency: float, min_height: float, max_height: float) -> void:
	"""Generate terrain from noise parameters."""
	Logger.verbose("World/Terrain", "generate_from_noise() called", {
		"seed": seed_value,
		"frequency": frequency,
		"min_height": min_height,
		"max_height": max_height
	})
	if not terrain:
		Logger.warn("World/Terrain", "No terrain instance available")
		return
	
	# Create FastNoiseLite for procedural generation
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	Logger.debug("World/Terrain", "Noise generator configured", {"type": "Perlin"})
	
	# Generate heightmap image
	var size: int = 2048  # Heightmap resolution
	Logger.verbose("World/Terrain", "Creating heightmap image", {"size": size})
	var height_image: Image = Image.create(size, size, false, Image.FORMAT_RF)
	
	# Sample noise into heightmap
	Logger.verbose("World/Terrain", "Sampling noise into heightmap")
	for x in range(size):
		for y in range(size):
			var noise_value: float = noise.get_noise_2d(x, y)
			# Normalize from -1..1 to 0..1, then scale to height range
			var normalized: float = (noise_value + 1.0) / 2.0
			var height: float = lerp(min_height, max_height, normalized)
			# Store height in red channel (RF format)
			height_image.set_pixel(x, y, Color(height, 0.0, 0.0, 1.0))
	
	Logger.debug("World/Terrain", "Heightmap image generated")
	
	# Import heightmap into terrain
	# Terrain3D uses import_images with position offset and height range
	if terrain.has_method("data") and terrain.data != null:
		Logger.verbose("World/Terrain", "Importing heightmap via terrain.data.import_images()")
		terrain.data.import_images([height_image, null, null], Vector3(-size/2, 0, -size/2), min_height, max_height)
		terrain.update_maps()
		Logger.info("World/Terrain", "Terrain generated from noise", {
			"seed": seed_value,
			"frequency": frequency,
			"size": size,
			"height_range": [min_height, max_height]
		})
	else:
		# Fallback: try create_from_heightmap_image if available
		if terrain.has_method("create_from_heightmap_image"):
			Logger.debug("World/Terrain", "Using fallback create_from_heightmap_image() method")
			terrain.create_from_heightmap_image(height_image)
		else:
			Logger.error("World/Terrain", "No valid method to import heightmap into terrain")


func generate_from_heightmap(heightmap_image: Image, min_height: float = -50.0, max_height: float = 300.0, terrain_position: Vector3 = Vector3.ZERO) -> void:
	"""Generate terrain from hand-drawn heightmap image."""
	Logger.verbose("World/Terrain", "generate_from_heightmap() called", {
		"min_height": min_height,
		"max_height": max_height,
		"position": terrain_position
	})
	if terrain == null:
		Logger.debug("World/Terrain", "Terrain instance not found, creating new one")
		create_terrain()
	
	if heightmap_image == null:
		Logger.error("World/Terrain", "generate_from_heightmap() - heightmap_image is null")
		return
	
	var image_size: Vector2i = heightmap_image.get_size()
	Logger.debug("World/Terrain", "Processing heightmap image", {"size": image_size})
	
	# Ensure image is in correct format (Terrain3D prefers 16-bit or float)
	if heightmap_image.get_format() != Image.FORMAT_RF:
		Logger.verbose("World/Terrain", "Converting image format to RF")
		heightmap_image.convert(Image.FORMAT_RF)
	
	# Center the terrain
	terrain.global_position = terrain_position
	
	# Import heightmap directly (Terrain3D supports Image array: [height, control, color])
	var images: Array[Image] = [heightmap_image, null, null]
	var offset: Vector3 = Vector3(-heightmap_image.get_width() / 2.0, min_height, -heightmap_image.get_height() / 2.0)
	
	if terrain.has_method("data") and terrain.data != null:
		Logger.verbose("World/Terrain", "Importing heightmap via terrain.data.import_images()")
		terrain.data.import_images(images, offset, 1.0, max_height - min_height)
		
		# Force update
		terrain.update_maps()
		terrain.update_collision()
		
		Logger.info("World/Terrain", "Generated terrain from hand-drawn heightmap", {
			"size": image_size,
			"height_range": [min_height, max_height],
			"position": terrain_position
		})
	else:
		Logger.error("World/Terrain", "Terrain data is null, cannot import heightmap")
