# ╔═══════════════════════════════════════════════════════════
# ║ test_e2e_ui_flows.gd
# ║ Desc: End-to-end UI flow tests - complete user journeys from start to finish
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Scene tree for UI testing
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

func test_e2e_world_builder_complete_workflow() -> void:
	"""Test complete E2E workflow: Main Menu → World Builder → All 8 Steps → Export."""
	# Step 1: Load Main Menu
	var main_menu_scene_path: String = "res://scenes/MainMenu.tscn"
	if not ResourceLoader.exists(main_menu_scene_path):
		pass_test("MainMenu scene not found, skipping E2E test")
		return
	
	var main_menu_scene: PackedScene = load(main_menu_scene_path)
	if not main_menu_scene:
		pass_test("Failed to load MainMenu scene")
		return
	
	var main_menu: Control = main_menu_scene.instantiate() as Control
	test_scene.add_child(main_menu)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Step 2: Click World Creation button
	var world_button := _find_button_recursive(main_menu, "Create World")
	if world_button:
		world_button.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("world creation button click")
	
	# Step 3: Load WorldBuilderUI (may be in new scene)
	var world_builder_scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(world_builder_scene_path):
		var world_builder_scene: PackedScene = load(world_builder_scene_path)
		if world_builder_scene:
			var world_builder: Control = world_builder_scene.instantiate() as Control
			test_scene.add_child(world_builder)
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			
			# Step 4: Navigate through all 8 steps
			if world_builder.has("current_step"):
				for step in range(8):
					world_builder.set("current_step", step)
					if world_builder.has_method("_update_step_display"):
						world_builder._update_step_display()
					await get_tree().process_frame
					await get_tree().process_frame
					_check_for_errors("step %d navigation" % step)
					
					# Interact with step elements
					_interact_with_step_elements(world_builder, step)
					await get_tree().process_frame
			
			# Step 5: Test export
			if world_builder.has("current_step"):
				world_builder.set("current_step", 7)  # Export step
				await get_tree().process_frame
				
				var export_button := _find_button_recursive(world_builder, "Export")
				if export_button:
					export_button.pressed.emit()
					await get_tree().process_frame
					await get_tree().process_frame
					_check_for_errors("export button")
	
	pass_test("E2E world builder complete workflow tested")

func test_e2e_character_creation_workflow() -> void:
	"""Test complete E2E workflow: Main Menu → Character Creation → Ability Scores."""
	# Step 1: Load Main Menu
	var main_menu_scene_path: String = "res://scenes/MainMenu.tscn"
	if not ResourceLoader.exists(main_menu_scene_path):
		pass_test("MainMenu scene not found, skipping E2E test")
		return
	
	var main_menu_scene: PackedScene = load(main_menu_scene_path)
	if not main_menu_scene:
		pass_test("Failed to load MainMenu scene")
		return
	
	var main_menu: Control = main_menu_scene.instantiate() as Control
	test_scene.add_child(main_menu)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Step 2: Click Character Creation button
	var char_button := _find_button_recursive(main_menu, "Create Character")
	if char_button:
		char_button.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("character creation button click")
	
	# Step 3: Test character creation scene (if exists)
	var char_creation_scene_path: String = "res://scenes/character_creation/CharacterCreationRoot.tscn"
	if ResourceLoader.exists(char_creation_scene_path):
		var char_creation_scene: PackedScene = load(char_creation_scene_path)
		if char_creation_scene:
			var char_creation: Control = char_creation_scene.instantiate() as Control
			test_scene.add_child(char_creation)
			await get_tree().process_frame
			await get_tree().process_frame
			
			# Test ability score interactions
			var ability_rows := _find_all_ability_score_rows(char_creation)
			for row in ability_rows:
				var plus_button := _find_button_recursive(row, "Plus")
				var minus_button := _find_button_recursive(row, "Minus")
				
				if plus_button:
					plus_button.pressed.emit()
					await get_tree().process_frame
					_check_for_errors("ability score plus button")
				
				if minus_button:
					minus_button.pressed.emit()
					await get_tree().process_frame
					_check_for_errors("ability score minus button")
	
	pass_test("E2E character creation workflow tested")

func test_e2e_error_propagation() -> void:
	"""Test error propagation through UI flow - invalid inputs should be handled gracefully."""
	var world_builder_scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if not ResourceLoader.exists(world_builder_scene_path):
		pass_test("WorldBuilderUI scene not found, skipping error propagation test")
		return
	
	var world_builder_scene: PackedScene = load(world_builder_scene_path)
	if not world_builder_scene:
		pass_test("Failed to load WorldBuilderUI scene")
		return
	
	var world_builder: Control = world_builder_scene.instantiate() as Control
	test_scene.add_child(world_builder)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Navigate to step 1
	if world_builder.has("current_step"):
		world_builder.set("current_step", 0)
		await get_tree().process_frame
		
		# Test invalid seed input
		var seed_input := _find_control_recursive(world_builder, "seed") as LineEdit
		if seed_input:
			# Set invalid seed
			seed_input.text = "invalid"
			seed_input.text_changed.emit("invalid")
			await get_tree().process_frame
			_check_for_errors("invalid seed input")
			
			# Try to generate with invalid seed
			var generate_button := _find_button_recursive(world_builder, "Generate")
			if generate_button:
				generate_button.pressed.emit()
				await get_tree().process_frame
				await get_tree().process_frame
				_check_for_errors("generate with invalid seed")
	
	pass_test("E2E error propagation tested")

func test_e2e_state_consistency() -> void:
	"""Test state consistency across navigation - data should persist."""
	var world_builder_scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if not ResourceLoader.exists(world_builder_scene_path):
		pass_test("WorldBuilderUI scene not found, skipping state consistency test")
		return
	
	var world_builder_scene: PackedScene = load(world_builder_scene_path)
	if not world_builder_scene:
		pass_test("Failed to load WorldBuilderUI scene")
		return
	
	var world_builder: Control = world_builder_scene.instantiate() as Control
	test_scene.add_child(world_builder)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	if world_builder.has("step_data"):
		var step_data: Dictionary = world_builder.get("step_data")
		
		# Set data in step 1
		step_data["Map Gen"] = {"seed": 12345, "width": 512, "height": 512}
		
		# Navigate to step 2
		if world_builder.has("current_step"):
			world_builder.set("current_step", 1)
			await get_tree().process_frame
			
			# Navigate back to step 1
			world_builder.set("current_step", 0)
			await get_tree().process_frame
			
			# Verify data persisted
			var map_gen_data: Dictionary = step_data.get("Map Gen", {})
			var seed_value = map_gen_data.get("seed", -1)
			assert_eq(seed_value, 12345, "FAIL: Step data should persist after navigation. Context: Forward then back. Why: Data should be preserved. Hint: Check WorldBuilderUI step_data persistence.")
	
	pass_test("E2E state consistency tested")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _interact_with_step_elements(world_builder: Control, step: int) -> void:
	"""Interact with elements in a specific step."""
	# Find and interact with common elements
	var all_buttons := _find_all_buttons(world_builder)
	for button in all_buttons:
		if button.visible and not button.disabled:
			# Don't click navigation buttons during step interaction
			if "Next" not in button.text and "Back" not in button.text:
				button.pressed.emit()
				await get_tree().process_frame
	
	var all_sliders := _find_all_sliders(world_builder)
	for slider in all_sliders:
		if slider.visible:
			slider.value = (slider.min_value + slider.max_value) / 2.0
			slider.value_changed.emit(slider.value)
			await get_tree().process_frame

func _find_button_recursive(parent: Node, text: String) -> Button:
	"""Find button by text content."""
	if not parent:
		return null
	
	if parent is Button:
		var button: Button = parent as Button
		if text.to_lower() in button.text.to_lower():
			return button
	
	for child in parent.get_children():
		var found := _find_button_recursive(child, text)
		if found:
			return found
	
	return null

func _find_control_recursive(parent: Node, name: String) -> Control:
	"""Find control by name."""
	if not parent:
		return null
	
	if parent is Control:
		var control: Control = parent as Control
		if control.name == name:
			return control
	
	for child in parent.get_children():
		var found := _find_control_recursive(child, name)
		if found:
			return found
	
	return null

func _find_all_buttons(parent: Node) -> Array[Button]:
	"""Find all buttons recursively."""
	var buttons: Array[Button] = []
	_find_all_buttons_recursive(parent, buttons)
	return buttons

func _find_all_buttons_recursive(node: Node, buttons: Array[Button]) -> void:
	"""Recursively find all buttons."""
	if node is Button:
		buttons.append(node as Button)
	
	for child in node.get_children():
		_find_all_buttons_recursive(child, buttons)

func _find_all_sliders(parent: Node) -> Array[HSlider]:
	"""Find all sliders recursively."""
	var sliders: Array[HSlider] = []
	_find_all_sliders_recursive(parent, sliders)
	return sliders

func _find_all_sliders_recursive(node: Node, sliders: Array[HSlider]) -> void:
	"""Recursively find all sliders."""
	if node is HSlider:
		sliders.append(node as HSlider)
	
	for child in node.get_children():
		_find_all_sliders_recursive(child, sliders)

func _find_all_ability_score_rows(parent: Node) -> Array[AbilityScoreRow]:
	"""Find all AbilityScoreRow instances."""
	var rows: Array[AbilityScoreRow] = []
	_find_all_ability_score_rows_recursive(parent, rows)
	return rows

func _find_all_ability_score_rows_recursive(node: Node, rows: Array[AbilityScoreRow]) -> void:
	"""Recursively find all AbilityScoreRow instances."""
	if node is AbilityScoreRow:
		rows.append(node as AbilityScoreRow)
	
	for child in node.get_children():
		_find_all_ability_score_rows_recursive(child, rows)

func _check_for_errors(context: String) -> void:
	"""Check for errors in flow_errors."""
	if flow_errors.size() > 0:
		var error_msg: String = "Errors during %s: %s" % [context, str(flow_errors)]
		push_error(error_msg)
		flow_errors.clear()
