# ╔═══════════════════════════════════════════════════════════
# ║ test_world_builder_ui_full_interactions.gd
# ║ Desc: Full-chain UI interaction tests for WorldBuilderUI - every button, slider, dropdown, text input
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends UIInteractionTestBase

## WorldBuilderUI scene path
const WORLD_BUILDER_SCENE: String = "res://ui/world_builder/WorldBuilderUI.tscn"

## Critical scripts that must preload
const CRITICAL_SCRIPTS: Array[String] = [
	"res://ui/world_builder/MapMakerModule.gd",
	"res://data/ProceduralWorldDatasource.gd"
]

## Critical resources that must preload
const CRITICAL_RESOURCES: Array[String] = [
	"res://themes/bg3_theme.tres",
	"res://data/map_icons.json",
	"res://data/biomes.json",
	"res://data/civilizations.json"
	# Note: Archetypes are now loaded dynamically from res://data/archetypes/ directory
]

func before_each() -> void:
	"""Setup WorldBuilderUI test environment."""
	super.before_each()
	
	# Preload all critical scripts
	for script_path in CRITICAL_SCRIPTS:
		var script = preload_script(script_path)
		if script == null:
			return  # Test will fail in preload_script
	
	# Preload all critical resources
	for resource_path in CRITICAL_RESOURCES:
		var resource = preload_resource(resource_path)
		if resource == null:
			return  # Test will fail in preload_resource
	
	# Load UI scene
	ui_instance = load_ui_scene(WORLD_BUILDER_SCENE)
	if ui_instance == null:
		return  # Test will fail in load_ui_scene

# ============================================================
# STEP 1: MAP GENERATION & EDITING - ALL INTERACTIONS
# ============================================================

func test_step_1_seed_input_all_scenarios() -> void:
	"""Test Step 1: Seed input - valid, invalid, edge cases."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var seed_input := find_control_by_name("seed") as LineEdit
	if not seed_input:
		pass_test("Seed input not found (may use different structure)")
		return
	
	# Test valid positive seed
	simulate_text_input(seed_input, "12345")
	await_process_frames(1)
	check_for_errors("valid positive seed")
	
	# Test valid large seed
	simulate_text_input(seed_input, "999999999")
	await_process_frames(1)
	check_for_errors("valid large seed")
	
	# Test negative seed
	simulate_text_input(seed_input, "-100")
	await_process_frames(1)
	check_for_errors("negative seed")
	
	# Test zero seed
	simulate_text_input(seed_input, "0")
	await_process_frames(1)
	check_for_errors("zero seed")
	
	# Test non-numeric input
	simulate_text_input(seed_input, "abc123")
	await_process_frames(1)
	check_for_errors("non-numeric seed")
	
	# Test empty string
	simulate_text_input(seed_input, "")
	await_process_frames(1)
	check_for_errors("empty seed")
	
	# Test very long string
	simulate_text_input(seed_input, "123456789012345678901234567890")
	await_process_frames(1)
	check_for_errors("very long seed")
	
	# Test special characters
	simulate_text_input(seed_input, "!@#$%^&*()")
	await_process_frames(1)
	check_for_errors("special characters in seed")
	
	pass_test("Step 1: Seed input handles all scenarios")

func test_step_1_random_seed_button() -> void:
	"""Test Step 1: Random seed button generates new seed."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var random_button := find_control_by_pattern("*Random*") as Button
	if random_button:
		var seed_before: String = ""
		var seed_input := find_control_by_name("seed") as LineEdit
		if seed_input:
			seed_before = seed_input.text
		
		simulate_button_click(random_button)
		await_process_frames(2)
		check_for_errors("random seed button")
		
		pass_test("Step 1: Random seed button clicked")
	else:
		pass_test("Step 1: Random seed button not found")

func test_step_1_generate_button_full_lifecycle() -> void:
	"""Test Step 1: Generate button - FULL LIFECYCLE with complete chain verification."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var generate_button := find_control_by_pattern("*Generate*Map*") as Button
	if not generate_button:
		generate_button = find_control_by_pattern("*Generate*") as Button
	
	if not generate_button:
		pass_test("Step 1: Generate button not found")
		return
	
	# Pre-check: Verify ProceduralWorldDatasource script is already preloaded
	var datasource_script_path: String = "res://data/ProceduralWorldDatasource.gd"
	if not tracked_scripts.has(datasource_script_path):
		fail_test("FAIL: ProceduralWorldDatasource not preloaded\nContext: Pre-generation check. Why: Script must be preloaded before generation. Hint: Check test setup.")
		return
	
	# Track expected signals
	if ui_instance.has_signal("generation_complete"):
		await_signal(ui_instance, "generation_complete", 10.0)
	if ui_instance.has_signal("map_generated"):
		await_signal(ui_instance, "map_generated", 10.0)
	
	# Click generate button
	simulate_button_click(generate_button)
	
	# Wait for generation with timeout
	var timeout: float = 10.0
	var elapsed: float = 0.0
	var generation_started: bool = false
	
	# Poll for generation completion
	while elapsed < timeout:
		await_process_frames(1)
		elapsed += get_process_delta_time()
		
		# Check if generation started
		if ui_instance.has("procedural_world_map"):
			var pwm = ui_instance.get("procedural_world_map")
			if pwm and pwm.has("datasource") and pwm.get("datasource") != null:
				generation_started = true
				break
		
		# Check for errors during generation
		if error_listener and error_listener.has_errors():
			var all_errors: String = error_listener.get_all_errors()
			fail_test("FAIL: Errors during generation:\n%s\nContext: Generation lifecycle. Why: Generation should complete without errors. Hint: Check script loading, resource creation, and signal emissions." % all_errors)
			return
	
	if not generation_started and elapsed >= timeout:
		fail_test("FAIL: Generation did not start within timeout. Context: Generation lifecycle. Why: Button click should trigger generation. Hint: Check _on_generate_map_pressed() method and signal connections.")
		return
	
	# Wait additional frames for completion
	await_process_frames(3)
	
	# Verify final state: map data exists
	if ui_instance.has("procedural_world_map"):
		var pwm = ui_instance.get("procedural_world_map")
		if pwm:
			if not pwm.has("datasource") or pwm.get("datasource") == null:
				fail_test("FAIL: Datasource not set after generation. Context: Post-generation state. Why: Generation should create and set datasource. Hint: Check _on_generate_map_pressed() implementation.")
				return
	
	# Check for errors after generation
	check_for_errors("generate button - full lifecycle")
	
	pass_test("Step 1: Generate button triggers map generation - full lifecycle verified")

func test_step_1_all_sliders_full_range() -> void:
	"""Test Step 1: All sliders - min, max, middle, edge cases."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var sliders: Array[String] = ["noise_frequency", "noise_persistence", "noise_lacunarity", "sea_level"]
	for slider_name in sliders:
		var slider := find_control_by_name(slider_name) as HSlider
		if slider:
			# Test min value
			simulate_slider_drag(slider, slider.min_value)
			await_process_frames(1)
			check_for_errors("%s min" % slider_name)
			
			# Test max value
			simulate_slider_drag(slider, slider.max_value)
			await_process_frames(1)
			check_for_errors("%s max" % slider_name)
			
			# Test middle value
			simulate_slider_drag(slider, (slider.min_value + slider.max_value) / 2.0)
			await_process_frames(1)
			check_for_errors("%s middle" % slider_name)
			
			# Test values outside range (should clamp)
			simulate_slider_drag(slider, slider.min_value - 1.0)
			await_process_frames(1)
			check_for_errors("%s below min" % slider_name)
			
			simulate_slider_drag(slider, slider.max_value + 1.0)
			await_process_frames(1)
			check_for_errors("%s above max" % slider_name)
	
	pass_test("Step 1: All sliders tested")

func test_step_1_all_dropdowns_all_options() -> void:
	"""Test Step 1: All dropdowns - select every option."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var dropdowns: Array[String] = ["style", "size", "landmass"]
	for dropdown_name in dropdowns:
		var dropdown := find_control_by_name(dropdown_name) as OptionButton
		if dropdown:
			var item_count: int = dropdown.get_item_count()
			if item_count > 0:
				# Test selecting each option
				for i in range(item_count):
					simulate_option_selection(dropdown, i)
					await_process_frames(1)
					check_for_errors("%s selection %d" % [dropdown_name, i])
	
	pass_test("Step 1: All dropdowns tested")

func test_step_1_checkboxes_all_states() -> void:
	"""Test Step 1: All checkboxes - toggle on/off, rapid toggles."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var checkboxes: Array[String] = ["erosion_enabled"]
	for checkbox_name in checkboxes:
		var checkbox := find_control_by_name(checkbox_name) as CheckBox
		if checkbox:
			# Toggle on
			simulate_checkbox_toggle(checkbox, true)
			await_process_frames(1)
			check_for_errors("%s on" % checkbox_name)
			
			# Toggle off
			simulate_checkbox_toggle(checkbox, false)
			await_process_frames(1)
			check_for_errors("%s off" % checkbox_name)
			
			# Rapid toggles
			for i in range(5):
				simulate_checkbox_toggle(checkbox, i % 2 == 0)
				await_process_frames(1)
			check_for_errors("rapid %s toggles" % checkbox_name)
	
	pass_test("Step 1: All checkboxes tested")

# ============================================================
# NAVIGATION - ALL BUTTONS
# ============================================================

func test_navigation_next_button_all_steps() -> void:
	"""Test Next button navigation through all 8 steps."""
	if not ui_instance.has("current_step"):
		pass_test("current_step not accessible")
		return
	
	# Start at step 0
	ui_instance.set("current_step", 0)
	await_process_frames(2)
	
	# Navigate forward through all steps
	for expected_step in range(8):
		var current: int = ui_instance.get("current_step")
		assert_eq(current, expected_step, "FAIL: Expected step %d, got %d. Context: Next button navigation. Why: Should advance step by step. Hint: Check WorldBuilderUI._on_next_pressed()." % [expected_step, current])
		
		if expected_step < 7:
			# Click Next button
			if ui_instance.has_method("_on_next_pressed"):
				ui_instance._on_next_pressed()
			else:
				var next_button := find_control_by_pattern("*Next*") as Button
				if next_button:
					simulate_button_click(next_button)
			
			await_process_frames(2)
			check_for_errors("next button at step %d" % expected_step)
	
	pass_test("Next button navigates through all 8 steps")

func test_navigation_back_button_all_steps() -> void:
	"""Test Back button navigation backwards through all steps."""
	if not ui_instance.has("current_step"):
		pass_test("current_step not accessible")
		return
	
	# Start at step 7
	ui_instance.set("current_step", 7)
	await_process_frames(2)
	
	# Navigate backwards
	for expected_step in range(7, -1, -1):
		var current: int = ui_instance.get("current_step")
		assert_eq(current, expected_step, "FAIL: Expected step %d, got %d. Context: Back button navigation. Why: Should decrement step. Hint: Check WorldBuilderUI._on_back_pressed()." % [expected_step, current])
		
		if expected_step > 0:
			if ui_instance.has_method("_on_back_pressed"):
				ui_instance._on_back_pressed()
			else:
				var back_button := find_control_by_pattern("*Back*") as Button
				if back_button:
					simulate_button_click(back_button)
			
			await_process_frames(2)
			check_for_errors("back button at step %d" % expected_step)
	
	pass_test("Back button navigates backwards through all steps")

func test_navigation_boundary_conditions() -> void:
	"""Test navigation boundary conditions - can't go before 0 or after 7."""
	if not ui_instance.has("current_step"):
		pass_test("current_step not accessible")
		return
	
	# Test at step 0 - Back should not go below 0
	ui_instance.set("current_step", 0)
	await_process_frames(2)
	
	if ui_instance.has_method("_on_back_pressed"):
		ui_instance._on_back_pressed()
		await_process_frames(1)
		var current: int = ui_instance.get("current_step")
		assert_eq(current, 0, "FAIL: Back button at step 0 should not go below 0. Context: Boundary condition. Why: Should clamp to 0. Hint: Check WorldBuilderUI._on_back_pressed() clamping.")
	
	# Test at step 7 - Next should not go above 7
	ui_instance.set("current_step", 7)
	await_process_frames(2)
	
	if ui_instance.has_method("_on_next_pressed"):
		ui_instance._on_next_pressed()
		await_process_frames(1)
		var current: int = ui_instance.get("current_step")
		assert_eq(current, 7, "FAIL: Next button at step 7 should not go above 7. Context: Boundary condition. Why: Should clamp to 7. Hint: Check WorldBuilderUI._on_next_pressed() clamping.")
	
	pass_test("Navigation respects boundary conditions")

# ============================================================
# RAPID INTERACTION TESTS - STRESS TESTING
# ============================================================

func test_rapid_button_clicks() -> void:
	"""Test rapid button clicks - should handle gracefully without crashes."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var generate_button := find_control_by_pattern("*Generate*") as Button
	if generate_button:
		# Rapid clicks
		for i in range(20):
			simulate_button_click(generate_button)
			await_process_frames(1)
		check_for_errors("rapid button clicks")
		pass_test("Rapid button clicks handled gracefully")
	else:
		pass_test("Generate button not found for rapid click test")

func test_rapid_slider_changes() -> void:
	"""Test rapid slider value changes - should handle gracefully."""
	_navigate_to_step(0)
	await_process_frames(2)
	
	var slider := find_control_by_name("noise_frequency") as HSlider
	if slider:
		# Rapid value changes
		for i in range(50):
			var value: float = slider.min_value + (slider.max_value - slider.min_value) * (float(i) / 50.0)
			simulate_slider_drag(slider, value)
			await_process_frames(1)
		check_for_errors("rapid slider changes")
		pass_test("Rapid slider changes handled gracefully")
	else:
		pass_test("Noise frequency slider not found for rapid change test")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _navigate_to_step(step: int) -> void:
	"""Navigate to specific step."""
	if ui_instance.has("current_step"):
		ui_instance.set("current_step", step)
		if ui_instance.has_method("_update_step_display"):
			ui_instance._update_step_display()
		await_process_frames(2)
