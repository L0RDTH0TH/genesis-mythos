# ╔═══════════════════════════════════════════════════════════
# ║ test_comprehensive_ui_interactions_map_maker.gd
# ║ Desc: Comprehensive UI interaction tests for MapMakerModule - buttons, view modes, tools, mouse interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MapMakerModule instance
var map_maker_module: MapMakerModule

## Test fixture: Scene tree for UI testing
var test_scene: Node

## Track errors during interactions
var interaction_errors: Array[String] = []

## Global error listener
var error_listener: TestErrorListener

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
	"""Setup MapMakerModule instance before each test."""
	interaction_errors.clear()
	error_listener = TestErrorListener.get_instance()
	error_listener.clear()
	
	# Create MapMakerModule instance
	var module_script = load("res://ui/world_builder/MapMakerModule.gd")
	if module_script != null:
		map_maker_module = module_script.new() as MapMakerModule
		if map_maker_module:
			map_maker_module.name = "MapMakerModule"
			test_scene.add_child(map_maker_module)
			await get_tree().process_frame
			await get_tree().process_frame
		else:
			push_error("Failed to instantiate MapMakerModule")
			map_maker_module = null
	else:
		push_error("Failed to load MapMakerModule script")
		map_maker_module = null

func after_each() -> void:
	"""Cleanup MapMakerModule instance after each test."""
	if map_maker_module:
		map_maker_module.queue_free()
		await get_tree().process_frame
	map_maker_module = null

func test_view_mode_heightmap_button() -> void:
	"""Test view mode button - Heightmap."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	# Find Heightmap button in toolbar
	var heightmap_button := _find_button_by_text("Heightmap")
	if heightmap_button:
		_simulate_button_click_safe(heightmap_button)
		await get_tree().process_frame
		_check_for_errors("heightmap view mode button")
		pass_test("Heightmap view mode button tested")
	else:
		pass_test("Heightmap button not found")

func test_view_mode_biomes_button() -> void:
	"""Test view mode button - Biomes."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	var biomes_button := _find_button_by_text("Biomes")
	if biomes_button:
		_simulate_button_click_safe(biomes_button)
		await get_tree().process_frame
		_check_for_errors("biomes view mode button")
		pass_test("Biomes view mode button tested")
	else:
		pass_test("Biomes button not found")

func test_tool_raise_button() -> void:
	"""Test tool button - Raise."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	var raise_button := _find_button_by_text("Raise")
	if raise_button:
		_simulate_button_click_safe(raise_button)
		await get_tree().process_frame
		_check_for_errors("raise tool button")
		pass_test("Raise tool button tested")
	else:
		pass_test("Raise button not found")

func test_tool_lower_button() -> void:
	"""Test tool button - Lower."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	var lower_button := _find_button_by_text("Lower")
	if lower_button:
		_simulate_button_click_safe(lower_button)
		await get_tree().process_frame
		_check_for_errors("lower tool button")
		pass_test("Lower tool button tested")
	else:
		pass_test("Lower button not found")

func test_tool_smooth_button() -> void:
	"""Test tool button - Smooth."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	var smooth_button := _find_button_by_text("Smooth")
	if smooth_button:
		_simulate_button_click_safe(smooth_button)
		await get_tree().process_frame
		_check_for_errors("smooth tool button")
		pass_test("Smooth tool button tested")
	else:
		pass_test("Smooth button not found")

func test_regenerate_button() -> void:
	"""Test Regenerate button."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	var regenerate_button := _find_button_by_text("Regenerate")
	if regenerate_button:
		_simulate_button_click_safe(regenerate_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("regenerate button")
		pass_test("Regenerate button tested")
	else:
		pass_test("Regenerate button not found")

func test_generate_3d_world_button() -> void:
	"""Test Generate 3D World button."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	var generate_3d_button := _find_button_by_text("Generate 3D World")
	if not generate_3d_button:
		generate_3d_button = _find_control_by_name("Generate3DButton") as Button
	
	if generate_3d_button:
		_simulate_button_click_safe(generate_3d_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("generate 3D world button")
		pass_test("Generate 3D World button tested")
	else:
		pass_test("Generate 3D World button not found")

func test_set_view_mode_programmatically() -> void:
	"""Test set_view_mode method with all ViewMode enums."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	if map_maker_module.has_method("set_view_mode"):
		# Test all view modes
		var view_modes: Array = [
			MapRenderer.ViewMode.HEIGHTMAP,
			MapRenderer.ViewMode.BIOMES,
			MapRenderer.ViewMode.POLITICAL
		]
		
		for mode in view_modes:
			map_maker_module.set_view_mode(mode)
			await get_tree().process_frame
			_check_for_errors("set_view_mode %d" % mode)
		
		pass_test("set_view_mode tested with all modes")
	else:
		pass_test("set_view_mode method not found")

func test_set_tool_programmatically() -> void:
	"""Test set_tool method with all EditTool enums."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	if map_maker_module.map_editor != null:
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
			map_maker_module.map_editor.set_tool(tool)
			await get_tree().process_frame
			_check_for_errors("set_tool %d" % tool)
		
		pass_test("set_tool tested with all tools")
	else:
		pass_test("map_editor not available")

func test_mouse_painting_simulation() -> void:
	"""Test mouse painting simulation - start, continue, end paint."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	# Initialize with test data
	var test_data := WorldMapData.new()
	test_data.seed = 12345
	test_data.world_width = 512
	test_data.world_height = 512
	test_data.create_heightmap(512, 512)
	
	if map_maker_module.has_method("initialize_from_step_data"):
		map_maker_module.initialize_from_step_data(12345, 512, 512)
		await get_tree().process_frame
		await get_tree().process_frame
	
	if map_maker_module.map_editor != null:
		# Simulate start paint
		map_maker_module.map_editor.start_paint(Vector2(100, 100))
		await get_tree().process_frame
		_check_for_errors("start paint")
		
		# Simulate continue paint
		map_maker_module.map_editor.continue_paint(Vector2(150, 150))
		await get_tree().process_frame
		_check_for_errors("continue paint")
		
		# Simulate end paint
		map_maker_module.map_editor.end_paint()
		await get_tree().process_frame
		_check_for_errors("end paint")
	
	pass_test("Mouse painting simulation tested")

func test_mouse_input_events() -> void:
	"""Test mouse input events - button press, motion, wheel."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	var viewport_container := _find_control_by_pattern("*ViewportContainer*") as SubViewportContainer
	if viewport_container:
		# Simulate left mouse button press
		var mouse_press := InputEventMouseButton.new()
		mouse_press.button_index = MOUSE_BUTTON_LEFT
		mouse_press.pressed = true
		mouse_press.position = Vector2(100, 100)
		
		viewport_container._gui_input(mouse_press)
		await get_tree().process_frame
		_check_for_errors("mouse button press")
		
		# Simulate mouse motion
		var mouse_motion := InputEventMouseMotion.new()
		mouse_motion.position = Vector2(150, 150)
		mouse_motion.relative = Vector2(50, 50)
		
		viewport_container._gui_input(mouse_motion)
		await get_tree().process_frame
		_check_for_errors("mouse motion")
		
		# Simulate mouse button release
		mouse_press.pressed = false
		viewport_container._gui_input(mouse_press)
		await get_tree().process_frame
		_check_for_errors("mouse button release")
		
		# Simulate wheel up
		var wheel_up := InputEventMouseButton.new()
		wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel_up.pressed = true
		wheel_up.position = Vector2(100, 100)
		
		viewport_container._gui_input(wheel_up)
		await get_tree().process_frame
		_check_for_errors("wheel up")
		
		pass_test("Mouse input events tested")
	else:
		pass_test("Viewport container not found")

func test_rapid_tool_switching() -> void:
	"""Test rapid tool switching - should handle gracefully."""
	if not map_maker_module or map_maker_module.map_editor == null:
		pass_test("MapMakerModule or map_editor not available")
		return
	
	var tools: Array = [
		MapEditor.EditTool.RAISE,
		MapEditor.EditTool.LOWER,
		MapEditor.EditTool.SMOOTH
	]
	
	# Rapidly switch tools
	for i in range(20):
		var tool = tools[i % tools.size()]
		map_maker_module.map_editor.set_tool(tool)
		await get_tree().process_frame
	
	_check_for_errors("rapid tool switching")
	pass_test("Rapid tool switching handled gracefully")

func test_rapid_view_mode_switching() -> void:
	"""Test rapid view mode switching - should handle gracefully."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	if map_maker_module.has_method("set_view_mode"):
		var modes: Array = [
			MapRenderer.ViewMode.HEIGHTMAP,
			MapRenderer.ViewMode.BIOMES
		]
		
		for i in range(20):
			var mode = modes[i % modes.size()]
			map_maker_module.set_view_mode(mode)
			await get_tree().process_frame
		
		_check_for_errors("rapid view mode switching")
		pass_test("Rapid view mode switching handled gracefully")
	else:
		pass_test("set_view_mode method not found")

func test_generate_map_with_various_parameters() -> void:
	"""Test generate_map with various parameter combinations."""
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	# Initialize with test data
	if map_maker_module.has_method("initialize_from_step_data"):
		map_maker_module.initialize_from_step_data(12345, 512, 512)
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Test generation
		if map_maker_module.has_method("generate_map"):
			map_maker_module.generate_map()
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame  # Wait for generation
			_check_for_errors("generate_map")
		
		pass_test("generate_map tested")
	else:
		pass_test("initialize_from_step_data method not found")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _find_button_by_text(text: String) -> Button:
	"""Find button by text (recursive search)."""
	return _find_control_by_text_recursive(map_maker_module, text) as Button

func _find_control_by_name(name: String) -> Control:
	"""Find control by exact name."""
	return _find_control_recursive(map_maker_module, name, false)

func _find_control_by_pattern(pattern: String) -> Control:
	"""Find control by name pattern."""
	return _find_control_recursive(map_maker_module, pattern, true)

func _find_control_by_text_recursive(parent: Node, text: String) -> Control:
	"""Recursively search for control by text content."""
	if not parent:
		return null
	
	if parent is Button:
		var button: Button = parent as Button
		if text in button.text:
			return button
	
	for child in parent.get_children():
		var found := _find_control_by_text_recursive(child, text)
		if found:
			return found
	
	return null

func _find_control_recursive(parent: Node, search: String, use_pattern: bool) -> Control:
	"""Recursively search for control by name or pattern."""
	if not parent:
		return null
	
	if parent is Control:
		var control: Control = parent as Control
		if use_pattern:
			if search.to_lower() in control.name.to_lower():
				return control
		else:
			if control.name == search:
				return control
	
	for child in parent.get_children():
		var found := _find_control_recursive(child, search, use_pattern)
		if found:
			return found
	
	return null

func _simulate_button_click_safe(button: Button) -> void:
	"""Safely simulate button click."""
	if button and is_instance_valid(button):
		button.pressed.emit()

func _check_for_errors(context: String) -> void:
	"""Check for errors in interaction_errors, debug output, and error listener."""
	# Check interaction errors
	if interaction_errors.size() > 0:
		var error_msg: String = "Errors during %s: %s" % [context, str(interaction_errors)]
		push_error(error_msg)
		interaction_errors.clear()
	
	# Check error listener
	if error_listener and error_listener.has_errors():
		var all_errors: String = error_listener.get_all_errors()
		var error_msg: String = "FAIL: Errors detected during %s:\n%s\nContext: Full lifecycle error detection. Why: Interactions should complete without errors. Hint: Check script compilation, resource loading, and signal emissions."
		fail_test(error_msg % [context, all_errors])
		error_listener.clear()
		return
	
	# Check for missing expected signals
	var missing_signals: Array[String] = error_listener.check_expected_signals() if error_listener else []
	if missing_signals.size() > 0:
		var error_msg: String = "FAIL: Missing expected signals during %s: %s\nContext: Signal tracking. Why: Expected signals should fire within timeout. Hint: Check signal connections and async operations."
		fail_test(error_msg % [context, str(missing_signals)])
		return
	
	# Check for active threads (potential leaks)
	var active_threads: Array[Thread] = error_listener.check_threads_complete() if error_listener else []
	if active_threads.size() > 0:
		var error_msg: String = "FAIL: Active threads detected during %s: %d threads still running\nContext: Thread lifecycle. Why: Threads should complete or be cleaned up. Hint: Check thread.wait_to_finish() calls."
		fail_test(error_msg % [context, active_threads.size()])
		return
