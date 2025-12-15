# ╔═══════════════════════════════════════════════════════════
# ║ MapGenerator.gd
# ║ Desc: Procedural map generation using FastNoiseLite (heightmap, erosion, rivers, biomes)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name MapGenerator

## Custom datasource callback (optional, for extensibility)
var custom_datasource_callback: Callable

## Custom post-processor callbacks (array of callables)
var custom_post_processors: Array[Callable] = []

## Noise instance for height generation
var height_noise: FastNoiseLite

## Noise instance for continent mask
var continent_noise: FastNoiseLite

## Noise instance for temperature
var temperature_noise: FastNoiseLite

## Noise instance for moisture
var moisture_noise: FastNoiseLite

## Noise instance for landmass masks
var landmass_mask_noise: FastNoiseLite

## Landmass type configurations loaded from JSON
var landmass_configs: Dictionary = {}

## Generation thread
var generation_thread: Thread


func _init() -> void:
	"""Initialize noise generators."""
	MythosLogger.verbose("World/Generation", "MapGenerator._init() - Initializing noise generators")
	height_noise = FastNoiseLite.new()
	continent_noise = FastNoiseLite.new()
	temperature_noise = FastNoiseLite.new()
	moisture_noise = FastNoiseLite.new()
	landmass_mask_noise = FastNoiseLite.new()
	_load_landmass_configs()
	_load_biome_configs()
	_load_post_processing_config()
	MythosLogger.verbose("World/Generation", "MapGenerator._init() - All noise generators created")


func generate_map(world_map_data: WorldMapData, use_thread: bool = true) -> void:
	"""Generate complete map (heightmap, rivers, biomes). Use thread for large maps.
	
	For very large maps (8192x8192+), automatically uses threading and LOD optimizations.
	"""
	MythosLogger.verbose("World/Generation", "MapGenerator.generate_map() - Starting map generation", {
		"width": world_map_data.world_width if world_map_data else 0,
		"height": world_map_data.world_height if world_map_data else 0,
		"use_thread": use_thread
	})
	
	if world_map_data == null:
		MythosLogger.error("World/Generation", "MapGenerator.generate_map() - world_map_data is null")
		return
	
	# Validate map dimensions
	if world_map_data.world_width <= 0 or world_map_data.world_height <= 0:
		MythosLogger.error("World/Generation", "MapGenerator.generate_map() - Invalid map dimensions: %dx%d (must be > 0)" % [world_map_data.world_width, world_map_data.world_height])
		return
	
	var map_size: int = world_map_data.world_width * world_map_data.world_height
	# Auto-enable threading for large maps (8192x8192 = 67M pixels)
	var use_threading: bool = use_thread and map_size > 512 * 512
	
	# For very large maps, optimize post-processing
	if map_size > 8192 * 8192:
		MythosLogger.info("World/Generation", "Very large map detected, optimizing post-processing", {"size": map_size})
		# Reduce post-processing iterations for performance
		var steps: Array = post_processing_config.get("steps", [])
		for step: Dictionary in steps:
			if step.has("iterations"):
				var orig_iterations: int = step.get("iterations", 5)
				step["iterations"] = max(1, orig_iterations / 2)  # Reduce by half for very large maps
	
	MythosLogger.verbose("World/Generation", "MapGenerator.generate_map() - Map size: %d pixels, threading: %s" % [map_size, use_threading])
	
	if use_threading:
		MythosLogger.verbose("World/Generation", "MapGenerator.generate_map() - Using threaded generation")
		_generate_in_thread(world_map_data)
	else:
		MythosLogger.verbose("World/Generation", "MapGenerator.generate_map() - Using synchronous generation")
		_generate_sync(world_map_data)


func _generate_sync(world_map_data: WorldMapData) -> void:
	"""Generate map synchronously (blocks main thread)."""
	MythosLogger.verbose("World/Generation", "MapGenerator._generate_sync() - Starting synchronous generation")
	_configure_noise(world_map_data)
	_generate_heightmap(world_map_data)
	
	# Apply post-processing pipeline (replaces old erosion/rivers checks)
	_apply_post_processing_pipeline(world_map_data)
	
	MythosLogger.verbose("World/Generation", "MapGenerator._generate_sync() - Synchronous generation complete")


func _generate_in_thread(world_map_data: WorldMapData) -> void:
	"""Generate map in background thread."""
	MythosLogger.verbose("World/Generation", "MapGenerator._generate_in_thread() - Starting threaded generation")
	
	if generation_thread != null and generation_thread.is_alive():
		MythosLogger.verbose("World/Generation", "MapGenerator._generate_in_thread() - Waiting for existing thread to finish")
		generation_thread.wait_to_finish()
	
	MythosLogger.verbose("World/Generation", "MapGenerator._generate_in_thread() - Creating new thread")
	generation_thread = Thread.new()
	generation_thread.start(_thread_generate.bind(world_map_data))
	MythosLogger.verbose("World/Generation", "MapGenerator._generate_in_thread() - Thread started")


func _thread_generate(world_map_data: WorldMapData) -> void:
	"""Thread function for map generation."""
	MythosLogger.verbose("World/Generation", "MapGenerator._thread_generate() - Thread function started")
	_configure_noise(world_map_data)
	_generate_heightmap(world_map_data)
	
	# Apply post-processing pipeline
	_apply_post_processing_pipeline(world_map_data)
	
	MythosLogger.verbose("World/Generation", "MapGenerator._thread_generate() - Thread generation complete")
	# Note: Since MapGenerator extends RefCounted (not Node), we can't use call_deferred
	# The caller should check thread status or handle completion via other means


func _on_generation_complete(world_map_data: WorldMapData) -> void:
	"""Called when thread generation completes."""
	MythosLogger.verbose("World/Generation", "MapGenerator._on_generation_complete() - Thread generation completed")
	if generation_thread != null:
		generation_thread.wait_to_finish()
		generation_thread = null
		MythosLogger.verbose("World/Generation", "MapGenerator._on_generation_complete() - Thread cleaned up")
	
	MythosLogger.info("World/Generation", "MapGenerator: Map generation complete")


func _configure_noise(world_map_data: WorldMapData) -> void:
	"""Configure noise generators from world_map_data parameters."""
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - Configuring noise generators", {
		"seed": world_map_data.seed,
		"noise_type": world_map_data.noise_type,
		"frequency": world_map_data.noise_frequency,
		"octaves": world_map_data.noise_octaves
	})
	
	# Configure height noise - use effective seed (allows sub-seeds)
	var effective_height_seed: int = world_map_data.get_effective_seed("height")
	height_noise.seed = effective_height_seed
	height_noise.noise_type = world_map_data.noise_type
	height_noise.frequency = world_map_data.noise_frequency
	height_noise.fractal_octaves = world_map_data.noise_octaves
	height_noise.fractal_gain = world_map_data.noise_persistence
	height_noise.fractal_lacunarity = world_map_data.noise_lacunarity
	height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - Height noise configured", {
		"seed": height_noise.seed,
		"noise_type": height_noise.noise_type
	})
	
	# Configure continent noise - use different seed offset to ensure variation
	continent_noise.seed = world_map_data.seed + 1000
	continent_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	continent_noise.frequency = world_map_data.noise_frequency * 0.3
	continent_noise.fractal_octaves = 3
	continent_noise.fractal_gain = 0.5
	continent_noise.fractal_lacunarity = 2.0
	continent_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - Continent noise configured", {
		"seed": continent_noise.seed
	})
	
	# Configure temperature noise - use effective climate seed
	var effective_climate_seed: int = world_map_data.get_effective_seed("climate")
	temperature_noise.seed = effective_climate_seed + 2000
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	temperature_noise.frequency = world_map_data.biome_temperature_noise_frequency
	# Apply temperature bias (via offset)
	var temp_bias: float = world_map_data.temperature_bias
	temperature_noise.offset = Vector3(0, 0, temp_bias * 1000.0)
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - Temperature noise configured", {
		"seed": temperature_noise.seed,
		"frequency": world_map_data.biome_temperature_noise_frequency,
		"bias": temp_bias
	})
	
	# Configure moisture noise - use effective climate seed
	moisture_noise.seed = effective_climate_seed + 3000
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture_noise.frequency = world_map_data.biome_moisture_noise_frequency
	# Apply moisture bias (via offset)
	var moist_bias: float = world_map_data.moisture_bias
	moisture_noise.offset = Vector3(0, 0, moist_bias * 1000.0)
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - Moisture noise configured", {
		"seed": moisture_noise.seed,
		"frequency": world_map_data.biome_moisture_noise_frequency,
		"bias": moist_bias
	})
	
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - All noise generators configured")


func _generate_heightmap(world_map_data: WorldMapData) -> void:
	"""Generate base heightmap using multi-octave noise."""
	MythosLogger.verbose("World/Generation", "MapGenerator._generate_heightmap() called")
	
	# Create or recreate heightmap if null or size doesn't match world dimensions
	var needs_creation: bool = false
	if world_map_data.heightmap_image == null:
		MythosLogger.debug("World/Generation", "Heightmap image is null, creating...")
		needs_creation = true
	else:
		var existing_size: Vector2i = world_map_data.heightmap_image.get_size()
		var expected_size: Vector2i = Vector2i(world_map_data.world_width, world_map_data.world_height)
		if existing_size != expected_size:
			MythosLogger.debug("World/Generation", "Heightmap size mismatch (existing: %s, expected: %s), recreating..." % [existing_size, expected_size])
			needs_creation = true
	
	if needs_creation:
		world_map_data.create_heightmap(world_map_data.world_width, world_map_data.world_height)
	
	var img: Image = world_map_data.heightmap_image
	if img == null:
		MythosLogger.error("World/Generation", "img is still null after create_heightmap!")
		return
	var size: Vector2i = img.get_size()
	MythosLogger.debug("World/Generation", "Generating heightmap", {"size": size})
	
	# Generate noise values (Images are thread-safe in Godot 4.3, no lock needed)
	for y in range(size.y):
		for x in range(size.x):
			# Normalize coordinates to world space
			var world_x: float = (float(x) / float(size.x) - 0.5) * world_map_data.world_width
			var world_y: float = (float(y) / float(size.y) - 0.5) * world_map_data.world_height
			
			# Get height noise value (-1 to 1) - this is the primary seed-dependent value
			var height_value: float = height_noise.get_noise_2d(world_x, world_y)
			
			# Apply continent mask (radial gradient + noise)
			var distance_from_center: float = Vector2(world_x, world_y).length() / (max(world_map_data.world_width, world_map_data.world_height) * 0.5)
			var continent_mask: float = continent_noise.get_noise_2d(world_x, world_y)
			continent_mask = (continent_mask + 1.0) * 0.5  # Normalize to 0-1
			
			# Combine: islands near edges, continents in center
			var mask_factor: float = 1.0 - smoothstep(0.3, 1.0, distance_from_center)
			mask_factor = lerp(mask_factor, continent_mask, 0.5)
			
			# Normalize height to 0-1 range - preserve full height_noise variation
			height_value = (height_value + 1.0) * 0.5
			# Apply mask while preserving seed-dependent height_noise variation
			# Use additive approach to ensure height_noise remains significant
			height_value = height_value * (0.7 + mask_factor * 0.3)
			height_value = clamp(height_value, 0.0, 1.0)
			
			# Apply sea level cutoff - preserve seed-dependent variation even underwater
			if height_value < world_map_data.sea_level:
				# Use a seed-dependent offset to preserve variation underwater
				# Sample height_noise at slightly different coordinates to get variation
				var underwater_noise: float = height_noise.get_noise_2d(world_x * 1.5, world_y * 1.5)
				var underwater_base: float = world_map_data.sea_level * 0.5
				var underwater_variation: float = (underwater_noise + 1.0) * 0.5 * 0.15
				height_value = underwater_base + underwater_variation
				height_value = clamp(height_value, 0.0, world_map_data.sea_level)
			
			# Store as grayscale (RF format uses red channel)
			var color: Color = Color(height_value, height_value, height_value, 1.0)
			img.set_pixel(x, size.y - 1 - y, color)  # Flip Y for proper orientation
	
	# Apply landmass mask if configured
	if world_map_data.landmass_type != "Continents" and landmass_configs.has(world_map_data.landmass_type):
		MythosLogger.debug("World/Generation", "Applying landmass mask", {"type": world_map_data.landmass_type})
		_apply_landmass_mask_to_heightmap(img, size, world_map_data)
	
	MythosLogger.info("World/Generation", "Heightmap generated", {"size": size})
	# Verify generation by sampling a few pixels
	var test_pixels: Array[Vector2i] = [Vector2i(0, 0), Vector2i(size.x / 2, size.y / 2), Vector2i(size.x - 1, size.y - 1)]
	for test_pos in test_pixels:
		if test_pos.x < size.x and test_pos.y < size.y:
			var test_color: Color = img.get_pixel(test_pos.x, test_pos.y)
			MythosLogger.verbose("World/Generation", "Heightmap sample", {"position": test_pos, "height": test_color.r})


func _load_post_processing_config() -> void:
	"""Load post-processing pipeline configuration from JSON."""
	const CONFIG_PATH: String = "res://data/config/terrain_generation.json"
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		MythosLogger.warn("World/Generation", "Failed to load post-processing config from " + CONFIG_PATH + ", using defaults")
		_use_default_post_processing()
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.warn("World/Generation", "Failed to parse post-processing config JSON: " + json.get_error_message() + ", using defaults")
		_use_default_post_processing()
		return
	
	var data: Dictionary = json.data
	post_processing_config = data.get("post_processing", {})
	MythosLogger.info("World/Generation", "Loaded post-processing configuration", {"enabled": post_processing_config.get("enabled", true)})


func _use_default_post_processing() -> void:
	"""Use default post-processing configuration if JSON fails to load."""
	post_processing_config = {
		"enabled": true,
		"steps": [
			{"type": "erosion", "enabled": true, "iterations": 5, "strength": 0.3, "sediment_factor": 0.1, "deposition_rate": 0.05}
		]
	}


func _apply_post_processing_pipeline(world_map_data: WorldMapData) -> void:
	"""Apply modular post-processing pipeline based on configuration."""
	# Check if post-processing is enabled (can be disabled for previews)
	if not post_processing_config.get("enabled", true):
		MythosLogger.verbose("World/Generation", "Post-processing pipeline disabled")
		return
	
	var steps: Array = post_processing_config.get("steps", [])
	if steps.is_empty():
		MythosLogger.verbose("World/Generation", "No post-processing steps configured")
		return
	
	MythosLogger.verbose("World/Generation", "Applying post-processing pipeline", {"step_count": steps.size()})
	
	for step_config: Dictionary in steps:
		if not step_config.get("enabled", true):
			continue
		
		var step_type: String = step_config.get("type", "")
		match step_type:
			"erosion":
				# Backward compatibility: Check erosion_enabled flag
				if not world_map_data.erosion_enabled:
					MythosLogger.verbose("World/Generation", "Erosion step skipped (erosion_enabled = false)")
					continue
				var iterations: int = step_config.get("iterations", world_map_data.erosion_iterations)
				var strength: float = step_config.get("strength", world_map_data.erosion_strength)
				var sediment_factor: float = step_config.get("sediment_factor", 0.1)
				var deposition_rate: float = step_config.get("deposition_rate", 0.05)
				_apply_advanced_erosion(world_map_data, iterations, strength, sediment_factor, deposition_rate)
			"smoothing":
				var smooth_iterations: int = step_config.get("iterations", 2)
				var radius: int = step_config.get("radius", 1)
				_apply_smoothing(world_map_data, smooth_iterations, radius)
			"river_carving":
				# Backward compatibility: Check rivers_enabled flag
				if not world_map_data.rivers_enabled:
					MythosLogger.verbose("World/Generation", "River carving step skipped (rivers_enabled = false)")
					continue
				var river_count: int = step_config.get("river_count", world_map_data.river_count)
				var start_elevation: float = step_config.get("start_elevation", world_map_data.river_start_elevation)
				var carving_strength: float = step_config.get("carving_strength", 0.2)
				_apply_river_carving(world_map_data, river_count, start_elevation, carving_strength)
			_:
				MythosLogger.warn("World/Generation", "Unknown post-processing step type: " + step_type)
	
	MythosLogger.info("World/Generation", "Post-processing pipeline complete")


func _apply_advanced_erosion(world_map_data: WorldMapData, iterations: int, strength: float, sediment_factor: float, deposition_rate: float) -> void:
	"""Apply advanced hydraulic erosion with sediment transport and deposition."""
	var img: Image = world_map_data.heightmap_image
	var size: Vector2i = img.get_size()
	
	# Create sediment map for tracking material transport
	var sediment_map: Array[float] = []
	sediment_map.resize(size.x * size.y)
	for i: int in sediment_map.size():
		sediment_map[i] = 0.0
	
	MythosLogger.verbose("World/Generation", "Starting advanced erosion", {
		"iterations": iterations,
		"strength": strength,
		"sediment_factor": sediment_factor
	})
	
	for iteration in range(iterations):
		var new_img: Image = img.duplicate()
		var new_sediment: Array[float] = sediment_map.duplicate()
		
		for y in range(1, size.y - 1):
			for x in range(1, size.x - 1):
				var current_height: float = img.get_pixel(x, y).r
				var current_sediment: float = sediment_map[y * size.x + x]
				
				# Find steepest downhill direction
				var neighbors: Array[Vector2i] = [
					Vector2i(x - 1, y),
					Vector2i(x + 1, y),
					Vector2i(x, y - 1),
					Vector2i(x, y + 1)
				]
				
				var max_slope: float = 0.0
				var downhill_dir: Vector2i = Vector2i.ZERO
				
				for neighbor in neighbors:
					var neighbor_height: float = img.get_pixel(neighbor.x, neighbor.y).r
					var slope: float = current_height - neighbor_height
					if slope > max_slope:
						max_slope = slope
						downhill_dir = neighbor
				
				# Calculate erosion and sediment transport
				if max_slope > 0.0:
					var erosion_amount: float = max_slope * strength * 0.1
					var sediment_capacity: float = max_slope * sediment_factor
					
					# Erode material
					var actual_erosion: float = min(erosion_amount, current_height)
					var new_height: float = clamp(current_height - actual_erosion, 0.0, 1.0)
					
					# Add to sediment
					var new_sediment_amount: float = current_sediment + actual_erosion
					
					# Transport sediment downhill if capacity exceeded
					if new_sediment_amount > sediment_capacity:
						var excess: float = new_sediment_amount - sediment_capacity
						new_sediment_amount = sediment_capacity
						# Move excess to downhill neighbor
						if downhill_dir != Vector2i.ZERO:
							var neighbor_idx: int = downhill_dir.y * size.x + downhill_dir.x
							if neighbor_idx >= 0 and neighbor_idx < new_sediment.size():
								new_sediment[neighbor_idx] += excess * 0.5  # Some loss during transport
					
					# Deposit sediment if slope is low
					if max_slope < 0.01:
						var deposit: float = new_sediment_amount * deposition_rate
						new_height = clamp(new_height + deposit, 0.0, 1.0)
						new_sediment_amount = max(0.0, new_sediment_amount - deposit)
					
					new_img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))
					new_sediment[y * size.x + x] = new_sediment_amount
		
		img = new_img
		world_map_data.heightmap_image = img
		sediment_map = new_sediment
		
		if iteration % 2 == 0:
			MythosLogger.debug("World/Generation", "Advanced erosion iteration", {
				"current": iteration + 1,
				"total": iterations
			})
	
	MythosLogger.info("World/Generation", "Advanced erosion complete", {"iterations": iterations})


func _apply_smoothing(world_map_data: WorldMapData, iterations: int, radius: int) -> void:
	"""Apply smoothing filter to heightmap."""
	var img: Image = world_map_data.heightmap_image
	var size: Vector2i = img.get_size()
	
	MythosLogger.verbose("World/Generation", "Applying smoothing", {"iterations": iterations, "radius": radius})
	
	for iteration in range(iterations):
		var new_img: Image = img.duplicate()
		
		for y in range(radius, size.y - radius):
			for x in range(radius, size.x - radius):
				var sum: float = 0.0
				var count: int = 0
				
				# Average neighboring pixels
				for dy in range(-radius, radius + 1):
					for dx in range(-radius, radius + 1):
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < size.x and ny >= 0 and ny < size.y:
							sum += img.get_pixel(nx, ny).r
							count += 1
				
				if count > 0:
					var avg: float = sum / float(count)
					new_img.set_pixel(x, y, Color(avg, avg, avg, 1.0))
		
		img = new_img
		world_map_data.heightmap_image = img
	
	MythosLogger.info("World/Generation", "Smoothing complete", {"iterations": iterations})


func _apply_river_carving(world_map_data: WorldMapData, river_count: int, start_elevation: float, carving_strength: float) -> void:
	"""Apply river carving by tracing paths from high points."""
	var img: Image = world_map_data.heightmap_image
	var size: Vector2i = img.get_size()
	
	# Use effective river seed if available
	var effective_river_seed: int = world_map_data.get_effective_seed("river")
	
	MythosLogger.verbose("World/Generation", "Applying river carving", {
		"river_count": river_count,
		"start_elevation": start_elevation,
		"seed": effective_river_seed
	})
	
	# Find high points (potential river sources)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = effective_river_seed + 9000
	
	var river_sources: Array[Vector2i] = []
	var attempts: int = 0
	const MAX_ATTEMPTS: int = 1000
	
	while river_sources.size() < river_count and attempts < MAX_ATTEMPTS:
		var x: int = rng.randi_range(size.x / 4, 3 * size.x / 4)
		var y: int = rng.randi_range(size.y / 4, 3 * size.y / 4)
		var height: float = img.get_pixel(x, y).r
		
		if height >= start_elevation:
			river_sources.append(Vector2i(x, y))
		
		attempts += 1
	
	# Carve rivers by tracing downhill
	for source: Vector2i in river_sources:
		var current_pos: Vector2i = source
		var path_length: int = 0
		const MAX_PATH_LENGTH: int = 500
		
		while path_length < MAX_PATH_LENGTH:
			var neighbors: Array[Vector2i] = [
				Vector2i(current_pos.x - 1, current_pos.y),
				Vector2i(current_pos.x + 1, current_pos.y),
				Vector2i(current_pos.x, current_pos.y - 1),
				Vector2i(current_pos.x, current_pos.y + 1)
			]
			
			var lowest_neighbor: Vector2i = current_pos
			var lowest_height: float = img.get_pixel(current_pos.x, current_pos.y).r
			
			for neighbor: Vector2i in neighbors:
				if neighbor.x < 0 or neighbor.x >= size.x or neighbor.y < 0 or neighbor.y >= size.y:
					continue
				
				var neighbor_height: float = img.get_pixel(neighbor.x, neighbor.y).r
				if neighbor_height < lowest_height:
					lowest_height = neighbor_height
					lowest_neighbor = neighbor
			
			# Stop if no downhill path
			if lowest_neighbor == current_pos:
				break
			
			# Carve river at current position
			var current_height: float = img.get_pixel(current_pos.x, current_pos.y).r
			var carved_height: float = clamp(current_height - carving_strength, 0.0, 1.0)
			img.set_pixel(current_pos.x, current_pos.y, Color(carved_height, carved_height, carved_height, 1.0))
			
			current_pos = lowest_neighbor
			path_length += 1
			
			# Stop if reached sea level
			if lowest_height < world_map_data.sea_level:
				break
	
	world_map_data.heightmap_image = img
	MythosLogger.info("World/Generation", "River carving complete", {"rivers_carved": river_sources.size()})


func _generate_rivers(world_map_data: WorldMapData) -> void:
	"""Generate rivers by tracing downhill from high points."""
	# Rivers are handled in MapRenderer as overlay, but we mark low valleys here
	# This is a simplified approach - full river system would need pathfinding
	var img: Image = world_map_data.heightmap_image
	var size: Vector2i = img.get_size()
	
	# For now, rivers are rendered as overlay in shader based on height gradients
	# Full implementation would trace paths and store river data
	print("MapGenerator: River generation (simplified - rendered as overlay)")


func generate_biome_preview(world_map_data: WorldMapData) -> Image:
	"""Generate biome color preview image based on height, temperature, moisture."""
	if world_map_data.heightmap_image == null:
		return null
	
	var height_img: Image = world_map_data.heightmap_image
	var size: Vector2i = height_img.get_size()
	var biome_img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	
	# Generate biome colors (Images are thread-safe in Godot 4.3, no lock needed)
	for y in range(size.y):
		for x in range(size.x):
			# Get world position
			var world_x: float = (float(x) / float(size.x) - 0.5) * world_map_data.world_width
			var world_y: float = (float(y) / float(size.y) - 0.5) * world_map_data.world_height
			
			# Get height
			var height: float = height_img.get_pixel(x, size.y - 1 - y).r
			
			# Get temperature and moisture (normalized to 0-1)
			var temperature: float = (temperature_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
			var moisture: float = (moisture_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
			
			# Apply global biases
			var temp_bias: float = world_map_data.temperature_bias
			var moist_bias: float = world_map_data.moisture_bias
			temperature = clampf(temperature + temp_bias * 0.5, 0.0, 1.0)
			moisture = clampf(moisture + moist_bias * 0.5, 0.0, 1.0)
			
			# Apply regional climate adjustments if available (from MapEditor painting)
			var pixel_key: String = "%d,%d" % [x, size.y - 1 - y]
			if world_map_data.regional_climate_adjustments.has(pixel_key):
				var adjustment: Dictionary = world_map_data.regional_climate_adjustments[pixel_key]
				var temp_adj: float = adjustment.get("temp", 0.0)
				var moist_adj: float = adjustment.get("moist", 0.0)
				temperature = clampf(temperature + temp_adj * 0.5, 0.0, 1.0)
				moisture = clampf(moisture + moist_adj * 0.5, 0.0, 1.0)
			
			# Determine biome color based on height, temperature, moisture
			var biome_color: Color = _get_biome_color(height, temperature, moisture, world_map_data.sea_level)
			biome_img.set_pixel(x, size.y - 1 - y, biome_color)
	
	world_map_data.biome_preview_image = biome_img
	return biome_img


func _load_biome_configs() -> void:
	"""Load biome configurations from JSON."""
	const CONFIG_PATH: String = "res://data/biomes.json"
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		MythosLogger.warn("World/Generation", "Failed to load biome configs from " + CONFIG_PATH + ", using defaults")
		_use_default_biomes()
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.warn("World/Generation", "Failed to parse biome configs JSON: " + json.get_error_message() + ", using defaults")
		_use_default_biomes()
		return
	
	var data: Dictionary = json.data
	biome_configs = data.get("biomes", [])
	
	# Convert temperature and rainfall ranges to normalized 0-1
	# Temperature: -50 to 50 Celsius -> 0.0 to 1.0
	# Rainfall: 0 to 300 mm -> 0.0 to 1.0
	# Height: 0.0 to 1.0 (already normalized)
	for biome: Dictionary in biome_configs:
		# Convert temperature range (Celsius to 0-1)
		var temp_range: Array = biome.get("temperature_range", [-50, 50])
		biome["temperature_range_normalized"] = [
			(temp_range[0] + 50.0) / 100.0,  # -50 -> 0.0, 50 -> 1.0
			(temp_range[1] + 50.0) / 100.0
		]
		
		# Convert rainfall range (mm to 0-1)
		var rain_range: Array = biome.get("rainfall_range", [0, 300])
		biome["rainfall_range_normalized"] = [
			rain_range[0] / 300.0,  # 0 -> 0.0, 300 -> 1.0
			rain_range[1] / 300.0
		]
		
		# Add height range if not specified (default based on biome type)
		if not biome.has("height_range_normalized"):
			var biome_id: String = biome.get("id", "")
			match biome_id:
				"ocean":
					biome["height_range_normalized"] = [0.0, 0.4]
				"swamp":
					biome["height_range_normalized"] = [0.35, 0.5]
				"grassland", "savanna", "desert":
					biome["height_range_normalized"] = [0.4, 0.6]
				"temperate_forest", "tropical_rainforest":
					biome["height_range_normalized"] = [0.4, 0.7]
				"taiga":
					biome["height_range_normalized"] = [0.5, 0.8]
				"tundra":
					biome["height_range_normalized"] = [0.6, 0.9]
				"mountain":
					biome["height_range_normalized"] = [0.7, 1.0]
				_:
					biome["height_range_normalized"] = [0.0, 1.0]  # Default: all heights
		
		# Convert color array to Color object
		var color_array: Array = biome.get("color", [0.5, 0.5, 0.5, 1.0])
		biome["color_object"] = Color(color_array[0], color_array[1], color_array[2], color_array[3] if color_array.size() > 3 else 1.0)
	
	MythosLogger.info("World/Generation", "Loaded biome configurations", {"count": biome_configs.size()})


func _use_default_biomes() -> void:
	"""Use default biome configurations if JSON fails to load."""
	biome_configs = [
		{"id": "ocean", "name": "Ocean", "height_range_normalized": [0.0, 0.4], "temperature_range_normalized": [0.0, 1.0], "rainfall_range_normalized": [0.0, 1.0], "color_object": Color(0.2, 0.4, 0.8, 1.0)},
		{"id": "beach", "name": "Beach", "height_range_normalized": [0.38, 0.42], "temperature_range_normalized": [0.0, 1.0], "rainfall_range_normalized": [0.0, 1.0], "color_object": Color(0.9, 0.85, 0.7, 1.0)},
		{"id": "grassland", "name": "Grassland", "height_range_normalized": [0.42, 0.6], "temperature_range_normalized": [0.3, 0.7], "rainfall_range_normalized": [0.2, 0.6], "color_object": Color(0.6, 0.7, 0.4, 1.0)},
		{"id": "forest", "name": "Forest", "height_range_normalized": [0.42, 0.7], "temperature_range_normalized": [0.3, 0.7], "rainfall_range_normalized": [0.5, 1.0], "color_object": Color(0.2, 0.5, 0.2, 1.0)},
		{"id": "desert", "name": "Desert", "height_range_normalized": [0.42, 0.6], "temperature_range_normalized": [0.6, 1.0], "rainfall_range_normalized": [0.0, 0.2], "color_object": Color(0.9, 0.8, 0.6, 1.0)},
		{"id": "mountain", "name": "Mountain", "height_range_normalized": [0.7, 0.95], "temperature_range_normalized": [0.0, 1.0], "rainfall_range_normalized": [0.0, 1.0], "color_object": Color(0.5, 0.5, 0.5, 1.0)},
		{"id": "snow", "name": "Snow", "height_range_normalized": [0.95, 1.0], "temperature_range_normalized": [0.0, 1.0], "rainfall_range_normalized": [0.0, 1.0], "color_object": Color(0.95, 0.95, 1.0, 1.0)}
	]


func _get_biome_color(height: float, temperature: float, moisture: float, sea_level: float = 0.4) -> Color:
	"""Determine biome color from height, temperature, moisture using loaded biome configs."""
	# Underwater check
	
	if height < sea_level:
		# Find ocean biome
		for biome: Dictionary in biome_configs:
			if biome.get("id", "") == "ocean":
				return biome.get("color_object", Color(0.2, 0.4, 0.8, 1.0))
		return Color(0.2, 0.4, 0.8, 1.0)  # Default ocean color
	
	# Find matching biomes with blending support
	var candidate_biomes: Array[Dictionary] = []
	var candidate_weights: Array[float] = []
	
	for biome: Dictionary in biome_configs:
		var biome_id: String = biome.get("id", "")
		if biome_id == "ocean":
			continue  # Skip ocean (already handled)
		
		var h_range: Array = biome.get("height_range_normalized", [0.0, 1.0])
		var t_range: Array = biome.get("temperature_range_normalized", [0.0, 1.0])
		var m_range: Array = biome.get("rainfall_range_normalized", [0.0, 1.0])
		
		# Calculate distance from range centers (for blending)
		var h_center: float = (h_range[0] + h_range[1]) * 0.5
		var t_center: float = (t_range[0] + t_range[1]) * 0.5
		var m_center: float = (m_range[0] + m_range[1]) * 0.5
		
		var h_dist: float = abs(height - h_center) / max(0.01, h_range[1] - h_range[0])
		var t_dist: float = abs(temperature - t_center) / max(0.01, t_range[1] - t_range[0])
		var m_dist: float = abs(moisture - m_center) / max(0.01, m_range[1] - m_range[0])
		
		# Calculate match weight (closer to center = higher weight)
		var weight: float = 1.0 / (1.0 + h_dist + t_dist + m_dist)
		
		# Only include biomes that are reasonably close
		if weight > 0.1:
			candidate_biomes.append(biome)
			candidate_weights.append(weight)
	
	# Blend colors if multiple candidates and blending enabled
	if candidate_biomes.size() > 1 and biome_transition_width > 0.0:
		var total_weight: float = 0.0
		var blended_color: Color = Color.BLACK
		
		for i: int in candidate_biomes.size():
			var biome: Dictionary = candidate_biomes[i]
			var weight: float = candidate_weights[i]
			var biome_color: Color = biome.get("color_object", Color(0.5, 0.5, 0.5, 1.0))
			
			blended_color += biome_color * weight
			total_weight += weight
		
		if total_weight > 0.0:
			blended_color /= total_weight
			return blended_color
	
	# Find best single match if no blending or only one candidate
	var best_match: Dictionary = {}
	var best_weight: float = 0.0
	
	for i: int in candidate_biomes.size():
		if candidate_weights[i] > best_weight:
			best_weight = candidate_weights[i]
			best_match = candidate_biomes[i]
	
	# Return best match color, or default if no match
	if not best_match.is_empty():
		return best_match.get("color_object", Color(0.5, 0.5, 0.5, 1.0))
	
	# Fallback: height-based selection
	if height < sea_level + 0.02:
		return Color(0.9, 0.85, 0.7, 1.0)  # Beach
	elif height < 0.5:
		return Color(0.6, 0.7, 0.4, 1.0)  # Grassland
	elif height < 0.7:
		return Color(0.2, 0.5, 0.2, 1.0)  # Forest
	elif height < 0.9:
		return Color(0.5, 0.5, 0.5, 1.0)  # Mountain
	else:
		return Color(0.95, 0.95, 1.0, 1.0)  # Snow


func _load_landmass_configs() -> void:
	"""Load landmass type configurations from JSON."""
	const CONFIG_PATH: String = "res://data/config/landmass_types.json"
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		MythosLogger.warn("World/Generation", "Failed to load landmass configs from " + CONFIG_PATH)
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.warn("World/Generation", "Failed to parse landmass configs JSON: " + json.get_error_message())
		return
	
	var data: Dictionary = json.data
	landmass_configs = data.get("landmass_types", {})
	MythosLogger.info("World/Generation", "Loaded landmass type configurations", {"count": landmass_configs.size()})


func _apply_landmass_mask_to_heightmap(img: Image, size: Vector2i, world_map_data: WorldMapData) -> void:
	"""Apply landmass-specific mask to heightmap using config-based masks."""
	var config: Dictionary = landmass_configs.get(world_map_data.landmass_type, {})
	var mask_type: String = config.get("type", "none")
	
	if mask_type == "none":
		return
	
	# Configure landmass mask noise if needed
	landmass_mask_noise.seed = world_map_data.seed + 4000
	
	match mask_type:
		"radial":
			var center: Array = config.get("center", [0.5, 0.5])
			var radius: float = config.get("radius", 0.35)
			var invert: bool = config.get("invert", false)
			var smooth: bool = config.get("smooth_edges", false)
			var smooth_radius: float = config.get("smooth_radius", 0.1)
			_apply_radial_mask_to_image(img, size.x, size.y, center[0], center[1], radius, invert, smooth, smooth_radius)
		"multi_radial":
			var count: int = config.get("count", 4)
			var radius: float = config.get("radius", 0.25)
			var pos_range: Array = config.get("position_range", [0.1, 0.9])
			var smooth: bool = config.get("smooth_edges", false)
			var min_spacing: float = config.get("min_spacing", 0.2)
			_apply_multi_radial_mask_to_image(img, size.x, size.y, count, radius, pos_range, smooth, min_spacing, world_map_data.seed)
		"noise_mask":
			var noise_type_str: String = config.get("noise_type", "TYPE_PERLIN")
			var frequency: float = config.get("frequency", 0.01)
			var threshold: float = config.get("threshold", 0.5)
			var invert: bool = config.get("invert", false)
			var octaves: int = config.get("octaves", 4)
			var lacunarity: float = config.get("lacunarity", 2.0)
			var persistence: float = config.get("persistence", 0.5)
			_apply_noise_mask_to_image(img, size.x, size.y, noise_type_str, frequency, threshold, invert, octaves, lacunarity, persistence, world_map_data)
		"voronoi":
			var cell_count: int = config.get("cell_count", 8)
			var jitter: float = config.get("jitter", 0.5)
			var threshold: float = config.get("threshold", 0.4)
			var invert: bool = config.get("invert", false)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_voronoi_mask_to_image(img, size.x, size.y, cell_count, jitter, threshold, invert, smooth, world_map_data.seed)
		"ring":
			var center: Array = config.get("center", [0.5, 0.5])
			var inner_radius: float = config.get("inner_radius", 0.3)
			var outer_radius: float = config.get("outer_radius", 0.5)
			var island_count: int = config.get("island_count", 8)
			var island_radius: float = config.get("island_radius", 0.08)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_ring_mask_to_image(img, size.x, size.y, center[0], center[1], inner_radius, outer_radius, island_count, island_radius, smooth, world_map_data.seed)
		"peninsula":
			var base_center: Array = config.get("base_center", [0.5, 0.8])
			var base_radius: float = config.get("base_radius", 0.4)
			var direction: Array = config.get("peninsula_direction", [0.0, -1.0])
			var length: float = config.get("peninsula_length", 0.3)
			var width: float = config.get("peninsula_width", 0.15)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_peninsula_mask_to_image(img, size.x, size.y, base_center[0], base_center[1], base_radius, Vector2(direction[0], direction[1]), length, width, smooth)
		"atoll":
			var center: Array = config.get("center", [0.5, 0.5])
			var outer_radius: float = config.get("outer_radius", 0.4)
			var inner_radius: float = config.get("inner_radius", 0.25)
			var island_count: int = config.get("island_count", 12)
			var island_radius: float = config.get("island_radius", 0.05)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_atoll_mask_to_image(img, size.x, size.y, center[0], center[1], outer_radius, inner_radius, island_count, island_radius, smooth, world_map_data.seed)
		"fjord":
			var coast_direction: Array = config.get("coast_direction", [0.0, 1.0])
			var fjord_count: int = config.get("fjord_count", 6)
			var fjord_length: float = config.get("fjord_length", 0.3)
			var fjord_width: float = config.get("fjord_width", 0.05)
			var land_base_radius: float = config.get("land_base_radius", 0.6)
			var smooth: bool = config.get("smooth_edges", false)
			_apply_fjord_mask_to_image(img, size.x, size.y, Vector2(coast_direction[0], coast_direction[1]), fjord_count, fjord_length, fjord_width, land_base_radius, smooth, world_map_data.seed)
		_:
			MythosLogger.warn("World/Generation", "Unknown landmass mask type: " + mask_type)


func _apply_radial_mask_to_image(img: Image, width: int, height: int, cx: float, cy: float, radius: float, invert: bool, smooth_edges: bool, smooth_radius: float) -> void:
	"""Apply radial mask to heightmap image."""
	var center: Vector2 = Vector2(width * cx, height * cy)
	var max_dist: float = width * radius
	
	for y: int in height:
		for x: int in width:
			var dist: float = Vector2(x, y).distance_to(center)
			var normalized_dist: float = dist / max_dist
			var falloff: float
			
			if smooth_edges and smooth_radius > 0.0:
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
			
			# Note: Image is Y-flipped in MapGenerator, so we need to flip Y when reading
			var img_y: int = height - 1 - y
			var val: float = img.get_pixel(x, img_y).r * falloff
			img.set_pixel(x, img_y, Color(val, val, val))


func _apply_multi_radial_mask_to_image(img: Image, width: int, height: int, num: int, radius: float, position_range: Array, smooth_edges: bool, min_spacing: float, seed_value: int) -> void:
	"""Apply multiple radial masks for island chains."""
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var positions: Array[Vector2] = []
	var min_dist_sq: float = (min_spacing * width) * (min_spacing * width)
	var attempts: int = 0
	const MAX_ATTEMPTS: int = 1000
	
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
			_apply_radial_mask_to_image(img, width, height, cx, cy, radius, false, smooth_edges, smooth_radius)


func _apply_noise_mask_to_image(img: Image, width: int, height: int, noise_type_str: String, frequency: float, threshold: float, invert: bool, octaves: int, lacunarity: float, persistence: float, world_map_data: WorldMapData) -> void:
	"""Apply noise-based mask to heightmap."""
	# Configure noise
	match noise_type_str:
		"TYPE_SIMPLEX":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		"TYPE_PERLIN":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
		"TYPE_VALUE":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_VALUE
		"TYPE_CELLULAR":
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_CELLULAR
		_:
			landmass_mask_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	
	landmass_mask_noise.frequency = frequency
	landmass_mask_noise.fractal_octaves = octaves
	landmass_mask_noise.fractal_lacunarity = lacunarity
	landmass_mask_noise.fractal_gain = persistence
	landmass_mask_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	for y: int in height:
		for x: int in width:
			# Convert to world coordinates
			var world_x: float = (float(x) / float(width) - 0.5) * world_map_data.world_width
			var world_y: float = (float(y) / float(height) - 0.5) * world_map_data.world_height
			
			var noise_val: float = (landmass_mask_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
			var mask_val: float = 1.0 if noise_val > threshold else 0.0
			
			if invert:
				mask_val = 1.0 - mask_val
			
			# Smooth transition
			var transition: float = abs(noise_val - threshold)
			if transition < 0.1:
				var t: float = transition / 0.1
				mask_val = lerp(mask_val, 1.0 - mask_val, smoothstep(0.0, 1.0, t))
			
			var img_y: int = height - 1 - y
			var val: float = img.get_pixel(x, img_y).r * mask_val
			img.set_pixel(x, img_y, Color(val, val, val))


func _apply_voronoi_mask_to_image(img: Image, width: int, height: int, cell_count: int, jitter: float, threshold: float, invert: bool, smooth_edges: bool, seed_value: int) -> void:
	"""Apply Voronoi-based mask."""
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var centers: Array[Vector2] = []
	for i: int in cell_count:
		var cx: float = rng.randf_range(0.1, 0.9)
		var cy: float = rng.randf_range(0.1, 0.9)
		centers.append(Vector2(cx * width, cy * height))
	
	for y: int in height:
		for x: int in width:
			var pos: Vector2 = Vector2(x, y)
			var min_dist: float = INF
			var second_min_dist: float = INF
			
			for center: Vector2 in centers:
				var dist: float = pos.distance_to(center)
				if dist < min_dist:
					second_min_dist = min_dist
					min_dist = dist
				elif dist < second_min_dist:
					second_min_dist = dist
			
			var diff: float = second_min_dist - min_dist
			var normalized_diff: float = diff / (width * 0.5)
			var mask_val: float = 1.0 if normalized_diff > threshold else 0.0
			
			if smooth_edges:
				var t: float = abs(normalized_diff - threshold) / 0.1
				if t < 1.0:
					mask_val = lerp(mask_val, 1.0 - mask_val, smoothstep(0.0, 1.0, t))
			
			if invert:
				mask_val = 1.0 - mask_val
			
			var img_y: int = height - 1 - y
			var val: float = img.get_pixel(x, img_y).r * mask_val
			img.set_pixel(x, img_y, Color(val, val, val))


func _apply_ring_mask_to_image(img: Image, width: int, height: int, cx: float, cy: float, inner_radius: float, outer_radius: float, island_count: int, island_radius: float, smooth_edges: bool, seed_value: int) -> void:
	"""Apply ring archipelago mask."""
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var ring_radius: float = (inner_radius + outer_radius) * 0.5 * width
	var angle_step: float = TAU / float(island_count)
	
	for i: int in island_count:
		var angle: float = angle_step * float(i) + rng.randf_range(-angle_step * 0.2, angle_step * 0.2)
		var island_cx: float = cx + cos(angle) * (ring_radius / width)
		var island_cy: float = cy + sin(angle) * (ring_radius / width)
		var smooth_rad: float = 0.05 if smooth_edges else 0.0
		_apply_radial_mask_to_image(img, width, height, island_cx, island_cy, island_radius, false, smooth_edges, smooth_rad)


func _apply_peninsula_mask_to_image(img: Image, width: int, height: int, base_cx: float, base_cy: float, base_radius: float, direction: Vector2, length: float, width_param: float, smooth_edges: bool) -> void:
	"""Apply peninsula mask."""
	var smooth_rad: float = 0.1 if smooth_edges else 0.0
	_apply_radial_mask_to_image(img, width, height, base_cx, base_cy, base_radius, false, smooth_edges, smooth_rad)
	
	var center: Vector2 = Vector2(width * base_cx, height * base_cy)
	var dir_normalized: Vector2 = direction.normalized()
	var peninsula_end: Vector2 = center + dir_normalized * (length * width)
	var peninsula_center: Vector2 = (center + peninsula_end) * 0.5
	
	var peninsula_cx: float = peninsula_center.x / width
	var peninsula_cy: float = peninsula_center.y / height
	_apply_radial_mask_to_image(img, width, height, peninsula_cx, peninsula_cy, width_param, false, smooth_edges, smooth_rad)


func _apply_atoll_mask_to_image(img: Image, width: int, height: int, cx: float, cy: float, outer_radius: float, inner_radius: float, island_count: int, island_radius: float, smooth_edges: bool, seed_value: int) -> void:
	"""Apply atoll mask."""
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var ring_radius: float = (outer_radius + inner_radius) * 0.5 * width
	var angle_step: float = TAU / float(island_count)
	
	for i: int in island_count:
		var angle: float = angle_step * float(i) + rng.randf_range(-angle_step * 0.1, angle_step * 0.1)
		var island_cx: float = cx + cos(angle) * (ring_radius / width)
		var island_cy: float = cy + sin(angle) * (ring_radius / width)
		var smooth_rad: float = 0.05 if smooth_edges else 0.0
		_apply_radial_mask_to_image(img, width, height, island_cx, island_cy, island_radius, false, smooth_edges, smooth_rad)
	
	_apply_radial_mask_to_image(img, width, height, cx, cy, inner_radius, true, smooth_edges, 0.05)


func _apply_fjord_mask_to_image(img: Image, width: int, height: int, coast_direction: Vector2, fjord_count: int, fjord_length: float, fjord_width: float, land_base_radius: float, smooth_edges: bool, seed_value: int) -> void:
	"""Apply fjord coast mask."""
	var smooth_rad: float = 0.1 if smooth_edges else 0.0
	_apply_radial_mask_to_image(img, width, height, 0.5, 0.5, land_base_radius, false, smooth_edges, smooth_rad)
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var dir_normalized: Vector2 = coast_direction.normalized()
	
	for i: int in fjord_count:
		var angle_offset: float = rng.randf_range(-PI * 0.25, PI * 0.25)
		var fjord_dir: Vector2 = dir_normalized.rotated(angle_offset)
		var fjord_start_cx: float = 0.5 + fjord_dir.x * land_base_radius * 0.8
		var fjord_start_cy: float = 0.5 + fjord_dir.y * land_base_radius * 0.8
		var fjord_end_cx: float = fjord_start_cx + fjord_dir.x * fjord_length
		var fjord_end_cy: float = fjord_start_cy + fjord_dir.y * fjord_length
		
		var fjord_center_cx: float = (fjord_start_cx + fjord_end_cx) * 0.5
		var fjord_center_cy: float = (fjord_start_cy + fjord_end_cy) * 0.5
		_apply_radial_mask_to_image(img, width, height, fjord_center_cx, fjord_center_cy, fjord_width, true, smooth_edges, 0.05)