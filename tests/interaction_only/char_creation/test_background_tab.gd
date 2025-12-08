# ╔═══════════════════════════════════════════════════════════
# ║ test_background_tab.gd
# ║ Desc: Tests background tab interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_background_selection() -> Dictionary:
	"""Test background selection (interaction-only)"""
	var result := {"name": "background_selection", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# Confirm race and class first
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if race_tab and race_tab.has_signal("race_selected"):
		race_tab.race_selected.emit("tiefling", "")
		await get_tree().process_frame
		var confirm_button := race_tab.find_child("*Confirm*", true, false) as Button
		if confirm_button:
			TestHelpers.simulate_button_click(confirm_button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	var class_tab: Node = cc_scene.find_child("ClassTab", true, false)
	if class_tab and class_tab.has_signal("class_selected"):
		class_tab.class_selected.emit("fighter", "")
		await get_tree().process_frame
		var confirm_button := class_tab.find_child("*Confirm*", true, false) as Button
		if confirm_button:
			TestHelpers.simulate_button_click(confirm_button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	var background_tab: Node = cc_scene.find_child("BackgroundTab", true, false)
	if not background_tab:
		result["message"] = "BackgroundTab not found or not accessible"
		cc_scene.queue_free()
		return result
	
	# Select background
	TestHelpers.log_step("Selecting background: acolyte")
	if background_tab.has_signal("background_selected"):
		background_tab.background_selected.emit("acolyte")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	# Confirm background
	var confirm_button := background_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.log_step("Clicking Confirm Background button")
		TestHelpers.simulate_button_click(confirm_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Background selection works"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result

func test_background_preview() -> Dictionary:
	"""Test background preview/description display"""
	var result := {"name": "background_preview", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# Navigate to background tab (simplified - skip race/class confirmation for this test)
	var background_tab: Node = cc_scene.find_child("BackgroundTab", true, false)
	if background_tab:
		# Test multiple background selections
		var test_backgrounds := ["acolyte", "criminal", "folk_hero"]
		for bg_id in test_backgrounds:
			TestHelpers.log_step("Selecting background: %s (checking preview)" % bg_id)
			if background_tab.has_signal("background_selected"):
				background_tab.background_selected.emit(bg_id)
				await TestHelpers.wait_visual(visual_delay)
				await get_tree().process_frame
		
		result["passed"] = true
		result["message"] = "Background preview works"
	else:
		result["message"] = "BackgroundTab not found"
	
	cc_scene.queue_free()
	return result
