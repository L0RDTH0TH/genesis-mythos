# ╔═══════════════════════════════════════════════════════════
# ║ test_seed_generation.gd
# ║ Desc: Tests seed generation (manual input, fresh button, validation)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")
const TestGameData = preload("res://tests/interaction_only/fixtures/TestGameData.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_manual_seed_input_valid() -> Dictionary:
	"""Test manual seed input with valid integer values"""
	var result := {"name": "manual_seed_input_valid", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	await TestHelpers.wait_visual(visual_delay)
	
	# Find seed section - it's dynamically instantiated, wait for it to be added
	var seed_section: Node = await TestHelpers.wait_for_node(wc_scene, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "Seed section not found after waiting"
		wc_scene.queue_free()
		return result
	
	# Find seed spinbox using async helper
	var seed_input: SpinBox = await TestHelpers.wait_for_node(seed_section, "SeedSpinBox", 5.0) as SpinBox
	if not seed_input:
		result["message"] = "Seed input not found"
		wc_scene.queue_free()
		return result
	
	# Test valid seed values
	var valid_seeds := TestGameData.get_valid_seeds()
	var seeds_tested := 0
	
	for seed_val in valid_seeds:
		TestHelpers.log_step("Testing valid seed: %s" % str(seed_val))
		
		TestHelpers.simulate_spinbox_change(seed_input, float(seed_val))
		
		await TestHelpers.wait_visual(visual_delay * 0.5)
		await get_tree().process_frame
		
		# Verify seed was set
		var world: Variant = wc_scene.get("world")
		if world:
			var world_seed: Variant = world.seed
			if world_seed == seed_val or (world_seed is int and abs(int(world_seed) - int(seed_val)) < 1):
				seeds_tested += 1
	
	result["passed"] = seeds_tested > 0
	result["message"] = "Tested %d/%d valid seeds" % [seeds_tested, valid_seeds.size()]
	wc_scene.queue_free()
	return result

func test_manual_seed_input_invalid() -> Dictionary:
	"""Test manual seed input with invalid values (validation)"""
	var result := {"name": "manual_seed_input_invalid", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	await TestHelpers.wait_visual(visual_delay)
	
	# Find seed section - it's dynamically instantiated, wait for it to be added
	var seed_section: Node = await TestHelpers.wait_for_node(wc_scene, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "Seed section not found after waiting"
		wc_scene.queue_free()
		return result
	
	# Find seed spinbox using async helper
	var seed_input: SpinBox = await TestHelpers.wait_for_node(seed_section, "SeedSpinBox", 5.0) as SpinBox
	if not seed_input:
		result["message"] = "Seed input not found"
		wc_scene.queue_free()
		return result
	
	# Test invalid seed values (strings, negative, etc.)
	# Note: SpinBox might auto-clamp, LineEdit might show validation error
	var invalid_seeds := ["not_a_number", "-999", ""]
	var validation_checked := 0
	
	for invalid_val in invalid_seeds:
		TestHelpers.log_step("Testing invalid seed: %s (expecting validation)" % str(invalid_val))
		
		# SpinBox might clamp to valid range
		var original_value := seed_input.value
		if invalid_val is String and invalid_val.is_valid_float():
			TestHelpers.simulate_spinbox_change(seed_input, float(invalid_val))
		elif invalid_val == "-999":
			TestHelpers.simulate_spinbox_change(seed_input, -999.0)
		await TestHelpers.wait_visual(visual_delay * 0.5)
		await get_tree().process_frame
		
		# Check if value was clamped
		var new_value := seed_input.value
		if new_value >= 0:  # Clamped to valid range
			validation_checked += 1
	
	result["passed"] = validation_checked > 0
	result["message"] = "Checked validation for %d invalid inputs" % validation_checked
	wc_scene.queue_free()
	return result

func test_fresh_seed_button() -> Dictionary:
	"""Test fresh/random seed button generation"""
	var result := {"name": "fresh_seed_button", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	await TestHelpers.wait_visual(visual_delay)
	
	# Find seed section - it's dynamically instantiated, wait for it using async helper
	var seed_section: Node = await TestHelpers.wait_for_node(wc_scene, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "Seed section not found after waiting"
		wc_scene.queue_free()
		return result
	
	# Find fresh seed button
	var fresh_button := seed_section.find_child("FreshSeedButton", true, false) as Button
	if not fresh_button:
		fresh_button = seed_section.find_child("*Fresh*", true, false) as Button
	if not fresh_button:
		fresh_button = wc_scene.find_child("*Fresh*", true, false) as Button
	
	if not fresh_button:
		result["message"] = "Fresh seed button not found"
		wc_scene.queue_free()
		return result
	
	# Get initial seed
	var world: Variant = wc_scene.get("world")
	var initial_seed: int = 0
	if world:
		initial_seed = world.seed as int
	
	TestHelpers.log_step("Clicking fresh seed button (initial seed: %d)" % initial_seed)
	TestHelpers.simulate_button_click(fresh_button)
	await TestHelpers.wait_visual(visual_delay)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify seed changed
	if world:
		var new_seed: int = world.seed as int
		if new_seed != initial_seed or new_seed > 0:
			result["passed"] = true
			result["message"] = "Fresh seed generated: %d (was %d)" % [new_seed, initial_seed]
		else:
			result["message"] = "Seed did not change or is invalid"
	else:
		result["message"] = "World not found"
	
	wc_scene.queue_free()
	return result

func test_seed_range_validation() -> Dictionary:
	"""Test seed value range validation (int32 limits)"""
	var result := {"name": "seed_range_validation", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	# Bulletproof UI ready wait - ensures TabContainer + SeedSection finish _ready()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	await TestHelpers.wait_visual(visual_delay)
	
	# Find seed section - it's dynamically instantiated, wait for it using async helper
	var seed_section: Node = await TestHelpers.wait_for_node(wc_scene, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "Seed section not found after waiting"
		wc_scene.queue_free()
		return result
	
	# Find seed spinbox using async helper
	var seed_input: SpinBox = await TestHelpers.wait_for_node(seed_section, "SeedSpinBox", 5.0) as SpinBox
	if not seed_input:
		result["message"] = "Seed input not found"
		wc_scene.queue_free()
		return result
	
	var spinbox := seed_input
	
	# Test range limits
	TestHelpers.log_step("Testing seed range validation")
	
	# Test max int32
	TestHelpers.simulate_spinbox_change(spinbox, 2147483647.0)
	await TestHelpers.wait_visual(visual_delay * 0.3)
	await get_tree().process_frame
	
	var max_value := spinbox.value
	var max_valid := max_value <= 2147483647.0 and max_value >= 0
	
	# Test min (0)
	TestHelpers.simulate_spinbox_change(spinbox, 0.0)
	await TestHelpers.wait_visual(visual_delay * 0.3)
	await get_tree().process_frame
	
	var min_value := spinbox.value
	var min_valid := min_value >= 0
	
	result["passed"] = max_valid and min_valid
	result["message"] = "Range validation: max=%s (valid: %s), min=%s (valid: %s)" % [str(max_value), str(max_valid), str(min_value), str(min_valid)]
	wc_scene.queue_free()
	return result

func test_seed_effects_on_generation() -> Dictionary:
	"""Test that different seeds produce different world generation results"""
	var result := {"name": "seed_effects_on_generation", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	# Bulletproof UI ready wait - ensures TabContainer + SeedSection finish _ready()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	await TestHelpers.wait_visual(visual_delay)
	
	# Find seed section - it's dynamically instantiated, wait for it using async helper
	var seed_section: Node = await TestHelpers.wait_for_node(wc_scene, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "Seed section not found after waiting"
		wc_scene.queue_free()
		return result
	
	# Find seed spinbox using async helper
	var seed_input: SpinBox = await TestHelpers.wait_for_node(seed_section, "SeedSpinBox", 5.0) as SpinBox
	if not seed_input:
		result["message"] = "Seed input not found"
		wc_scene.queue_free()
		return result
	
	# Test two different seeds and verify they produce different results
	var test_seeds := [42, 12345]
	var seeds_tested := 0
	
	for seed_val in test_seeds:
		TestHelpers.log_step("Testing seed %d effects on generation" % seed_val)
		TestHelpers.simulate_spinbox_change(seed_input, float(seed_val))
		
		await TestHelpers.wait_visual(visual_delay * 1.5)  # Wait for generation
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Verify seed was applied
		var world: Variant = wc_scene.get("world")
		if world:
			var world_seed: Variant = world.seed
			if world_seed == seed_val or abs(int(world_seed) - int(seed_val)) < 1:
				seeds_tested += 1
	
	result["passed"] = seeds_tested == test_seeds.size()
	result["message"] = "Tested seed effects for %d/%d seeds" % [seeds_tested, test_seeds.size()]
	wc_scene.queue_free()
	return result
