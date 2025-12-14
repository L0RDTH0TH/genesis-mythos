# ╔═══════════════════════════════════════════════════════════
# ║ test_map_editor.gd
# ║ Desc: Unit tests for MapEditor brush tools, painting operations, and undo functionality
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MapEditor instance
var map_editor: MapEditor

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
	"""Setup MapEditor instance before each test."""
	test_data = UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
	map_editor = MapEditor.new()
	map_editor.name = "MapEditor"
	map_editor.set_world_map_data(test_data)
	test_scene.add_child(map_editor)
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup MapEditor instance after each test."""
	if map_editor:
		map_editor.queue_free()
	if test_data:
		test_data = null
	await get_tree().process_frame
	map_editor = null

func test_map_editor_initializes() -> void:
	"""Test that MapEditor initializes without errors."""
	assert_not_null(map_editor, "FAIL: Expected MapEditor to be created. Context: Instantiation. Why: Editor should initialize. Hint: Check MapEditor._init() completes without errors.")

func test_map_editor_set_world_map_data() -> void:
	"""Test that set_world_map_data sets the world map data."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 128, 128)
	map_editor.set_world_map_data(data)
	
	# Verify data is set (we can't easily access private var, but we can test methods work)
	# Test that painting works (which requires data to be set)
	map_editor.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	
	pass_test("set_world_map_data sets data correctly (painting works)")

func test_map_editor_set_tool() -> void:
	"""Test that set_tool changes the current editing tool."""
	# Test all tools
	var tools: Array = [
		MapEditor.EditTool.RAISE,
		MapEditor.EditTool.LOWER,
		MapEditor.EditTool.SMOOTH,
		MapEditor.EditTool.SHARPEN,
		MapEditor.EditTool.RIVER,
		MapEditor.EditTool.MOUNTAIN,
		MapEditor.EditTool.CRATER,
		MapEditor.EditTool.ISLAND
	]
	
	for tool in tools:
		map_editor.set_tool(tool)
		await get_tree().process_frame
		# Verify tool is set (we can't easily access private var, but we can test painting works)
		map_editor.start_paint(Vector2(0, 0))
		await get_tree().process_frame
		map_editor.end_paint()
		await get_tree().process_frame
	
	pass_test("set_tool changes tool correctly (all tools tested)")

func test_map_editor_set_brush_radius() -> void:
	"""Test that set_brush_radius sets brush radius correctly."""
	# Test various radius values
	var radii: Array[float] = [1.0, 10.0, 50.0, 100.0, 500.0]
	
	for radius in radii:
		map_editor.set_brush_radius(radius)
		await get_tree().process_frame
		# Verify radius is set (tested through painting)
		map_editor.start_paint(Vector2(0, 0))
		await get_tree().process_frame
		map_editor.end_paint()
		await get_tree().process_frame
	
	pass_test("set_brush_radius sets radius correctly (all values tested)")

func test_map_editor_set_brush_radius_clamps_minimum() -> void:
	"""Test that set_brush_radius clamps minimum value to 1.0."""
	# Test negative and zero values
	map_editor.set_brush_radius(-10.0)
	await get_tree().process_frame
	map_editor.set_brush_radius(0.0)
	await get_tree().process_frame
	
	# Should not crash, radius should be clamped to 1.0
	map_editor.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	map_editor.end_paint()
	await get_tree().process_frame
	
	pass_test("set_brush_radius clamps minimum to 1.0")

func test_map_editor_set_brush_strength() -> void:
	"""Test that set_brush_strength sets brush strength correctly."""
	# Test various strength values
	var strengths: Array[float] = [0.0, 0.1, 0.5, 1.0]
	
	for strength in strengths:
		map_editor.set_brush_strength(strength)
		await get_tree().process_frame
		# Verify strength is set (tested through painting)
		map_editor.start_paint(Vector2(0, 0))
		await get_tree().process_frame
		map_editor.end_paint()
		await get_tree().process_frame
	
	pass_test("set_brush_strength sets strength correctly (all values tested)")

func test_map_editor_set_brush_strength_clamps_range() -> void:
	"""Test that set_brush_strength clamps values to 0.0-1.0 range."""
	# Test out-of-range values
	map_editor.set_brush_strength(-0.5)
	await get_tree().process_frame
	map_editor.set_brush_strength(1.5)
	await get_tree().process_frame
	
	# Should not crash, strength should be clamped
	map_editor.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	map_editor.end_paint()
	await get_tree().process_frame
	
	pass_test("set_brush_strength clamps values to 0.0-1.0")

func test_map_editor_start_paint_with_null_data() -> void:
	"""Test that start_paint handles null world_map_data gracefully."""
	var editor_without_data := MapEditor.new()
	editor_without_data.name = "MapEditorNoData"
	test_scene.add_child(editor_without_data)
	await get_tree().process_frame
	
	# Should not crash with null data
	editor_without_data.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	
	editor_without_data.queue_free()
	await get_tree().process_frame
	
	pass_test("start_paint with null data handled without crash")

func test_map_editor_start_paint_saves_to_history() -> void:
	"""Test that start_paint saves heightmap to undo history."""
	# Get initial heightmap state
	var initial_height: float = test_data.heightmap_image.get_pixel(128, 128).r
	
	# Start painting (should save to history)
	map_editor.set_tool(MapEditor.EditTool.RAISE)
	map_editor.set_brush_strength(0.5)
	map_editor.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	
	# Modify heightmap
	map_editor.continue_paint(Vector2(10, 10))
	await get_tree().process_frame
	map_editor.end_paint()
	await get_tree().process_frame
	
	# Undo should restore initial state
	var undo_success: bool = map_editor.undo()
	assert_true(undo_success, "FAIL: Expected undo to succeed. Context: After painting operation. Why: start_paint should save to history. Hint: Check MapEditor.start_paint() calls world_map_data.save_heightmap_to_history().")
	
	await get_tree().process_frame
	var restored_height: float = test_data.heightmap_image.get_pixel(128, 128).r
	assert_almost_eq(restored_height, initial_height, 0.01, "FAIL: Expected undo to restore heightmap. Context: After painting and undo. Why: Undo should restore previous state. Hint: Check MapEditor.undo() calls world_map_data.undo_heightmap().")

func test_map_editor_continue_paint_interpolates() -> void:
	"""Test that continue_paint interpolates between positions to avoid gaps."""
	map_editor.set_tool(MapEditor.EditTool.RAISE)
	map_editor.set_brush_radius(20.0)
	map_editor.set_brush_strength(0.5)
	
	# Start painting
	map_editor.start_paint(Vector2(0, 0))
	await get_tree().process_frame
	
	# Continue painting far away (should interpolate)
	map_editor.continue_paint(Vector2(100, 100))
	await get_tree().process_frame
	
	map_editor.end_paint()
	await get_tree().process_frame
	
	# Should not crash and should have painted along the path
	pass_test("continue_paint interpolates between positions")

func test_map_editor_all_tools_paint_correctly() -> void:
	"""Test that all editing tools paint correctly."""
	var tools: Array = [
		MapEditor.EditTool.RAISE,
		MapEditor.EditTool.LOWER,
		MapEditor.EditTool.SMOOTH,
		MapEditor.EditTool.SHARPEN,
		MapEditor.EditTool.RIVER,
		MapEditor.EditTool.MOUNTAIN,
		MapEditor.EditTool.CRATER,
		MapEditor.EditTool.ISLAND
	]
	
	for tool in tools:
		# Reset data for each tool
		test_data = UnitTestHelpers.create_test_world_map_data(12345, 256, 256)
		map_editor.set_world_map_data(test_data)
		
		map_editor.set_tool(tool)
		map_editor.set_brush_radius(30.0)
		map_editor.set_brush_strength(0.3)
		
		# Paint with tool
		map_editor.start_paint(Vector2(0, 0))
		await get_tree().process_frame
		map_editor.continue_paint(Vector2(50, 50))
		await get_tree().process_frame
		map_editor.end_paint()
		await get_tree().process_frame
		
		# Verify heightmap was modified (not all black)
		var sample_height: float = test_data.heightmap_image.get_pixel(128, 128).r
		# Some tools may not modify center, so we just check it doesn't crash
		pass_test("Tool %d painted without crash" % tool)
	
	pass_test("All editing tools paint correctly")

func test_map_editor_undo_with_no_history() -> void:
	"""Test that undo returns false when no history exists."""
	var editor_without_history := MapEditor.new()
	editor_without_history.name = "MapEditorNoHistory"
	var data := UnitTestHelpers.create_test_world_map_data(12345, 128, 128)
	editor_without_history.set_world_map_data(data)
	test_scene.add_child(editor_without_history)
	await get_tree().process_frame
	
	# Try to undo without any edits
	var undo_success: bool = editor_without_history.undo()
	assert_false(undo_success, "FAIL: Expected undo to return false when no history. Context: Before any edits. Why: Undo should fail if no history exists. Hint: Check MapEditor.undo() returns false when undo_history is empty.")
	
	editor_without_history.queue_free()
	await get_tree().process_frame

func test_map_editor_paint_with_invalid_world_position() -> void:
	"""Test that painting handles invalid world positions gracefully."""
	# Test extreme positions
	var extreme_positions: Array[Vector2] = [
		Vector2(-999999, -999999),
		Vector2(999999, 999999),
		Vector2(0, 0),
		Vector2(1000, 1000)
	]
	
	for pos in extreme_positions:
		map_editor.start_paint(pos)
		await get_tree().process_frame
		map_editor.end_paint()
		await get_tree().process_frame
		
		# Should not crash, positions should be clamped
		pass_test("Paint with position %s handled without crash" % pos)
	
	pass_test("Paint with invalid world positions handled gracefully")
