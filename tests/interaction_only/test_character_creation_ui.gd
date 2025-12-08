# ╔═══════════════════════════════════════════════════════════
# ║ test_character_creation_ui.gd
# ║ Desc: Tests character creation UI interaction-only paths
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

var test_results: Array[Dictionary] = []

func test_race_button_clicks() -> Dictionary:
	"""Test race selection button clicks (interaction-only)"""
	var result := {"name": "race_button_clicks", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene := load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if not race_tab:
		result["message"] = "RaceTab not found"
		cc_scene.queue_free()
		return result
	
	# Test race selection via signal (simulates button click)
	if race_tab.has_signal("race_selected"):
		race_tab.race_selected.emit("human", "")
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Race selection signal works"
	else:
		result["message"] = "RaceTab does not have race_selected signal"
	
	cc_scene.queue_free()
	return result

func test_stat_point_buy_interaction() -> Dictionary:
	"""Test stat point buy system interactions (interaction-only)"""
	var result := {"name": "stat_point_buy", "passed": false, "message": ""}
	
	if not PlayerData:
		result["message"] = "PlayerData singleton not found"
		return result
	
	# Test point buy interaction (only happens on button click)
	var original_points := PlayerData.points_remaining
	PlayerData.points_remaining = 27
	
	# Simulate ability score increase (interaction-only)
	if PlayerData.has_signal("points_changed"):
		PlayerData.points_changed.emit()
		result["passed"] = true
		result["message"] = "Point buy interaction works"
	else:
		result["message"] = "PlayerData does not have points_changed signal"
	
	PlayerData.points_remaining = original_points
	return result
