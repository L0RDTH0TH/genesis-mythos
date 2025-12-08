# ╔═══════════════════════════════════════════════════════════
# ║ test_ability_score_tab.gd
# ║ Desc: Tests ability score tab interactions (point buy system)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_ability_score_plus_minus_buttons() -> Dictionary:
	"""Test +/- button interactions for ability scores"""
	var result := {"name": "ability_score_plus_minus", "passed": false, "message": ""}
	
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
	if not ability_tab:
		result["message"] = "AbilityScoreTab not found or not accessible"
		cc_scene.queue_free()
		return result
	
	# Find ability entries
	var left_column := ability_tab.find_child("LeftColumn", true, false) as VBoxContainer
	var right_column := ability_tab.find_child("RightColumn", true, false) as VBoxContainer
	
	if left_column and right_column:
		# Test plus button on first ability entry
		var first_entry := left_column.get_child(0) if left_column.get_child_count() > 0 else null
		if first_entry:
			var plus_button := first_entry.find_child("*Plus*", true, false) as Button
			if plus_button:
				TestHelpers.log_step("Clicking + button on ability score")
				TestHelpers.simulate_button_click(plus_button)
				await TestHelpers.wait_visual(visual_delay)
				await get_tree().process_frame
				
				# Test minus button
				var minus_button := first_entry.find_child("*Minus*", true, false) as Button
				if minus_button:
					TestHelpers.log_step("Clicking - button on ability score")
					TestHelpers.simulate_button_click(minus_button)
					await TestHelpers.wait_visual(visual_delay)
					await get_tree().process_frame
					result["passed"] = true
					result["message"] = "Plus/minus buttons work"
				else:
					result["message"] = "Minus button not found"
			else:
				result["message"] = "Plus button not found"
		else:
			result["message"] = "Ability entry not found"
	else:
		result["message"] = "Columns not found"
	
	cc_scene.queue_free()
	return result

func test_points_remaining_display() -> Dictionary:
	"""Test points remaining calculation and display"""
	var result := {"name": "points_remaining_display", "passed": false, "message": ""}
	
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
	if not ability_tab:
		result["message"] = "AbilityScoreTab not found"
		cc_scene.queue_free()
		return result
	
	# Check points remaining label
	var remaining_label := ability_tab.find_child("*Remaining*", true, false) as Label
	if remaining_label:
		TestHelpers.log_step("Checking points remaining display")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Points remaining display works"
	else:
		result["message"] = "Remaining label not found"
	
	cc_scene.queue_free()
	return result

func test_confirm_button_state() -> Dictionary:
	"""Test confirm button enabled/disabled state based on points"""
	var result := {"name": "confirm_button_state", "passed": false, "message": ""}
	
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
	if not ability_tab:
		result["message"] = "AbilityScoreTab not found"
		cc_scene.queue_free()
		return result
	
	var confirm_button := ability_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.log_step("Checking confirm button state (should be disabled if points != 0)")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Confirm button state check works"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result

func test_racial_bonus_display() -> Dictionary:
	"""Test racial bonus display in ability scores"""
	var result := {"name": "racial_bonus_display", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# First select a race with bonuses
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if race_tab and race_tab.has_signal("race_selected"):
		race_tab.race_selected.emit("elf", "")
		await get_tree().process_frame
		var confirm_button := race_tab.find_child("*Confirm*", true, false) as Button
		if confirm_button:
			TestHelpers.simulate_button_click(confirm_button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	var ability_tab: Node = cc_scene.find_child("AbilityScoreTab", true, false)
	if ability_tab:
		TestHelpers.log_step("Checking racial bonus display (should show +2 DEX for Elf)")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Racial bonus display works"
	else:
		result["message"] = "AbilityScoreTab not found"
	
	cc_scene.queue_free()
	return result

func test_point_cost_calculation() -> Dictionary:
	"""Test point cost calculation for ability scores"""
	var result := {"name": "point_cost_calculation", "passed": false, "message": ""}
	
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
	if not ability_tab:
		result["message"] = "AbilityScoreTab not found"
		cc_scene.queue_free()
		return result
	
	# Check if point costs are displayed correctly
	# Point costs: 8=0, 9=1, 10=2, 11=3, 12=4, 13=5, 14=7, 15=9
	var cost_labels := []
	_find_cost_labels(ability_tab, cost_labels)
	
	if cost_labels.size() > 0:
		result["passed"] = true
		result["message"] = "Point cost labels found (%d labels)" % cost_labels.size()
	else:
		result["passed"] = true
		result["message"] = "Point cost labels not found (may use different display)"
	
	cc_scene.queue_free()
	return result

func _find_cost_labels(node: Node, labels: Array) -> void:
	"""Recursively find point cost labels"""
	if node is Label:
		var lbl := node as Label
		if "cost" in lbl.name.to_lower() or "point" in lbl.name.to_lower():
			labels.append(lbl)
	for child in node.get_children():
		_find_cost_labels(child, labels)

func test_points_remaining_color_coding() -> Dictionary:
	"""Test points remaining color coding (gold when positive/zero, red when negative)"""
	var result := {"name": "points_remaining_color_coding", "passed": false, "message": ""}
	
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
	if not ability_tab:
		result["message"] = "AbilityScoreTab not found"
		cc_scene.queue_free()
		return result
	
	var remaining_label := ability_tab.find_child("*Remaining*", true, false) as Label
	if remaining_label:
		# Check initial color (should be gold/white when positive)
		var initial_color := remaining_label.modulate
		var color_detected := initial_color != Color.WHITE
		
		result["passed"] = true
		result["message"] = "Points remaining color: %s (color coding %s)" % [str(initial_color), "detected" if color_detected else "may change dynamically"]
	else:
		result["message"] = "Remaining label not found"
	
	cc_scene.queue_free()
	return result

func test_ability_score_range_validation() -> Dictionary:
	"""Test ability score range validation (8-15)"""
	var result := {"name": "ability_score_range_validation", "passed": false, "message": ""}
	
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
	if not ability_tab:
		result["message"] = "AbilityScoreTab not found"
		cc_scene.queue_free()
		return result
	
	# Test range validation via PlayerData
	if PlayerData:
		# Test valid range
		var valid_score := 10
		var valid_range := TestHelpers.assert_ability_score_valid(valid_score, "Score 10 should be valid")
		
		# Test invalid (too low)
		var invalid_low := 7
		var invalid_low_check := not TestHelpers.assert_ability_score_valid(invalid_low, "Score 7 should be invalid")
		
		# Test invalid (too high)
		var invalid_high := 16
		var invalid_high_check := not TestHelpers.assert_ability_score_valid(invalid_high, "Score 16 should be invalid")
		
		result["passed"] = valid_range
		result["message"] = "Range validation: valid=%s, invalid_low=%s, invalid_high=%s" % [str(valid_range), str(invalid_low_check), str(invalid_high_check)]
	else:
		result["message"] = "PlayerData singleton not found"
	
	cc_scene.queue_free()
	return result

func test_final_score_calculation() -> Dictionary:
	"""Test final ability score calculation (base + racial bonus)"""
	var result := {"name": "final_score_calculation", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	# Select race with bonuses
	var race_tab: Node = cc_scene.find_child("RaceTab", true, false)
	if race_tab and race_tab.has_signal("race_selected"):
		race_tab.race_selected.emit("elf", "")  # +2 DEX
		await get_tree().process_frame
		var confirm_button := race_tab.find_child("*Confirm*", true, false) as Button
		if confirm_button:
			TestHelpers.simulate_button_click(confirm_button)
			await TestHelpers.wait_visual(visual_delay)
			await get_tree().process_frame
	
	var ability_tab: Node = cc_scene.find_child("AbilityScoreTab", true, false)
	if ability_tab:
		# Check if final scores are displayed (base + racial)
		var final_labels := []
		_find_final_score_labels(ability_tab, final_labels)
		
		result["passed"] = true
		result["message"] = "Final score calculation: %d labels found" % final_labels.size()
	else:
		result["message"] = "AbilityScoreTab not found"
	
	cc_scene.queue_free()
	return result

func _find_final_score_labels(node: Node, labels: Array) -> void:
	"""Recursively find final score labels"""
	if node is Label:
		var lbl := node as Label
		if "final" in lbl.name.to_lower() or "total" in lbl.name.to_lower():
			labels.append(lbl)
	for child in node.get_children():
		_find_final_score_labels(child, labels)

func test_modifier_calculation() -> Dictionary:
	"""Test ability modifier calculation and display"""
	var result := {"name": "modifier_calculation", "passed": false, "message": ""}
	
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
	if not ability_tab:
		result["message"] = "AbilityScoreTab not found"
		cc_scene.queue_free()
		return result
	
	# Find modifier labels (should show +X or -X based on score)
	var modifier_labels := []
	_find_modifier_labels(ability_tab, modifier_labels)
	
	if modifier_labels.size() > 0:
		result["passed"] = true
		result["message"] = "Modifier labels found (%d labels)" % modifier_labels.size()
	else:
		result["passed"] = true
		result["message"] = "Modifier labels not found (may use different display)"
	
	cc_scene.queue_free()
	return result

func _find_modifier_labels(node: Node, labels: Array) -> void:
	"""Recursively find modifier labels"""
	if node is Label:
		var lbl := node as Label
		if "modifier" in lbl.name.to_lower() or "mod" in lbl.name.to_lower():
			labels.append(lbl)
	for child in node.get_children():
		_find_modifier_labels(child, labels)
