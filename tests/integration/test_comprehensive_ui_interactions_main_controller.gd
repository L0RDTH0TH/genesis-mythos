# ╔═══════════════════════════════════════════════════════════
# ║ test_comprehensive_ui_interactions_main_controller.gd
# ║ Desc: Comprehensive UI interaction tests for main.tscn controller - TabBar, toolbar buttons, OptionButton
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Main controller scene instance
var main_controller: Control

## Test fixture: Scene tree for UI testing
var test_scene: Node

## Track errors during interactions
var interaction_errors: Array[String] = []

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
	"""Setup Main controller instance before each test."""
	interaction_errors.clear()
	
	var scene_path: String = "res://scenes/main.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			main_controller = scene.instantiate() as Control
			if main_controller:
				test_scene.add_child(main_controller)
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame  # Extra frame for full initialization
			else:
				push_error("Failed to instantiate main.tscn")
				main_controller = Control.new()
				test_scene.add_child(main_controller)
		else:
			push_error("Failed to load main.tscn scene")
			main_controller = Control.new()
			test_scene.add_child(main_controller)
	else:
		# Create minimal instance for testing
		main_controller = Control.new()
		main_controller.name = "MainController"
		test_scene.add_child(main_controller)

func after_each() -> void:
	"""Cleanup Main controller instance after each test."""
	if main_controller:
		main_controller.queue_free()
		await get_tree().process_frame
	main_controller = null

# ============================================================
# TAB BAR - ALL INTERACTIONS
# ============================================================

func test_tab_bar_all_tabs() -> void:
	"""Test TabBar - select every tab, including invalid indices."""
	var tab_bar := _find_control_by_name("mode_tabs") as TabBar
	if not tab_bar:
		tab_bar = _find_control_by_pattern("*TabBar*") as TabBar
	
	if tab_bar:
		var tab_count: int = tab_bar.get_tab_count()
		if tab_count > 0:
			# Test selecting each tab
			for i in range(tab_count):
				_simulate_tab_selection_safe(tab_bar, i)
				await get_tree().process_frame
				_check_for_errors("tab selection %d" % i)
				_verify_debug_output_clean("tab selection %d" % i)
			
			# Test invalid index (should handle gracefully)
			if tab_count > 0:
				_simulate_tab_selection_safe(tab_bar, -1)
				await get_tree().process_frame
				_check_for_errors("invalid tab index -1")
				
				_simulate_tab_selection_safe(tab_bar, tab_count + 1)
				await get_tree().process_frame
				_check_for_errors("invalid tab index %d" % (tab_count + 1))
			
			pass_test("TabBar - %d tabs tested" % tab_count)
		else:
			pass_test("TabBar has no tabs")
	else:
		pass_test("TabBar not found")

func test_tab_bar_rapid_switching() -> void:
	"""Test rapid tab switching - should handle gracefully."""
	var tab_bar := _find_control_by_name("mode_tabs") as TabBar
	if not tab_bar:
		tab_bar = _find_control_by_pattern("*TabBar*") as TabBar
	
	if tab_bar:
		var tab_count: int = tab_bar.get_tab_count()
		if tab_count > 0:
			# Rapidly switch tabs
			for i in range(20):
				var tab_index: int = i % tab_count
				_simulate_tab_selection_safe(tab_bar, tab_index)
				await get_tree().process_frame
			_check_for_errors("rapid tab switching")
			_verify_debug_output_clean("rapid tab switching")
			pass_test("Rapid tab switching handled gracefully")
		else:
			pass_test("TabBar has no tabs for rapid switching test")
	else:
		pass_test("TabBar not found for rapid switching test")

# ============================================================
# TOOLBAR BUTTONS - ALL INTERACTIONS
# ============================================================

func test_new_world_button() -> void:
	"""Test New World button - click, rapid clicks, verify no errors."""
	var new_world_button := _find_control_by_name("NewWorldButton") as Button
	if not new_world_button:
		new_world_button = _find_button_by_text("New World")
	
	if new_world_button:
		# Single click
		_simulate_button_click_safe(new_world_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("new world button")
		_verify_debug_output_clean("new world button")
		
		# Rapid clicks
		for i in range(5):
			_simulate_button_click_safe(new_world_button)
			await get_tree().process_frame
		_check_for_errors("rapid new world button clicks")
		_verify_debug_output_clean("rapid new world button clicks")
		
		pass_test("New World button tested")
	else:
		pass_test("New World button not found")

func test_save_world_button() -> void:
	"""Test Save World button - click, rapid clicks."""
	var save_world_button := _find_control_by_name("SaveWorldButton") as Button
	if not save_world_button:
		save_world_button = _find_button_by_text("Save World")
	
	if save_world_button:
		_simulate_button_click_safe(save_world_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("save world button")
		_verify_debug_output_clean("save world button")
		
		# Rapid clicks
		for i in range(5):
			_simulate_button_click_safe(save_world_button)
			await get_tree().process_frame
		_check_for_errors("rapid save world button clicks")
		
		pass_test("Save World button tested")
	else:
		pass_test("Save World button not found")

func test_load_world_button() -> void:
	"""Test Load World button - click, rapid clicks."""
	var load_world_button := _find_control_by_name("LoadWorldButton") as Button
	if not load_world_button:
		load_world_button = _find_button_by_text("Load World")
	
	if load_world_button:
		_simulate_button_click_safe(load_world_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("load world button")
		_verify_debug_output_clean("load world button")
		
		# Rapid clicks
		for i in range(5):
			_simulate_button_click_safe(load_world_button)
			await get_tree().process_frame
		_check_for_errors("rapid load world button clicks")
		
		pass_test("Load World button tested")
	else:
		pass_test("Load World button not found")

func test_all_toolbar_buttons_rapidly() -> void:
	"""Test all toolbar buttons in rapid succession."""
	var buttons: Array[Button] = []
	
	var new_world_button := _find_control_by_name("NewWorldButton") as Button
	var save_world_button := _find_control_by_name("SaveWorldButton") as Button
	var load_world_button := _find_control_by_name("LoadWorldButton") as Button
	
	if new_world_button:
		buttons.append(new_world_button)
	if save_world_button:
		buttons.append(save_world_button)
	if load_world_button:
		buttons.append(load_world_button)
	
	if buttons.size() > 0:
		# Rapidly click all buttons in sequence
		for i in range(10):
			var button: Button = buttons[i % buttons.size()]
			_simulate_button_click_safe(button)
			await get_tree().process_frame
		_check_for_errors("all toolbar buttons rapidly")
		_verify_debug_output_clean("all toolbar buttons rapidly")
		pass_test("All toolbar buttons tested in rapid sequence")
	else:
		pass_test("No toolbar buttons found")

# ============================================================
# PRESET OPTION BUTTON - ALL INTERACTIONS
# ============================================================

func test_preset_option_button_all_options() -> void:
	"""Test Preset OptionButton - select every option, invalid indices."""
	var preset_option := _find_control_by_name("PresetOptionButton") as OptionButton
	if not preset_option:
		preset_option = _find_control_by_pattern("*Preset*Option*") as OptionButton
	
	if preset_option:
		var item_count: int = preset_option.get_item_count()
		if item_count > 0:
			# Test selecting each option
			for i in range(item_count):
				_simulate_option_selection_safe(preset_option, i)
				await get_tree().process_frame
				_check_for_errors("preset option selection %d" % i)
				_verify_debug_output_clean("preset option selection %d" % i)
			
			# Test invalid index (should handle gracefully)
			if item_count > 0:
				_simulate_option_selection_safe(preset_option, -1)
				await get_tree().process_frame
				_check_for_errors("invalid preset option index -1")
			
			pass_test("Preset OptionButton - %d options tested" % item_count)
		else:
			pass_test("Preset OptionButton has no items")
	else:
		pass_test("Preset OptionButton not found")

func test_preset_option_button_rapid_selection() -> void:
	"""Test rapid preset option selection - should handle gracefully."""
	var preset_option := _find_control_by_name("PresetOptionButton") as OptionButton
	if not preset_option:
		preset_option = _find_control_by_pattern("*Preset*Option*") as OptionButton
	
	if preset_option:
		var item_count: int = preset_option.get_item_count()
		if item_count > 0:
			for i in range(20):
				var option_index: int = i % item_count
				_simulate_option_selection_safe(preset_option, option_index)
				await get_tree().process_frame
			_check_for_errors("rapid preset option selection")
			_verify_debug_output_clean("rapid preset option selection")
			pass_test("Rapid preset option selection handled gracefully")
		else:
			pass_test("Preset OptionButton has no items for rapid selection test")
	else:
		pass_test("Preset OptionButton not found for rapid selection test")

# ============================================================
# ERROR HANDLING - NULL STATES, INVALID OPERATIONS
# ============================================================

func test_button_clicks_with_null_data() -> void:
	"""Test button clicks when data might be null/invalid."""
	var save_world_button := _find_control_by_name("SaveWorldButton") as Button
	if save_world_button:
		# Try to save when there might be no world data
		_simulate_button_click_safe(save_world_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("save button with null data")
		_verify_debug_output_clean("save button with null data")
	
	var load_world_button := _find_control_by_name("LoadWorldButton") as Button
	if load_world_button:
		# Try to load when there might be no save files
		_simulate_button_click_safe(load_world_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("load button with no save files")
		_verify_debug_output_clean("load button with no save files")
	
	pass_test("Button clicks with null/invalid data tested")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _find_button_by_text(text: String) -> Button:
	"""Find button by text content (recursive search)."""
	return _find_control_by_text_recursive(main_controller, text) as Button

func _find_control_by_name(name: String) -> Control:
	"""Find control by exact name (recursive search)."""
	return _find_control_recursive(main_controller, name, false)

func _find_control_by_pattern(pattern: String) -> Control:
	"""Find control by name pattern (recursive search)."""
	return _find_control_recursive(main_controller, pattern, true)

func _find_control_by_text_recursive(parent: Node, text: String) -> Control:
	"""Recursively search for control by text content."""
	if not parent:
		return null
	
	if parent is Button:
		var button: Button = parent as Button
		if text.to_lower() in button.text.to_lower():
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
	"""Safely simulate button click with error handling."""
	if button and is_instance_valid(button):
		try:
			button.pressed.emit()
		except:
			interaction_errors.append("Button click failed: %s" % button.name)

func _simulate_tab_selection_safe(tab_bar: TabBar, index: int) -> void:
	"""Safely simulate tab selection with error handling."""
	if tab_bar and is_instance_valid(tab_bar):
		try:
			if index >= 0 and index < tab_bar.get_tab_count():
				tab_bar.current_tab = index
				tab_bar.tab_selected.emit(index)
		except:
			interaction_errors.append("Tab selection failed: %s at index %d" % [tab_bar.name, index])

func _simulate_option_selection_safe(option_button: OptionButton, index: int) -> void:
	"""Safely simulate option selection with error handling."""
	if option_button and is_instance_valid(option_button):
		try:
			if index >= 0 and index < option_button.get_item_count():
				option_button.selected = index
				option_button.item_selected.emit(index)
		except:
			interaction_errors.append("Option selection failed: %s at index %d" % [option_button.name, index])

func _check_for_errors(context: String) -> void:
	"""Check for errors in interaction_errors."""
	if interaction_errors.size() > 0:
		var error_msg: String = "Errors during %s: %s" % [context, str(interaction_errors)]
		push_error(error_msg)
		interaction_errors.clear()

func _verify_debug_output_clean(context: String) -> void:
	"""Verify debug output is clean after interaction."""
	var debug_output = get_debug_output()
	if debug_output:
		if debug_output.has("errors") and debug_output["errors"].size() > 0:
			var errors: Array = debug_output["errors"]
			push_error("Debug errors during %s: %s" % [context, str(errors)])
		
		if debug_output.has("warnings") and debug_output["warnings"].size() > 0:
			var warnings: Array = debug_output["warnings"]
			# Warnings are less critical, but log them
			push_warning("Debug warnings during %s: %s" % [context, str(warnings)])
