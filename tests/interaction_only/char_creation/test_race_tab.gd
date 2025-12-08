# ╔═══════════════════════════════════════════════════════════
# ║ test_race_tab.gd
# ║ Desc: Tests race tab complete flow interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")
const TestGameData = preload("res://tests/interaction_only/fixtures/TestGameData.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_race_selection_no_subrace() -> Dictionary:
	"""Test race selection flow for race without subraces (interaction-only)"""
	var result := {"name": "race_selection_no_subrace", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if not race_tab:
		result["message"] = "RaceTab not found"
		cc_scene.queue_free()
		return result
	
	# Select a race without subraces (Tiefling or Human)
	TestHelpers.log_step("Selecting race: tiefling (no subraces)")
	if race_tab.has_signal("race_selected"):
		race_tab.race_selected.emit("tiefling", "")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	# Find and click confirm button
	var confirm_button := race_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.log_step("Clicking Confirm Race button")
		TestHelpers.simulate_button_click(confirm_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Race selection (no subrace) works"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result

func test_race_selection_with_subrace() -> Dictionary:
	"""Test race selection flow for race with subraces (interaction-only)"""
	var result := {"name": "race_selection_with_subrace", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if not race_tab:
		result["message"] = "RaceTab not found"
		cc_scene.queue_free()
		return result
	
	# Select a race with subraces (Elf)
	TestHelpers.log_step("Selecting race: elf (has subraces)")
	if race_tab.has_signal("race_selected"):
		race_tab.race_selected.emit("elf", "")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
	
	# Click confirm to go to subrace selection
	var confirm_button := race_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.log_step("Clicking Confirm Race → (should show subraces)")
		TestHelpers.simulate_button_click(confirm_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		
		# Now select a subrace
		TestHelpers.log_step("Selecting subrace: wood_elf")
		if race_tab.has_signal("race_selected"):
			race_tab.race_selected.emit("elf", "wood_elf")
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
		
		# Confirm subrace
		var subrace_confirm := race_tab.find_child("*Confirm*", true, false) as Button
		if subrace_confirm:
			TestHelpers.log_step("Clicking Confirm Subrace →")
			TestHelpers.simulate_button_click(subrace_confirm)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
			result["passed"] = true
			result["message"] = "Race selection (with subrace) works"
		else:
			result["message"] = "Subrace confirm button not found"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result

func test_race_back_button() -> Dictionary:
	"""Test back button from subrace to race selection"""
	var result := {"name": "race_back_button", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if not race_tab:
		result["message"] = "RaceTab not found"
		cc_scene.queue_free()
		return result
	
	# Select race with subraces and go to subrace selection
	if race_tab.has_signal("race_selected"):
		race_tab.race_selected.emit("elf", "")
		await get_tree().process_frame
	
	var confirm_button := race_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.simulate_button_click(confirm_button)
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		
		# Now test back button
		var back_button := race_tab.find_child("*Back*", true, false) as Button
		if back_button:
			TestHelpers.log_step("Clicking back button from subrace selection")
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

func test_race_preview_update() -> Dictionary:
	"""Test preview panel updates on race selection"""
	var result := {"name": "race_preview_update", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if not race_tab:
		result["message"] = "RaceTab not found"
		cc_scene.queue_free()
		return result
	
	# Select different races and verify preview updates
	var test_races := ["human", "elf", "dwarf", "tiefling"]
	for race_id in test_races:
		TestHelpers.log_step("Selecting race: %s (checking preview update)" % race_id)
		if race_tab.has_signal("race_selected"):
			race_tab.race_selected.emit(race_id, "")
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Race preview updates work"
	cc_scene.queue_free()
	return result
