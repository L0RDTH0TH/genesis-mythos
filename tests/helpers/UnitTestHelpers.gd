# ╔═══════════════════════════════════════════════════════════
# ║ UnitTestHelpers.gd
# ║ Desc: Shared unit test mocks/fixtures for core systems
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name UnitTestHelpers

## Create minimal WorldMapData-like dictionary for MapGenerator tests
static func create_seed_data(p_seed: int, p_width: int = 512, p_height: int = 512) -> Dictionary:
	"""Fixture: Minimal WorldMapData-like dict for MapGenerator tests."""
	return {
		"seed_value": p_seed,
		"world_width": p_width,
		"world_height": p_height
	}

## Create a WorldMapData resource with test parameters
static func create_test_world_map_data(p_seed: int = 12345, p_width: int = 512, p_height: int = 512) -> WorldMapData:
	"""Create a WorldMapData resource with test parameters."""
	var data := WorldMapData.new()
	data.seed = p_seed
	data.world_width = p_width
	data.world_height = p_height
	data.noise_type = FastNoiseLite.TYPE_PERLIN
	data.noise_frequency = 0.0005
	data.noise_octaves = 4
	data.noise_persistence = 0.5
	data.noise_lacunarity = 2.0
	data.erosion_enabled = false  # Disable for faster tests
	data.erosion_iterations = 0
	data.rivers_enabled = false  # Disable for faster tests
	data.sea_level = 0.4
	data.biome_temperature_noise_frequency = 0.002
	data.biome_moisture_noise_frequency = 0.002
	return data

## Create invalid JSON string for error testing
static func create_invalid_json() -> String:
	"""Create invalid JSON string for error testing."""
	return "{ invalid json: missing quotes, }"

## Create valid biome JSON structure
static func create_test_biome_json() -> Dictionary:
	"""Create valid biome JSON structure for testing."""
	return {
		"biomes": [
			{
				"id": "test_biome",
				"name": "Test Biome",
				"temperature_range": [0, 20],
				"rainfall_range": [50, 100],
				"color": [0.5, 0.5, 0.5, 1.0]
			}
		]
	}

## Create mock Logger output capture
static func capture_logger_output() -> Array[String]:
	"""Create a mock logger output capture (returns empty array, actual implementation would capture)."""
	return []

## Assert heightmap values are in valid range [0.0, 1.0]
static func assert_heightmap_valid(img: Image, msg_prefix: String = "") -> bool:
	"""Assert all heightmap pixel values are in valid range [0.0, 1.0]."""
	if img == null:
		push_error("FAIL: Heightmap image is null. Context: %s. Why: Cannot validate null image. Hint: Ensure MapGenerator created heightmap before validation." % msg_prefix)
		return false
	
	var size: Vector2i = img.get_size()
	var invalid_count: int = 0
	var invalid_pixels: Array[Vector2i] = []
	
	for y in range(size.y):
		for x in range(size.x):
			var color: Color = img.get_pixel(x, y)
			var height: float = color.r  # RF format uses red channel
			if height < 0.0 or height > 1.0:
				invalid_count += 1
				if invalid_pixels.size() < 10:  # Limit to first 10 for error message
					invalid_pixels.append(Vector2i(x, y))
	
	if invalid_count > 0:
		var pixel_list: String = str(invalid_pixels)
		push_error("FAIL: Expected all heightmap values in range [0.0, 1.0], got %d invalid pixels. Context: %s. Invalid pixels (first 10): %s. Why: Heightmap normalization failed or values not clamped. Hint: Check MapGenerator._generate_heightmap() normalization logic." % [invalid_count, msg_prefix, pixel_list])
		return false
	
	return true

## Compare two heightmap images pixel-by-pixel (for determinism tests)
static func compare_heightmaps(img1: Image, img2: Image, tolerance: float = 0.0001, msg_prefix: String = "") -> bool:
	"""Compare two heightmap images pixel-by-pixel. Returns true if identical within tolerance."""
	if img1 == null or img2 == null:
		push_error("FAIL: One or both heightmap images are null. Context: %s. Why: Cannot compare null images. Hint: Ensure both MapGenerator instances generated heightmaps." % msg_prefix)
		return false
	
	var size1: Vector2i = img1.get_size()
	var size2: Vector2i = img2.get_size()
	
	if size1 != size2:
		push_error("FAIL: Expected identical heightmap sizes, got %s vs %s. Context: %s. Why: Different map sizes cannot be identical. Hint: Ensure both generators use same world_width/world_height." % [size1, size2, msg_prefix])
		return false
	
	var diff_count: int = 0
	var max_diff: float = 0.0
	var diff_pixels: Array[Vector2i] = []
	
	for y in range(size1.y):
		for x in range(size1.x):
			var h1: float = img1.get_pixel(x, y).r
			var h2: float = img2.get_pixel(x, y).r
			var diff: float = abs(h1 - h2)
			
			if diff > tolerance:
				diff_count += 1
				max_diff = max(max_diff, diff)
				if diff_pixels.size() < 10:
					diff_pixels.append(Vector2i(x, y))
	
	if diff_count > 0:
		var pixel_list: String = str(diff_pixels)
		push_error("FAIL: Expected identical heightmaps (tolerance %.6f), got %d differing pixels (max diff: %.6f). Context: %s. Differing pixels (first 10): %s. Why: Non-deterministic generation (RNG seed not set correctly or noise generators not initialized identically). Hint: Check MapGenerator._configure_noise() seed initialization, ensure FastNoiseLite instances use same seed." % [tolerance, diff_count, max_diff, msg_prefix, pixel_list])
		return false
	
	return true
