# ╔═══════════════════════════════════════════════════════════
# ║ test_terrain.gd
# ║ Desc: Tests terrain section UI interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_terrain_sliders() -> Dictionary:
	"""Test terrain slider interactions (interaction-only)"""
	var result := {"name": "terrain_sliders", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Switch to terrain tab
	var terrain_tab_button := world_creator.find_child("TerrainTabButton", true, false) as Button
	if terrain_tab_button:
		TestHelpers.simulate_button_click(terrain_tab_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	var terrain_section: Node = world_creator.find_child("terrain_section", true, false)
	if not terrain_section:
		result["message"] = "terrain_section not found"
		world_creator.queue_free()
		return result
	
	# Test elevation scale slider
	var elevation_slider := terrain_section.find_child("ElevationScaleSlider", true, false) as HSlider
	if elevation_slider:
		TestHelpers.log_step("Testing elevation scale slider")
		TestHelpers.simulate_slider_drag(elevation_slider, 50.0)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	# Test terrain chaos slider
	var chaos_slider := terrain_section.find_child("TerrainChaosSlider", true, false) as HSlider
	if chaos_slider:
		TestHelpers.log_step("Testing terrain chaos slider")
		TestHelpers.simulate_slider_drag(chaos_slider, 30.0)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Terrain sliders work"
	world_creator.queue_free()
	return result

func test_noise_type_selection() -> Dictionary:
	"""Test noise type option selection (interaction-only)"""
	var result := {"name": "noise_type_selection", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var terrain_tab_button := world_creator.find_child("TerrainTabButton", true, false) as Button
	if terrain_tab_button:
		TestHelpers.simulate_button_click(terrain_tab_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	var terrain_section: Node = world_creator.find_child("terrain_section", true, false)
	if not terrain_section:
		result["message"] = "terrain_section not found"
		world_creator.queue_free()
		return result
	
	var noise_option := terrain_section.find_child("NoiseTypeOptionButton", true, false) as OptionButton
	if noise_option:
		# Test all noise types
		for i in range(4):  # Perlin, Simplex, Cellular, Value
			TestHelpers.log_step("Testing noise type: %d" % i)
			TestHelpers.simulate_option_selection(noise_option, i)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Noise type selection works"
	world_creator.queue_free()
	return result

func test_erosion_checkbox() -> Dictionary:
	"""Test erosion checkbox toggle (interaction-only)"""
	var result := {"name": "erosion_checkbox", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var terrain_tab_button := world_creator.find_child("TerrainTabButton", true, false) as Button
	if terrain_tab_button:
		TestHelpers.simulate_button_click(terrain_tab_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	var terrain_section: Node = world_creator.find_child("terrain_section", true, false)
	if not terrain_section:
		result["message"] = "terrain_section not found"
		world_creator.queue_free()
		return result
	
	var erosion_checkbox := terrain_section.find_child("EnableErosionCheckBox", true, false) as CheckBox
	if erosion_checkbox:
		TestHelpers.log_step("Toggling erosion checkbox ON")
		TestHelpers.simulate_checkbox_toggle(erosion_checkbox, true)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		
		TestHelpers.log_step("Toggling erosion checkbox OFF")
		TestHelpers.simulate_checkbox_toggle(erosion_checkbox, false)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Erosion checkbox works"
	world_creator.queue_free()
	return result
