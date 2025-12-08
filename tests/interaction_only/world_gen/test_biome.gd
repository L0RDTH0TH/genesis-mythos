# ╔═══════════════════════════════════════════════════════════
# ║ test_biome.gd
# ║ Desc: Tests biome section UI interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_biome_tab_switch() -> Dictionary:
	"""Test switching to biome tab (interaction-only)"""
	var result := {"name": "biome_tab_switch", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var biome_tab_button := world_creator.find_child("BiomesTabButton", true, false) as Button
	if not biome_tab_button:
		result["message"] = "BiomesTabButton not found"
		world_creator.queue_free()
		return result
	
	TestHelpers.log_step("Clicking Biomes tab button")
	TestHelpers.simulate_button_click(biome_tab_button)
	await TestHelpers.wait_visual(visual_delay)
	await get_tree().process_frame
	
	var biome_section: Node = world_creator.find_child("biome_section", true, false)
	if biome_section:
		result["passed"] = true
		result["message"] = "Biome tab switch works"
	else:
		result["message"] = "Biome section not loaded after tab switch"
	
	world_creator.queue_free()
	return result

func test_biome_controls() -> Dictionary:
	"""Test biome control interactions (interaction-only)"""
	var result := {"name": "biome_controls", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var biome_tab_button := world_creator.find_child("BiomesTabButton", true, false) as Button
	if biome_tab_button:
		TestHelpers.simulate_button_click(biome_tab_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	var biome_section: Node = world_creator.find_child("biome_section", true, false)
	if biome_section:
		# Test any controls in biome section
		var sliders := []
		_find_all_sliders(biome_section, sliders)
		for slider in sliders:
			if slider is HSlider:
				TestHelpers.log_step("Testing biome slider: %s" % slider.name)
				TestHelpers.simulate_slider_drag(slider, 50.0)
				await TestHelpers.wait_visual(visual_delay * 0.5)
				await get_tree().process_frame
		
		result["passed"] = true
		result["message"] = "Biome controls work"
	else:
		result["message"] = "Biome section not found"
	
	world_creator.queue_free()
	return result

func _find_all_sliders(node: Node, sliders: Array) -> void:
	"""Recursively find all sliders"""
	if node is HSlider:
		sliders.append(node)
	for child in node.get_children():
		_find_all_sliders(child, sliders)
