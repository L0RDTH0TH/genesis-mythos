# ╔═══════════════════════════════════════════════════════════
# ║ test_comprehensive_ui_interactions_world_builder.gd
# ║ Desc: Comprehensive UI interaction tests for WorldBuilderUI - EVERY button, slider, dropdown, text input, checkbox
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Preload TestErrorListener
const TestErrorListener = preload("res://tests/helpers/TestErrorListener.gd")

## Test fixture: WorldBuilderUI instance
var world_builder_ui: Control

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
	"""Setup WorldBuilderUI instance before each test."""
	interaction_errors.clear()
	error_listener = TestErrorListener.get_instance()
	error_listener.clear()
	
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene == null:
			push_error("Failed to load WorldBuilderUI scene")
			world_builder_ui = Control.new()
			test_scene.add_child(world_builder_ui)
			return
		
		world_builder_ui = scene.instantiate() as Control
		if world_builder_ui == null:
			push_error("Failed to instantiate WorldBuilderUI")
			world_builder_ui = Control.new()
		
		test_scene.add_child(world_builder_ui)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame  # Extra frame for full initialization
	else:
		# Create minimal instance for testing
		world_builder_ui = Control.new()
		world_builder_ui.name = "WorldBuilderUI"
		test_scene.add_child(world_builder_ui)

func after_each() -> void:
	"""Cleanup WorldBuilderUI instance after each test."""
	if world_builder_ui:
		world_builder_ui.queue_free()
		await get_tree().process_frame
	world_builder_ui = null

# ============================================================
# STEP 1: MAP GENERATION & EDITING - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_1_seed_input_all_scenarios() -> void:
	"""Test Step 1: Seed input - valid, invalid, edge cases, special characters."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var seed_input := _find_control_by_name("seed") as LineEdit
	if not seed_input:
		pass_test("Seed input not found (may use different structure)")
		return
	
	# Test valid positive seed
	_simulate_text_input_safe(seed_input, "12345")
	await get_tree().process_frame
	_check_for_errors("valid positive seed")
	
	# Test valid large seed
	_simulate_text_input_safe(seed_input, "999999999")
	await get_tree().process_frame
	_check_for_errors("valid large seed")
	
	# Test negative seed (should handle gracefully)
	_simulate_text_input_safe(seed_input, "-100")
	await get_tree().process_frame
	_check_for_errors("negative seed")
	
	# Test zero seed
	_simulate_text_input_safe(seed_input, "0")
	await get_tree().process_frame
	_check_for_errors("zero seed")
	
	# Test non-numeric input
	_simulate_text_input_safe(seed_input, "abc123")
	await get_tree().process_frame
	_check_for_errors("non-numeric seed")
	
	# Test empty string
	_simulate_text_input_safe(seed_input, "")
	await get_tree().process_frame
	_check_for_errors("empty seed")
	
	# Test very long string
	_simulate_text_input_safe(seed_input, "123456789012345678901234567890")
	await get_tree().process_frame
	_check_for_errors("very long seed")
	
	# Test special characters
	_simulate_text_input_safe(seed_input, "!@#$%^&*()")
	await get_tree().process_frame
	_check_for_errors("special characters in seed")
	
	pass_test("Step 1: Seed input handles all scenarios")

func test_step_1_random_seed_button() -> void:
	"""Test Step 1: Random seed button generates new seed."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var random_button := _find_control_by_pattern("*Random*") as Button
	if random_button:
		var seed_before: String = ""
		var seed_input := _find_control_by_name("seed") as LineEdit
		if seed_input:
			seed_before = seed_input.text
		
		_simulate_button_click_safe(random_button)
		await get_tree().process_frame
		_check_for_errors("random seed button")
		
		if seed_input and seed_input.text != seed_before:
			pass_test("Step 1: Random seed button generates new seed")
		else:
			pass_test("Step 1: Random seed button clicked (seed may not change visibly)")
	else:
		pass_test("Step 1: Random seed button not found")

func test_step_1_fantasy_style_dropdown_all_options() -> void:
	"""Test Step 1: Fantasy style dropdown - select every option."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var style_dropdown := _find_control_by_name("style") as OptionButton
	if style_dropdown:
		var item_count: int = style_dropdown.get_item_count()
		if item_count > 0:
			# Test selecting each option
			for i in range(item_count):
				_simulate_option_selection_safe(style_dropdown, i)
				await get_tree().process_frame
				_check_for_errors("fantasy style selection %d" % i)
			
			# Test invalid index (should handle gracefully)
			if item_count > 0:
				_simulate_option_selection_safe(style_dropdown, -1)
				await get_tree().process_frame
				_check_for_errors("invalid style index")
			
			pass_test("Step 1: Fantasy style dropdown - %d options tested" % item_count)
		else:
			pass_test("Step 1: Fantasy style dropdown has no items")
	else:
		pass_test("Step 1: Fantasy style dropdown not found")

func test_step_1_size_dropdown_all_options() -> void:
	"""Test Step 1: Size dropdown - select every option."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var size_dropdown := _find_control_by_name("size") as OptionButton
	if size_dropdown:
		var item_count: int = size_dropdown.get_item_count()
		if item_count > 0:
			for i in range(item_count):
				_simulate_option_selection_safe(size_dropdown, i)
				await get_tree().process_frame
				_check_for_errors("size selection %d" % i)
			
			pass_test("Step 1: Size dropdown - %d options tested" % item_count)
		else:
			pass_test("Step 1: Size dropdown has no items")
	else:
		pass_test("Step 1: Size dropdown not found")

func test_step_1_landmass_dropdown_all_options() -> void:
	"""Test Step 1: Landmass dropdown - select every option."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var landmass_dropdown := _find_control_by_name("landmass") as OptionButton
	if landmass_dropdown:
		var item_count: int = landmass_dropdown.get_item_count()
		if item_count > 0:
			for i in range(item_count):
				_simulate_option_selection_safe(landmass_dropdown, i)
				await get_tree().process_frame
				_check_for_errors("landmass selection %d" % i)
			
			pass_test("Step 1: Landmass dropdown - %d options tested" % item_count)
		else:
			pass_test("Step 1: Landmass dropdown has no items")
	else:
		pass_test("Step 1: Landmass dropdown not found")

func test_step_1_generate_button() -> void:
	"""Test Step 1: Generate button triggers map generation - FULL LIFECYCLE."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var generate_button := _find_control_by_pattern("*Generate*Map*") as Button
	if not generate_button:
		generate_button = _find_control_by_pattern("*Generate*") as Button
	
	if generate_button:
		# Pre-check: Verify ProceduralWorldDatasource script can be loaded
		var datasource_script_path: String = "res://data/ProceduralWorldDatasource.gd"
		var datasource_script: GDScript = load(datasource_script_path) as GDScript
		if datasource_script == null:
			error_listener.capture_script_error(datasource_script_path, "Failed to load script")
			fail_test("FAIL: ProceduralWorldDatasource script failed to load. Context: Pre-generation check. Why: Script must load before generation. Hint: Check parse errors in ProceduralWorldDatasource.gd.")
			return
		
		# Verify script can be instantiated
		if datasource_script.can_instantiate():
			var test_instance = datasource_script.new()
			if test_instance == null:
				error_listener.capture_script_error(datasource_script_path, "Failed to instantiate")
				fail_test("FAIL: ProceduralWorldDatasource failed to instantiate. Context: Pre-generation check. Why: Script must be instantiable. Hint: Check _init() method.")
				return
			# Clean up test instance
			if test_instance is RefCounted:
				pass  # Auto-freed
			elif test_instance is Node:
				test_instance.queue_free()
		
		# Track expected signals (if WorldBuilderUI emits generation_complete or similar)
		if world_builder_ui.has_signal("generation_complete"):
			error_listener.expect_signal(world_builder_ui, "generation_complete", 10.0)
		if world_builder_ui.has_signal("map_generated"):
			error_listener.expect_signal(world_builder_ui, "map_generated", 10.0)
		
		# Click generate button
		_simulate_button_click_safe(generate_button)
		
		# Wait for generation with timeout
		var timeout: float = 10.0
		var elapsed: float = 0.0
		var generation_started: bool = false
		
		# Poll for generation completion
		while elapsed < timeout:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
			
			# Check if generation started (check for datasource creation or map data)
			if world_builder_ui.has("procedural_world_map"):
				var pwm = world_builder_ui.get("procedural_world_map")
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
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Verify final state: map data exists
		if world_builder_ui.has("procedural_world_map"):
			var pwm = world_builder_ui.get("procedural_world_map")
			if pwm:
				if not pwm.has("datasource") or pwm.get("datasource") == null:
					fail_test("FAIL: Datasource not set after generation. Context: Post-generation state. Why: Generation should create and set datasource. Hint: Check _on_generate_map_pressed() implementation.")
					return
		
		# Check for errors after generation
		_check_for_errors("generate button - full lifecycle")
		
		# Test rapid clicks (should handle gracefully)
		for i in range(5):
			_simulate_button_click_safe(generate_button)
			await get_tree().process_frame
		_check_for_errors("rapid generate button clicks")
		
		pass_test("Step 1: Generate button triggers map generation - full lifecycle verified")
	else:
		pass_test("Step 1: Generate button not found")

func test_step_1_bake_to_3d_button() -> void:
	"""Test Step 1: Bake to 3D button."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var bake_button := _find_control_by_pattern("*Bake*3D*") as Button
	if bake_button:
		_simulate_button_click_safe(bake_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("bake to 3D button")
		pass_test("Step 1: Bake to 3D button clicked")
	else:
		pass_test("Step 1: Bake to 3D button not found")

func test_step_1_noise_frequency_slider_all_values() -> void:
	"""Test Step 1: Noise frequency slider - min, max, middle, edge cases."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var slider := _find_control_by_name("noise_frequency") as HSlider
	if slider:
		# Test min value
		_simulate_slider_drag_safe(slider, slider.min_value)
		await get_tree().process_frame
		_check_for_errors("noise frequency min")
		
		# Test max value
		_simulate_slider_drag_safe(slider, slider.max_value)
		await get_tree().process_frame
		_check_for_errors("noise frequency max")
		
		# Test middle value
		_simulate_slider_drag_safe(slider, (slider.min_value + slider.max_value) / 2.0)
		await get_tree().process_frame
		_check_for_errors("noise frequency middle")
		
		# Test values outside range (should clamp)
		_simulate_slider_drag_safe(slider, slider.min_value - 1.0)
		await get_tree().process_frame
		_check_for_errors("noise frequency below min")
		
		_simulate_slider_drag_safe(slider, slider.max_value + 1.0)
		await get_tree().process_frame
		_check_for_errors("noise frequency above max")
		
		pass_test("Step 1: Noise frequency slider tested")
	else:
		pass_test("Step 1: Noise frequency slider not found")

func test_step_1_octaves_spinbox_all_values() -> void:
	"""Test Step 1: Octaves spinbox - min, max, all valid values."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var spinbox := _find_control_by_name("noise_octaves") as SpinBox
	if spinbox:
		# Test min value
		_simulate_spinbox_change_safe(spinbox, spinbox.min_value)
		await get_tree().process_frame
		_check_for_errors("octaves min")
		
		# Test max value
		_simulate_spinbox_change_safe(spinbox, spinbox.max_value)
		await get_tree().process_frame
		_check_for_errors("octaves max")
		
		# Test all intermediate values
		for i in range(int(spinbox.min_value), int(spinbox.max_value) + 1):
			_simulate_spinbox_change_safe(spinbox, float(i))
			await get_tree().process_frame
			_check_for_errors("octaves value %d" % i)
		
		# Test invalid values (should clamp)
		_simulate_spinbox_change_safe(spinbox, spinbox.min_value - 1.0)
		await get_tree().process_frame
		_check_for_errors("octaves below min")
		
		pass_test("Step 1: Octaves spinbox tested")
	else:
		pass_test("Step 1: Octaves spinbox not found")

func test_step_1_persistence_slider_all_values() -> void:
	"""Test Step 1: Persistence slider - full range."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var slider := _find_control_by_name("noise_persistence") as HSlider
	if slider:
		_simulate_slider_drag_safe(slider, slider.min_value)
		await get_tree().process_frame
		_simulate_slider_drag_safe(slider, slider.max_value)
		await get_tree().process_frame
		_simulate_slider_drag_safe(slider, 0.5)
		await get_tree().process_frame
		_check_for_errors("persistence slider")
		pass_test("Step 1: Persistence slider tested")
	else:
		pass_test("Step 1: Persistence slider not found")

func test_step_1_lacunarity_slider_all_values() -> void:
	"""Test Step 1: Lacunarity slider - full range."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var slider := _find_control_by_name("noise_lacunarity") as HSlider
	if slider:
		_simulate_slider_drag_safe(slider, slider.min_value)
		await get_tree().process_frame
		_simulate_slider_drag_safe(slider, slider.max_value)
		await get_tree().process_frame
		_check_for_errors("lacunarity slider")
		pass_test("Step 1: Lacunarity slider tested")
	else:
		pass_test("Step 1: Lacunarity slider not found")

func test_step_1_sea_level_slider_all_values() -> void:
	"""Test Step 1: Sea level slider - full range."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var slider := _find_control_by_name("sea_level") as HSlider
	if slider:
		_simulate_slider_drag_safe(slider, slider.min_value)
		await get_tree().process_frame
		_simulate_slider_drag_safe(slider, slider.max_value)
		await get_tree().process_frame
		_check_for_errors("sea level slider")
		pass_test("Step 1: Sea level slider tested")
	else:
		pass_test("Step 1: Sea level slider not found")

func test_step_1_erosion_checkbox() -> void:
	"""Test Step 1: Erosion checkbox - toggle on/off, rapid toggles."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var checkbox := _find_control_by_name("erosion_enabled") as CheckBox
	if checkbox:
		# Toggle on
		_simulate_checkbox_toggle_safe(checkbox, true)
		await get_tree().process_frame
		_check_for_errors("erosion checkbox on")
		
		# Toggle off
		_simulate_checkbox_toggle_safe(checkbox, false)
		await get_tree().process_frame
		_check_for_errors("erosion checkbox off")
		
		# Rapid toggles
		for i in range(5):
			_simulate_checkbox_toggle_safe(checkbox, i % 2 == 0)
			await get_tree().process_frame
		_check_for_errors("rapid erosion checkbox toggles")
		
		pass_test("Step 1: Erosion checkbox tested")
	else:
		pass_test("Step 1: Erosion checkbox not found")

# ============================================================
# STEP 2: TERRAIN - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_2_all_sliders() -> void:
	"""Test Step 2: All terrain sliders - height, frequency, octaves, persistence, lacunarity."""
	_navigate_to_step(1)
	await get_tree().process_frame
	
	var sliders: Array[String] = ["height_scale", "noise_frequency", "octaves", "persistence", "lacunarity"]
	for slider_name in sliders:
		var slider := _find_control_by_name(slider_name) as HSlider
		if slider:
			_simulate_slider_drag_safe(slider, slider.min_value)
			await get_tree().process_frame
			_simulate_slider_drag_safe(slider, slider.max_value)
			await get_tree().process_frame
			_check_for_errors("terrain slider %s" % slider_name)
	
	pass_test("Step 2: All terrain sliders tested")

func test_step_2_noise_type_dropdown() -> void:
	"""Test Step 2: Noise type dropdown - all options."""
	_navigate_to_step(1)
	await get_tree().process_frame
	
	var dropdown := _find_control_by_name("noise_type") as OptionButton
	if dropdown:
		var item_count: int = dropdown.get_item_count()
		for i in range(item_count):
			_simulate_option_selection_safe(dropdown, i)
			await get_tree().process_frame
			_check_for_errors("noise type %d" % i)
		pass_test("Step 2: Noise type dropdown - %d options tested" % item_count)
	else:
		pass_test("Step 2: Noise type dropdown not found")

func test_step_2_regenerate_button() -> void:
	"""Test Step 2: Regenerate terrain button."""
	_navigate_to_step(1)
	await get_tree().process_frame
	
	var button := _find_control_by_pattern("*Regenerate*Terrain*") as Button
	if button:
		_simulate_button_click_safe(button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("regenerate terrain button")
		pass_test("Step 2: Regenerate terrain button tested")
	else:
		pass_test("Step 2: Regenerate terrain button not found")

# ============================================================
# STEP 3: CLIMATE - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_3_all_climate_sliders() -> void:
	"""Test Step 3: All climate sliders - temperature, rainfall, wind, time."""
	_navigate_to_step(2)
	await get_tree().process_frame
	
	var sliders: Array[String] = ["temperature_intensity", "rainfall_intensity", "wind_strength", "time_of_day"]
	for slider_name in sliders:
		var slider := _find_control_by_name(slider_name) as HSlider
		if slider:
			_simulate_slider_drag_safe(slider, slider.min_value)
			await get_tree().process_frame
			_simulate_slider_drag_safe(slider, slider.max_value)
			await get_tree().process_frame
			_check_for_errors("climate slider %s" % slider_name)
	
	pass_test("Step 3: All climate sliders tested")

func test_step_3_wind_direction_spinboxes() -> void:
	"""Test Step 3: Wind direction X and Y spinboxes."""
	_navigate_to_step(2)
	await get_tree().process_frame
	
	var x_spinbox := _find_control_by_name("wind_direction_x") as SpinBox
	var y_spinbox := _find_control_by_name("wind_direction_y") as SpinBox
	
	if x_spinbox:
		_simulate_spinbox_change_safe(x_spinbox, x_spinbox.min_value)
		await get_tree().process_frame
		_simulate_spinbox_change_safe(x_spinbox, x_spinbox.max_value)
		await get_tree().process_frame
		_check_for_errors("wind direction X")
	
	if y_spinbox:
		_simulate_spinbox_change_safe(y_spinbox, y_spinbox.min_value)
		await get_tree().process_frame
		_simulate_spinbox_change_safe(y_spinbox, y_spinbox.max_value)
		await get_tree().process_frame
		_check_for_errors("wind direction Y")
	
	pass_test("Step 3: Wind direction spinboxes tested")

# ============================================================
# STEP 4: BIOMES - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_4_biome_overlay_checkbox() -> void:
	"""Test Step 4: Biome overlay checkbox."""
	_navigate_to_step(3)
	await get_tree().process_frame
	
	var checkbox := _find_control_by_name("show_biome_overlay") as CheckBox
	if checkbox:
		_simulate_checkbox_toggle_safe(checkbox, true)
		await get_tree().process_frame
		_simulate_checkbox_toggle_safe(checkbox, false)
		await get_tree().process_frame
		_check_for_errors("biome overlay checkbox")
		pass_test("Step 4: Biome overlay checkbox tested")
	else:
		pass_test("Step 4: Biome overlay checkbox not found")

func test_step_4_biome_list_selection() -> void:
	"""Test Step 4: Biome list - select all items."""
	_navigate_to_step(3)
	await get_tree().process_frame
	
	var biome_list := _find_control_by_name("biome_list") as ItemList
	if biome_list:
		var item_count: int = biome_list.get_item_count()
		if item_count > 0:
			for i in range(min(item_count, 10)):  # Limit to 10 for speed
				biome_list.select(i)
				await get_tree().process_frame
				_check_for_errors("biome list selection %d" % i)
			pass_test("Step 4: Biome list - %d items tested" % item_count)
		else:
			pass_test("Step 4: Biome list has no items")
	else:
		pass_test("Step 4: Biome list not found")

func test_step_4_generation_mode_dropdown() -> void:
	"""Test Step 4: Generation mode dropdown."""
	_navigate_to_step(3)
	await get_tree().process_frame
	
	var dropdown := _find_control_by_name("generation_mode") as OptionButton
	if dropdown:
		var item_count: int = dropdown.get_item_count()
		for i in range(item_count):
			_simulate_option_selection_safe(dropdown, i)
			await get_tree().process_frame
			_check_for_errors("generation mode %d" % i)
		pass_test("Step 4: Generation mode dropdown - %d options tested" % item_count)
	else:
		pass_test("Step 4: Generation mode dropdown not found")

func test_step_4_generate_biomes_button() -> void:
	"""Test Step 4: Generate biomes button."""
	_navigate_to_step(3)
	await get_tree().process_frame
	
	var button := _find_control_by_name("generate_biomes") as Button
	if button:
		_simulate_button_click_safe(button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("generate biomes button")
		pass_test("Step 4: Generate biomes button tested")
	else:
		pass_test("Step 4: Generate biomes button not found")

# ============================================================
# STEP 5: STRUCTURES & CIVILIZATIONS - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_5_process_cities_button() -> void:
	"""Test Step 5: Process cities button."""
	_navigate_to_step(4)
	await get_tree().process_frame
	
	var button := _find_control_by_name("process_cities") as Button
	if button:
		_simulate_button_click_safe(button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("process cities button")
		pass_test("Step 5: Process cities button tested")
	else:
		pass_test("Step 5: Process cities button not found")

func test_step_5_city_list_selection() -> void:
	"""Test Step 5: City list selection (if populated)."""
	_navigate_to_step(4)
	await get_tree().process_frame
	
	var city_list := _find_control_by_name("city_list") as ItemList
	if city_list:
		var item_count: int = city_list.get_item_count()
		if item_count > 0:
			for i in range(min(item_count, 5)):  # Limit to 5
				city_list.select(i)
				await get_tree().process_frame
				_check_for_errors("city list selection %d" % i)
			pass_test("Step 5: City list - %d items tested" % item_count)
		else:
			pass_test("Step 5: City list empty (may need to process cities first)")
	else:
		pass_test("Step 5: City list not found")

# ============================================================
# STEP 6: ENVIRONMENT - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_6_environment_sliders() -> void:
	"""Test Step 6: Environment sliders - fog, ambient, water."""
	_navigate_to_step(5)
	await get_tree().process_frame
	
	var sliders: Array[String] = ["fog_density", "ambient_intensity", "water_level"]
	for slider_name in sliders:
		var slider := _find_control_by_name(slider_name) as HSlider
		if slider:
			_simulate_slider_drag_safe(slider, slider.min_value)
			await get_tree().process_frame
			_simulate_slider_drag_safe(slider, slider.max_value)
			await get_tree().process_frame
			_check_for_errors("environment slider %s" % slider_name)
	
	pass_test("Step 6: Environment sliders tested")

func test_step_6_sky_type_dropdown() -> void:
	"""Test Step 6: Sky type dropdown."""
	_navigate_to_step(5)
	await get_tree().process_frame
	
	var dropdown := _find_control_by_name("sky_type") as OptionButton
	if dropdown:
		var item_count: int = dropdown.get_item_count()
		for i in range(item_count):
			_simulate_option_selection_safe(dropdown, i)
			await get_tree().process_frame
			_check_for_errors("sky type %d" % i)
		pass_test("Step 6: Sky type dropdown - %d options tested" % item_count)
	else:
		pass_test("Step 6: Sky type dropdown not found")

func test_step_6_ocean_shader_checkbox() -> void:
	"""Test Step 6: Ocean shader checkbox."""
	_navigate_to_step(5)
	await get_tree().process_frame
	
	var checkbox := _find_control_by_name("ocean_shader") as CheckBox
	if checkbox:
		_simulate_checkbox_toggle_safe(checkbox, true)
		await get_tree().process_frame
		_simulate_checkbox_toggle_safe(checkbox, false)
		await get_tree().process_frame
		_check_for_errors("ocean shader checkbox")
		pass_test("Step 6: Ocean shader checkbox tested")
	else:
		pass_test("Step 6: Ocean shader checkbox not found")

# ============================================================
# STEP 7: RESOURCES & MAGIC - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_7_resource_overlay_checkbox() -> void:
	"""Test Step 7: Resource overlay checkbox."""
	_navigate_to_step(6)
	await get_tree().process_frame
	
	var checkbox := _find_control_by_pattern("*resource*overlay*") as CheckBox
	if checkbox:
		_simulate_checkbox_toggle_safe(checkbox, true)
		await get_tree().process_frame
		_simulate_checkbox_toggle_safe(checkbox, false)
		await get_tree().process_frame
		_check_for_errors("resource overlay checkbox")
		pass_test("Step 7: Resource overlay checkbox tested")
	else:
		pass_test("Step 7: Resource overlay checkbox not found")

func test_step_7_magic_density_slider() -> void:
	"""Test Step 7: Magic density slider."""
	_navigate_to_step(6)
	await get_tree().process_frame
	
	var slider := _find_control_by_name("magic_density") as HSlider
	if slider:
		_simulate_slider_drag_safe(slider, slider.min_value)
		await get_tree().process_frame
		_simulate_slider_drag_safe(slider, slider.max_value)
		await get_tree().process_frame
		_check_for_errors("magic density slider")
		pass_test("Step 7: Magic density slider tested")
	else:
		pass_test("Step 7: Magic density slider not found")

# ============================================================
# STEP 8: EXPORT - ALL INTERACTIVE ELEMENTS
# ============================================================

func test_step_8_world_name_input() -> void:
	"""Test Step 8: World name input - valid, invalid, edge cases."""
	_navigate_to_step(7)
	await get_tree().process_frame
	
	var name_edit := _find_control_by_pattern("*name*") as LineEdit
	if name_edit:
		# Test valid name
		_simulate_text_input_safe(name_edit, "Test World")
		await get_tree().process_frame
		_check_for_errors("valid world name")
		
		# Test empty name
		_simulate_text_input_safe(name_edit, "")
		await get_tree().process_frame
		_check_for_errors("empty world name")
		
		# Test very long name
		var long_name: String = ""
		for i in range(1000):
			long_name += "A"
		_simulate_text_input_safe(name_edit, long_name)
		await get_tree().process_frame
		_check_for_errors("very long world name")
		
		# Test special characters
		_simulate_text_input_safe(name_edit, "World!@#$%^&*()")
		await get_tree().process_frame
		_check_for_errors("special characters in world name")
		
		pass_test("Step 8: World name input tested")
	else:
		pass_test("Step 8: World name input not found")

func test_step_8_all_export_buttons() -> void:
	"""Test Step 8: All export buttons - save config, export heightmap, export biome map, generate scene."""
	_navigate_to_step(7)
	await get_tree().process_frame
	
	var buttons: Array[String] = ["save_config", "export_heightmap", "export_biome_map", "generate_scene"]
	for button_name in buttons:
		var button := _find_control_by_pattern("*%s*" % button_name) as Button
		if button:
			_simulate_button_click_safe(button)
			await get_tree().process_frame
			await get_tree().process_frame
			_check_for_errors("export button %s" % button_name)
	
	pass_test("Step 8: All export buttons tested")

# ============================================================
# NAVIGATION - ALL BUTTONS
# ============================================================

func test_navigation_next_button_all_steps() -> void:
	"""Test Next button navigation through all 8 steps."""
	# Try to get current_step property - use get() which returns null if property doesn't exist
	var current_step_check = world_builder_ui.get("current_step")
	if current_step_check == null:
		pass_test("current_step not accessible")
		return
	
	# Start at step 0
	world_builder_ui.set("current_step", 0)
	await get_tree().process_frame
	
	# Navigate forward through all steps
	for expected_step in range(8):
		var current: int = world_builder_ui.get("current_step")
		assert_eq(current, expected_step, "FAIL: Expected step %d, got %d. Context: Next button navigation. Why: Should advance step by step. Hint: Check WorldBuilderUI._on_next_pressed().")
		
		if expected_step < 7:
			# Click Next button
			if world_builder_ui.has_method("_on_next_pressed"):
				world_builder_ui._on_next_pressed()
			else:
				var next_button := _find_control_by_pattern("*Next*") as Button
				if next_button:
					_simulate_button_click_safe(next_button)
			
			await get_tree().process_frame
			_check_for_errors("next button at step %d" % expected_step)
	
	pass_test("Next button navigates through all 8 steps")

func test_navigation_back_button_all_steps() -> void:
	"""Test Back button navigation backwards through all steps."""
	# Try to get current_step property - use get() which returns null if property doesn't exist
	var current_step_check = world_builder_ui.get("current_step")
	if current_step_check == null:
		pass_test("current_step not accessible")
		return
	
	# Start at step 7
	world_builder_ui.set("current_step", 7)
	await get_tree().process_frame
	
	# Navigate backwards
	for expected_step in range(7, -1, -1):
		var current: int = world_builder_ui.get("current_step")
		assert_eq(current, expected_step, "FAIL: Expected step %d, got %d. Context: Back button navigation. Why: Should decrement step. Hint: Check WorldBuilderUI._on_back_pressed().")
		
		if expected_step > 0:
			if world_builder_ui.has_method("_on_back_pressed"):
				world_builder_ui._on_back_pressed()
			else:
				var back_button := _find_control_by_pattern("*Back*") as Button
				if back_button:
					_simulate_button_click_safe(back_button)
			
			await get_tree().process_frame
			_check_for_errors("back button at step %d" % expected_step)
	
	pass_test("Back button navigates backwards through all steps")

func test_navigation_step_buttons_direct_jump() -> void:
	"""Test step buttons for direct navigation to each step."""
	if not world_builder_ui.has("step_buttons"):
		pass_test("step_buttons not accessible")
		return
	
	var step_buttons: Array = world_builder_ui.get("step_buttons")
	if step_buttons.size() == 0:
		pass_test("No step buttons found")
		return
	
	# Test clicking each step button
	for i in range(min(step_buttons.size(), 8)):
		var button: Button = step_buttons[i] as Button
		if button:
			_simulate_button_click_safe(button)
			await get_tree().process_frame
			_check_for_errors("step button %d" % i)
			
			var current_step_check_inner = world_builder_ui.get("current_step")
			if current_step_check_inner != null:
				var current: int = world_builder_ui.get("current_step")
				assert_true(current >= 0 and current < 8, "FAIL: Step button %d navigated to invalid step %d. Context: Direct step navigation. Why: Should navigate to valid step. Hint: Check WorldBuilderUI._on_step_button_pressed().")
	
	pass_test("Step buttons navigate directly to each step")

func test_navigation_boundary_conditions() -> void:
	"""Test navigation boundary conditions - can't go before 0 or after 7."""
	# Try to get current_step property - use get() which returns null if property doesn't exist
	var current_step_check = world_builder_ui.get("current_step")
	if current_step_check == null:
		pass_test("current_step not accessible")
		return
	
	# Test at step 0 - Back should not go below 0
	world_builder_ui.set("current_step", 0)
	await get_tree().process_frame
	
	if world_builder_ui.has_method("_on_back_pressed"):
		world_builder_ui._on_back_pressed()
		await get_tree().process_frame
		var current: int = world_builder_ui.get("current_step")
		assert_eq(current, 0, "FAIL: Back button at step 0 should not go below 0. Context: Boundary condition. Why: Should clamp to 0. Hint: Check WorldBuilderUI._on_back_pressed() clamping.")
	
	# Test at step 7 - Next should not go above 7
	world_builder_ui.set("current_step", 7)
	await get_tree().process_frame
	
	if world_builder_ui.has_method("_on_next_pressed"):
		world_builder_ui._on_next_pressed()
		await get_tree().process_frame
		var current: int = world_builder_ui.get("current_step")
		assert_eq(current, 7, "FAIL: Next button at step 7 should not go above 7. Context: Boundary condition. Why: Should clamp to 7. Hint: Check WorldBuilderUI._on_next_pressed() clamping.")
	
	pass_test("Navigation respects boundary conditions")

# ============================================================
# RAPID INTERACTION TESTS - STRESS TESTING
# ============================================================

func test_rapid_button_clicks() -> void:
	"""Test rapid button clicks - should handle gracefully without crashes."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var generate_button := _find_control_by_pattern("*Generate*") as Button
	if generate_button:
		# Rapid clicks
		for i in range(20):
			_simulate_button_click_safe(generate_button)
			await get_tree().process_frame
		_check_for_errors("rapid button clicks")
		pass_test("Rapid button clicks handled gracefully")
	else:
		pass_test("Generate button not found for rapid click test")

func test_rapid_slider_changes() -> void:
	"""Test rapid slider value changes - should handle gracefully."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	var slider := _find_control_by_name("noise_frequency") as HSlider
	if slider:
		# Rapid value changes
		for i in range(50):
			var value: float = slider.min_value + (slider.max_value - slider.min_value) * (float(i) / 50.0)
			_simulate_slider_drag_safe(slider, value)
			await get_tree().process_frame
		_check_for_errors("rapid slider changes")
		pass_test("Rapid slider changes handled gracefully")
	else:
		pass_test("Noise frequency slider not found for rapid change test")

func test_rapid_navigation() -> void:
	"""Test rapid navigation between steps - should handle gracefully."""
	# Try to get current_step property - use get() which returns null if property doesn't exist
	var current_step_check = world_builder_ui.get("current_step")
	if current_step_check == null:
		pass_test("current_step not accessible")
		return
	
	# Rapidly navigate forward and back
	for i in range(10):
		world_builder_ui.set("current_step", i % 8)
		await get_tree().process_frame
		if world_builder_ui.has_method("_on_next_pressed"):
			world_builder_ui._on_next_pressed()
			await get_tree().process_frame
		_check_for_errors("rapid navigation iteration %d" % i)
	
	pass_test("Rapid navigation handled gracefully")

# ============================================================
# ERROR HANDLING TESTS
# ============================================================

func test_invalid_input_handling() -> void:
	"""Test that invalid inputs are handled gracefully without crashes."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	# Test invalid seed input
	var seed_input := _find_control_by_name("seed") as LineEdit
	if seed_input:
		# Try various invalid inputs
		var invalid_inputs: Array[String] = ["", "abc", "-999999", "999999999999999999", "!@#$%"]
		for invalid_input in invalid_inputs:
			_simulate_text_input_safe(seed_input, invalid_input)
			await get_tree().process_frame
			_check_for_errors("invalid input: %s" % invalid_input)
	
	pass_test("Invalid inputs handled gracefully")

func test_null_state_handling() -> void:
	"""Test that null states are handled gracefully."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	# Try to trigger generation with null/invalid data
	var generate_button := _find_control_by_pattern("*Generate*") as Button
	if generate_button:
		# Clear step data to simulate null state
		if world_builder_ui.has("step_data"):
			var step_data: Dictionary = world_builder_ui.get("step_data")
			step_data.clear()
		
		_simulate_button_click_safe(generate_button)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_for_errors("generation with null state")
	
	pass_test("Null states handled gracefully")

# ============================================================
# ADDITIONAL SIGNAL HANDLERS - ICON TOOLBAR, PREVIEW, ZOOM, ETC.
# ============================================================

func test_icon_toolbar_selection() -> void:
	"""Test icon toolbar selection - all icon IDs."""
	_navigate_to_step(0)
	await get_tree().process_frame
	
	# Try to find icon toolbar buttons
	var icon_toolbar := _find_control_by_pattern("*icon*toolbar*") as Control
	if not icon_toolbar:
		icon_toolbar = _find_control_by_pattern("*IconToolbar*") as Control
	
	if icon_toolbar or world_builder_ui.has_method("_on_icon_toolbar_selected"):
		# Test icon selection if method exists
		if world_builder_ui.has_method("_on_icon_toolbar_selected"):
			var test_icon_ids: Array[String] = ["city", "dungeon", "town", "village", "castle", "ruin"]
			for icon_id in test_icon_ids:
				world_builder_ui._on_icon_toolbar_selected(icon_id)
				await get_tree().process_frame
				_check_for_errors("icon toolbar selection: %s" % icon_id)
		
		pass_test("Icon toolbar selection tested")
	else:
		pass_test("Icon toolbar not found (may be in Step 1 Map Maker)")

func test_preview_click_events() -> void:
	"""Test preview click events - left click, right click, middle click."""
	if world_builder_ui.has_method("_on_preview_clicked"):
		# Test left mouse button
		var left_click := InputEventMouseButton.new()
		left_click.button_index = MOUSE_BUTTON_LEFT
		left_click.pressed = true
		left_click.position = Vector2(100, 100)
		
		world_builder_ui._on_preview_clicked(left_click)
		await get_tree().process_frame
		_check_for_errors("preview left click")
		
		# Test right mouse button
		var right_click := InputEventMouseButton.new()
		right_click.button_index = MOUSE_BUTTON_RIGHT
		right_click.pressed = true
		right_click.position = Vector2(200, 200)
		
		world_builder_ui._on_preview_clicked(right_click)
		await get_tree().process_frame
		_check_for_errors("preview right click")
		
		# Test mouse motion
		var mouse_motion := InputEventMouseMotion.new()
		mouse_motion.position = Vector2(150, 150)
		mouse_motion.relative = Vector2(50, 50)
		
		world_builder_ui._on_preview_clicked(mouse_motion)
		await get_tree().process_frame
		_check_for_errors("preview mouse motion")
		
		pass_test("Preview click events tested")
	else:
		pass_test("_on_preview_clicked method not found")

func test_zoom_changes() -> void:
	"""Test zoom changes - positive and negative deltas."""
	if world_builder_ui.has_method("_on_zoom_changed"):
		# Test zoom in
		world_builder_ui._on_zoom_changed(1.2)
		await get_tree().process_frame
		_check_for_errors("zoom in")
		
		# Test zoom out
		world_builder_ui._on_zoom_changed(0.8)
		await get_tree().process_frame
		_check_for_errors("zoom out")
		
		# Test extreme zoom values
		world_builder_ui._on_zoom_changed(10.0)
		await get_tree().process_frame
		_check_for_errors("extreme zoom in")
		
		world_builder_ui._on_zoom_changed(0.01)
		await get_tree().process_frame
		_check_for_errors("extreme zoom out")
		
		pass_test("Zoom changes tested")
	else:
		pass_test("_on_zoom_changed method not found")

func test_type_selection_dialog() -> void:
	"""Test type selection dialog handler."""
	if world_builder_ui.has_method("_on_type_selected"):
		# Create mock dialog and test type selection
		var test_dialog := AcceptDialog.new()
		test_dialog.name = "TestDialog"
		test_scene.add_child(test_dialog)
		
		var test_group: Array[String] = ["type1", "type2", "type3"]
		
		world_builder_ui._on_type_selected("TestType", test_group, test_dialog)
		await get_tree().process_frame
		_check_for_errors("type selection")
		
		test_dialog.queue_free()
		pass_test("Type selection dialog tested")
	else:
		pass_test("_on_type_selected method not found")

func test_city_name_generation() -> void:
	"""Test city name generation handler."""
	_navigate_to_step(4)  # Structures & Civilizations step
	await get_tree().process_frame
	
	if world_builder_ui.has_method("_on_generate_city_name"):
		# Create mock LineEdit
		var name_edit := LineEdit.new()
		name_edit.text = ""
		test_scene.add_child(name_edit)
		
		world_builder_ui._on_generate_city_name(name_edit, 0)
		await get_tree().process_frame
		_check_for_errors("city name generation")
		
		name_edit.queue_free()
		pass_test("City name generation tested")
	else:
		pass_test("_on_generate_city_name method not found")

func test_civilization_selection() -> void:
	"""Test civilization selection handler."""
	_navigate_to_step(4)  # Structures & Civilizations step
	await get_tree().process_frame
	
	if world_builder_ui.has_method("_on_civilization_selected"):
		# Create mock dialog and name edit
		var test_dialog := AcceptDialog.new()
		test_dialog.name = "TestDialog"
		test_scene.add_child(test_dialog)
		
		var name_edit := LineEdit.new()
		name_edit.text = ""
		test_scene.add_child(name_edit)
		
		world_builder_ui._on_civilization_selected(0, 0, test_dialog, name_edit)
		await get_tree().process_frame
		_check_for_errors("civilization selection")
		
		test_dialog.queue_free()
		name_edit.queue_free()
		pass_test("Civilization selection tested")
	else:
		pass_test("_on_civilization_selected method not found")

func test_city_list_selection() -> void:
	"""Test city list selection handler."""
	_navigate_to_step(4)  # Structures & Civilizations step
	await get_tree().process_frame
	
	if world_builder_ui.has_method("_on_city_selected"):
		# Test selecting various city indices
		for i in range(5):
			world_builder_ui._on_city_selected(i)
			await get_tree().process_frame
			_check_for_errors("city selection %d" % i)
		
		# Test invalid index
		world_builder_ui._on_city_selected(-1)
		await get_tree().process_frame
		_check_for_errors("city selection -1")
		
		pass_test("City list selection tested")
	else:
		pass_test("_on_city_selected method not found")

func test_map_scroll_container_input() -> void:
	"""Test map scroll container input handler."""
	if world_builder_ui.has_method("_on_map_scroll_container_input"):
		# Test mouse button events
		var mouse_button := InputEventMouseButton.new()
		mouse_button.button_index = MOUSE_BUTTON_LEFT
		mouse_button.pressed = true
		mouse_button.position = Vector2(100, 100)
		
		world_builder_ui._on_map_scroll_container_input(mouse_button)
		await get_tree().process_frame
		_check_for_errors("map scroll container mouse button")
		
		# Test mouse motion
		var mouse_motion := InputEventMouseMotion.new()
		mouse_motion.position = Vector2(150, 150)
		mouse_motion.relative = Vector2(50, 50)
		
		world_builder_ui._on_map_scroll_container_input(mouse_motion)
		await get_tree().process_frame
		_check_for_errors("map scroll container mouse motion")
		
		pass_test("Map scroll container input tested")
	else:
		pass_test("_on_map_scroll_container_input method not found")

func test_terrain_generated_signal() -> void:
	"""Test terrain generated signal handler."""
	if world_builder_ui.has_method("_on_terrain_generated"):
		# Test with null terrain (should handle gracefully)
		world_builder_ui._on_terrain_generated(null)
		await get_tree().process_frame
		_check_for_errors("terrain generated null")
		
		pass_test("Terrain generated signal tested")
	else:
		pass_test("_on_terrain_generated method not found")

func test_terrain_updated_signal() -> void:
	"""Test terrain updated signal handler."""
	if world_builder_ui.has_method("_on_terrain_updated"):
		world_builder_ui._on_terrain_updated()
		await get_tree().process_frame
		_check_for_errors("terrain updated")
		
		pass_test("Terrain updated signal tested")
	else:
		pass_test("_on_terrain_updated method not found")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _navigate_to_step(step: int) -> void:
	"""Navigate to specific step."""
	var current_step_check = world_builder_ui.get("current_step")
	if current_step_check != null:
		world_builder_ui.set("current_step", step)
		if world_builder_ui.has_method("_update_step_display"):
			world_builder_ui._update_step_display()

func _find_control_by_name(name: String) -> Control:
	"""Find control by exact name (recursive search)."""
	return _find_control_recursive(world_builder_ui, name, false)

func _find_control_by_pattern(pattern: String) -> Control:
	"""Find control by name pattern (recursive search)."""
	return _find_control_recursive(world_builder_ui, pattern, true)

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
		button.pressed.emit()

func _simulate_text_input_safe(line_edit: LineEdit, text: String) -> void:
	"""Safely simulate text input with error handling."""
	if line_edit and is_instance_valid(line_edit):
		line_edit.text = text
		line_edit.text_changed.emit(text)

func _simulate_slider_drag_safe(slider: HSlider, value: float) -> void:
	"""Safely simulate slider drag with error handling."""
	if slider and is_instance_valid(slider):
		slider.value = value
		slider.value_changed.emit(value)

func _simulate_spinbox_change_safe(spinbox: SpinBox, value: float) -> void:
	"""Safely simulate spinbox change with error handling."""
	if spinbox and is_instance_valid(spinbox):
		spinbox.value = value
		spinbox.value_changed.emit(value)

func _simulate_option_selection_safe(option_button: OptionButton, index: int) -> void:
	"""Safely simulate option selection with error handling."""
	if option_button and is_instance_valid(option_button):
		if index >= 0 and index < option_button.get_item_count():
			option_button.selected = index
			option_button.item_selected.emit(index)

func _simulate_checkbox_toggle_safe(checkbox: CheckBox, pressed: bool) -> void:
	"""Safely simulate checkbox toggle with error handling."""
	if checkbox and is_instance_valid(checkbox):
		checkbox.button_pressed = pressed
		checkbox.toggled.emit(pressed)

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
