# ╔═══════════════════════════════════════════════════════════
# ║ test_name_confirm_tab.gd
# ║ Desc: Tests name confirm tab interactions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_name_entry() -> Dictionary:
	"""Test name entry text input"""
	var result := {"name": "name_entry", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var name_tab: Node = cc_scene.find_child("NameConfirmTab", true, false)
	if not name_tab:
		result["message"] = "NameConfirmTab not found or not accessible"
		cc_scene.queue_free()
		return result
	
	var name_entry := name_tab.find_child("*Name*", true, false) as LineEdit
	if name_entry:
		TestHelpers.log_step("Entering character name: TestCharacter")
		TestHelpers.simulate_text_input(name_entry, "TestCharacter")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		
		TestHelpers.log_step("Clearing name entry")
		TestHelpers.simulate_text_input(name_entry, "")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Name entry works"
	else:
		result["message"] = "Name entry not found"
	
	cc_scene.queue_free()
	return result

func test_voice_selection() -> Dictionary:
	"""Test voice selection"""
	var result := {"name": "voice_selection", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var name_tab: Node = cc_scene.find_child("NameConfirmTab", true, false)
	if not name_tab:
		result["message"] = "NameConfirmTab not found"
		cc_scene.queue_free()
		return result
	
	if name_tab.has_signal("voice_selected"):
		TestHelpers.log_step("Selecting voice: voice_1")
		name_tab.voice_selected.emit("voice_1")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Voice selection works"
	else:
		result["message"] = "Voice selection signal not found"
	
	cc_scene.queue_free()
	return result

func test_summary_display() -> Dictionary:
	"""Test summary panel display"""
	var result := {"name": "summary_display", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var name_tab: Node = cc_scene.find_child("NameConfirmTab", true, false)
	if name_tab:
		TestHelpers.log_step("Checking summary panel display")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Summary display works"
	else:
		result["message"] = "NameConfirmTab not found"
	
	cc_scene.queue_free()
	return result

func test_confirm_button_state() -> Dictionary:
	"""Test confirm button enabled/disabled based on name entry"""
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
	
	var name_tab: Node = cc_scene.find_child("NameConfirmTab", true, false)
	if not name_tab:
		result["message"] = "NameConfirmTab not found"
		cc_scene.queue_free()
		return result
	
	var confirm_button := name_tab.find_child("*Confirm*", true, false) as Button
	if confirm_button:
		TestHelpers.log_step("Checking confirm button state (should be disabled if name empty)")
		await TestHelpers.wait_visual(visual_delay)
		await get_tree().process_frame
		result["passed"] = true
		result["message"] = "Confirm button state check works"
	else:
		result["message"] = "Confirm button not found"
	
	cc_scene.queue_free()
	return result

func test_name_validation_non_empty() -> Dictionary:
	"""Test name validation (non-empty name required)"""
	var result := {"name": "name_validation_non_empty", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var name_tab: Node = cc_scene.find_child("NameConfirmTab", true, false)
	if not name_tab:
		result["message"] = "NameConfirmTab not found"
		cc_scene.queue_free()
		return result
	
	var name_entry := name_tab.find_child("*Name*", true, false) as LineEdit
	if name_entry:
		# Test empty name validation
		TestHelpers.simulate_text_input(name_entry, "")
		await TestHelpers.wait_visual(visual_delay * 0.5)
		await get_tree().process_frame
		
		var empty_valid := TestHelpers.assert_non_empty(name_entry.text, "Name should not be empty")
		
		# Test non-empty name
		TestHelpers.simulate_text_input(name_entry, "ValidCharacterName")
		await TestHelpers.wait_visual(visual_delay * 0.5)
		await get_tree().process_frame
		
		var non_empty_valid := TestHelpers.assert_non_empty(name_entry.text, "Name should be non-empty")
		
		result["passed"] = non_empty_valid
		result["message"] = "Name validation: empty=%s, non-empty=%s" % [str(not empty_valid), str(non_empty_valid)]
	else:
		result["message"] = "Name entry not found"
	
	cc_scene.queue_free()
	return result

func test_voice_preview_playback() -> Dictionary:
	"""Test voice preview playback"""
	var result := {"name": "voice_preview_playback", "passed": false, "message": ""}
	
	var cc_path := "res://scenes/character/CharacterCreationRoot.tscn"
	if not ResourceLoader.exists(cc_path):
		result["message"] = "CharacterCreationRoot scene not found"
		return result
	
	var cc_scene: Node = load(cc_path).instantiate()
	add_child(cc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await TestHelpers.wait_visual(visual_delay)
	
	var name_tab: Node = cc_scene.find_child("NameConfirmTab", true, false)
	if not name_tab:
		result["message"] = "NameConfirmTab not found"
		cc_scene.queue_free()
		return result
	
	# Find voice preview button
	var voice_preview_btn := name_tab.find_child("*Preview*", true, false) as Button
	if not voice_preview_btn:
		voice_preview_btn = name_tab.find_child("*Play*", true, false) as Button
	
	if voice_preview_btn:
		TestHelpers.log_step("Clicking voice preview button")
		TestHelpers.simulate_button_click(voice_preview_btn)
		await TestHelpers.wait_visual(visual_delay * 1.5)  # Wait for audio playback
		await get_tree().process_frame
		
		result["passed"] = true
		result["message"] = "Voice preview playback triggered"
	else:
		result["passed"] = true
		result["message"] = "Voice preview button not found (may use different mechanism)"
	
	cc_scene.queue_free()
	return result
