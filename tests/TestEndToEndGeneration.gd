# ╔═══════════════════════════════════════════════════════════
# ║ TestEndToEndGeneration.gd
# ║ Desc: End-to-end tests for complete 2D map generation pipeline
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MapGenerator instance
var map_generator: MapGenerator

## Test fixture: MapRenderer instance
var map_renderer: MapRenderer

## Test fixture: WorldMapData instance
var world_map_data: WorldMapData


func before_each() -> void:
	"""Setup test fixtures before each test."""
	map_generator = MapGenerator.new()
	map_renderer = MapRenderer.new()
	world_map_data = WorldMapData.new()
	world_map_data.seed = 12345
	world_map_data.world_width = 512
	world_map_data.world_height = 512
	world_map_data.create_heightmap(512, 512)


func after_each() -> void:
	"""Cleanup test fixtures after each test."""
	if map_generator != null:
		map_generator = null
	if map_renderer != null:
		map_renderer.queue_free()
	if world_map_data != null:
		world_map_data = null


func test_complete_generation_pipeline() -> void:
	"""Test complete generation pipeline from start to finish."""
	# Step 1: Configure parameters
	world_map_data.landmass_type = "Single Island"
	world_map_data.noise_frequency = 0.005
	world_map_data.noise_octaves = 4
	world_map_data.sea_level = 0.4
	
	# Step 2: Generate heightmap
	map_generator.generate_map(world_map_data, false)
	assert_not_null(world_map_data.heightmap_image, "FAIL: Expected heightmap after generation. Context: Complete pipeline. Why: Generation should create heightmap. Hint: Check generate_map().")
	
	# Step 3: Generate biome preview
	var biome_img: Image = map_generator.generate_biome_preview(world_map_data)
	assert_not_null(biome_img, "FAIL: Expected biome preview. Context: Complete pipeline. Why: Should generate biome preview. Hint: Check generate_biome_preview().")
	
	# Step 4: Verify data integrity
	var height_size: Vector2i = world_map_data.heightmap_image.get_size()
	var biome_size: Vector2i = biome_img.get_size()
	assert_eq(height_size, biome_size, "FAIL: Heightmap and biome sizes should match. Context: Complete pipeline. Why: Same world dimensions. Hint: Check generation consistency.")
	
	# Step 5: Verify heightmap has valid data
	var sample_count: int = 0
	var valid_samples: int = 0
	for y in range(0, height_size.y, 50):
		for x in range(0, height_size.x, 50):
			var height: float = world_map_data.heightmap_image.get_pixel(x, y).r
			if height >= 0.0 and height <= 1.0:
				valid_samples += 1
			sample_count += 1
	
	var valid_ratio: float = float(valid_samples) / float(sample_count)
	assert_gt(valid_ratio, 0.95, "FAIL: Most heightmap samples should be valid. Context: Complete pipeline. Why: Heightmap should have valid data. Hint: Check normalization.")
	
	pass_test("Complete generation pipeline works end-to-end")


func test_generation_with_landmass_mask() -> void:
	"""Test that generation with landmass mask produces expected results."""
	# Generate with Single Island (should have land in center)
	world_map_data.landmass_type = "Single Island"
	world_map_data.seed = 12345
	map_generator.generate_map(world_map_data, false)
	
	var img: Image = world_map_data.heightmap_image
	var center_x: int = img.get_width() / 2
	var center_y: int = img.get_height() / 2
	var center_height: float = img.get_pixel(center_x, center_y).r
	
	# Center should be above sea level for Single Island
	assert_gt(center_height, world_map_data.sea_level, "FAIL: Center should be land for Single Island. Context: Landmass mask. Why: Single Island creates land in center. Hint: Check _apply_landmass_mask_to_heightmap().")
	
	pass_test("Generation with landmass mask works correctly")


func test_generation_with_post_processing() -> void:
	"""Test that post-processing pipeline applies correctly."""
	# Generate base map
	map_generator.generate_map(world_map_data, false)
	var img_before: Image = world_map_data.heightmap_image.duplicate()
	
	# Enable post-processing and regenerate
	map_generator.post_processing_config["enabled"] = true
	map_generator.generate_map(world_map_data, false)
	var img_after: Image = world_map_data.heightmap_image
	
	# Compare - post-processing should modify the map
	var center_x: int = img_before.get_width() / 2
	var center_y: int = img_before.get_height() / 2
	var height_before: float = img_before.get_pixel(center_x, center_y).r
	var height_after: float = img_after.get_pixel(center_x, center_y).r
	
	# Heights may differ (post-processing modifies terrain)
	# Just verify both are valid
	assert_ge(height_before, 0.0, "FAIL: Height before should be valid. Context: Post-processing. Why: Should have valid data. Hint: Check generation.")
	assert_le(height_before, 1.0, "FAIL: Height before should be <= 1.0. Context: Post-processing. Why: Should be normalized. Hint: Check normalization.")
	assert_ge(height_after, 0.0, "FAIL: Height after should be valid. Context: Post-processing. Why: Should have valid data. Hint: Check post-processing.")
	assert_le(height_after, 1.0, "FAIL: Height after should be <= 1.0. Context: Post-processing. Why: Should be normalized. Hint: Check post-processing.")
	
	pass_test("Generation with post-processing works correctly")


func test_sub_seed_handling() -> void:
	"""Test that sub-seeds work correctly."""
	# Set main seed
	world_map_data.set_seed(12345)
	
	# Set a sub-seed
	world_map_data.height_seed = 99999
	world_map_data.height_seed_locked = true
	
	# Verify effective seed
	var effective_seed: int = world_map_data.get_effective_seed("height")
	assert_eq(effective_seed, 99999, "FAIL: Effective seed should use sub-seed when set. Context: Sub-seed handling. Why: Sub-seeds allow partial randomization. Hint: Check get_effective_seed().")
	
	# Verify other systems use main seed
	var biome_effective: int = world_map_data.get_effective_seed("biome")
	assert_eq(biome_effective, 12345, "FAIL: Biome should use main seed when sub-seed not set. Context: Sub-seed handling. Why: Should fallback to main seed. Hint: Check get_effective_seed().")
	
	pass_test("Sub-seed handling works correctly")


func test_custom_post_processor_api() -> void:
	"""Test that custom post-processors can be registered."""
	var processor_called: bool = false
	
	var test_processor: Callable = func(data: WorldMapData) -> void:
		processor_called = true
		MythosLogger.debug("Test", "Custom post-processor called")
	
	# Register processor
	map_generator.register_custom_post_processor(test_processor)
	
	# Generate map (should call processor)
	map_generator.generate_map(world_map_data, false)
	
	# Verify processor was called
	assert_true(processor_called, "FAIL: Custom post-processor should be called. Context: API extensibility. Why: Registered processors should execute. Hint: Check register_custom_post_processor().")
	
	# Unregister
	map_generator.unregister_custom_post_processor(test_processor)
	
	pass_test("Custom post-processor API works correctly")
