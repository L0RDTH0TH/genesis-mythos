# ╔═══════════════════════════════════════════════════════════
# ║ test_climate.gd
# ║ Desc: Tests climate section UI interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_climate_tab_switch() -> Dictionary:
	"""Test switching to climate tab (interaction-only)"""
	var result := {"name": "climate_tab_switch", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var climate_tab_button := world_creator.find_child("ClimateTabButton", true, false) as Button
	if not climate_tab_button:
		result["message"] = "ClimateTabButton not found"
		world_creator.queue_free()
		return result
	
	TestHelpers.log_step("Clicking Climate tab button")
	TestHelpers.simulate_button_click(climate_tab_button)
	await TestHelpers.wait_visual(visual_delay)
	await get_tree().process_frame
	
	var climate_section: Node = world_creator.find_child("climate_section", true, false)
	if climate_section:
		result["passed"] = true
		result["message"] = "Climate tab switch works"
	else:
		result["message"] = "Climate section not loaded after tab switch"
	
	world_creator.queue_free()
	return result

func test_climate_controls() -> Dictionary:
	"""Test climate control interactions (interaction-only)"""
	var result := {"name": "climate_controls", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var climate_tab_button := world_creator.find_child("ClimateTabButton", true, false) as Button
	if climate_tab_button:
		TestHelpers.simulate_button_click(climate_tab_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	var climate_section: Node = world_creator.find_child("climate_section", true, false)
	if climate_section:
		# Test any sliders/spinboxes in climate section
		var sliders := []
		_find_all_sliders(climate_section, sliders)
		for slider in sliders:
			if slider is HSlider:
				TestHelpers.log_step("Testing climate slider: %s" % slider.name)
				TestHelpers.simulate_slider_drag(slider, 50.0)
				await TestHelpers.wait_visual(visual_delay * 0.5)
				await get_tree().process_frame
		
		result["passed"] = true
		result["message"] = "Climate controls work"
	else:
		result["message"] = "Climate section not found"
	
	world_creator.queue_free()
	return result

func _find_all_sliders(node: Node, sliders: Array) -> void:
	"""Recursively find all sliders"""
	if node is HSlider:
		sliders.append(node)
	for child in node.get_children():
		_find_all_sliders(child, sliders)
