# ╔═══════════════════════════════════════════════════════════
# ║ RaceTab.gd
# ║ Desc: Two-stage race → subrace selection (BG3 style)
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends Control

signal race_selected(race_id: String, subrace_id: String)
signal tab_completed()

const MODE_RACE: int = 0
const MODE_SUBRACE: int = 1

@onready var race_grid: GridContainer = %RaceGrid
@onready var unified_scroll: ScrollContainer = %UnifiedScroll
@onready var race_confirm_button: Button = %ConfirmRaceButton
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel

var race_entry_scene: PackedScene = preload("res://scenes/character/tabs/components/RaceEntry.tscn")
var current_mode: int = MODE_RACE
var pending_race: Dictionary = {}
var selected_race: String = ""
var selected_subrace: String = ""
var selected_entry: PanelContainer = null
var all_entries: Array = []

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame  # double await = 100% safe after full tree + autoloads
	
	if not GameData.races or GameData.races.is_empty():
		Logger.error("RaceTab: GameData.races is empty! Aborting population.", "character_creation")
		return
	
	# Restore previous selection if returning from another tab
	_restore_selection_state()
	
	# Initialize UI state
	_update_ui_for_mode()
	_populate_list()
	
	# Restore visual selection after population completes
	if selected_race != "":
		await get_tree().process_frame  # Wait for entries to be fully created
		_restore_visual_selection()

func _populate_list() -> void:
	"""Populate grid based on current mode"""
	if not race_grid:
		push_error("RaceTab: RaceGrid node missing!")
		return
	
	# Clear existing entries
	for child in race_grid.get_children():
		child.queue_free()
	all_entries.clear()
	selected_entry = null
	
	if GameData.races.is_empty():
		Logger.error("RaceTab: No race items to display!", "character_creation")
		return
	
	# Ensure GridContainer is properly configured
	if race_grid:
		race_grid.columns = 3
		race_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		race_grid.visible = true
	
	# Wait for layout to update before adding children
	await get_tree().process_frame
	
	if current_mode == MODE_RACE:
		_populate_races()
	elif current_mode == MODE_SUBRACE:
		_populate_subraces()
	
	# Wait for all entries to be added and processed
	await get_tree().process_frame
	
	# Force layout updates
	if race_grid:
		race_grid.update_minimum_size()
		race_grid.queue_sort()
	
	# Update unified scroll container
	await get_tree().process_frame
	if unified_scroll:
		unified_scroll.update_minimum_size()
		unified_scroll.queue_sort()
		unified_scroll.scroll_vertical = 0

func _populate_races() -> void:
	"""Populate grid with base races only (ignore subraces)"""
	for race in GameData.races:
		var entry := race_entry_scene.instantiate()
		if not entry:
			Logger.error("RaceTab: Failed to instantiate race_entry_scene!", "character_creation")
			continue
		
		race_grid.add_child(entry)
		all_entries.append(entry)
		
		if entry.has_method("setup"):
			entry.setup(race)
		
		if entry.has_signal("race_selected"):
			entry.race_selected.connect(_on_race_selected)
		
		Logger.debug("RaceTab: Added race entry: %s" % race.get("name", ""), "character_creation")

func _populate_subraces() -> void:
	"""Populate grid with subraces of pending_race"""
	if pending_race.is_empty():
		Logger.error("RaceTab: Cannot populate subraces - pending_race is empty!", "character_creation")
		return
	
	var subraces: Array = pending_race.get("subraces", [])
	if subraces.is_empty():
		Logger.warning("RaceTab: Race %s has no subraces!" % pending_race.get("name", ""), "character_creation")
		return
	
	for subrace in subraces:
		var entry := race_entry_scene.instantiate()
		if not entry:
			Logger.error("RaceTab: Failed to instantiate race_entry_scene!", "character_creation")
			continue
		
		race_grid.add_child(entry)
		all_entries.append(entry)
		
		if entry.has_method("setup"):
			entry.setup(pending_race, subrace)
		
		if entry.has_signal("race_selected"):
			entry.race_selected.connect(_on_race_selected)
		
		Logger.debug("RaceTab: Added subrace entry: %s" % subrace.get("name", ""), "character_creation")

func _update_ui_for_mode() -> void:
	"""Update UI elements based on current mode"""
	if current_mode == MODE_RACE:
		title_label.text = "CHOOSE YOUR RACE"
		back_button.visible = false
		selected_race = ""
		selected_subrace = ""
	elif current_mode == MODE_SUBRACE:
		title_label.text = "CHOOSE YOUR SUBRACE"
		back_button.visible = true
	
	_update_race_confirm_button_state()

func _go_back_to_races() -> void:
	"""Return to race selection mode"""
	current_mode = MODE_RACE
	pending_race = {}
	selected_race = ""
	selected_subrace = ""
	selected_entry = null
	_update_ui_for_mode()
	_populate_list()
	
	Logger.info("RaceTab: Returned to race selection", "character_creation")

func _on_back_button_pressed() -> void:
	"""Handle back button press"""
	_go_back_to_races()

func _notification(what: int) -> void:
	"""Handle resize notifications to update layout."""
	if what == NOTIFICATION_RESIZED:
		if race_grid:
			race_grid.update_minimum_size()
			race_grid.queue_sort()
		if unified_scroll:
			unified_scroll.queue_sort()
		queue_redraw()

func _on_race_selected(race_id: String, subrace_id: String) -> void:
	"""Handle race/subrace selection"""
	Logger.log_user_action("select_race", race_id, "character_creation", {
		"subrace": subrace_id if subrace_id != "" else "none"
	})
	
	# Deselect all entries
	for entry in all_entries:
		if entry and entry.has_method("set_selected"):
			entry.set_selected(false)
	
	# Find and select the clicked entry
	for entry in all_entries:
		if not entry:
			continue
		
		# Check if entry has race_data property (RaceEntry instances have this)
		var entry_race_data = entry.get("race_data")
		if not entry_race_data or not (entry_race_data is Dictionary):
			continue
		
		if entry_race_data.get("id", "") == race_id:
			var entry_subrace_data = entry.get("subrace_data")
			if subrace_id == "" or (entry_subrace_data is Dictionary and not entry_subrace_data.is_empty() and entry_subrace_data.get("id", "") == subrace_id):
				if entry.has_method("set_selected"):
					entry.set_selected(true)
				selected_entry = entry
				break
	
	selected_race = race_id
	selected_subrace = subrace_id if subrace_id != "" else ""
	
	Logger.debug("RaceTab: Race selected (preview) - race: %s, subrace: %s" % [race_id, subrace_id if subrace_id != "" else "none"], "character_creation")
	
	# Emit signal for preview (CharacterCreationRoot handles preview panel update)
	race_selected.emit(race_id, subrace_id)
	
	# Update confirm button state
	_update_race_confirm_button_state()
	
	Logger.info("RaceTab: Race previewed - %s%s" % [race_id, " (%s)" % subrace_id if subrace_id != "" else ""], "character_creation")

func _update_race_confirm_button_state() -> void:
	"""Update the confirm button state based on selection and mode"""
	if not race_confirm_button:
		return
	
	if current_mode == MODE_RACE:
		if selected_race.is_empty():
			race_confirm_button.disabled = true
			race_confirm_button.text = "Select a Race"
		else:
			race_confirm_button.disabled = false
			race_confirm_button.text = "Confirm Race →"
	elif current_mode == MODE_SUBRACE:
		if selected_subrace.is_empty():
			race_confirm_button.disabled = true
			race_confirm_button.text = "Select a Subrace"
		else:
			race_confirm_button.disabled = false
			race_confirm_button.text = "Confirm Subrace →"

func _on_confirm_button_pressed() -> void:
	"""Handle confirm button press - behavior depends on mode"""
	# Disable button immediately to prevent spam clicks
	if race_confirm_button:
		race_confirm_button.disabled = true
	
	if current_mode == MODE_RACE:
		_confirm_race()
	elif current_mode == MODE_SUBRACE:
		_confirm_subrace()

func _confirm_race() -> void:
	"""Confirm base race selection"""
	if selected_race.is_empty():
		Logger.warning("RaceTab: Confirm pressed but no race selected", "character_creation")
		return
	
	# Find the selected race data
	var race_data: Dictionary = {}
	for race in GameData.races:
		if race.get("id", "") == selected_race:
			race_data = race
			break
	
	if race_data.is_empty():
		Logger.error("RaceTab: Selected race not found in GameData!", "character_creation")
		return
	
	var subraces: Array = race_data.get("subraces", [])
	
	# If race has subraces, switch to subrace selection mode
	if subraces.size() > 0:
		current_mode = MODE_SUBRACE
		pending_race = race_data
		selected_subrace = ""
		selected_entry = null
		_update_ui_for_mode()
		_populate_list()
		
		# Keep the race preview active
		race_selected.emit(selected_race, "")
		
		Logger.info("RaceTab: Switched to subrace selection for %s" % race_data.get("name", ""), "character_creation")
	else:
		# No subraces - store and advance immediately
		_store_race_data(race_data, "")
		
		Logger.info("RaceTab: Race confirmed (no subraces) - emitting tab_completed signal", "character_creation")
		Logger.debug("RaceTab: tab_completed signal has %d connections" % tab_completed.get_connections().size(), "character_creation")
		
		# Explicitly emit the signal with logging
		if tab_completed.get_connections().is_empty():
			Logger.error("RaceTab: tab_completed signal has no connections! Tab advancement will fail.", "character_creation")
		else:
			for conn in tab_completed.get_connections():
				Logger.debug("RaceTab: tab_completed connected to: %s" % str(conn), "character_creation")
		
		tab_completed.emit()
		Logger.info("RaceTab: tab_completed signal emitted - awaiting tab transition", "character_creation")

func _confirm_subrace() -> void:
	"""Confirm subrace selection and advance to next tab"""
	if selected_subrace.is_empty():
		Logger.warning("RaceTab: Confirm pressed but no subrace selected", "character_creation")
		return
	
	if pending_race.is_empty():
		Logger.error("RaceTab: Cannot confirm subrace - pending_race is empty!", "character_creation")
		return
	
	_store_race_data(pending_race, selected_subrace)
	
	Logger.info("RaceTab: Subrace confirmed - emitting tab_completed signal", "character_creation")
	Logger.debug("RaceTab: tab_completed signal has %d connections" % tab_completed.get_connections().size(), "character_creation")
	
	# Explicitly emit the signal with logging
	if tab_completed.get_connections().is_empty():
		Logger.error("RaceTab: tab_completed signal has no connections! Tab advancement will fail.", "character_creation")
	else:
		for conn in tab_completed.get_connections():
			Logger.debug("RaceTab: tab_completed connected to: %s" % str(conn), "character_creation")
	
	tab_completed.emit()
	Logger.info("RaceTab: tab_completed signal emitted - awaiting tab transition", "character_creation")

func _store_race_data(race: Dictionary, subrace_id: String) -> void:
	"""Store race and subrace data in PlayerData"""
	PlayerData.race_id = race.get("id", "")
	PlayerData.subrace_id = subrace_id if subrace_id != "" else ""
	
	# Create merged race data
	var race_data: Dictionary = race.duplicate()
	if subrace_id != "":
		var subraces: Array = race_data.get("subraces", [])
		for subrace in subraces:
			if subrace.get("id", "") == subrace_id:
				# Merge subrace data
				if subrace.has("name"):
					race_data["name"] = subrace.get("name", race_data.get("name", ""))
				if subrace.has("description") and subrace.get("description", "") != "":
					race_data["description"] = subrace.get("description", race_data.get("description", ""))
				break
	
	PlayerData.race_data = race_data
	PlayerData.racial_bonuses_updated.emit()
	
	Logger.log_user_action("confirm_race", race.get("id", ""), "character_creation", {
		"subrace": subrace_id if subrace_id != "" else "none"
	})
	Logger.info("RaceTab: Race data stored in PlayerData", "character_creation")

func _restore_selection_state() -> void:
	"""Restore race/subrace selection from PlayerData when navigating back"""
	if PlayerData.race_id.is_empty():
		return  # No previous selection to restore
	
	selected_race = PlayerData.race_id
	selected_subrace = PlayerData.subrace_id
	
	# Find the race data from GameData
	for race in GameData.races:
		if race.get("id", "") == selected_race:
			if selected_subrace != "":
				# We have a subrace - set mode and pending race
				current_mode = MODE_SUBRACE
				pending_race = race
			else:
				# Just race selected, check if it has subraces
				var subraces: Array = race.get("subraces", [])
				if subraces.size() > 0:
					# Race has subraces but none selected - stay in race mode
					current_mode = MODE_RACE
				else:
					# Race has no subraces - confirmed state
					current_mode = MODE_RACE
			break
	
	Logger.debug("RaceTab: Restored selection state - race: %s, subrace: %s, mode: %s" % [
		selected_race,
		selected_subrace if selected_subrace != "" else "none",
		"SUBRACE" if current_mode == MODE_SUBRACE else "RACE"
	], "character_creation")

func _restore_visual_selection() -> void:
	"""Restore visual highlighting of selected race/subrace entry"""
	if all_entries.is_empty():
		return
	
	var target_race_id: String = selected_race
	var target_subrace_id: String = selected_subrace if selected_subrace != "" else ""
	
	# Find and highlight the matching entry
	for entry in all_entries:
		if not entry:
			continue
		
		var entry_race_data = entry.get("race_data")
		if not entry_race_data or not (entry_race_data is Dictionary):
			continue
		
		if entry_race_data.get("id", "") == target_race_id:
			var entry_subrace_data = entry.get("subrace_data")
			var entry_subrace_id: String = ""
			if entry_subrace_data is Dictionary and not entry_subrace_data.is_empty():
				entry_subrace_id = entry_subrace_data.get("id", "")
			
			# Match subrace if needed
			if target_subrace_id == "" or entry_subrace_id == target_subrace_id:
				if entry.has_method("set_selected"):
					entry.set_selected(true)
				selected_entry = entry
				
				# Emit preview signal to update preview panel
				race_selected.emit(target_race_id, target_subrace_id)
				
				Logger.debug("RaceTab: Restored visual selection for %s%s" % [
					target_race_id,
					" (%s)" % target_subrace_id if target_subrace_id != "" else ""
				], "character_creation")
				break
