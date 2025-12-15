# ╔═══════════════════════════════════════════════════════════
# ║ ProceduralWorldDatasource.gd
# ║ Desc: Custom datasource for ProceduralWorldMap addon with archetype-based generation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends "res://addons/procedural_world_map/datasource.gd"

## Fantasy archetype configuration
var archetype: Dictionary = {}

## Landmass type (Continents, Single Island, Island Chain, etc.)
var landmass_type: String = "Continents"

## Landmass type configurations loaded from JSON
var landmass_configs: Dictionary = {}

## Additional noise generator for landmass masks (e.g., noise_mask, voronoi)
var landmass_mask_noise: FastNoiseLite = null

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
	noise = FastNoiseLite.new()
	temperature_noise = FastNoiseLite.new()
	moisture_noise = FastNoiseLite.new()
	landmass_mask_noise = FastNoiseLite.new()
	fantasy_rng = RandomNumberGenerator.new()
	_load_landmass_configs()


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


func _load_landmass_configs() -> void:
	"""Load landmass type configurations from JSON."""
	const CONFIG_PATH: String = "res://data/config/landmass_types.json"
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("ProceduralWorldDatasource: Failed to load landmass configs from " + CONFIG_PATH)
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("ProceduralWorldDatasource: Failed to parse landmass configs JSON: " + json.get_error_message())
		return
	
	var data: Dictionary = json.data
	landmass_configs = data.get("landmass_types", {})
	print("ProceduralWorldDatasource: Loaded ", landmass_configs.size(), " landmass type configurations")


func _apply_landmass_mask(img: Image, size: Vector2i) -> void:
	"""Apply landmass-specific mask to heightmap using config-based masks."""
	if landmass_type == "Continents" or not landmass_configs.has(landmass_type):
		# Continents: no mask, or type not found in config
		return
	
	var config: Dictionary = landmass_configs.get(landmass_type, {})
	var mask_type: String = config.get("type", "none")
	
	match mask_type:
		"none":
			# No mask applied
			pass
		"radial":
			var center: Array = config.get("center", [0.5, 0.5])
			var radius: float = config.get("radius", 0.35)
			var invert: bool = config.get("invert", false)
			var smooth: bool = config.get("smooth_edges", false)
			var smooth_radius: float = config.get("smooth_radius", 0.1)
			_apply_radial_mask(img, size.x, size.y, center[0], center[1], radius, invert, smooth, smooth_radius)
		"multi_radial":
			var count: int = config.get("count", 4)
			var radius: float = config.get("radius", 0.25)
			var pos_range: Array = config.get("position_range", [0.1, 0.9])
			var smooth: bool = config.get("smooth_edges", false)
			var min_spacing: float = config.get("min_spacing", 0.2)
			_apply_multi_radial_mask(img, size.x, size.y, count, radius, pos_range, smooth, min_spacing)
		"noise_mask":
			var noise_type_str: String = config.get("noise_type", "TYPE_PERLIN")
			var frequency: float = config.get("frequency", 0.01)
			var threshold: float = config.get("threshold", 0.5)
			var invert: bool = config.get("invert", false)
			var octaves: int = config.get("octaves", 4)
			var lacunarity: float = config.get("lacunarity", 2.0)
			var persistence: float = config.get("persistence", 0.5)
			_apply_noise_mask(img, size.x, size.y, noise_type_str, frequency, threshold, invert, octaves, lacunarity, persistence)
		"voronoi":
			var cell_count: int = config.get("cell_count", 8)
			var jitter: float = config.get("jitter", 0.5)
			var threshold: float = config.get("threshold", 0.4)
			var invert: bool = config.get("invert", false)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_voronoi_mask(img, size.x, size.y, cell_count, jitter, threshold, invert, smooth)
		"ring":
			var center: Array = config.get("center", [0.5, 0.5])
			var inner_radius: float = config.get("inner_radius", 0.3)
			var outer_radius: float = config.get("outer_radius", 0.5)
			var island_count: int = config.get("island_count", 8)
			var island_radius: float = config.get("island_radius", 0.08)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_ring_mask(img, size.x, size.y, center[0], center[1], inner_radius, outer_radius, island_count, island_radius, smooth)
		"peninsula":
			var base_center: Array = config.get("base_center", [0.5, 0.8])
			var base_radius: float = config.get("base_radius", 0.4)
			var direction: Array = config.get("peninsula_direction", [0.0, -1.0])
			var length: float = config.get("peninsula_length", 0.3)
			var width: float = config.get("peninsula_width", 0.15)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_peninsula_mask(img, size.x, size.y, base_center[0], base_center[1], base_radius, Vector2(direction[0], direction[1]), length, width, smooth)
		"atoll":
			var center: Array = config.get("center", [0.5, 0.5])
			var outer_radius: float = config.get("outer_radius", 0.4)
			var inner_radius: float = config.get("inner_radius", 0.25)
			var island_count: int = config.get("island_count", 12)
			var island_radius: float = config.get("island_radius", 0.05)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_atoll_mask(img, size.x, size.y, center[0], center[1], outer_radius, inner_radius, island_count, island_radius, smooth)
		"fjord":
			var coast_direction: Array = config.get("coast_direction", [0.0, 1.0])
			var fjord_count: int = config.get("fjord_count", 6)
			var fjord_length: float = config.get("fjord_length", 0.3)
			var fjord_width: float = config.get("fjord_width", 0.05)
			var land_base_radius: float = config.get("land_base_radius", 0.6)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_fjord_mask(img, size.x, size.y, Vector2(coast_direction[0], coast_direction[1]), fjord_count, fjord_length, fjord_width, land_base_radius, smooth)
		_:
			push_warning("ProceduralWorldDatasource: Unknown landmass mask type: " + mask_type)


func _apply_radial_mask(img: Image, width: int, height: int, cx: float, cy: float, radius: float, invert: bool = false, smooth_edges: bool = false, smooth_radius: float = 0.1) -> void:
	"""Apply radial mask to heightmap."""
	var center: Vector2 = Vector2(width * cx, height * cy)
	var max_dist: float = width * radius
	
	for y: int in height:
		for x: int in width:
			var dist: float = Vector2(x, y).distance_to(center)
			var normalized_dist: float = dist / max_dist
			var falloff: float
			
			if smooth_edges and smooth_radius > 0.0:
				# Smooth falloff using smoothstep
				var edge_start: float = 1.0 - smooth_radius
				if normalized_dist < edge_start:
					falloff = 1.0
				elif normalized_dist > 1.0:
					falloff = 0.0
				else:
					var t: float = (normalized_dist - edge_start) / smooth_radius
					falloff = 1.0 - smoothstep(0.0, 1.0, t)
			else:
				falloff = clampf(1.0 - normalized_dist, 0.0, 1.0)
			
			if invert:
				falloff = 1.0 - falloff
			
			var val: float = img.get_pixel(x, y).r * falloff
			img.set_pixel(x, y, Color(val, val, val))


func _apply_multi_radial_mask(img: Image, width: int, height: int, num: int, radius: float, position_range: Array = [0.1, 0.9], smooth_edges: bool = false, min_spacing: float = 0.2) -> void:
	"""Apply multiple radial masks for island chains."""
	# Use deterministic seed for reproducible results
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	
	var positions: Array[Vector2] = []
	var min_dist_sq: float = (min_spacing * width) * (min_spacing * width)
	var attempts: int = 0
	const MAX_ATTEMPTS: int = 1000
	
	# Generate positions with minimum spacing
	for i: int in num:
		var valid: bool = false
		var cx: float
		var cy: float
		
		while not valid and attempts < MAX_ATTEMPTS:
			cx = rng.randf_range(position_range[0], position_range[1])
			cy = rng.randf_range(position_range[0], position_range[1])
			var pos: Vector2 = Vector2(cx * width, cy * height)
			
			valid = true
			for existing_pos: Vector2 in positions:
				if pos.distance_squared_to(existing_pos) < min_dist_sq:
					valid = false
					break
			
			attempts += 1
		
		if valid:
			positions.append(Vector2(cx * width, cy * height))
			var smooth_radius: float = 0.1 if smooth_edges else 0.0
			_apply_radial_mask(img, width, height, cx, cy, radius, false, smooth_edges, smooth_radius)


func _apply_coastal_mask(img: Image, width: int, height: int) -> void:
	"""Apply coastal mask (lower edges)."""
	_apply_radial_mask(img, width, height, 0.5, 0.5, 0.7, true, true, 0.1)


func _apply_noise_mask(img: Image, width: int, height: int, noise_type_str: String, frequency: float, threshold: float, invert: bool, octaves: int, lacunarity: float, persistence: float) -> void:
	"""Apply noise-based mask to heightmap."""
	# Configure noise generator
	landmass_mask_noise.seed = seed + 4000  # Different seed offset
	_configure_noise_type_for_mask(noise_type_str)
	landmass_mask_noise.frequency = frequency
	landmass_mask_noise.fractal_octaves = octaves
	landmass_mask_noise.fractal_lacunarity = lacunarity
	landmass_mask_noise.fractal_gain = persistence
	landmass_mask_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	landmass_mask_noise.offset = Vector3(offset.x, offset.y, 0)
	
	for y: int in height:
		for x: int in width:
			var world_x: float = float(x) + offset.x
			var world_y: float = float(y) + offset.y
			var noise_val: float = (landmass_mask_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
			var mask_val: float = 1.0 if noise_val > threshold else 0.0
			
			if invert:
				mask_val = 1.0 - mask_val
			
			# Smooth transition at threshold
			var transition: float = abs(noise_val - threshold)
			if transition < 0.1:
				var t: float = transition / 0.1
				mask_val = lerp(mask_val, 1.0 - mask_val, smoothstep(0.0, 1.0, t))
			
			var val: float = img.get_pixel(x, y).r * mask_val
			img.set_pixel(x, y, Color(val, val, val))


func _apply_voronoi_mask(img: Image, width: int, height: int, cell_count: int, jitter: float, threshold: float, invert: bool, smooth_edges: bool) -> void:
	"""Apply Voronoi-based mask for cellular continent shapes."""
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed + 5000
	
	# Generate Voronoi cell centers
	var centers: Array[Vector2] = []
	for i: int in cell_count:
		var cx: float = rng.randf_range(0.1, 0.9)
		var cy: float = rng.randf_range(0.1, 0.9)
		centers.append(Vector2(cx * width, cy * height))
	
	# Apply Voronoi mask
	for y: int in height:
		for x: int in width:
			var pos: Vector2 = Vector2(x, y)
			var min_dist: float = INF
			var second_min_dist: float = INF
			
			# Find closest and second closest centers
			for center: Vector2 in centers:
				var dist: float = pos.distance_to(center)
				if dist < min_dist:
					second_min_dist = min_dist
					min_dist = dist
				elif dist < second_min_dist:
					second_min_dist = dist
			
			# Use distance difference for mask (Worley noise style)
			var diff: float = second_min_dist - min_dist
			var normalized_diff: float = diff / (width * 0.5)
			var mask_val: float = 1.0 if normalized_diff > threshold else 0.0
			
			if smooth_edges:
				var t: float = abs(normalized_diff - threshold) / 0.1
				if t < 1.0:
					mask_val = lerp(mask_val, 1.0 - mask_val, smoothstep(0.0, 1.0, t))
			
			if invert:
				mask_val = 1.0 - mask_val
			
			var val: float = img.get_pixel(x, y).r * mask_val
			img.set_pixel(x, y, Color(val, val, val))


func _apply_ring_mask(img: Image, width: int, height: int, cx: float, cy: float, inner_radius: float, outer_radius: float, island_count: int, island_radius: float, smooth_edges: bool) -> void:
	"""Apply ring archipelago mask (islands in a ring pattern)."""
	var center: Vector2 = Vector2(width * cx, height * cy)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed + 6000
	
	# Create ring of islands
	var ring_radius: float = (inner_radius + outer_radius) * 0.5 * width
	var angle_step: float = TAU / float(island_count)
	
	for i: int in island_count:
		var angle: float = angle_step * float(i) + rng.randf_range(-angle_step * 0.2, angle_step * 0.2)
		var island_cx: float = cx + cos(angle) * (ring_radius / width)
		var island_cy: float = cy + sin(angle) * (ring_radius / width)
		var smooth_rad: float = 0.05 if smooth_edges else 0.0
		_apply_radial_mask(img, width, height, island_cx, island_cy, island_radius, false, smooth_edges, smooth_rad)


func _apply_peninsula_mask(img: Image, width: int, height: int, base_cx: float, base_cy: float, base_radius: float, direction: Vector2, length: float, width_param: float, smooth_edges: bool) -> void:
	"""Apply peninsula mask (landmass with extending peninsula)."""
	# Base landmass
	var smooth_rad: float = 0.1 if smooth_edges else 0.0
	_apply_radial_mask(img, width, height, base_cx, base_cy, base_radius, false, smooth_edges, smooth_rad)
	
	# Peninsula extension
	var center: Vector2 = Vector2(width * base_cx, height * base_cy)
	var dir_normalized: Vector2 = direction.normalized()
	var peninsula_end: Vector2 = center + dir_normalized * (length * width)
	var peninsula_center: Vector2 = (center + peninsula_end) * 0.5
	
	# Apply elongated radial mask for peninsula
	var peninsula_cx: float = peninsula_center.x / width
	var peninsula_cy: float = peninsula_center.y / height
	var peninsula_radius: float = width_param
	_apply_radial_mask(img, width, height, peninsula_cx, peninsula_cy, peninsula_radius, false, smooth_edges, smooth_rad)


func _apply_atoll_mask(img: Image, width: int, height: int, cx: float, cy: float, outer_radius: float, inner_radius: float, island_count: int, island_radius: float, smooth_edges: bool) -> void:
	"""Apply atoll mask (ring of islands around central lagoon)."""
	var center: Vector2 = Vector2(width * cx, height * cy)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed + 7000
	
	# Create ring of islands around center
	var ring_radius: float = (outer_radius + inner_radius) * 0.5 * width
	var angle_step: float = TAU / float(island_count)
	
	for i: int in island_count:
		var angle: float = angle_step * float(i) + rng.randf_range(-angle_step * 0.1, angle_step * 0.1)
		var island_cx: float = cx + cos(angle) * (ring_radius / width)
		var island_cy: float = cy + sin(angle) * (ring_radius / width)
		var smooth_rad: float = 0.05 if smooth_edges else 0.0
		_apply_radial_mask(img, width, height, island_cx, island_cy, island_radius, false, smooth_edges, smooth_rad)
	
	# Remove center (lagoon) - invert inner radius
	_apply_radial_mask(img, width, height, cx, cy, inner_radius, true, smooth_edges, 0.05)


func _apply_fjord_mask(img: Image, width: int, height: int, coast_direction: Vector2, fjord_count: int, fjord_length: float, fjord_width: float, land_base_radius: float, smooth_edges: bool) -> void:
	"""Apply fjord coast mask (landmass with deep inlets)."""
	# Base landmass
	var smooth_rad: float = 0.1 if smooth_edges else 0.0
	_apply_radial_mask(img, width, height, 0.5, 0.5, land_base_radius, false, smooth_edges, smooth_rad)
	
	# Create fjords (deep inlets) by subtracting from landmass
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed + 8000
	var dir_normalized: Vector2 = coast_direction.normalized()
	
	for i: int in fjord_count:
		var angle_offset: float = rng.randf_range(-PI * 0.25, PI * 0.25)
		var fjord_dir: Vector2 = dir_normalized.rotated(angle_offset)
		var fjord_start_cx: float = 0.5 + fjord_dir.x * land_base_radius * 0.8
		var fjord_start_cy: float = 0.5 + fjord_dir.y * land_base_radius * 0.8
		var fjord_end_cx: float = fjord_start_cx + fjord_dir.x * fjord_length
		var fjord_end_cy: float = fjord_start_cy + fjord_dir.y * fjord_length
		
		# Apply elongated mask (subtract from landmass)
		var fjord_center_cx: float = (fjord_start_cx + fjord_end_cx) * 0.5
		var fjord_center_cy: float = (fjord_start_cy + fjord_end_cy) * 0.5
		_apply_radial_mask(img, width, height, fjord_center_cx, fjord_center_cy, fjord_width, true, smooth_edges, 0.05)


func _configure_noise_type_for_mask(noise_type_str: String) -> void:
	"""Configure noise type for landmass mask noise generator."""
	match noise_type_str:
		"TYPE_SIMPLEX":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		"TYPE_SIMPLEX_SMOOTH":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
		"TYPE_PERLIN":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
		"TYPE_VALUE":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_VALUE
		"TYPE_CELLULAR":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_CELLULAR
		_:
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN


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
