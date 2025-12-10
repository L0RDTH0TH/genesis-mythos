# ╔═══════════════════════════════════════════════════════════
# ║ TerrainGenerationConfig.gd
# ║ Desc: Data-driven terrain generation configuration loader
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name TerrainGenerationConfig
extends RefCounted

## Load terrain generation config from JSON
static func load_from_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TerrainGenerationConfig: Failed to load config from " + path)
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("TerrainGenerationConfig: Failed to parse JSON: " + json.get_error_message())
		return {}
	
	return json.data as Dictionary


## Get noise configuration from config dictionary
static func get_noise_config(config: Dictionary) -> Dictionary:
	return config.get("noise", {
		"seed": 0,
		"frequency": 0.0005,
		"type": "Perlin",
		"octaves": 4,
		"lacunarity": 2.0,
		"gain": 0.5
	})


## Get height configuration from config dictionary
static func get_height_config(config: Dictionary) -> Dictionary:
	return config.get("height", {
		"min": 0.0,
		"max": 150.0,
		"scale": 1.0
	})


## Get texture configurations from config dictionary
static func get_texture_configs(config: Dictionary) -> Array:
	return config.get("textures", [])


## Get terrain settings from config dictionary
static func get_terrain_settings(config: Dictionary) -> Dictionary:
	return config.get("terrain", {
		"region_size": 1024,
		"mesh_size": 64,
		"vertex_spacing": 1.0
	})


## Apply config to Terrain3DManager
static func apply_to_manager(config: Dictionary, manager) -> void:
	var noise_config: Dictionary = get_noise_config(config)
	var height_config: Dictionary = get_height_config(config)
	var terrain_settings: Dictionary = get_terrain_settings(config)
	
	# Apply terrain settings if terrain exists
	if manager.terrain != null:
		manager.terrain.region_size = terrain_settings.get("region_size", 1024)
		manager.terrain.mesh_size = terrain_settings.get("mesh_size", 64)
		manager.terrain.vertex_spacing = terrain_settings.get("vertex_spacing", 1.0)
	
	# Generate terrain with noise config
	manager.generate_from_noise(
		noise_config.get("seed", 0),
		noise_config.get("frequency", 0.0005),
		height_config.get("min", 0.0),
		height_config.get("max", 150.0)
	)
