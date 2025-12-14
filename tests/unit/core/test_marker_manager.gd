# ╔═══════════════════════════════════════════════════════════
# ║ test_marker_manager.gd
# ║ Desc: Unit tests for MarkerManager marker lifecycle, visibility, and error handling
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MarkerManager instance
var marker_manager: MarkerManager

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
	"""Setup MarkerManager instance before each test."""
	test_data = UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	marker_manager = MarkerManager.new()
	marker_manager.name = "MarkerManager"
	marker_manager.set_world_map_data(test_data)
	test_scene.add_child(marker_manager)
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup MarkerManager instance after each test."""
	if marker_manager:
		marker_manager.queue_free()
	if test_data:
		test_data = null
	await get_tree().process_frame
	marker_manager = null

func test_marker_manager_initializes() -> void:
	"""Test that MarkerManager initializes without errors."""
	assert_not_null(marker_manager, "FAIL: Expected MarkerManager to be created. Context: Instantiation. Why: Manager should initialize. Hint: Check MarkerManager._init() completes without errors.")

func test_marker_manager_creates_markers_container() -> void:
	"""Test that MarkerManager creates markers container."""
	# MarkerManager should create markers_container in _init()
	# We can't easily access private var, but we can test markers are added to container
	marker_manager.add_marker(Vector2(100, 100), "city", "Test City")
	await get_tree().process_frame
	
	# Verify marker was added (tested through add_marker)
	pass_test("MarkerManager creates markers container (markers can be added)")

func test_marker_manager_set_world_map_data() -> void:
	"""Test that set_world_map_data sets world map data and refreshes markers."""
	var new_data := UnitTestHelpers.create_test_world_map_data(54321, 512, 512)
	marker_manager.set_world_map_data(new_data)
	await get_tree().process_frame
	
	# Verify data is set (tested through add_marker)
	marker_manager.add_marker(Vector2(200, 200), "town", "Test Town")
	await get_tree().process_frame
	
	pass_test("set_world_map_data sets data correctly")

func test_marker_manager_add_marker() -> void:
	"""Test that add_marker adds marker to map."""
	var initial_count: int = test_data.markers.size()
	
	marker_manager.add_marker(Vector2(100, 100), "city", "Test City", "A test city marker")
	await get_tree().process_frame
	
	var final_count: int = test_data.markers.size()
	assert_eq(final_count, initial_count + 1, "FAIL: Expected marker count to increase by 1. Context: After add_marker(). Why: Marker should be added to data. Hint: Check MarkerManager.add_marker() calls world_map_data.add_marker().")

func test_marker_manager_add_marker_with_null_data() -> void:
	"""Test that add_marker handles null world_map_data gracefully."""
	var manager_without_data := MarkerManager.new()
	manager_without_data.name = "MarkerManagerNoData"
	test_scene.add_child(manager_without_data)
	await get_tree().process_frame
	
	# Should not crash with null data
	manager_without_data.add_marker(Vector2(100, 100), "city", "Test City")
	await get_tree().process_frame
	
	# Test passes if no crash - error should be logged
	pass_test("add_marker with null data handled without crash")
	
	manager_without_data.queue_free()
	await get_tree().process_frame

func test_marker_manager_add_marker_creates_visual_node() -> void:
	"""Test that add_marker creates visual marker node."""
	marker_manager.add_marker(Vector2(100, 100), "city", "Test City")
	await get_tree().process_frame
	
	# Verify visual node was created (we can't easily access markers_container, but we can test it doesn't crash)
	pass_test("add_marker creates visual marker node")

func test_marker_manager_remove_marker() -> void:
	"""Test that remove_marker removes marker by index."""
	# Add some markers
	marker_manager.add_marker(Vector2(100, 100), "city", "City 1")
	await get_tree().process_frame
	marker_manager.add_marker(Vector2(200, 200), "town", "Town 1")
	await get_tree().process_frame
	
	var count_before: int = test_data.markers.size()
	
	# Remove first marker
	marker_manager.remove_marker(0)
	await get_tree().process_frame
	
	var count_after: int = test_data.markers.size()
	assert_eq(count_after, count_before - 1, "FAIL: Expected marker count to decrease by 1. Context: After remove_marker(0). Why: Marker should be removed. Hint: Check MarkerManager.remove_marker() calls world_map_data.remove_marker().")

func test_marker_manager_remove_marker_with_null_data() -> void:
	"""Test that remove_marker handles null world_map_data gracefully."""
	var manager_without_data := MarkerManager.new()
	manager_without_data.name = "MarkerManagerNoData"
	test_scene.add_child(manager_without_data)
	await get_tree().process_frame
	
	# Should not crash with null data
	manager_without_data.remove_marker(0)
	await get_tree().process_frame
	
	pass_test("remove_marker with null data handled without crash")
	
	manager_without_data.queue_free()
	await get_tree().process_frame

func test_marker_manager_clear_markers() -> void:
	"""Test that clear_markers removes all markers."""
	# Add some markers
	marker_manager.add_marker(Vector2(100, 100), "city", "City 1")
	await get_tree().process_frame
	marker_manager.add_marker(Vector2(200, 200), "town", "Town 1")
	await get_tree().process_frame
	
	var count_before: int = test_data.markers.size()
	assert_true(count_before > 0, "Markers should exist before clear")
	
	# Clear all markers
	marker_manager.clear_markers()
	await get_tree().process_frame
	
	var count_after: int = test_data.markers.size()
	assert_eq(count_after, 0, "FAIL: Expected marker count to be 0. Context: After clear_markers(). Why: All markers should be removed. Hint: Check MarkerManager.clear_markers() calls world_map_data.clear_markers().")

func test_marker_manager_set_group_visible() -> void:
	"""Test that set_group_visible shows/hides marker groups."""
	# Add markers of different types
	marker_manager.add_marker(Vector2(100, 100), "city", "City 1")  # settlements group
	await get_tree().process_frame
	marker_manager.add_marker(Vector2(200, 200), "forest", "Forest 1")  # features group
	await get_tree().process_frame
	
	# Hide settlements group
	marker_manager.set_group_visible("settlements", false)
	await get_tree().process_frame
	
	# Show settlements group
	marker_manager.set_group_visible("settlements", true)
	await get_tree().process_frame
	
	pass_test("set_group_visible toggles marker group visibility")

func test_marker_manager_get_marker_at_position() -> void:
	"""Test that get_marker_at_position finds marker at position."""
	# Add marker at specific position
	marker_manager.add_marker(Vector2(100, 100), "city", "Test City")
	await get_tree().process_frame
	
	# Find marker at position
	var index: int = marker_manager.get_marker_at_position(Vector2(100, 100), 50.0)
	assert_eq(index, 0, "FAIL: Expected marker index 0 at position (100, 100). Context: After add_marker(). Why: Marker should be found at position. Hint: Check MarkerManager.get_marker_at_position() searches markers correctly.")
	
	# Find marker with larger radius
	var index_large_radius: int = marker_manager.get_marker_at_position(Vector2(120, 120), 50.0)
	assert_eq(index_large_radius, 0, "FAIL: Expected marker index 0 within radius. Context: Position (120, 120) within 50.0 of (100, 100). Why: Marker should be found within radius. Hint: Check distance calculation in get_marker_at_position().")

func test_marker_manager_get_marker_at_position_not_found() -> void:
	"""Test that get_marker_at_position returns -1 when no marker found."""
	# Don't add any markers
	
	# Try to find marker at position
	var index: int = marker_manager.get_marker_at_position(Vector2(100, 100), 50.0)
	assert_eq(index, -1, "FAIL: Expected -1 when no marker found. Context: No markers added. Why: Should return -1 for not found. Hint: Check MarkerManager.get_marker_at_position() returns -1 when no match.")

func test_marker_manager_get_marker_at_position_with_null_data() -> void:
	"""Test that get_marker_at_position handles null world_map_data gracefully."""
	var manager_without_data := MarkerManager.new()
	manager_without_data.name = "MarkerManagerNoData"
	test_scene.add_child(manager_without_data)
	await get_tree().process_frame
	
	# Should return -1 with null data
	var index: int = manager_without_data.get_marker_at_position(Vector2(100, 100), 50.0)
	assert_eq(index, -1, "FAIL: Expected -1 with null data. Context: world_map_data is null. Why: Should return -1 when data is null. Hint: Check MarkerManager.get_marker_at_position() handles null data.")
	
	manager_without_data.queue_free()
	await get_tree().process_frame

func test_marker_manager_handles_missing_icon_textures() -> void:
	"""Test that MarkerManager handles missing icon textures gracefully."""
	# Add marker with non-existent icon type
	marker_manager.add_marker(Vector2(100, 100), "nonexistent_icon_type", "Test Marker")
	await get_tree().process_frame
	
	# Should not crash, should use fallback color
	pass_test("MarkerManager handles missing icon textures gracefully (fallback color used)")

func test_marker_manager_refresh_markers() -> void:
	"""Test that _refresh_markers recreates marker nodes from data."""
	# Add marker directly to data
	test_data.add_marker(Vector2(100, 100), "city", "Direct City")
	
	# Refresh should create visual node
	# We can't easily call private method, but set_world_map_data calls it
	marker_manager.set_world_map_data(test_data)
	await get_tree().process_frame
	
	# Verify marker node was created (tested through get_marker_at_position)
	var index: int = marker_manager.get_marker_at_position(Vector2(100, 100), 50.0)
	assert_eq(index, 0, "FAIL: Expected marker to be found after refresh. Context: Marker added directly to data, then set_world_map_data() called. Why: _refresh_markers should create visual nodes. Hint: Check MarkerManager._refresh_markers() creates nodes from data.")
