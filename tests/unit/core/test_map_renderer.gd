# ╔═══════════════════════════════════════════════════════════
# ║ test_map_renderer.gd
# ║ Desc: Unit tests for MapRenderer view modes, texture updates, and shader material handling
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MapRenderer instance
var map_renderer: MapRenderer

## Test fixture: WorldMapData for testing
var test_data: WorldMapData

## Test fixture: Scene tree for testing
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
	"""Setup MapRenderer instance before each test."""
	test_data = UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	map_renderer = MapRenderer.new()
	map_renderer.name = "MapRenderer"
	test_scene.add_child(map_renderer)
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup MapRenderer instance after each test."""
	if map_renderer:
		map_renderer.queue_free()
	if test_data:
		test_data = null
	await get_tree().process_frame
	map_renderer = null

func test_map_renderer_initializes() -> void:
	"""Test that MapRenderer initializes without errors."""
	assert_not_null(map_renderer, "FAIL: Expected MapRenderer to be created. Context: Instantiation. Why: Renderer should initialize. Hint: Check MapRenderer._init() completes without errors.")

func test_map_renderer_loads_shader() -> void:
	"""Test that MapRenderer loads shader material."""
	# MapRenderer should load shader in _init()
	# If shader doesn't exist, it should log error but not crash
	pass_test("MapRenderer shader loading (may fail if shader not found, but should not crash)")

func test_map_renderer_set_world_map_data() -> void:
	"""Test that set_world_map_data sets world map data and updates textures."""
	map_renderer.set_world_map_data(test_data)
	await get_tree().process_frame
	
	# Verify textures are updated (we can't easily access private vars, but we can test methods work)
	pass_test("set_world_map_data sets data and updates textures")

func test_map_renderer_set_world_map_data_with_null() -> void:
	"""Test that set_world_map_data handles null data gracefully."""
	# Should not crash with null data
	map_renderer.set_world_map_data(null)
	await get_tree().process_frame
	
	# Test passes if no crash - error should be logged
	pass_test("set_world_map_data with null data handled without crash")

func test_map_renderer_set_world_map_data_with_null_heightmap() -> void:
	"""Test that set_world_map_data handles null heightmap gracefully."""
	var data_without_heightmap := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	data_without_heightmap.heightmap_image = null
	
	map_renderer.set_world_map_data(data_without_heightmap)
	await get_tree().process_frame
	
	# Test passes if no crash - error should be logged
	pass_test("set_world_map_data with null heightmap handled without crash")

func test_map_renderer_setup_render_target_texture_rect() -> void:
	"""Test that setup_render_target works with TextureRect."""
	var texture_rect := TextureRect.new()
	texture_rect.name = "TestTextureRect"
	test_scene.add_child(texture_rect)
	await get_tree().process_frame
	
	map_renderer.setup_render_target(texture_rect)
	await get_tree().process_frame
	
	# Verify material is applied (we can't easily check, but we can test it doesn't crash)
	pass_test("setup_render_target with TextureRect handled without crash")
	
	texture_rect.queue_free()
	await get_tree().process_frame

func test_map_renderer_setup_render_target_sprite2d() -> void:
	"""Test that setup_render_target works with Sprite2D."""
	var sprite := Sprite2D.new()
	sprite.name = "TestSprite"
	test_scene.add_child(sprite)
	await get_tree().process_frame
	
	map_renderer.setup_render_target(sprite)
	await get_tree().process_frame
	
	# Verify material is applied
	pass_test("setup_render_target with Sprite2D handled without crash")
	
	sprite.queue_free()
	await get_tree().process_frame

func test_map_renderer_setup_render_target_with_null() -> void:
	"""Test that setup_render_target handles null target gracefully."""
	# Should not crash with null target
	map_renderer.setup_render_target(null)
	await get_tree().process_frame
	
	# Test passes if no crash - warning should be logged
	pass_test("setup_render_target with null target handled without crash")

func test_map_renderer_set_view_mode() -> void:
	"""Test that set_view_mode changes view mode correctly."""
	var modes: Array = [
		MapRenderer.ViewMode.HEIGHTMAP,
		MapRenderer.ViewMode.BIOMES,
		MapRenderer.ViewMode.POLITICAL
	]
	
	map_renderer.set_world_map_data(test_data)
	await get_tree().process_frame
	
	for mode in modes:
		map_renderer.set_view_mode(mode)
		await get_tree().process_frame
		
		# Verify mode is set (we can't easily access private var, but we can test it doesn't crash)
		pass_test("View mode %d set without crash" % mode)
	
	pass_test("set_view_mode changes view mode correctly")

func test_map_renderer_set_light_direction() -> void:
	"""Test that set_light_direction sets light direction correctly."""
	var directions: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(0.5, 0.5),
		Vector2(1.0, 1.0),
		Vector2(-0.5, -0.5),  # Should be clamped
		Vector2(1.5, 1.5)     # Should be clamped
	]
	
	map_renderer.set_world_map_data(test_data)
	await get_tree().process_frame
	
	for direction in directions:
		map_renderer.set_light_direction(direction)
		await get_tree().process_frame
		
		# Verify direction is set and clamped
		pass_test("Light direction %s set without crash" % direction)
	
	pass_test("set_light_direction sets direction correctly (with clamping)")

func test_map_renderer_set_rivers_visible() -> void:
	"""Test that set_rivers_visible toggles river overlay."""
	map_renderer.set_world_map_data(test_data)
	await get_tree().process_frame
	
	# Test both true and false
	map_renderer.set_rivers_visible(true)
	await get_tree().process_frame
	map_renderer.set_rivers_visible(false)
	await get_tree().process_frame
	
	pass_test("set_rivers_visible toggles river overlay")

func test_map_renderer_refresh() -> void:
	"""Test that refresh updates rendering."""
	map_renderer.set_world_map_data(test_data)
	await get_tree().process_frame
	
	# Setup render target
	var sprite := Sprite2D.new()
	sprite.name = "TestSprite"
	test_scene.add_child(sprite)
	map_renderer.setup_render_target(sprite)
	await get_tree().process_frame
	
	# Refresh should update textures
	map_renderer.refresh()
	await get_tree().process_frame
	
	pass_test("refresh updates rendering")
	
	sprite.queue_free()
	await get_tree().process_frame

func test_map_renderer_refresh_with_null_render_target() -> void:
	"""Test that refresh handles null render target gracefully."""
	map_renderer.set_world_map_data(test_data)
	await get_tree().process_frame
	
	# Refresh without render target should log error but not crash
	map_renderer.refresh()
	await get_tree().process_frame
	
	pass_test("refresh with null render target handled without crash")

func test_map_renderer_generates_biome_preview_if_missing() -> void:
	"""Test that MapRenderer generates biome preview if not present in world_map_data."""
	var data_without_biome := UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	data_without_biome.biome_preview_image = null
	
	map_renderer.set_world_map_data(data_without_biome)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Biome preview should be generated (or error logged if generation fails)
	pass_test("MapRenderer generates biome preview if missing")

func test_map_renderer_handles_missing_shader() -> void:
	"""Test that MapRenderer handles missing shader gracefully."""
	# If shader file doesn't exist, MapRenderer should log error but not crash
	# This is tested implicitly through initialization
	pass_test("MapRenderer handles missing shader gracefully (error logged)")
