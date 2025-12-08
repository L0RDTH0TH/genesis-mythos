# ╔═══════════════════════════════════════════════════════════
# ║ test_seed_size.gd
# ║ Desc: Tests seed & size section UI interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_seed_spinbox_change() -> Dictionary:
	"""Test seed spinbox value change (interaction-only)"""
	var result := {"name": "seed_spinbox_change", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	
	# Find seed_size section - it's dynamically instantiated, wait for it
	var seed_section: Node = await TestHelpers.wait_for_node(world_creator, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "seed_size_section not found"
		world_creator.queue_free()
		return result
	
	# Find seed spinbox using async helper
	var seed_spinbox: SpinBox = await TestHelpers.wait_for_node(seed_section, "SeedSpinBox", 5.0) as SpinBox
	if not seed_spinbox:
		result["message"] = "SeedSpinBox not found"
		world_creator.queue_free()
		return result
	
	# Test seed value changes (interaction-only)
	var test_seeds := [42, 1337, 99999, 0, -1]
	for seed_val in test_seeds:
		TestHelpers.log_step("Testing seed value: %d" % seed_val)
		TestHelpers.simulate_spinbox_change(seed_spinbox, float(seed_val))
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Seed spinbox changes work"
	world_creator.queue_free()
	return result

func test_fresh_seed_button() -> Dictionary:
	"""Test fresh seed button click (interaction-only)"""
	var result := {"name": "fresh_seed_button", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	# Bulletproof UI ready wait - ensures TabContainer + SeedSection finish _ready()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	
	# Find seed section - it's dynamically instantiated, wait for it using async helper
	var seed_section: Node = await TestHelpers.wait_for_node(world_creator, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "seed_size_section not found after waiting"
		world_creator.queue_free()
		return result
	
	var fresh_seed_button := seed_section.find_child("FreshSeedButton", true, false) as Button
	if not fresh_seed_button:
		# Fallback search
		fresh_seed_button = seed_section.find_child("*Fresh*", true, false) as Button
	if not fresh_seed_button:
		result["message"] = "FreshSeedButton not found"
		world_creator.queue_free()
		return result
	
	# Test fresh seed button (interaction-only)
	TestHelpers.log_step("Clicking fresh seed button")
	TestHelpers.simulate_button_click(fresh_seed_button)
	await TestHelpers.wait_visual(visual_delay)
	await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Fresh seed button works"
	world_creator.queue_free()
	return result

func test_size_option_change() -> Dictionary:
	"""Test size option button selection (interaction-only)"""
	var result := {"name": "size_option_change", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	# Bulletproof UI ready wait - ensures TabContainer + SeedSection finish _ready()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete and load sections
	
	# Find seed section - it's dynamically instantiated, wait for it using async helper
	var seed_section: Node = await TestHelpers.wait_for_node(world_creator, "seed_size_section", 10.0)
	if not seed_section:
		result["message"] = "seed_size_section not found after waiting"
		world_creator.queue_free()
		return result
	
	var size_option := seed_section.find_child("SizeOptionButton", true, false) as OptionButton
	if not size_option:
		result["message"] = "SizeOptionButton not found"
		world_creator.queue_free()
		return result
	
	# Test size option changes (interaction-only)
	var size_options := [0, 1, 2, 3, 4]  # All 5 size presets
	for size_idx in size_options:
		TestHelpers.log_step("Testing size option: %d" % size_idx)
		TestHelpers.simulate_option_selection(size_option, size_idx)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Size option changes work"
	world_creator.queue_free()
	return result
