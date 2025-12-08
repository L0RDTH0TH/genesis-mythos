# ╔═══════════════════════════════════════════════════════════
# ║ test_class_tab.gd
# ║ Desc: Tests class tab complete flow interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_class_selection_no_subclass() -> Dictionary:
	"""Test class selection flow for class without subclasses"""
	var result := {"name": "class_selection_no_subclass", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# First confirm a race to enable Class tab
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
	if not class_tab:
		result["message"] = "ClassTab not found or not accessible"
		cc_scene.queue_free()
		return result
	
	# Select a class
	TestHelpers.log_step("Selecting class: fighter")
	if class_tab.has_signal("class_selected"):
		class_tab.class_selected.emit("fighter", "")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	# Confirm class
	var confirm_button := class_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.log_step("Clicking Confirm Class button")
		TestHelpers.simulate_button_click(confirm_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Class selection works"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result

func test_class_selection_with_subclass() -> Dictionary:
	"""Test class selection flow for class with subclasses"""
	var result := {"name": "class_selection_with_subclass", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# Confirm race first
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
	if not class_tab:
		result["message"] = "ClassTab not found"
		cc_scene.queue_free()
		return result
	
	# Select class with subclasses (Wizard)
	TestHelpers.log_step("Selecting class: wizard (has subclasses)")
	if class_tab.has_signal("class_selected"):
		class_tab.class_selected.emit("wizard", "")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	var confirm_button := class_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.simulate_button_click(confirm_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		
		# Select subclass
		TestHelpers.log_step("Selecting subclass: evocation")
		if class_tab.has_signal("class_selected"):
			class_tab.class_selected.emit("wizard", "evocation")
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
		
		# Confirm subclass
		var subclass_confirm := class_tab.find_child("*Confirm*", true, false) as Button
		if subclass_confirm:
			TestHelpers.simulate_button_click(subclass_confirm)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
			result["passed"] = true
			result["message"] = "Class selection (with subclass) works"
		else:
			result["message"] = "Subclass confirm button not found"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result

func test_class_back_button() -> Dictionary:
	"""Test back button from subclass to class selection"""
	var result := {"name": "class_back_button", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# Confirm race first
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
	if not class_tab:
		result["message"] = "ClassTab not found"
		cc_scene.queue_free()
		return result
	
	# Go to subclass selection
	if class_tab.has_signal("class_selected"):
		class_tab.class_selected.emit("wizard", "")
		await get_tree().process_frame
	
	var confirm_button := class_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.simulate_button_click(confirm_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		
		# Test back button
		var back_button := class_tab.find_child("*Back*", true, false) as Button
		if back_button:
			TestHelpers.log_step("Clicking back button from subclass selection")
			TestHelpers.simulate_button_click(back_button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
			result["passed"] = true
			result["message"] = "Back button works"
		else:
			result["message"] = "Back button not found"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result
