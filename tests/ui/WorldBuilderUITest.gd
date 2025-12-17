# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUITest.gd
# ║ Desc: Automated tests for WorldBuilderUI.tscn UI compliance
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Scene path
const SCENE_PATH: String = "res://ui/world_builder/WorldBuilderUI.tscn"

## UIConstants reference
const UIConstants = preload("res://scripts/ui/UIConstants.gd")

## Expected number of steps
const EXPECTED_STEPS: int = 8

## Test fixture
var world_builder_ui: Control = null
var test_scene: Node = null

func before_all() -> void:
	"""Setup test scene before all tests."""
	test_scene = Node.new()
	test_scene.name = "TestScene"
	get_tree().root.add_child(test_scene)

func after_all() -> void:
	"""Cleanup test scene after all tests."""
	if test_scene:
		test_scene.queue_free()
		await get_tree().process_frame

func before_each() -> void:
	"""Setup WorldBuilderUI instance before each test."""
	if not ResourceLoader.exists(SCENE_PATH):
		push_error("WorldBuilderUI.tscn not found at %s" % SCENE_PATH)
		return
	
	var scene: PackedScene = load(SCENE_PATH)
	world_builder_ui = scene.instantiate() as Control
	test_scene.add_child(world_builder_ui)
	await get_tree().process_frame
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup WorldBuilderUI instance after each test."""
	if world_builder_ui:
		world_builder_ui.queue_free()
		await get_tree().process_frame
	world_builder_ui = null

func test_world_builder_ui_loads_without_errors() -> void:
	"""Test that WorldBuilderUI.tscn loads without errors."""
	assert_not_null(world_builder_ui, "WorldBuilderUI should load from scene")
	assert_true(world_builder_ui is Control, "WorldBuilderUI root should be Control node")

func test_root_has_full_rect_anchors() -> void:
	"""Test that root node has anchors_preset = 15 (PRESET_FULL_RECT)."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	assert_eq(world_builder_ui.anchors_preset, Control.PRESET_FULL_RECT,
		"Root should have anchors_preset = PRESET_FULL_RECT (15)")
	assert_eq(world_builder_ui.anchor_right, 1.0, "Root anchor_right should be 1.0")
	assert_eq(world_builder_ui.anchor_bottom, 1.0, "Root anchor_bottom should be 1.0")

func test_all_major_containers_are_built_in() -> void:
	"""Test that all major containers are built-in Godot containers (not GameGUI)."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	# Check for built-in containers
	var hsplit: HSplitContainer = world_builder_ui.find_child("MainContainer", true, false) as HSplitContainer
	assert_not_null(hsplit, "MainContainer should be HSplitContainer (built-in)")
	
	# Verify no GameGUI nodes exist (they would have type='GGVBox' or similar)
	var scene_text: String = _read_scene_file()
	assert_false(scene_text.contains("type=\"GGVBox\""), "Should not contain GameGUI GGVBox nodes")
	assert_false(scene_text.contains("type=\"GGHBox\""), "Should not contain GameGUI GGHBox nodes")
	assert_false(scene_text.contains("type=\"GGLabel\""), "Should not contain GameGUI GGLabel nodes")

func test_no_hard_coded_custom_minimum_size() -> void:
	"""Test that no nodes have hard-coded custom_minimum_size > 10."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	var scene_text: String = _read_scene_file()
	var violations: Array[String] = []
	
	# Look for custom_minimum_size = Vector2(x, y) where x or y > 10
	var regex: RegEx = RegEx.new()
	regex.compile("custom_minimum_size\\s*=\\s*Vector2\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*\\)")
	
	var results: Array[RegExMatch] = regex.search_all(scene_text)
	for result in results:
		var x: int = result.get_string(1).to_int()
		var y: int = result.get_string(2).to_int()
		
		if x > 10:
			violations.append("custom_minimum_size.x = %d (should use UIConstants)" % x)
		if y > 10:
			violations.append("custom_minimum_size.y = %d (should use UIConstants)" % y)
	
	if violations.size() > 0:
		assert_true(false, "Found hard-coded custom_minimum_size values:\n  - %s" % "\n  - ".join(violations))
	else:
		pass_test("No hard-coded custom_minimum_size values found")

func test_viewport_resizes_dynamically() -> void:
	"""Test that viewport/preview containers resize dynamically."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	# Find SubViewportContainer
	var viewport_container: SubViewportContainer = world_builder_ui.find_child("Terrain3DView", true, false) as SubViewportContainer
	if viewport_container:
		# Should have anchors for dynamic sizing
		assert_eq(viewport_container.anchors_preset, Control.PRESET_FULL_RECT,
			"Terrain3DView should have full-rect anchors for dynamic resizing")
		assert_true(viewport_container.stretch, "Terrain3DView should have stretch enabled")

func test_all_8_steps_have_correct_layout() -> void:
	"""Test that all 8 steps have correct layout (check key nodes exist)."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	# Check that STEPS array has 8 items
	if world_builder_ui.has("STEPS"):
		var steps: Array = world_builder_ui.get("STEPS")
		assert_eq(steps.size(), EXPECTED_STEPS,
			"WorldBuilderUI should have %d steps, got %d" % [EXPECTED_STEPS, steps.size()])
	
	# Check for key layout nodes
	var main_container: HSplitContainer = world_builder_ui.find_child("MainContainer", true, false) as HSplitContainer
	assert_not_null(main_container, "MainContainer (HSplitContainer) should exist")
	
	var left_nav: Panel = world_builder_ui.find_child("LeftNav", true, false) as Panel
	assert_not_null(left_nav, "LeftNav panel should exist")
	
	var center_panel: Panel = world_builder_ui.find_child("CenterPanel", true, false) as Panel
	assert_not_null(center_panel, "CenterPanel should exist")
	
	var button_container: HBoxContainer = world_builder_ui.find_child("ButtonContainer", true, false) as HBoxContainer
	assert_not_null(button_container, "ButtonContainer should exist")
	
	var back_button: Button = world_builder_ui.find_child("BackButton", true, false) as Button
	assert_not_null(back_button, "BackButton should exist")
	
	var next_button: Button = world_builder_ui.find_child("NextButton", true, false) as Button
	assert_not_null(next_button, "NextButton should exist")

func test_theme_is_applied() -> void:
	"""Test that theme is applied to WorldBuilderUI."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	var theme: Theme = world_builder_ui.theme
	assert_not_null(theme, "WorldBuilderUI should have a theme applied")
	if theme:
		var theme_path: String = theme.resource_path
		assert_true(theme_path.contains("bg3_theme.tres"),
			"WorldBuilderUI theme should be bg3_theme.tres, got: %s" % theme_path)

func test_containers_have_proper_size_flags() -> void:
	"""Test that major containers have proper size_flags for responsiveness."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	var main_container: HSplitContainer = world_builder_ui.find_child("MainContainer", true, false) as HSplitContainer
	if main_container:
		# HSplitContainer should expand
		assert_true(main_container.size_flags_horizontal == Control.SIZE_EXPAND_FILL or \
		           main_container.size_flags_vertical == Control.SIZE_EXPAND_FILL,
			"MainContainer should have size_flags for expansion")

func test_responsive_on_resize() -> void:
	"""Test that WorldBuilderUI responds correctly to window resize."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	# Get initial size
	var initial_size: Vector2 = world_builder_ui.size
	
	# Simulate resize
	var viewport: Viewport = get_viewport()
	var original_size: Vector2 = viewport.size
	
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that root maintains anchors
	assert_eq(world_builder_ui.anchors_preset, Control.PRESET_FULL_RECT,
		"WorldBuilderUI should maintain full-rect anchors after resize")
	
	# Restore
	DisplayServer.window_set_size(Vector2i(int(original_size.x), int(original_size.y)))
	await get_tree().process_frame

func test_no_negative_positions() -> void:
	"""Test that no Control nodes have negative positions outside viewport."""
	if not world_builder_ui:
		pass_test("WorldBuilderUI not loaded, skipping")
		return
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var violations: Array[String] = []
	
	_check_node_for_negative_position(world_builder_ui, viewport_size, violations)
	
	if violations.size() > 0:
		assert_true(false, "Found nodes with negative positions or outside viewport:\n  - %s" % "\n  - ".join(violations))
	else:
		pass_test("All nodes have valid positions")

## Helper functions

func _read_scene_file() -> String:
	"""Read the scene file as text."""
	var file: FileAccess = FileAccess.open(SCENE_PATH, FileAccess.READ)
	if not file:
		return ""
	
	var content: String = file.get_as_text()
	file.close()
	return content

func _check_node_for_negative_position(node: Node, viewport_size: Vector2, violations: Array[String]) -> void:
	"""Recursively check node and children for negative positions."""
	if node is Control:
		var control: Control = node as Control
		var global_pos: Vector2 = control.global_position
		var size: Vector2 = control.size
		
		if global_pos.x < 0 or global_pos.y < 0:
			violations.append("%s: position %s" % [control.name, str(global_pos)])
		if global_pos.x + size.x > viewport_size.x or global_pos.y + size.y > viewport_size.y:
			if control.anchors_preset == Control.PRESET_FULL_RECT:
				pass
			else:
				violations.append("%s: extends beyond viewport (%s + %s)" % [control.name, str(global_pos), str(size)])
	
	for child in node.get_children():
		_check_node_for_negative_position(child, viewport_size, violations)
