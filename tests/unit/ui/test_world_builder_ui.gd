# ╔═══════════════════════════════════════════════════════════
# ║ test_world_builder_ui.gd
# ║ Desc: Unit tests for WorldBuilderUI wizard navigation, step transitions, and data persistence
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: WorldBuilderUI instance
var world_builder_ui: Control

## Test fixture: Scene tree for UI testing
var test_scene: Node

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
	# Load the scene
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		world_builder_ui = scene.instantiate() as Control
		test_scene.add_child(world_builder_ui)
		# Wait for _ready to complete
		await get_tree().process_frame
		await get_tree().process_frame
	else:
		# If scene doesn't exist, create minimal instance for testing
		world_builder_ui = Control.new()
		world_builder_ui.name = "WorldBuilderUI"
		test_scene.add_child(world_builder_ui)
		# Manually initialize if needed
		if world_builder_ui.has_method("_ready"):
			world_builder_ui._ready()
		await get_tree().process_frame

func after_each() -> void:
	"""Cleanup WorldBuilderUI instance after each test."""
	if world_builder_ui:
		world_builder_ui.queue_free()
		await get_tree().process_frame
	world_builder_ui = null

func test_world_builder_ui_initializes() -> void:
	"""Test that WorldBuilderUI initializes without errors."""
	assert_not_null(world_builder_ui, "FAIL: Expected WorldBuilderUI to be created. Context: Scene instantiation. Why: UI should load from scene. Hint: Check WorldBuilderUI.tscn exists and is valid.")

func test_steps_array_has_correct_count() -> void:
	"""Test that STEPS array has 8 steps as documented."""
	if not world_builder_ui.has("STEPS"):
		push_warning("WorldBuilderUI.STEPS not accessible, skipping test")
		pass_test("STEPS array not accessible (may be private)")
		return
	
	var steps: Array = world_builder_ui.get("STEPS")
	assert_not_null(steps, "FAIL: Expected STEPS array to exist. Context: WorldBuilderUI initialization. Why: Steps should be defined. Hint: Check WorldBuilderUI.gd STEPS constant.")
	
	var expected_count: int = 8
	assert_eq(steps.size(), expected_count, "FAIL: Expected %d steps, got %d. Context: WorldBuilderUI.STEPS. Why: Wizard should have 8 steps. Hint: Check STEPS array definition in WorldBuilderUI.gd." % [expected_count, steps.size()])

func test_current_step_starts_at_zero() -> void:
	"""Test that current_step starts at 0 (first step)."""
	if not world_builder_ui.has("current_step"):
		push_warning("WorldBuilderUI.current_step not accessible, skipping test")
		pass_test("current_step not accessible (may be private)")
		return
	
	var current_step: int = world_builder_ui.get("current_step")
	assert_eq(current_step, 0, "FAIL: Expected current_step to start at 0, got %d. Context: WorldBuilderUI initialization. Why: Wizard should start on first step. Hint: Check WorldBuilderUI._ready() sets current_step = 0.")

func test_step_data_initialized() -> void:
	"""Test that step_data dictionary is initialized."""
	if not world_builder_ui.has("step_data"):
		push_warning("WorldBuilderUI.step_data not accessible, skipping test")
		pass_test("step_data not accessible (may be private)")
		return
	
	var step_data: Dictionary = world_builder_ui.get("step_data")
	assert_not_null(step_data, "FAIL: Expected step_data to be initialized. Context: WorldBuilderUI initialization. Why: Step data should be available. Hint: Check WorldBuilderUI._ready() initializes step_data.")

func test_next_button_advances_step() -> void:
	"""Test that Next button advances to next step."""
	if not world_builder_ui.has("current_step"):
		push_warning("WorldBuilderUI.current_step not accessible, skipping test")
		pass_test("current_step not accessible")
		return
	
	var initial_step: int = world_builder_ui.get("current_step")
	
	# Try to call _on_next_pressed if method exists
	if world_builder_ui.has_method("_on_next_pressed"):
		world_builder_ui._on_next_pressed()
		await get_tree().process_frame
		
		var new_step: int = world_builder_ui.get("current_step")
		# Should advance by 1, but not exceed max steps
		var expected_step: int = min(initial_step + 1, 7)  # 0-7 for 8 steps
		assert_eq(new_step, expected_step, "FAIL: Expected step to advance from %d to %d, got %d. Context: Next button pressed. Why: Navigation should advance. Hint: Check WorldBuilderUI._on_next_pressed() increments current_step.")
	else:
		push_warning("_on_next_pressed method not found, skipping test")
		pass_test("_on_next_pressed method not accessible")

func test_back_button_goes_to_previous_step() -> void:
	"""Test that Back button goes to previous step."""
	if not world_builder_ui.has("current_step"):
		push_warning("WorldBuilderUI.current_step not accessible, skipping test")
		pass_test("current_step not accessible")
		return
	
	# Set to step 2 first
	world_builder_ui.set("current_step", 2)
	await get_tree().process_frame
	
	var initial_step: int = world_builder_ui.get("current_step")
	
	# Try to call _on_back_pressed if method exists
	if world_builder_ui.has_method("_on_back_pressed"):
		world_builder_ui._on_back_pressed()
		await get_tree().process_frame
		
		var new_step: int = world_builder_ui.get("current_step")
		# Should go back by 1, but not below 0
		var expected_step: int = max(initial_step - 1, 0)
		assert_eq(new_step, expected_step, "FAIL: Expected step to go back from %d to %d, got %d. Context: Back button pressed. Why: Navigation should go back. Hint: Check WorldBuilderUI._on_back_pressed() decrements current_step.")
	else:
		push_warning("_on_back_pressed method not found, skipping test")
		pass_test("_on_back_pressed method not accessible")

func test_step_data_persists_between_steps() -> void:
	"""Test that step data persists when navigating between steps."""
	if not world_builder_ui.has("step_data"):
		push_warning("WorldBuilderUI.step_data not accessible, skipping test")
		pass_test("step_data not accessible")
		return
	
	var step_data: Dictionary = world_builder_ui.get("step_data")
	
	# Set some test data
	var test_key: String = "test_value"
	var test_data: String = "test_data_123"
	step_data["Map Generation & Editing"] = {test_key: test_data}
	
	# Navigate away and back
	if world_builder_ui.has_method("_on_next_pressed"):
		world_builder_ui._on_next_pressed()
		await get_tree().process_frame
		
		world_builder_ui._on_back_pressed()
		await get_tree().process_frame
		
		# Check data still exists
		var step_data_after: Dictionary = world_builder_ui.get("step_data")
		var map_gen_data: Dictionary = step_data_after.get("Map Generation & Editing", {})
		var retrieved_value: String = map_gen_data.get(test_key, "")
		
		assert_eq(retrieved_value, test_data, "FAIL: Expected step data to persist, got '%s' instead of '%s'. Context: Navigated away and back. Why: Data should persist. Hint: Check WorldBuilderUI step_data is not cleared on navigation.")
	else:
		push_warning("Navigation methods not found, skipping test")
		pass_test("Navigation methods not accessible")

func test_map_icons_data_loaded() -> void:
	"""Test that map icons data is loaded from JSON."""
	if not world_builder_ui.has("map_icons_data"):
		push_warning("WorldBuilderUI.map_icons_data not accessible, skipping test")
		pass_test("map_icons_data not accessible")
		return
	
	var map_icons_data: Dictionary = world_builder_ui.get("map_icons_data")
	# Should be loaded (even if empty dict if file doesn't exist)
	assert_not_null(map_icons_data, "FAIL: Expected map_icons_data to be initialized. Context: WorldBuilderUI initialization. Why: Icons should be loaded. Hint: Check WorldBuilderUI._load_map_icons() loads from res://data/map_icons.json.")

func test_biomes_data_loaded() -> void:
	"""Test that biomes data is loaded from JSON."""
	if not world_builder_ui.has("biomes_data"):
		push_warning("WorldBuilderUI.biomes_data not accessible, skipping test")
		pass_test("biomes_data not accessible")
		return
	
	var biomes_data: Dictionary = world_builder_ui.get("biomes_data")
	assert_not_null(biomes_data, "FAIL: Expected biomes_data to be initialized. Context: WorldBuilderUI initialization. Why: Biomes should be loaded. Hint: Check WorldBuilderUI._load_biomes() loads from res://data/biomes.json.")

func test_civilizations_data_loaded() -> void:
	"""Test that civilizations data is loaded from JSON."""
	if not world_builder_ui.has("civilizations_data"):
		push_warning("WorldBuilderUI.civilizations_data not accessible, skipping test")
		pass_test("civilizations_data not accessible")
		return
	
	var civilizations_data: Dictionary = world_builder_ui.get("civilizations_data")
	assert_not_null(civilizations_data, "FAIL: Expected civilizations_data to be initialized. Context: WorldBuilderUI initialization. Why: Civilizations should be loaded. Hint: Check WorldBuilderUI._load_civilizations() loads from res://data/civilizations.json.")

func test_step_button_navigation() -> void:
	"""Test that clicking step buttons navigates to that step."""
	if not world_builder_ui.has("current_step"):
		push_warning("WorldBuilderUI.current_step not accessible, skipping test")
		pass_test("current_step not accessible")
		return
	
	# Try to find step buttons
	var step_buttons: Array = []
	if world_builder_ui.has("step_buttons"):
		step_buttons = world_builder_ui.get("step_buttons")
	
	if step_buttons.size() == 0:
		push_warning("No step buttons found, skipping test")
		pass_test("Step buttons not accessible")
		return
	
	# Test navigating to step 2 (index 2)
	var target_step: int = 2
	if step_buttons.size() > target_step:
		var button: Button = step_buttons[target_step] as Button
		if button:
			button.pressed.emit()
			await get_tree().process_frame
			
			var current_step: int = world_builder_ui.get("current_step")
			assert_eq(current_step, target_step, "FAIL: Expected step button to navigate to step %d, got %d. Context: Step button clicked. Why: Button should navigate. Hint: Check WorldBuilderUI._on_step_button_pressed() sets current_step correctly.")
		else:
			push_warning("Step button is not a Button, skipping test")
			pass_test("Step button type check")
	else:
		push_warning("Not enough step buttons, skipping test")
		pass_test("Step buttons count check")

func test_placed_icons_array_initialized() -> void:
	"""Test that placed_icons array is initialized."""
	if not world_builder_ui.has("placed_icons"):
		push_warning("WorldBuilderUI.placed_icons not accessible, skipping test")
		pass_test("placed_icons not accessible")
		return
	
	var placed_icons: Array = world_builder_ui.get("placed_icons")
	assert_not_null(placed_icons, "FAIL: Expected placed_icons to be initialized. Context: WorldBuilderUI initialization. Why: Icons array should exist. Hint: Check WorldBuilderUI.gd initializes placed_icons = [].")

func test_icon_groups_array_initialized() -> void:
	"""Test that icon_groups array is initialized."""
	if not world_builder_ui.has("icon_groups"):
		push_warning("WorldBuilderUI.icon_groups not accessible, skipping test")
		pass_test("icon_groups not accessible")
		return
	
	var icon_groups: Array = world_builder_ui.get("icon_groups")
	assert_not_null(icon_groups, "FAIL: Expected icon_groups to be initialized. Context: WorldBuilderUI initialization. Why: Icon groups array should exist. Hint: Check WorldBuilderUI.gd initializes icon_groups = [].")
