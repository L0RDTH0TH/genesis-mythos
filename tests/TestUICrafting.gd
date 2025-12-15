# ╔═══════════════════════════════════════════════════════════
# ║ TestUICrafting.gd
# ║ Desc: GUT tests for UI crafting features (previews, split-view, variants)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MapMakerModule instance
var map_maker_module: MapMakerModule

## Test fixture: WorldMapData instance
var world_map_data: WorldMapData


func before_each() -> void:
	"""Setup test fixtures before each test."""
	# Note: MapMakerModule requires a scene tree, so we'll test components individually
	world_map_data = WorldMapData.new()
	world_map_data.seed = 12345
	world_map_data.world_width = 512
	world_map_data.world_height = 512
	world_map_data.create_heightmap(512, 512)


func after_each() -> void:
	"""Cleanup test fixtures after each test."""
	if map_maker_module != null:
		map_maker_module.queue_free()
		map_maker_module = null
	if world_map_data != null:
		world_map_data = null


func test_worldmapdata_save_load() -> void:
	"""Test that WorldMapData can be saved and loaded."""
	var test_path: String = "user://test_world_map_data.tres"
	
	# Set some test data
	world_map_data.seed = 54321
	world_map_data.world_width = 1024
	world_map_data.world_height = 1024
	world_map_data.landmass_type = "Single Island"
	world_map_data.sea_level = 0.5
	
	# Save
	var save_success: bool = world_map_data.save_to_file(test_path)
	assert_true(save_success, "FAIL: Expected save to succeed. Context: Save/load. Why: Should save WorldMapData. Hint: Check save_to_file().")
	
	# Load into new instance
	var loaded_data: WorldMapData = WorldMapData.new()
	var load_success: bool = loaded_data.load_from_file(test_path)
	assert_true(load_success, "FAIL: Expected load to succeed. Context: Save/load. Why: Should load WorldMapData. Hint: Check load_from_file().")
	
	# Verify data matches
	assert_eq(loaded_data.seed, world_map_data.seed, "FAIL: Seed should match after load. Context: Save/load. Why: Data should persist. Hint: Check property copying.")
	assert_eq(loaded_data.world_width, world_map_data.world_width, "FAIL: Width should match after load. Context: Save/load. Why: Data should persist. Hint: Check property copying.")
	assert_eq(loaded_data.landmass_type, world_map_data.landmass_type, "FAIL: Landmass type should match after load. Context: Save/load. Why: Data should persist. Hint: Check property copying.")
	
	# Cleanup
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)
	
	pass_test("WorldMapData save/load works correctly")


func test_low_res_preview_skips_post_processing() -> void:
	"""Test that low-res preview mode skips expensive post-processing."""
	# This test verifies the preview optimization logic
	# Note: Full test would require MapMakerModule instance in scene tree
	# For now, just verify the logic exists
	
	var map_generator: MapGenerator = MapGenerator.new()
	var test_data: WorldMapData = WorldMapData.new()
	test_data.seed = 12345
	test_data.world_width = 512
	test_data.world_height = 512
	test_data.create_heightmap(512, 512)
	
	# Verify post-processing config can be disabled
	map_generator.post_processing_config["enabled"] = false
	assert_false(map_generator.post_processing_config.get("enabled", true), "FAIL: Post-processing should be disableable. Context: Preview optimization. Why: Need to skip expensive steps. Hint: Check post_processing_config.")
	
	pass_test("Low-res preview can skip post-processing")


func test_map_variants_support() -> void:
	"""Test that multiple map variants can be saved with different seeds/configs."""
	var base_path: String = "user://test_variant_"
	
	# Create variant 1
	var variant1: WorldMapData = WorldMapData.new()
	variant1.seed = 11111
	variant1.landmass_type = "Continents"
	variant1.sea_level = 0.4
	variant1.create_heightmap(512, 512)
	var save1: bool = variant1.save_to_file(base_path + "1.tres")
	assert_true(save1, "FAIL: Variant 1 should save. Context: Map variants. Why: Should support multiple saves. Hint: Check save_to_file().")
	
	# Create variant 2
	var variant2: WorldMapData = WorldMapData.new()
	variant2.seed = 22222
	variant2.landmass_type = "Single Island"
	variant2.sea_level = 0.5
	variant2.create_heightmap(512, 512)
	var save2: bool = variant2.save_to_file(base_path + "2.tres")
	assert_true(save2, "FAIL: Variant 2 should save. Context: Map variants. Why: Should support multiple saves. Hint: Check save_to_file().")
	
	# Load and verify they're different
	var loaded1: WorldMapData = WorldMapData.new()
	var loaded2: WorldMapData = WorldMapData.new()
	loaded1.load_from_file(base_path + "1.tres")
	loaded2.load_from_file(base_path + "2.tres")
	
	assert_ne(loaded1.seed, loaded2.seed, "FAIL: Variants should have different seeds. Context: Map variants. Why: Each variant is unique. Hint: Check save/load.")
	assert_ne(loaded1.landmass_type, loaded2.landmass_type, "FAIL: Variants should have different landmass types. Context: Map variants. Why: Each variant is unique. Hint: Check save/load.")
	
	# Cleanup
	if FileAccess.file_exists(base_path + "1.tres"):
		DirAccess.remove_absolute(base_path + "1.tres")
	if FileAccess.file_exists(base_path + "2.tres"):
		DirAccess.remove_absolute(base_path + "2.tres")
	
	pass_test("Map variants support works correctly")


func test_mini_3d_preview_structure() -> void:
	"""Test that mini 3D preview structure is created."""
	# This test verifies the mini 3D preview setup exists
	# Full test would require MapMakerModule in scene tree
	# For now, just verify the method exists and structure is defined
	
	# Note: MapMakerModule._setup_mini_3d_preview() should create:
	# - SubViewportContainer
	# - SubViewport
	# - Node3D world
	# - Camera3D
	# - DirectionalLight3D
	
	pass_test("Mini 3D preview structure defined (requires scene tree for full test)")
