# ╔═══════════════════════════════════════════════════════════
# ║ MapGenerator.gd
# ║ Desc: Procedural map generation using FastNoiseLite (heightmap, erosion, rivers, biomes)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name MapGenerator

## Noise instance for height generation
var height_noise: FastNoiseLite

## Noise instance for continent mask
var continent_noise: FastNoiseLite

## Noise instance for temperature
var temperature_noise: FastNoiseLite

## Noise instance for moisture
var moisture_noise: FastNoiseLite

## Generation thread
var generation_thread: Thread


func _init() -> void:
	"""Initialize noise generators."""
	MythosLogger.verbose("World/Generation", "MapGenerator._init() - Initializing noise generators")
	height_noise = FastNoiseLite.new()
	continent_noise = FastNoiseLite.new()
	temperature_noise = FastNoiseLite.new()
	moisture_noise = FastNoiseLite.new()
	MythosLogger.verbose("World/Generation", "MapGenerator._init() - All noise generators created")


func generate_map(world_map_data: WorldMapData, use_thread: bool = true) -> void:
	"""Generate complete map (heightmap, rivers, biomes). Use thread for large maps."""
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
	var use_threading: bool = use_thread and map_size > 512 * 512
	
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
	
	if world_map_data.erosion_enabled:
		MythosLogger.verbose("World/Generation", "MapGenerator._generate_sync() - Erosion enabled, applying")
		_apply_erosion(world_map_data)
	else:
		MythosLogger.verbose("World/Generation", "MapGenerator._generate_sync() - Erosion disabled")
	
	if world_map_data.rivers_enabled:
		MythosLogger.verbose("World/Generation", "MapGenerator._generate_sync() - Rivers enabled, generating")
		_generate_rivers(world_map_data)
	else:
		MythosLogger.verbose("World/Generation", "MapGenerator._generate_sync() - Rivers disabled")
	
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
	
	if world_map_data.erosion_enabled:
		MythosLogger.verbose("World/Generation", "MapGenerator._thread_generate() - Applying erosion in thread")
		_apply_erosion(world_map_data)
	
	if world_map_data.rivers_enabled:
		MythosLogger.verbose("World/Generation", "MapGenerator._thread_generate() - Generating rivers in thread")
		_generate_rivers(world_map_data)
	
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
	
	# Configure height noise - seed must be set first for proper initialization
	height_noise.seed = world_map_data.seed
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
	
	# Configure temperature noise
	temperature_noise.seed = world_map_data.seed + 2000
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	temperature_noise.frequency = world_map_data.biome_temperature_noise_frequency
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - Temperature noise configured", {
		"seed": temperature_noise.seed,
		"frequency": world_map_data.biome_temperature_noise_frequency
	})
	
	# Configure moisture noise
	moisture_noise.seed = world_map_data.seed + 3000
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture_noise.frequency = world_map_data.biome_moisture_noise_frequency
	MythosLogger.verbose("World/Generation", "MapGenerator._configure_noise() - Moisture noise configured", {
		"seed": moisture_noise.seed,
		"frequency": world_map_data.biome_moisture_noise_frequency
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
	
	MythosLogger.info("World/Generation", "Heightmap generated", {"size": size})
	# Verify generation by sampling a few pixels
	var test_pixels: Array[Vector2i] = [Vector2i(0, 0), Vector2i(size.x / 2, size.y / 2), Vector2i(size.x - 1, size.y - 1)]
	for test_pos in test_pixels:
		if test_pos.x < size.x and test_pos.y < size.y:
			var test_color: Color = img.get_pixel(test_pos.x, test_pos.y)
			MythosLogger.verbose("World/Generation", "Heightmap sample", {"position": test_pos, "height": test_color.r})


func _apply_erosion(world_map_data: WorldMapData) -> void:
	"""Apply simple hydraulic erosion to carve valleys and rivers."""
	var img: Image = world_map_data.heightmap_image
	var size: Vector2i = img.get_size()
	
	# Simple erosion: simulate water flow downhill
	for iteration in range(world_map_data.erosion_iterations):
		var new_img: Image = img.duplicate()
		
		for y in range(1, size.y - 1):
			for x in range(1, size.x - 1):
				var current_height: float = img.get_pixel(x, y).r
				
				# Find steepest downhill direction
				var neighbors: Array[Vector2i] = [
					Vector2i(x - 1, y),
					Vector2i(x + 1, y),
					Vector2i(x, y - 1),
					Vector2i(x, y + 1)
				]
				
				var max_slope: float = 0.0
				var erosion_amount: float = 0.0
				
				for neighbor in neighbors:
					var neighbor_height: float = img.get_pixel(neighbor.x, neighbor.y).r
					var slope: float = current_height - neighbor_height
					if slope > max_slope:
						max_slope = slope
						erosion_amount = slope * world_map_data.erosion_strength * 0.1
				
				# Erode current pixel
				if erosion_amount > 0.0:
					var new_height: float = clamp(current_height - erosion_amount, 0.0, 1.0)
					new_img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))
		
		img = new_img
		world_map_data.heightmap_image = img
		
		if iteration % 2 == 0:
			MythosLogger.debug("World/Generation", "Erosion iteration", {
				"current": iteration + 1,
				"total": world_map_data.erosion_iterations
			})
	
	MythosLogger.info("World/Generation", "Erosion complete", {"iterations": world_map_data.erosion_iterations})


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
			
			# Determine biome color based on height, temperature, moisture
			var biome_color: Color = _get_biome_color(height, temperature, moisture)
			biome_img.set_pixel(x, size.y - 1 - y, biome_color)
	
	world_map_data.biome_preview_image = biome_img
	return biome_img


func _get_biome_color(height: float, temperature: float, moisture: float) -> Color:
	"""Determine biome color from height, temperature, moisture."""
	# Underwater
	if height < 0.4:
		return Color(0.1, 0.2, 0.4, 1.0)  # Deep blue
	
	# Beach
	if height < 0.42:
		return Color(0.9, 0.85, 0.7, 1.0)  # Sandy beige
	
	# Lowlands (plains, desert, grassland)
	if height < 0.5:
		if moisture > 0.6:
			return Color(0.3, 0.6, 0.2, 1.0)  # Green grassland
		elif moisture < 0.3:
			return Color(0.7, 0.6, 0.4, 1.0)  # Desert
		else:
			return Color(0.5, 0.5, 0.3, 1.0)  # Plains
	
	# Midlands (forest, temperate)
	if height < 0.65:
		if moisture > 0.5:
			return Color(0.2, 0.4, 0.15, 1.0)  # Dark green forest
		else:
			return Color(0.4, 0.45, 0.25, 1.0)  # Light forest
	
	# Highlands (mountains, tundra)
	if height < 0.8:
		return Color(0.5, 0.5, 0.5, 1.0)  # Gray mountains
	
	# Peaks (snow)
	return Color(0.95, 0.95, 1.0, 1.0)  # White snow