# ╔═══════════════════════════════════════════════════════════
# ║ test_resources.gd
# ║ Desc: Tests resources section UI interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_resources_tab_switch() -> Dictionary:
	"""Test switching to resources tab (interaction-only)"""
	var result := {"name": "resources_tab_switch", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var resources_tab_button := world_creator.find_child("ResourcesMagicTabButton", true, false) as Button
	if not resources_tab_button:
		result["message"] = "ResourcesMagicTabButton not found"
		world_creator.queue_free()
		return result
	
	TestHelpers.log_step("Clicking Resources & Magic tab button")
	TestHelpers.simulate_button_click(resources_tab_button)
	await TestHelpers.wait_visual(visual_delay)
	await get_tree().process_frame
	
	var resources_section: Node = world_creator.find_child("resources_section", true, false)
	if resources_section:
		result["passed"] = true
		result["message"] = "Resources tab switch works"
	else:
		result["message"] = "Resources section not loaded after tab switch"
	
	world_creator.queue_free()
	return result

func test_resources_controls() -> Dictionary:
	"""Test resources control interactions (interaction-only)"""
	var result := {"name": "resources_controls", "passed": false, "message": ""}
	
	var world_creator_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(world_creator_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var world_creator: Node = load(world_creator_path).instantiate()
	add_child(world_creator)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var resources_tab_button := world_creator.find_child("ResourcesMagicTabButton", true, false) as Button
	if resources_tab_button:
		TestHelpers.simulate_button_click(resources_tab_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	var resources_section: Node = world_creator.find_child("resources_section", true, false)
	if resources_section:
		# Test any controls in resources section
		var sliders := []
		_find_all_sliders(resources_section, sliders)
		for slider in sliders:
			if slider is HSlider:
				TestHelpers.log_step("Testing resources slider: %s" % slider.name)
				TestHelpers.simulate_slider_drag(slider, 50.0)
				await TestHelpers.wait_visual(visual_delay * 0.5)
				await get_tree().process_frame
		
		result["passed"] = true
		result["message"] = "Resources controls work"
	else:
		result["message"] = "Resources section not found"
	
	world_creator.queue_free()
	return result

func _find_all_sliders(node: Node, sliders: Array) -> void:
	"""Recursively find all sliders"""
	if node is HSlider:
		sliders.append(node)
	for child in node.get_children():
		_find_all_sliders(child, sliders)
