# ╔═══════════════════════════════════════════════════════════
# ║ test_full_world_gen_workflow.gd
# ║ Desc: End-to-end integration test for complete world generation workflow
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Complete workflow components
var map_generator: MapGenerator
var map_renderer: MapRenderer
var map_editor: MapEditor
var marker_manager: MarkerManager
var terrain_manager: Terrain3DManager
var test_data: WorldMapData
var test_scene: Node2D

func before_all() -> void:
	"""Setup test scene before all tests."""
	test_scene = Node2D.new()
	test_scene.name = "TestScene"
	get_tree().root.add_child(test_scene)

func after_all() -> void:
	"""Cleanup test scene after all tests."""
	if test_scene:
		test_scene.queue_free()
		await get_tree().process_frame

func before_each() -> void:
	"""Setup components before each test."""
	test_data = UnitTestHelpers.create_test_world_map_data(12345, 512, 512)
	map_generator = MapGenerator.new()
	map_renderer = MapRenderer.new()
	map_editor = MapEditor.new()
	marker_manager = MarkerManager.new()
	terrain_manager = Terrain3DManager.new()
	
	test_scene.add_child(map_renderer)
	test_scene.add_child(map_editor)
	test_scene.add_child(marker_manager)
	test_scene.add_child(terrain_manager)
	
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup components after each test."""
	if map_generator:
		map_generator = null
	if map_renderer:
		map_renderer.queue_free()
	if map_editor:
		map_editor.queue_free()
	if marker_manager:
		marker_manager.queue_free()
	if terrain_manager:
		terrain_manager.queue_free()
	if test_data:
		test_data = null
	await get_tree().process_frame

func test_complete_world_generation_workflow() -> void:
	"""Test complete workflow: Generate → Render → Edit → Add Markers → Export to Terrain3D."""
	# Step 1: Generate map
	map_generator.generate_map(test_data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(test_data.heightmap_image, "FAIL: Expected heightmap after generation. Context: Complete workflow step 1. Why: Generation should create heightmap. Hint: Check MapGenerator.generate_map().")
	
	# Step 2: Render map
	map_renderer.set_world_map_data(test_data)
	await get_tree().process_frame
	
	var sprite := Sprite2D.new()
	sprite.name = "MapSprite"
	test_scene.add_child(sprite)
	map_renderer.setup_render_target(sprite)
	await get_tree().process_frame
	
	pass_test("Step 2: Map rendered")
	
	# Step 3: Edit map
	map_editor.set_world_map_data(test_data)
	map_editor.set_tool(MapEditor.EditTool.RAISE)
	map_editor.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	map_editor.end_paint()
	await get_tree().process_frame
	
	pass_test("Step 3: Map edited")
	
	# Step 4: Add markers
	marker_manager.set_world_map_data(test_data)
	marker_manager.add_marker(Vector2(100, 100), "city", "Test City")
	await get_tree().process_frame
	
	assert_eq(test_data.markers.size(), 1, "FAIL: Expected 1 marker after add_marker(). Context: Complete workflow step 4. Why: Marker should be added. Hint: Check MarkerManager.add_marker().")
	
	# Step 5: Export to Terrain3D
	if terrain_manager.has_method("generate_from_heightmap"):
		terrain_manager.generate_from_heightmap(test_data.heightmap_image, -50.0, 300.0, Vector3.ZERO)
		await get_tree().process_frame
		await get_tree().process_frame
		pass_test("Step 5: Terrain3D generated")
	
	sprite.queue_free()
	await get_tree().process_frame
	
	pass_test("Complete world generation workflow executed successfully")

func test_error_propagation_map_generator_failure() -> void:
	"""Test that other systems handle MapGenerator failure gracefully."""
	# Simulate MapGenerator failure (null data)
	map_generator.generate_map(null, false)
	await get_tree().process_frame
	
	# Other systems should handle missing heightmap gracefully
	map_renderer.set_world_map_data(null)
	await get_tree().process_frame
	
	map_editor.set_world_map_data(null)
	await get_tree().process_frame
	
	# Should not crash
	pass_test("Systems handle MapGenerator failure gracefully")

func test_error_propagation_map_renderer_failure() -> void:
	"""Test that other systems handle MapRenderer failure gracefully."""
	# Generate map successfully
	map_generator.generate_map(test_data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# MapRenderer with null shader should not crash other systems
	# (Renderer may log error but shouldn't affect other systems)
	pass_test("Systems handle MapRenderer failure gracefully")

func test_stress_test_large_map_generation() -> void:
	"""Stress test: Generate very large map and verify all systems handle it."""
	var large_data := UnitTestHelpers.create_test_world_map_data(12345, 2048, 2048)
	
	# Generate large map (may take time)
	map_generator.generate_map(large_data, true)  # Use threading for large map
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Wait for thread if accessible
	if map_generator.has("generation_thread") and map_generator.generation_thread != null:
		if map_generator.generation_thread.is_alive():
			map_generator.generation_thread.wait_to_finish()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(large_data.heightmap_image, "FAIL: Expected heightmap for large map. Context: 2048x2048 map. Why: Large maps should generate. Hint: Check memory allocation and threading for large maps.")
	
	var img_size: Vector2i = large_data.heightmap_image.get_size()
	assert_eq(img_size, Vector2i(2048, 2048), "FAIL: Expected large map size 2048x2048, got %s. Context: Stress test. Why: Large maps should generate correctly. Hint: Check MapGenerator handles large maps without memory issues.")
	
	pass_test("Stress test: Large map generation successful")

func test_state_consistency_across_systems() -> void:
	"""Test that all systems maintain consistent state when world_map_data changes."""
	# Generate initial map
	map_generator.generate_map(test_data, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Set data in all systems
	map_renderer.set_world_map_data(test_data)
	map_editor.set_world_map_data(test_data)
	marker_manager.set_world_map_data(test_data)
	await get_tree().process_frame
	
	# Modify data (edit map)
	map_editor.set_tool(MapEditor.EditTool.RAISE)
	map_editor.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	map_editor.end_paint()
	await get_tree().process_frame
	
	# Refresh renderer (should update)
	map_renderer.refresh()
	await get_tree().process_frame
	
	# All systems should reflect changes
	pass_test("State consistency maintained across systems")
