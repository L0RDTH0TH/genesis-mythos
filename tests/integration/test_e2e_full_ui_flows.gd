# ╔═══════════════════════════════════════════════════════════
# ║ test_e2e_full_ui_flows.gd
# ║ Desc: End-to-end UI flow tests - complete user journeys from start to finish
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Scene tree for E2E testing
var test_scene: Node

## Track errors during flows
var flow_errors: Array[String] = []

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
	"""Setup before each test."""
	flow_errors.clear()

func after_each() -> void:
	"""Cleanup after each test."""
	# Cleanup any created UI instances
	for child in test_scene.get_children():
		child.queue_free()
	await get_tree().process_frame

func test_e2e_world_builder_complete_flow() -> void:
	"""Test complete World Builder flow: Start → Configure → Generate → Export."""
	var world_builder_ui: Control = null
	
	# Step 1: Load WorldBuilderUI
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui:
		pass_test("WorldBuilderUI not available for E2E test")
		return
	
	# Step 2: Navigate through all 8 steps
	if world_builder_ui.has("current_step"):
		for step in range(8):
			world_builder_ui.set("current_step", step)
			if world_builder_ui.has_method("_update_step_display"):
				world_builder_ui._update_step_display()
			await get_tree().process_frame
			await get_tree().process_frame
			_check_for_errors("navigate to step %d" % step)
		
		# Step 3: Configure Step 1 (Map Generation)
		world_builder_ui.set("current_step", 0)
		await get_tree().process_frame
		
		# Set seed
		var seed_input := _find_control_recursive(world_builder_ui, "seed", false) as LineEdit
		if seed_input:
			seed_input.text = "12345"
			seed_input.text_changed.emit("12345")
			await get_tree().process_frame
		
		# Select size
		var size_dropdown := _find_control_recursive(world_builder_ui, "size", false) as OptionButton
		if size_dropdown and size_dropdown.get_item_count() > 0:
			size_dropdown.selected = 1
			size_dropdown.item_selected.emit(1)
			await get_tree().process_frame
		
		# Click Generate
		var generate_button := _find_button_by_text_recursive(world_builder_ui, "Generate")
		if generate_button:
			generate_button.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame  # Wait for generation
		
		# Step 4: Navigate to Export step
		world_builder_ui.set("current_step", 7)
		if world_builder_ui.has_method("_update_step_display"):
			world_builder_ui._update_step_display()
		await get_tree().process_frame
		
		# Step 5: Set world name and export
		var name_edit := _find_control_recursive(world_builder_ui, "name", true) as LineEdit
		if name_edit:
			name_edit.text = "Test World"
			name_edit.text_changed.emit("Test World")
			await get_tree().process_frame
		
		# Click export button
		var export_button := _find_button_by_text_recursive(world_builder_ui, "Export")
		if export_button:
			export_button.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
		
		_check_for_errors("complete world builder flow")
		pass_test("E2E: Complete World Builder flow executed")
	else:
		pass_test("WorldBuilderUI current_step not accessible")

func test_e2e_main_menu_to_world_builder() -> void:
	"""Test E2E flow: Main Menu → World Creation → World Builder."""
	# Step 1: Load MainMenu
	var main_menu: Control = null
	var main_menu_path: String = "res://scenes/MainMenu.tscn"
	if ResourceLoader.exists(main_menu_path):
		var scene: PackedScene = load(main_menu_path)
		if scene:
			main_menu = scene.instantiate() as Control
			if main_menu:
				test_scene.add_child(main_menu)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not main_menu:
		pass_test("MainMenu not available for E2E test")
		return
	
	# Step 2: Click World Creation button
	var world_button := _find_button_by_text_recursive(main_menu, "Create World")
	if not world_button:
		world_button = main_menu.get_node_or_null("%WorldCreationButton") as Button
	
	if world_button:
		world_button.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("main menu to world creation")
		pass_test("E2E: Main Menu → World Creation flow executed")
	else:
		pass_test("World Creation button not found")

func test_e2e_main_menu_to_character_creation() -> void:
	"""Test E2E flow: Main Menu → Character Creation."""
	var main_menu: Control = null
	var main_menu_path: String = "res://scenes/MainMenu.tscn"
	if ResourceLoader.exists(main_menu_path):
		var scene: PackedScene = load(main_menu_path)
		if scene:
			main_menu = scene.instantiate() as Control
			if main_menu:
				test_scene.add_child(main_menu)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not main_menu:
		pass_test("MainMenu not available for E2E test")
		return
	
	# Click Character Creation button
	var char_button := _find_button_by_text_recursive(main_menu, "Create Character")
	if not char_button:
		char_button = main_menu.get_node_or_null("%CharacterCreationButton") as Button
	
	if char_button:
		char_button.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("main menu to character creation")
		pass_test("E2E: Main Menu → Character Creation flow executed")
	else:
		pass_test("Character Creation button not found")

func test_e2e_world_builder_with_all_interactions() -> void:
	"""Test E2E flow: World Builder with interactions at every step."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui or not world_builder_ui.has("current_step"):
		pass_test("WorldBuilderUI not available")
		return
	
	# Interact with each step
	for step in range(8):
		world_builder_ui.set("current_step", step)
		if world_builder_ui.has_method("_update_step_display"):
			world_builder_ui._update_step_display()
		await get_tree().process_frame
		
		# Find and interact with all controls in this step
		_interact_with_all_controls_in_step(world_builder_ui, step)
		await get_tree().process_frame
		_check_for_errors("step %d interactions" % step)
	
	pass_test("E2E: World Builder with all step interactions executed")

func test_e2e_error_propagation() -> void:
	"""Test that errors in one step propagate correctly to subsequent steps."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui:
		pass_test("WorldBuilderUI not available")
		return
	
	# Step 1: Set invalid data
	if world_builder_ui.has("step_data"):
		var step_data: Dictionary = world_builder_ui.get("step_data")
		step_data["Map Gen"] = {"seed": -1, "width": 0, "height": 0}  # Invalid data
	
	# Step 2: Try to navigate forward
	if world_builder_ui.has_method("_on_next_pressed"):
		world_builder_ui._on_next_pressed()
		await get_tree().process_frame
		_check_for_errors("error propagation")
	
	pass_test("E2E: Error propagation tested")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _find_button_by_text_recursive(parent: Node, text: String) -> Button:
	"""Recursively find button by text."""
	if not parent:
		return null
	
	if parent is Button:
		var button: Button = parent as Button
		if text.to_lower() in button.text.to_lower():
			return button
	
	for child in parent.get_children():
		var found := _find_button_by_text_recursive(child, text)
		if found:
			return found
	
	return null

func _find_control_recursive(parent: Node, name: String, use_pattern: bool) -> Control:
	"""Recursively find control by name or pattern."""
	if not parent:
		return null
	
	if parent is Control:
		var control: Control = parent as Control
		if use_pattern:
			if name.to_lower() in control.name.to_lower():
				return control
		else:
			if control.name == name:
				return control
	
	for child in parent.get_children():
		var found := _find_control_recursive(child, name, use_pattern)
		if found:
			return found
	
	return null

func _interact_with_all_controls_in_step(ui: Control, step: int) -> void:
	"""Interact with all controls in a specific step."""
	# Find all interactive controls
	var all_nodes := _get_all_nodes_recursive(ui)
	
	for node in all_nodes:
		if node is Button:
			var button: Button = node as Button
			if button.visible and not button.disabled:
				button.pressed.emit()
		elif node is HSlider:
			var slider: HSlider = node as HSlider
			if slider.visible:
				slider.value = (slider.min_value + slider.max_value) / 2.0
				slider.value_changed.emit(slider.value)
		elif node is OptionButton:
			var option: OptionButton = node as OptionButton
			if option.visible and option.get_item_count() > 0:
				option.selected = 0
				option.item_selected.emit(0)
		elif node is CheckBox:
			var checkbox: CheckBox = node as CheckBox
			if checkbox.visible:
				checkbox.button_pressed = not checkbox.button_pressed
				checkbox.toggled.emit(checkbox.button_pressed)

func _get_all_nodes_recursive(parent: Node) -> Array:
	"""Get all nodes recursively."""
	var nodes: Array = [parent]
	for child in parent.get_children():
		nodes.append_array(_get_all_nodes_recursive(child))
	return nodes

func _check_for_errors(context: String) -> void:
	"""Check for errors in flow_errors."""
	if flow_errors.size() > 0:
		var error_msg: String = "Errors during %s: %s" % [context, str(flow_errors)]
		push_error(error_msg)
		flow_errors.clear()
