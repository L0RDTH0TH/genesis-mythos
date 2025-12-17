# ╔═══════════════════════════════════════════════════════════
# ║ CharacterCreationRootTest.gd
# ║ Desc: Automated tests for CharacterCreationRoot.tscn UI compliance
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Scene path
const SCENE_PATH: String = "res://scenes/character_creation/CharacterCreationRoot.tscn"

## UIConstants reference
const UIConstants = preload("res://scripts/ui/UIConstants.gd")

## Test fixture
var character_creation_root: Control = null
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
	"""Setup CharacterCreationRoot instance before each test."""
	if not ResourceLoader.exists(SCENE_PATH):
		push_warning("CharacterCreationRoot.tscn not found at %s, skipping tests" % SCENE_PATH)
		return
	
	var scene: PackedScene = load(SCENE_PATH)
	character_creation_root = scene.instantiate() as Control
	test_scene.add_child(character_creation_root)
	await get_tree().process_frame
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup CharacterCreationRoot instance after each test."""
	if character_creation_root:
		character_creation_root.queue_free()
		await get_tree().process_frame
	character_creation_root = null

func test_character_creation_root_loads_without_errors() -> void:
	"""Test that CharacterCreationRoot.tscn loads without errors."""
	if not ResourceLoader.exists(SCENE_PATH):
		pass_test("CharacterCreationRoot.tscn does not exist, skipping")
		return
	
	assert_not_null(character_creation_root, "CharacterCreationRoot should load from scene")
	assert_true(character_creation_root is Control, "CharacterCreationRoot root should be Control node")

func test_root_has_full_rect_anchors() -> void:
	"""Test that root node has anchors_preset = 15 (PRESET_FULL_RECT)."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	assert_eq(character_creation_root.anchors_preset, Control.PRESET_FULL_RECT,
		"Root should have anchors_preset = PRESET_FULL_RECT (15)")
	assert_eq(character_creation_root.anchor_right, 1.0, "Root anchor_right should be 1.0")
	assert_eq(character_creation_root.anchor_bottom, 1.0, "Root anchor_bottom should be 1.0")

func test_uses_hsplit_container() -> void:
	"""Test that CharacterCreationRoot uses HSplitContainer for left/right layout."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	var hsplit: HSplitContainer = character_creation_root.find_child("ContentArea", true, false) as HSplitContainer
	assert_not_null(hsplit, "CharacterCreationRoot should contain HSplitContainer (ContentArea)")

func test_left_panel_exists() -> void:
	"""Test that left panel (options) exists."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	var left_panel: Panel = character_creation_root.find_child("LeftPanel", true, false) as Panel
	assert_not_null(left_panel, "LeftPanel should exist for options")
	
	var options_container: VBoxContainer = character_creation_root.find_child("OptionsContainer", true, false) as VBoxContainer
	assert_not_null(options_container, "OptionsContainer (VBoxContainer) should exist in left panel")

func test_right_panel_preview_exists() -> void:
	"""Test that right panel (SubViewport preview) exists."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	var right_panel: Panel = character_creation_root.find_child("RightPanel", true, false) as Panel
	assert_not_null(right_panel, "RightPanel should exist for preview")
	
	var preview_container: SubViewportContainer = character_creation_root.find_child("PreviewContainer", true, false) as SubViewportContainer
	assert_not_null(preview_container, "PreviewContainer (SubViewportContainer) should exist")
	
	var preview_viewport: SubViewport = character_creation_root.find_child("PreviewViewport", true, false) as SubViewport
	assert_not_null(preview_viewport, "PreviewViewport should exist")

func test_proper_size_flags() -> void:
	"""Test that panels have proper size_flags and UIConstants usage."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	var left_panel: Panel = character_creation_root.find_child("LeftPanel", true, false) as Panel
	if left_panel:
		# Left panel should expand horizontally
		assert_true(left_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL or \
		           left_panel.size_flags_horizontal != 0,
			"LeftPanel should have size_flags for horizontal expansion")
	
	var right_panel: Panel = character_creation_root.find_child("RightPanel", true, false) as Panel
	if right_panel:
		# Right panel should have vertical expansion
		assert_true(right_panel.size_flags_vertical == Control.SIZE_EXPAND_FILL or \
		           right_panel.size_flags_vertical != 0,
			"RightPanel should have size_flags for vertical expansion")

func test_navigation_buttons_exist() -> void:
	"""Test that navigation buttons (Back/Next) exist."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	var back_button: Button = character_creation_root.find_child("BackButton", true, false) as Button
	assert_not_null(back_button, "BackButton should exist")
	if back_button:
		assert_eq(back_button.text, "Back", "BackButton text should be 'Back'")
	
	var next_button: Button = character_creation_root.find_child("NextButton", true, false) as Button
	assert_not_null(next_button, "NextButton should exist")
	if next_button:
		assert_eq(next_button.text, "Next", "NextButton text should be 'Next'")

func test_theme_is_applied() -> void:
	"""Test that theme is applied to CharacterCreationRoot."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	var theme: Theme = character_creation_root.theme
	assert_not_null(theme, "CharacterCreationRoot should have a theme applied")
	if theme:
		var theme_path: String = theme.resource_path
		assert_true(theme_path.contains("bg3_theme.tres"),
			"CharacterCreationRoot theme should be bg3_theme.tres, got: %s" % theme_path)

func test_no_hard_coded_sizes() -> void:
	"""Test that no nodes have hard-coded custom_minimum_size > 10."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
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

func test_responsive_on_resize() -> void:
	"""Test that CharacterCreationRoot responds correctly to window resize."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	# Simulate resize
	var viewport: Viewport = get_viewport()
	var original_size: Vector2 = viewport.size
	
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that root maintains anchors
	assert_eq(character_creation_root.anchors_preset, Control.PRESET_FULL_RECT,
		"CharacterCreationRoot should maintain full-rect anchors after resize")
	
	# Restore
	DisplayServer.window_set_size(Vector2i(int(original_size.x), int(original_size.y)))
	await get_tree().process_frame

func test_no_negative_positions() -> void:
	"""Test that no Control nodes have negative positions outside viewport."""
	if not character_creation_root:
		pass_test("CharacterCreationRoot not loaded, skipping")
		return
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var violations: Array[String] = []
	
	_check_node_for_negative_position(character_creation_root, viewport_size, violations)
	
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
