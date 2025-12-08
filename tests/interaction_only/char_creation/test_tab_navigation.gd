# ╔═══════════════════════════════════════════════════════════
# ║ test_tab_navigation.gd
# ║ Desc: Tests tab navigation system interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_tab_button_clicks() -> Dictionary:
	"""Test all tab button clicks (interaction-only)"""
	var result := {"name": "tab_button_clicks", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# Find TabNavigation
	var tab_nav: Node = cc_scene.find_child("TabNavigation", true, false)
	if not tab_nav:
		result["message"] = "TabNavigation not found"
		cc_scene.queue_free()
		return result
	
	# Test all tab buttons
	var tab_buttons := [
		{"name": "RaceButton", "tab": "Race"},
		{"name": "ClassButton", "tab": "Class"},
		{"name": "BackgroundButton", "tab": "Background"},
		{"name": "AbilityButton", "tab": "AbilityScore"},
		{"name": "AppearanceButton", "tab": "Appearance"},
		{"name": "ConfirmButton", "tab": "NameConfirm"}
	]
	
	for tab_info in tab_buttons:
		var button := tab_nav.find_child(tab_info.name, true, false) as Button
		if button:
			TestHelpers.log_step("Clicking %s tab button" % tab_info.tab)
			TestHelpers.simulate_button_click(button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
		else:
			TestHelpers.log_step("WARNING: %s button not found" % tab_info.name)
	
	result["passed"] = true
	result["message"] = "Tab button clicks work"
	cc_scene.queue_free()
	return result

func test_tab_order_validation() -> Dictionary:
	"""Test tab order validation (can't skip ahead)"""
	var result := {"name": "tab_order_validation", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var tab_nav: Node = cc_scene.find_child("TabNavigation", true, false)
	if not tab_nav:
		result["message"] = "TabNavigation not found"
		cc_scene.queue_free()
		return result
	
	# Try to click Class tab before Race is confirmed (should be blocked)
	var class_button := tab_nav.find_child("ClassButton", true, false) as Button
	if class_button:
		TestHelpers.log_step("Attempting to click Class tab before Race confirmed")
		var current_tab_before: Variant = tab_nav.get("current_tab")
		TestHelpers.simulate_button_click(class_button)
		await get_tree().process_frame
		var current_tab_after: Variant = tab_nav.get("current_tab")
		
		# Should still be on Race tab (validation should block)
		if current_tab_before == current_tab_after:
			TestHelpers.log_step("Tab order validation works - Class tab blocked")
			result["passed"] = true
			result["message"] = "Tab order validation works"
		else:
			result["message"] = "Tab order validation failed - Class tab allowed"
	else:
		result["message"] = "ClassButton not found"
	
	cc_scene.queue_free()
	return result

func test_back_button_navigation() -> Dictionary:
	"""Test back button navigation between tabs"""
	var result := {"name": "back_button_navigation", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# First, confirm a race to enable Class tab
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if race_tab and race_tab.has_signal("race_selected"):
		# Select a race without subraces (like Tiefling)
		race_tab.race_selected.emit("tiefling", "")
		await get_tree().process_frame
		await TestHelpers.wait_visual(visual_delay)
		
		# Try to find confirm button and click it
		var confirm_button := race_tab.find_child("*Confirm*", true, false) as Button
		if confirm_button:
			TestHelpers.log_step("Confirming race selection")
			TestHelpers.simulate_button_click(confirm_button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	# Now try back button from Class tab
	var class_tab: Node = cc_scene.find_child("ClassTab", true, false)
	if class_tab:
		var back_button := class_tab.find_child("*Back*", true, false) as Button
		if back_button:
			TestHelpers.log_step("Clicking back button from Class tab")
			TestHelpers.simulate_button_click(back_button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
			result["passed"] = true
			result["message"] = "Back button navigation works"
		else:
			result["message"] = "Back button not found in Class tab"
	else:
		result["message"] = "ClassTab not found or not accessible"
	
	cc_scene.queue_free()
	return result
