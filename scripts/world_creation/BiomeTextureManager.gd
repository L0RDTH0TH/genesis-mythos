# ╔═══════════════════════════════════════════════════════════
# ║ BiomeTextureManager.gd
# ║ Desc: Static utility class for loading and managing biome textures
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name BiomeTextureManager
extends RefCounted

"""Static utility class for biome texture loading and management."""

static var texture_cache: Dictionary = {}
static var normal_cache: Dictionary = {}
static var biome_config: Dictionary = {}

static func load_config() -> bool:
	"""Load biome texture configuration from JSON.
	
	Returns:
		True if config loaded successfully
	"""
	var config_path: String = "res://assets/data/biome_textures.json"
	var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		print("BiomeTextureManager: WARNING - Config file not found: ", config_path)
		return false
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_text)
	if error != OK:
		print("BiomeTextureManager: ERROR - Failed to parse JSON: ", json.get_error_message())
		return false
	
	biome_config = json.data
	print("BiomeTextureManager: Loaded config for ", biome_config.get("biome_textures", {}).size(), " biomes")
	return true

static func get_texture(biome_name: String) -> Texture2D:
	"""Get texture for a biome (with caching).
	
	Args:
		biome_name: Name of the biome (e.g., "forest", "desert")
	
	Returns:
		Texture2D or null if not found
	"""
	if texture_cache.has(biome_name):
		return texture_cache[biome_name]
	
	if biome_config.is_empty():
		if not load_config():
			return null
	
	var biome_textures: Dictionary = biome_config.get("biome_textures", {})
	if not biome_textures.has(biome_name):
		print("BiomeTextureManager: WARNING - Biome not found: ", biome_name)
		return null
	
	var biome_data: Dictionary = biome_textures[biome_name]
	var texture_path: String = biome_data.get("texture_path", "")
	
	if texture_path.is_empty():
		return null
	
	# Try to load texture
	var texture: Texture2D = load(texture_path)
	if texture:
		texture_cache[biome_name] = texture
		return texture
	else:
		print("BiomeTextureManager: WARNING - Failed to load texture: ", texture_path)
		return null

static func get_normal_map(biome_name: String) -> Texture2D:
	"""Get normal map for a biome (with caching).
	
	Args:
		biome_name: Name of the biome
	
	Returns:
		Texture2D or null if not found/optional
	"""
	if normal_cache.has(biome_name):
		return normal_cache[biome_name]
	
	if biome_config.is_empty():
		if not load_config():
			return null
	
	var biome_textures: Dictionary = biome_config.get("biome_textures", {})
	if not biome_textures.has(biome_name):
		return null
	
	var biome_data: Dictionary = biome_textures[biome_name]
	var normal_path: String = biome_data.get("normal_path", "")
	
	if normal_path.is_empty():
		return null
	
	var normal: Texture2D = load(normal_path)
	if normal:
		normal_cache[biome_name] = normal
		return normal
	
	return null

static func get_biome_color(biome_name: String) -> Color:
	"""Get default color for a biome.
	
	Args:
		biome_name: Name of the biome
	
	Returns:
		Color (defaults to gray if not found)
	"""
	if biome_config.is_empty():
		if not load_config():
			return Color(0.5, 0.5, 0.5)
	
	var biome_textures: Dictionary = biome_config.get("biome_textures", {})
	if not biome_textures.has(biome_name):
		return Color(0.5, 0.5, 0.5)
	
	var biome_data: Dictionary = biome_textures[biome_name]
	var color_array: Array = biome_data.get("color", [0.5, 0.5, 0.5])
	
	if color_array.size() >= 3:
		return Color(color_array[0], color_array[1], color_array[2])
	
	return Color(0.5, 0.5, 0.5)

static func get_splat_channel(biome_name: String) -> int:
	"""Get splat channel index for a biome.
	
	Args:
		biome_name: Name of the biome
	
	Returns:
		Splat channel (0-3) or 0 if not found
	"""
	if biome_config.is_empty():
		if not load_config():
			return 0
	
	var biome_textures: Dictionary = biome_config.get("biome_textures", {})
	if not biome_textures.has(biome_name):
		return 0
	
	var biome_data: Dictionary = biome_textures[biome_name]
	return biome_data.get("splat_channel", 0)

static func get_all_biome_names() -> Array[String]:
	"""Get list of all biome names from config.
	
	Returns:
		Array of biome name strings
	"""
	if biome_config.is_empty():
		if not load_config():
			return []
	
	var biome_textures: Dictionary = biome_config.get("biome_textures", {})
	var names: Array[String] = []
	for biome_name in biome_textures.keys():
		names.append(biome_name)
	return names
