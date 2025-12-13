# ╔═══════════════════════════════════════════════════════════
# ║ ProceduralWorldDatasource.gd
# ║ Desc: Custom datasource for ProceduralWorldMap addon with archetype-based generation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends ProceduralWorldDatasource

## Fantasy archetype configuration
var archetype: Dictionary = {}

## Landmass type (Continents, Single Island, Island Chain, etc.)
var landmass_type: String = "Continents"

## Biome colors from archetype
var biome_colors: Dictionary = {}

## Biome thresholds from archetype (Phase 1)
var biome_thresholds: Dictionary = {}

## Height scale from archetype
var height_scale: float = 0.8

## Sea level from terrain config (Phase 4)
var sea_level: float = 0.4

## Noise generator for heightmap
var noise: FastNoiseLite = null

## Temperature and moisture noise generators (Phase 2)
var temperature_noise: FastNoiseLite = null
var moisture_noise: FastNoiseLite = null

## Generation mode: "height_only" or "height_and_climate" (Phase 2)
var generation_mode: String = "height_only"

## Fantasy biome configurations (Phase 3)
var fantasy_biomes: Dictionary = {}

## Additional parameters for UI/metadata (Phase 5)
var additional_params: Dictionary = {}

## Cached height image
var cached_height_image: Image = null

## Cached biome image
var cached_biome_image: Image = null

## RNG for fantasy biome spawning (Phase 3)
var fantasy_rng: RandomNumberGenerator = null


func _init() -> void:
	"""Initialize datasource with default values."""
	super._init()
	noise = FastNoiseLite.new()
	temperature_noise = FastNoiseLite.new()
	moisture_noise = FastNoiseLite.new()
	fantasy_rng = RandomNumberGenerator.new()


func configure_from_archetype(arch: Dictionary, landmass: String, seed_value: int) -> void:
	"""Configure datasource from fantasy archetype with backward compatibility."""
	archetype = arch
	landmass_type = landmass
	
	# Backward compatibility: Check if using old flat format or new grouped format
	var using_new_format: bool = arch.has("noise") or arch.has("biomes") or arch.has("terrain")
	
	if using_new_format:
		# New grouped format
		var noise_config: Dictionary = arch.get("noise", {})
		var biomes_config: Dictionary = arch.get("biomes", {})
		var terrain_config: Dictionary = arch.get("terrain", {})
		
		# Configure noise from grouped structure
		var noise_type_str: String = noise_config.get("noise_type", "TYPE_SIMPLEX")
		_configure_noise_type(noise_type_str)
		noise.seed = seed_value
		noise.frequency = noise_config.get("frequency", 0.004)
		noise.fractal_octaves = noise_config.get("octaves", 6)
		noise.fractal_gain = noise_config.get("gain", 0.5)
		noise.fractal_lacunarity = noise_config.get("lacunarity", 2.0)
		height_scale = noise_config.get("height_scale", 0.8)
		
		# Configure biome colors and thresholds (Phase 1)
		biome_colors = biomes_config.get("colors", {})
		biome_thresholds = biomes_config.get("thresholds", {
			"water": 0.35,
			"beach": 0.38,
			"grass": 0.5,
			"forest": 0.65,
			"hill": 0.8,
			"mountain": 0.95,
			"snow": 1.0
		})
		generation_mode = biomes_config.get("generation_mode", "height_only")
		fantasy_biomes = biomes_config.get("fantasy_biomes", {})
		
		# Configure terrain (Phase 4)
		sea_level = terrain_config.get("sea_level", 0.4)
		
		# Configure climate (Phase 2)
		var climate_config: Dictionary = arch.get("climate", {})
		var temp_freq: float = climate_config.get("temperature_noise_frequency", 0.002)
		var moist_freq: float = climate_config.get("moisture_noise_frequency", 0.002)
		var temp_bias: float = climate_config.get("temperature_bias", 0.0)
		var moist_bias: float = climate_config.get("moisture_bias", 0.0)
		
		temperature_noise.seed = seed_value + 2000
		temperature_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		temperature_noise.frequency = temp_freq
		temperature_noise.offset = Vector3(0, 0, temp_bias * 1000.0)  # Bias via offset
		
		moisture_noise.seed = seed_value + 3000
		moisture_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		moisture_noise.frequency = moist_freq
		moisture_noise.offset = Vector3(0, 0, moist_bias * 1000.0)  # Bias via offset
		
		# Additional params (Phase 5)
		additional_params = arch.get("additional_params", {})
	else:
		# Old flat format - backward compatibility
		biome_colors = arch.get("biome_colors", {})
		height_scale = arch.get("height_scale", 0.8)
		sea_level = 0.4  # Default
		
		# Configure noise from flat keys
		var noise_type_str: String = arch.get("noise_type", "TYPE_SIMPLEX")
		_configure_noise_type(noise_type_str)
		noise.seed = seed_value
		noise.frequency = arch.get("frequency", 0.004)
		noise.fractal_octaves = arch.get("octaves", 6)
		noise.fractal_gain = arch.get("gain", 0.5)
		noise.fractal_lacunarity = arch.get("lacunarity", 2.0)
		
		# Default thresholds for old format
		biome_thresholds = {
			"water": 0.35,
			"beach": 0.38,
			"grass": 0.5,
			"forest": 0.65,
			"hill": 0.8,
			"mountain": 0.95,
			"snow": 1.0
		}
		generation_mode = "height_only"
		fantasy_biomes = {}
		
		# Default climate config for old format
		temperature_noise.seed = seed_value + 2000
		temperature_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		temperature_noise.frequency = 0.002
		moisture_noise.seed = seed_value + 3000
		moisture_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		moisture_noise.frequency = 0.002
		
		additional_params = {}
	
	seed = seed_value
	fantasy_rng.seed = seed_value


func _configure_noise_type(noise_type_str: String) -> void:
	"""Map noise type string to enum."""
	match noise_type_str:
		"TYPE_SIMPLEX":
			noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		"TYPE_SIMPLEX_SMOOTH":
			noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
		"TYPE_PERLIN":
			noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
		"TYPE_VALUE":
			noise.noise_type = FastNoiseLite.NoiseType.TYPE_VALUE
		"TYPE_CELLULAR":
			noise.noise_type = FastNoiseLite.NoiseType.TYPE_CELLULAR


func get_biome_image(camera_zoomed_size: Vector2i) -> ImageTexture:
	"""Generate biome image using archetype-based parameters."""
	if archetype.is_empty():
		# Fallback to default generation
		var default_img: Image = Image.create(camera_zoomed_size.x, camera_zoomed_size.y, false, Image.FORMAT_RGB8)
		default_img.fill(Color.BLUE)
		return ImageTexture.create_from_image(default_img)
	
	# Generate heightmap
	var height_img: Image = _generate_height_image(camera_zoomed_size)
	
	# Apply landmass mask
	_apply_landmass_mask(height_img, camera_zoomed_size)
	
	# Generate biome image from heightmap
	var biome_img: Image = _generate_biome_image(height_img, camera_zoomed_size)
	
	# Cache images for later use
	cached_height_image = height_img
	cached_biome_image = biome_img
	
	return ImageTexture.create_from_image(biome_img)


func get_height_image() -> Image:
	"""Get cached height image as grayscale."""
	if cached_height_image == null:
		return null
	return cached_height_image


func get_cached_biome_image() -> Image:
	"""Get cached biome image."""
	if cached_biome_image == null:
		return null
	return cached_biome_image


func get_additional_params() -> Dictionary:
	"""Get additional parameters for UI/metadata (Phase 5)."""
	return additional_params.duplicate()


func _generate_height_image(size: Vector2i) -> Image:
	"""Generate heightmap using noise with proper world coordinates."""
	var height_img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RF)
	
	# Update noise offset and frequency based on datasource offset/zoom (set by addon)
	noise.offset = Vector3(offset.x, offset.y, 0)
	
	# Get base frequency from archetype (support both formats)
	var base_frequency: float
	if archetype.has("noise"):
		base_frequency = archetype["noise"].get("frequency", 0.004)
	else:
		base_frequency = archetype.get("frequency", 0.004)
	
	noise.frequency = base_frequency / zoom if zoom > 0.0 else base_frequency
	
	# Generate heightmap using world coordinates
	for y: int in size.y:
		for x: int in size.x:
			# Use world coordinates (offset is already set by addon)
			var world_x: float = float(x) + offset.x
			var world_y: float = float(y) + offset.y
			var val: float = (noise.get_noise_2d(world_x, world_y) + 1.0) / 2.0 * height_scale
			val = clampf(val, 0.0, 1.0)
			height_img.set_pixel(x, y, Color(val, val, val))
	
	return height_img


func _apply_landmass_mask(img: Image, size: Vector2i) -> void:
	"""Apply landmass-specific mask to heightmap."""
	match landmass_type:
		"Single Island":
			_apply_radial_mask(img, size.x, size.y, 0.5, 0.5, 0.35)
		"Island Chain":
			_apply_multi_radial_mask(img, size.x, size.y, 4, 0.25)
		"Archipelago":
			_apply_multi_radial_mask(img, size.x, size.y, 12, 0.15)
		"Pangea":
			_apply_radial_mask(img, size.x, size.y, 0.5, 0.5, 0.9, true)
		"Coastal":
			_apply_coastal_mask(img, size.x, size.y)
		_:  # Continents: no mask
			pass


func _apply_radial_mask(img: Image, width: int, height: int, cx: float, cy: float, radius: float, invert: bool = false) -> void:
	"""Apply radial mask to heightmap."""
	var center: Vector2 = Vector2(width * cx, height * cy)
	for y: int in height:
		for x: int in width:
			var dist: float = Vector2(x, y).distance_to(center) / (width * radius)
			var falloff: float = clampf(1.0 - dist, 0.0, 1.0)
			if invert:
				falloff = 1.0 - falloff
			var val: float = img.get_pixel(x, y).r * falloff
			img.set_pixel(x, y, Color(val, val, val))


func _apply_multi_radial_mask(img: Image, width: int, height: int, num: int, radius: float) -> void:
	"""Apply multiple radial masks for island chains."""
	# Use deterministic seed for reproducible results
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	
	for i: int in num:
		var cx: float = rng.randf_range(0.1, 0.9)
		var cy: float = rng.randf_range(0.1, 0.9)
		_apply_radial_mask(img, width, height, cx, cy, radius)


func _apply_coastal_mask(img: Image, width: int, height: int) -> void:
	"""Apply coastal mask (lower edges)."""
	_apply_radial_mask(img, width, height, 0.5, 0.5, 0.7, true)


func _generate_biome_image(height_img: Image, size: Vector2i) -> Image:
	"""Generate biome image using height and optionally climate (Phase 2) and fantasy biomes (Phase 3)."""
	var biome_img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	
	# Update climate noise offsets for world coordinates
	temperature_noise.offset = Vector3(offset.x, offset.y, 0)
	moisture_noise.offset = Vector3(offset.x, offset.y, 0)
	
	for y: int in size.y:
		for x: int in size.x:
			var h: float = height_img.get_pixel(x, y).r
			var col: Color
			
			# Get world coordinates for climate sampling
			var world_x: float = float(x) + offset.x
			var world_y: float = float(y) + offset.y
			
			# Sample temperature and moisture if using climate generation
			var temp: float = 0.5
			var moist: float = 0.5
			if generation_mode == "height_and_climate":
				temp = (temperature_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
				moist = (moisture_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
				# Apply biases (already in offset, but can add direct bias if needed)
				temp = clampf(temp, 0.0, 1.0)
				moist = clampf(moist, 0.0, 1.0)
			
			# Check for fantasy biomes first (Phase 3)
			var fantasy_match: String = _check_fantasy_biome(h, temp, moist)
			if fantasy_match != "":
				col = Color(biome_colors.get(fantasy_match, "#000000"))
			elif generation_mode == "height_and_climate":
				# Climate-based biome selection (Phase 2)
				col = _get_biome_color_from_climate(h, temp, moist)
			else:
				# Height-based biome selection (Phase 1)
				col = _get_biome_color_from_height(h)
			
			biome_img.set_pixel(x, y, col)
	
	return biome_img


func _get_biome_color_from_height(height: float) -> Color:
	"""Get biome color based on height using configurable thresholds (Phase 1)."""
	# Sort thresholds by value
	var sorted_biomes: Array = []
	for biome_name: String in biome_thresholds.keys():
		sorted_biomes.append({
			"name": biome_name,
			"threshold": biome_thresholds[biome_name]
		})
	sorted_biomes.sort_custom(func(a, b): return a["threshold"] < b["threshold"])
	
	# Find matching biome
	for biome_data: Dictionary in sorted_biomes:
		if height < biome_data["threshold"]:
			return Color(biome_colors.get(biome_data["name"], "#000000"))
	
	# Default to last biome (usually snow)
	if sorted_biomes.size() > 0:
		var last_biome: String = sorted_biomes[-1]["name"]
		return Color(biome_colors.get(last_biome, "#ffffff"))
	
	return Color.WHITE


func _get_biome_color_from_climate(height: float, temperature: float, moisture: float) -> Color:
	"""Get biome color based on height, temperature, and moisture (Phase 2)."""
	# Underwater - use sea_level from terrain config
	if height < sea_level:
		return Color(biome_colors.get("water", "#2a6d9e"))
	
	# Beach - narrow band above sea level
	if height < sea_level + 0.03:
		return Color(biome_colors.get("beach", "#d4b56a"))
	
	# Climate-based biomes
	# Simple rules: temperature determines base biome, moisture modifies it
	# This is a simplified system - can be enhanced with biomes.json integration later
	
	# Cold regions (temperature < 0.3)
	if temperature < 0.3:
		if moisture > 0.6:
			# Tundra/snow
			if height > 0.8:
				return Color(biome_colors.get("snow", "#ffffff"))
			else:
				return Color(biome_colors.get("snow", "#ffffff"))  # Use snow color for tundra
		else:
			# Cold desert/ice
			if height > 0.8:
				return Color(biome_colors.get("snow", "#ffffff"))
			else:
				return Color(biome_colors.get("hill", "#8b7355"))
	
	# Temperate regions (0.3 <= temperature < 0.7)
	elif temperature < 0.7:
		if moisture > 0.7:
			# Forest (high moisture)
			return Color(biome_colors.get("forest", "#2d5a3d"))
		elif moisture > 0.4:
			# Grass/plains (moderate moisture)
			return Color(biome_colors.get("grass", "#3d8c40"))
		else:
			# Grassland (low moisture)
			return Color(biome_colors.get("grass", "#3d8c40"))
	
	# Hot regions (temperature >= 0.7)
	else:
		if moisture > 0.7:
			# Tropical/jungle (high moisture)
			return Color(biome_colors.get("forest", "#2d5a3d"))
		elif moisture > 0.3:
			# Savanna/grass (moderate moisture)
			return Color(biome_colors.get("grass", "#3d8c40"))
		else:
			# Desert (low moisture)
			return Color(biome_colors.get("hill", "#8b7355"))  # Use hill color for desert
	
	# Fallback to height-based if no climate match
	return _get_biome_color_from_height(height)


func _check_fantasy_biome(height: float, temperature: float, moisture: float) -> String:
	"""Check if conditions match a fantasy biome (Phase 3)."""
	if fantasy_biomes.is_empty():
		return ""
	
	for biome_name: String in fantasy_biomes.keys():
		var biome_def: Dictionary = fantasy_biomes[biome_name]
		var h_range: Array = biome_def.get("height_range", [0.0, 1.0])
		var t_range: Array = biome_def.get("temperature_range", [0.0, 1.0])
		var m_range: Array = biome_def.get("moisture_range", [0.0, 1.0])
		var spawn_chance: float = biome_def.get("spawn_chance", 0.0)
		
		# Check if conditions match
		if (height >= h_range[0] and height <= h_range[1] and
			temperature >= t_range[0] and temperature <= t_range[1] and
			moisture >= m_range[0] and moisture <= m_range[1]):
			# Check spawn chance
			if fantasy_rng.randf() < spawn_chance:
				return biome_name
	
	return ""


func _apply_terrain_post_processing(height_img: Image) -> Image:
	"""Apply optional terrain post-processing (erosion, rivers) - Phase 4.
	Note: This is a placeholder - full erosion/river implementation can be added later."""
	# For now, just return the original image
	# Erosion and rivers are computationally expensive and may be better suited
	# for full map generation in MapGenerator.gd rather than datasource preview
	return height_img
