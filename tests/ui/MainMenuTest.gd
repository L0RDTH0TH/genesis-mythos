# ╔═══════════════════════════════════════════════════════════
# ║ MainMenuTest.gd
# ║ Desc: Automated tests for MainMenu.tscn UI compliance
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Scene path
const SCENE_PATH: String = "res://scenes/MainMenu.tscn"

## UIConstants reference
const UIConstants = preload("res://scripts/ui/UIConstants.gd")

## Test fixture
var main_menu: Control = null
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
	"""Setup MainMenu instance before each test."""
	if not ResourceLoader.exists(SCENE_PATH):
		push_error("MainMenu.tscn not found at %s" % SCENE_PATH)
		return
	
	var scene: PackedScene = load(SCENE_PATH)
	main_menu = scene.instantiate() as Control
	test_scene.add_child(main_menu)
	await get_tree().process_frame
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup MainMenu instance after each test."""
	if main_menu:
		main_menu.queue_free()
		await get_tree().process_frame
	main_menu = null

func test_main_menu_loads_without_errors() -> void:
	"""Test that MainMenu.tscn loads without errors."""
	assert_not_null(main_menu, "MainMenu should load from scene")
	assert_true(main_menu is Control, "MainMenu root should be Control node")

func test_root_has_full_rect_anchors() -> void:
	"""Test that root node has anchors_preset = 15 (PRESET_FULL_RECT)."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	assert_eq(main_menu.anchors_preset, Control.PRESET_FULL_RECT, 
		"Root should have anchors_preset = PRESET_FULL_RECT (15)")
	
	# Also verify anchor values
	assert_eq(main_menu.anchor_right, 1.0, "Root anchor_right should be 1.0")
	assert_eq(main_menu.anchor_bottom, 1.0, "Root anchor_bottom should be 1.0")

func test_contains_vbox_container() -> void:
	"""Test that MainMenu contains VBoxContainer for layout."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var vbox: VBoxContainer = main_menu.find_child("VBoxContainer", true, false) as VBoxContainer
	assert_not_null(vbox, "MainMenu should contain VBoxContainer")

func test_contains_title_label() -> void:
	"""Test that MainMenu contains TitleLabel."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var title: Label = main_menu.find_child("TitleLabel", true, false) as Label
	assert_not_null(title, "MainMenu should contain TitleLabel")
	if title:
		assert_eq(title.text, "Main Menu", "TitleLabel text should be 'Main Menu'")

func test_contains_character_creation_button() -> void:
	"""Test that MainMenu contains CharacterCreationButton."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var button: Button = main_menu.find_child("CharacterCreationButton", true, false) as Button
	assert_not_null(button, "MainMenu should contain CharacterCreationButton")
	if button:
		assert_eq(button.text, "Create Character", "CharacterCreationButton text should be 'Create Character'")

func test_contains_world_creation_button() -> void:
	"""Test that MainMenu contains WorldCreationButton."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var button: Button = main_menu.find_child("WorldCreationButton", true, false) as Button
	assert_not_null(button, "MainMenu should contain WorldCreationButton")
	if button:
		assert_eq(button.text, "Create World", "WorldCreationButton text should be 'Create World'")

func test_buttons_use_ui_constants() -> void:
	"""Test that buttons use UIConstants for sizing (or have proper size_flags)."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var char_button: Button = main_menu.find_child("CharacterCreationButton", true, false) as Button
	var world_button: Button = main_menu.find_child("WorldCreationButton", true, false) as Button
	
	if char_button:
		# Check that button has size_flags set (indicates responsive design)
		assert_true(char_button.size_flags_horizontal != 0 or char_button.size_flags_vertical != 0,
			"CharacterCreationButton should have size_flags set for responsiveness")
	
	if world_button:
		# Check that button has size_flags set
		assert_true(world_button.size_flags_horizontal != 0 or world_button.size_flags_vertical != 0,
			"WorldCreationButton should have size_flags set for responsiveness")

func test_all_elements_have_proper_size_flags() -> void:
	"""Test that all major UI elements have proper size_flags."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var vbox: VBoxContainer = main_menu.find_child("VBoxContainer", true, false) as VBoxContainer
	if vbox:
		# VBoxContainer should have size_flags for expansion
		assert_true(vbox.size_flags_horizontal == Control.SIZE_EXPAND_FILL or \
		           vbox.size_flags_vertical == Control.SIZE_EXPAND_FILL,
			"VBoxContainer should have size_flags set for expansion")

func test_theme_is_applied() -> void:
	"""Test that theme is applied to MainMenu."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var theme: Theme = main_menu.theme
	assert_not_null(theme, "MainMenu should have a theme applied")
	if theme:
		var theme_path: String = theme.resource_path
		assert_true(theme_path.contains("bg3_theme.tres"), 
			"MainMenu theme should be bg3_theme.tres, got: %s" % theme_path)

func test_responsive_on_resize() -> void:
	"""Test that MainMenu responds correctly to window resize."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	# Get initial size
	var initial_size: Vector2 = main_menu.size
	
	# Simulate resize by changing viewport size
	var viewport: Viewport = get_viewport()
	var original_size: Vector2 = viewport.size
	
	# Set new size
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that root still has proper anchors
	assert_eq(main_menu.anchors_preset, Control.PRESET_FULL_RECT,
		"MainMenu should maintain full-rect anchors after resize")
	
	# Restore original size
	DisplayServer.window_set_size(Vector2i(int(original_size.x), int(original_size.y)))
	await get_tree().process_frame

func test_no_negative_positions() -> void:
	"""Test that no Control nodes have negative positions outside viewport."""
	if not main_menu:
		pass_test("MainMenu not loaded, skipping")
		return
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var violations: Array[String] = []
	
	_check_node_for_negative_position(main_menu, viewport_size, violations)
	
	if violations.size() > 0:
		assert_true(false, "Found nodes with negative positions or outside viewport:\n  - %s" % "\n  - ".join(violations))
	else:
		pass_test("All nodes have valid positions")

func _check_node_for_negative_position(node: Node, viewport_size: Vector2, violations: Array[String]) -> void:
	"""Recursively check node and children for negative positions."""
	if node is Control:
		var control: Control = node as Control
		var global_pos: Vector2 = control.global_position
		var size: Vector2 = control.size
		
		# Check if position is negative or outside viewport
		if global_pos.x < 0 or global_pos.y < 0:
			violations.append("%s: position %s" % [control.name, str(global_pos)])
		if global_pos.x + size.x > viewport_size.x or global_pos.y + size.y > viewport_size.y:
			# Allow if using anchors (which is fine)
			if control.anchors_preset == Control.PRESET_FULL_RECT:
				pass  # Full rect is fine
			else:
				violations.append("%s: extends beyond viewport (%s + %s)" % [control.name, str(global_pos), str(size)])
	
	# Check children
	for child in node.get_children():
		_check_node_for_negative_position(child, viewport_size, violations)
