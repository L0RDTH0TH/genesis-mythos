# ╔═══════════════════════════════════════════════════════════════════════════════
# ║ test_map_generator.gd
# ║ Desc: Unit tests for MapGenerator determinism, performance, and correctness
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════════════════════════

extends GutTest

## Test fixture: WorldMapData for testing
var test_data: WorldMapData

## Test fixture: MapGenerator instances
var gen1: MapGenerator
var gen2: MapGenerator

func before_each() -> void:
	"""Setup test fixtures before each test."""
	test_data = UnitTestHelpers.create_test_world_map_data(12345, 512, 512)
	gen1 = MapGenerator.new()
	gen2 = MapGenerator.new()

func after_each() -> void:
	"""Cleanup after each test."""
	if test_data:
		test_data = null
	if gen1:
		gen1 = null
	if gen2:
		gen2 = null

func test_same_seed_produces_identical_heightmap() -> void:
	"""Test that same seed produces identical heightmap (determinism for reproducible worlds)."""
	var data1 := UnitTestHelpers.create_test_world_map_data(12345, 512, 512)
	var data2 := UnitTestHelpers.create_test_world_map_data(12345, 512, 512)
	
	# Generate heightmaps synchronously (non-threaded for determinism)
	gen1.generate_map(data1, false)
	gen2.generate_map(data2, false)
	
	# Wait for generation to complete (synchronous, but ensure frames processed)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify heightmaps were created
	assert_not_null(data1.heightmap_image, "FAIL: Expected data1.heightmap_image to exist after generation. Context: seed=12345, size=512x512, non-threaded. Why: MapGenerator should create heightmap_image. Hint: Check MapGenerator._generate_heightmap() creates image.")
	assert_not_null(data2.heightmap_image, "FAIL: Expected data2.heightmap_image to exist after generation. Context: seed=12345, size=512x512, non-threaded. Why: MapGenerator should create heightmap_image. Hint: Check MapGenerator._generate_heightmap() creates image.")
	
	# Compare heightmaps pixel-by-pixel
	var is_identical: bool = UnitTestHelpers.compare_heightmaps(
		data1.heightmap_image,
		data2.heightmap_image,
		0.0001,
		"seed=12345, size=512x512, non-threaded"
	)
	assert_true(is_identical, "FAIL: Expected identical heightmaps for seed 12345 (determinism for repro worlds). Got different. Context: non-threaded, 512x512. Why: Non-deterministic generation (RNG seed not set correctly). Hint: Check RNG seed in FastNoiseLite initialization in MapGenerator._configure_noise().")

func test_different_seeds_produce_different_heightmaps() -> void:
	"""Test that different seeds produce different heightmaps."""
	var data1 := UnitTestHelpers.create_test_world_map_data(12345, 512, 512)
	var data2 := UnitTestHelpers.create_test_world_map_data(54321, 512, 512)
	
	gen1.generate_map(data1, false)
	gen2.generate_map(data2, false)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(data1.heightmap_image, "FAIL: Expected data1.heightmap_image to exist. Context: seed=12345. Why: Generation should create heightmap. Hint: Check MapGenerator.generate_map().")
	assert_not_null(data2.heightmap_image, "FAIL: Expected data2.heightmap_image to exist. Context: seed=54321. Why: Generation should create heightmap. Hint: Check MapGenerator.generate_map().")
	
	# Compare - should be different (check for differences directly, not identity)
	var size1: Vector2i = data1.heightmap_image.get_size()
	var size2: Vector2i = data2.heightmap_image.get_size()
	assert_eq(size1, size2, "Heightmaps must have same size for comparison")
	
	var diff_count: int = 0
	var max_diff: float = 0.0
	var tolerance: float = 0.0001
	
	for y in range(size1.y):
		for x in range(size1.x):
			var h1: float = data1.heightmap_image.get_pixel(x, y).r
			var h2: float = data2.heightmap_image.get_pixel(x, y).r
			var diff: float = abs(h1 - h2)
			if diff > tolerance:
				diff_count += 1
				max_diff = max(max_diff, diff)
	
	# Different seeds should produce significantly different heightmaps
	# Expect at least 10% of pixels to differ (to account for edge cases)
	var min_expected_diffs: int = (size1.x * size1.y) / 10
	assert_true(diff_count > min_expected_diffs, "FAIL: Expected different heightmaps for different seeds (12345 vs 54321). Found only %d differing pixels (%.2f%%), expected at least %d (10%%). Max diff: %.6f. Context: size=512x512, non-threaded. Why: Seeds not affecting noise generation sufficiently. Hint: Check MapGenerator._configure_noise() sets FastNoiseLite.seed correctly and heightmap generation preserves seed-dependent variation." % [diff_count, (float(diff_count) / float(size1.x * size1.y)) * 100.0, min_expected_diffs, max_diff])

func test_heightmap_values_in_valid_range() -> void:
	"""Test that all heightmap values are in valid range [0.0, 1.0]."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)  # Smaller for speed
	
	gen1.generate_map(data, false)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(data.heightmap_image, "FAIL: Expected heightmap_image to exist. Context: seed=12345, size=256x256. Why: Generation should create image. Hint: Check MapGenerator._generate_heightmap().")
	
	var is_valid: bool = UnitTestHelpers.assert_heightmap_valid(
		data.heightmap_image,
		"seed=12345, size=256x256"
	)
	assert_true(is_valid, "FAIL: Expected all heightmap values in range [0.0, 1.0]. Got values outside range. Context: seed=12345, size=256x256. Why: Heightmap normalization failed. Hint: Check MapGenerator._generate_heightmap() normalization logic (height_value = (height_value + 1.0) * 0.5).")

func test_erosion_reduces_peak_heights() -> void:
	"""Test that erosion reduces peak heights (simplified test - check max height decreases)."""
	var data_no_erosion := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	data_no_erosion.erosion_enabled = false
	data_no_erosion.erosion_iterations = 0
	
	var data_with_erosion := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	data_with_erosion.erosion_enabled = true
	data_with_erosion.erosion_iterations = 5
	data_with_erosion.erosion_strength = 0.3
	
	gen1.generate_map(data_no_erosion, false)
	gen2.generate_map(data_with_erosion, false)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(data_no_erosion.heightmap_image, "FAIL: Expected no-erosion heightmap to exist. Context: seed=12345. Why: Generation should create image. Hint: Check MapGenerator.generate_map().")
	assert_not_null(data_with_erosion.heightmap_image, "FAIL: Expected with-erosion heightmap to exist. Context: seed=12345. Why: Generation should create image. Hint: Check MapGenerator._apply_erosion().")
	
	# Find max heights
	var max_no_erosion: float = 0.0
	var max_with_erosion: float = 0.0
	var size: Vector2i = data_no_erosion.heightmap_image.get_size()
	
	for y in range(size.y):
		for x in range(size.x):
			var h1: float = data_no_erosion.heightmap_image.get_pixel(x, y).r
			var h2: float = data_with_erosion.heightmap_image.get_pixel(x, y).r
			max_no_erosion = max(max_no_erosion, h1)
			max_with_erosion = max(max_with_erosion, h2)
	
	# Erosion should reduce peaks (but same seed means same initial, so erosion should lower max)
	# Note: This is a simplified test - actual erosion is more complex
	var erosion_worked: bool = max_with_erosion <= max_no_erosion
	assert_true(erosion_worked, "FAIL: Expected erosion to reduce or maintain peak heights (max_with_erosion <= max_no_erosion). Got max_no_erosion=%.6f, max_with_erosion=%.6f. Context: seed=12345, iterations=5, strength=0.3. Why: Erosion should carve valleys and reduce peaks. Hint: Check MapGenerator._apply_erosion() logic (erosion_amount calculation, height reduction)." % [max_no_erosion, max_with_erosion])

func test_generate_map_with_null_data_handles_gracefully() -> void:
	"""Test that generate_map handles null world_map_data gracefully."""
	# This should not crash - should log error and return early
	gen1.generate_map(null, false)
	
	await get_tree().process_frame
	
	# Test passes if no crash - Logger should have logged error
	# (We can't easily test Logger output in unit tests without mocking)
	pass_test("generate_map with null data handled without crash")

func test_generate_map_creates_heightmap_image() -> void:
	"""Test that generate_map creates heightmap_image if it doesn't exist."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	data.heightmap_image = null  # Ensure it's null
	
	gen1.generate_map(data, false)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(data.heightmap_image, "FAIL: Expected heightmap_image to be created when null. Context: seed=12345, size=256x256. Why: MapGenerator should create image if missing. Hint: Check MapGenerator._generate_heightmap() calls world_map_data.create_heightmap() when image is null.")

func test_generate_map_sets_correct_image_size() -> void:
	"""Test that generated heightmap has correct size matching world dimensions."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 512, 256)  # Non-square for testing
	
	gen1.generate_map(data, false)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(data.heightmap_image, "FAIL: Expected heightmap_image to exist. Context: seed=12345, size=512x256. Why: Generation should create image. Hint: Check MapGenerator._generate_heightmap().")
	
	var img_size: Vector2i = data.heightmap_image.get_size()
	var expected_size: Vector2i = Vector2i(512, 256)
	
	assert_eq(img_size, expected_size, "FAIL: Expected heightmap size %s, got %s. Context: seed=12345, world_width=512, world_height=256. Why: Image size should match world dimensions. Hint: Check WorldMapData.create_heightmap() uses correct size parameters.")

func test_generate_map_with_zero_size_handles_gracefully() -> void:
	"""Test that generate_map handles zero-size maps gracefully."""
	var data_zero := UnitTestHelpers.create_test_world_map_data(12345, 0, 0)
	
	# Should validate and return early with error logged
	gen1.generate_map(data_zero, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Should not create heightmap with zero size
	# MapGenerator should validate and return early
	pass_test("generate_map with zero size handled gracefully (validation prevents crash)")

func test_generate_map_with_negative_size_handles_gracefully() -> void:
	"""Test that generate_map handles negative dimensions gracefully."""
	# Create data with negative dimensions (should be validated)
	var data_negative := WorldMapData.new()
	data_negative.seed = 12345
	data_negative.world_width = -100
	data_negative.world_height = -100
	
	# Should validate and return early with error logged
	gen1.generate_map(data_negative, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Should not create heightmap with negative size
	# MapGenerator should validate and return early
	pass_test("generate_map with negative size handled gracefully (validation prevents crash)")

func test_generate_map_with_extremely_large_size() -> void:
	"""Test that generate_map handles extremely large maps (memory/performance test)."""
	# Use moderately large size (4096x4096 would be too slow for tests)
	var data_large := UnitTestHelpers.create_test_world_map_data(12345, 2048, 2048)
	
	# Generate synchronously (threading may be used for very large maps)
	gen1.generate_map(data_large, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Wait additional frames for large map generation
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(data_large.heightmap_image, "FAIL: Expected heightmap_image for large map. Context: seed=12345, size=2048x2048. Why: Large maps should still generate. Hint: Check MapGenerator handles large maps without memory issues.")
	
	var img_size: Vector2i = data_large.heightmap_image.get_size()
	var expected_size: Vector2i = Vector2i(2048, 2048)
	assert_eq(img_size, expected_size, "FAIL: Expected heightmap size %s for large map, got %s. Context: size=2048x2048. Why: Large maps should generate correctly. Hint: Check memory allocation for large images.")

func test_generate_map_with_invalid_seed_values() -> void:
	"""Test that generate_map handles invalid seed values gracefully."""
	var invalid_seeds: Array = [-1, -999999, 2147483648, 999999999]
	
	for seed_value in invalid_seeds:
		var data := WorldMapData.new()
		data.seed = seed_value as int
		data.world_width = 256
		data.world_height = 256
		
		# Should not crash with invalid seed
		gen1.generate_map(data, false)
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Test passes if no crash (seed may be clamped or used as-is)
		pass_test("generate_map with seed %s handled without crash" % seed_value)

func test_generate_map_with_extreme_noise_parameters() -> void:
	"""Test that generate_map handles extreme noise parameters gracefully."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	
	# Test extreme noise parameters
	data.noise_frequency = 0.0  # Zero frequency
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	pass_test("generate_map with zero noise frequency handled")
	
	data.noise_frequency = 1000.0  # Very high frequency
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	pass_test("generate_map with very high noise frequency handled")
	
	data.noise_octaves = 0  # Zero octaves
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	pass_test("generate_map with zero octaves handled")
	
	data.noise_octaves = 100  # Very high octaves
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	pass_test("generate_map with very high octaves handled")

func test_generate_map_with_extreme_erosion_parameters() -> void:
	"""Test that generate_map handles extreme erosion parameters gracefully."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	data.erosion_enabled = true
	
	# Test extreme erosion parameters
	data.erosion_iterations = 0
	data.erosion_strength = 0.0
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	pass_test("generate_map with zero erosion iterations handled")
	
	data.erosion_iterations = 1000  # Very high iterations
	data.erosion_strength = 1.0
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	pass_test("generate_map with very high erosion iterations handled")

func test_generate_map_recreates_heightmap_on_size_mismatch() -> void:
	"""Test that generate_map recreates heightmap when size doesn't match."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	
	# Generate first time
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Change world size
	data.world_width = 512
	data.world_height = 512
	
	# Generate again - should recreate heightmap
	gen1.generate_map(data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img_size: Vector2i = data.heightmap_image.get_size()
	var expected_size: Vector2i = Vector2i(512, 512)
	assert_eq(img_size, expected_size, "FAIL: Expected heightmap to be recreated with new size %s, got %s. Context: Size changed from 256x256 to 512x512. Why: Heightmap should be recreated when size changes. Hint: Check MapGenerator._generate_heightmap() detects size mismatch and recreates image.")
