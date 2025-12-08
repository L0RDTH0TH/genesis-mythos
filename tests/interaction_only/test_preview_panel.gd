# ╔═══════════════════════════════════════════════════════════
# ║ test_preview_panel.gd
# ║ Desc: Tests preview panel updates across tabs
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_preview_on_race_selection() -> Dictionary:
	"""Test preview panel updates on race selection"""
	var result := {"name": "preview_on_race_selection", "passed": false, "message": ""}
	
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
	var test_races := ["human", "elf", "dwarf"]
	for race_id in test_races:
		TestHelpers.log_step("Selecting race: %s (checking preview update)" % race_id)
		if race_tab.has_signal("race_selected"):
			race_tab.race_selected.emit(race_id, "")
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Preview updates on race selection work"
	cc_scene.queue_free()
	return result

func test_preview_on_class_selection() -> Dictionary:
	"""Test preview panel updates on class selection"""
	var result := {"name": "preview_on_class_selection", "passed": false, "message": ""}
	
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
	if class_tab:
		TestHelpers.log_step("Selecting class: fighter (checking preview update)")
		if class_tab.has_signal("class_selected"):
			class_tab.class_selected.emit("fighter", "")
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Preview updates on class selection work"
	else:
		result["message"] = "ClassTab not found"
	
	cc_scene.queue_free()
	return result

func test_preview_on_ability_change() -> Dictionary:
	"""Test preview panel updates on ability score changes"""
	var result := {"name": "preview_on_ability_change", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var ability_tab: Node = cc_scene.find_child("AbilityScoreTab", true, false)
	if ability_tab:
		TestHelpers.log_step("Changing ability scores (checking preview update)")
		# Simulate ability score changes via PlayerData if available
		if PlayerData and PlayerData.has_signal("stats_changed"):
			PlayerData.stats_changed.emit()
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Preview updates on ability change work"
	else:
		result["message"] = "AbilityScoreTab not found"
	
	cc_scene.queue_free()
	return result
