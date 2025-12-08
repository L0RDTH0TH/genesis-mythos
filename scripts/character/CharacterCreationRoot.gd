# ╔═══════════════════════════════════════════════════════════
# ║ CharacterCreationRoot.gd
# ║ Desc: Root layout controller for character creation – forces proper centering
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Control

const CharacterData = preload("res://resources/CharacterData.gd")

signal race_confirmed(race_id: String, subrace_id: String)

@onready var tab_navigation: Control = $MainHBox/MarginContainer/VBoxContainer/TabNavigation
@onready var content_area: Control = $MainHBox/MarginContainer2/center_area/MarginContainer3/CurrentTabContainer
@onready var preview_subtitle: Label = %Subtitle
@onready var preview_description: RichTextLabel = %Description
@onready var preview_speed_size: Label = %SpeedSize
@onready var preview_ability_scores: RichTextLabel = %AbilityScores
@onready var preview_features_list: ItemList = %FeaturesList

const ABILITIES := ["STR", "DEX", "CON", "INT", "WIS", "CHA"]
const ABILITY_MAP := {
	"STR": "strength",
	"DEX": "dexterity",
	"CON": "constitution",
	"INT": "intelligence",
	"WIS": "wisdom",
	"CHA": "charisma"
}

var current_tab_instance: Node = null
var selected_race: String = ""
var selected_subrace: String = ""
var selected_class: String = ""
var selected_background: String = ""
var final_ability_scores: Dictionary = {}
var appearance_data: Dictionary = {}
var character_name: String = ""
var selected_voice: String = ""

# Preview + Confirm state for race selection
var preview_race: String = ""
var preview_subrace: String = ""
var confirmed_race: String = ""
var confirmed_subrace: String = ""

const TAB_SCENES := {
	"Race": "res://scenes/character/tabs/RaceTab.tscn",
	"Class": "res://scenes/character/tabs/ClassTab.tscn",
	"Background": "res://scenes/character/tabs/BackgroundTab.tscn",
	"AbilityScore": "res://scenes/character/tabs/AbilityScoreTab.tscn",
	"Appearance": "res://scenes/character/tabs/AppearanceTab.tscn",
	"NameConfirm": "res://scenes/character/tabs/NameConfirmTab.tscn"
}

func _ready() -> void:
	add_to_group("character_creation_root")
	
	# Connect window resize handler
	get_tree().get_root().size_changed.connect(_on_window_resize)
	_on_window_resize()
	
	if not tab_navigation.tab_changed.is_connected(_on_tab_changed):
		tab_navigation.tab_changed.connect(_on_tab_changed)
		Logger.debug("CharacterCreationRoot: Connected TabNavigation.tab_changed signal", "character_creation")
	else:
		Logger.debug("CharacterCreationRoot: TabNavigation.tab_changed already connected", "character_creation")
	
	Logger.debug("CharacterCreationRoot: TabNavigation.tab_changed has %d connections" % tab_navigation.tab_changed.get_connections().size(), "character_creation")
	
	# Connect PlayerData signals to update preview panel when stats or racial bonuses change
	if PlayerData:
		if not PlayerData.stats_changed.is_connected(_on_player_stats_changed):
			PlayerData.stats_changed.connect(_on_player_stats_changed)
		if not PlayerData.racial_bonuses_updated.is_connected(_on_racial_bonuses_updated):
			PlayerData.racial_bonuses_updated.connect(_on_racial_bonuses_updated)
		# NEW: Keep Appearance preview in sync with Race selection at all times
		if not PlayerData.racial_bonuses_updated.is_connected(_on_player_data_race_changed):
			PlayerData.racial_bonuses_updated.connect(_on_player_data_race_changed)
	
	_show_default_preview()
	_load_tab("Race")

func _on_window_resize() -> void:
	"""Handle window resize to update race grid layout"""
	# Find RaceGrid in the current tab instance
	if current_tab_instance:
		var race_grid: GridContainer = current_tab_instance.get_node_or_null("MainPanel/UnifiedScroll/RaceGrid")
		if is_instance_valid(race_grid):
			print("Grid size: ", race_grid.size)
			race_grid.update_minimum_size()

func _on_tab_changed(tab_name: String) -> void:
	Logger.debug("CharacterCreationRoot: _on_tab_changed() called for tab: %s" % tab_name, "character_creation")
	
	# Validate race selection before loading ClassTab
	if tab_name == "Class" and PlayerData.race_id.is_empty():
		Logger.warning("CharacterCreationRoot: Cannot load ClassTab: No race selected", "character_creation")
		_show_validation_error("Please select a race first before choosing a class.")
		# Revert to Race tab
		tab_navigation._select_tab("Race")
		return
	
	# Load tab (async - will complete after fade animation)
	# Note: Signal connections are handled in _load_tab() via _connect_tab_signals()
	Logger.debug("CharacterCreationRoot: About to call _load_tab(%s)" % tab_name, "character_creation")
	await _load_tab(tab_name)
	Logger.debug("CharacterCreationRoot: _load_tab(%s) completed - signals connected via _connect_tab_signals()" % tab_name, "character_creation")

func _load_tab(tab_name: String) -> void:
	Logger.debug("Loading tab scene: %s" % tab_name, "character_creation")
	
	# Fade out current tab if it exists
	if current_tab_instance:
		Logger.debug("Starting fade-out for old tab: %s" % current_tab_instance.name, "character_creation")
		var old_tab: Node = current_tab_instance
		
		# Create fade-out tween
		var tween := create_tween()
		if not tween:
			Logger.warning("Failed to create fade-out tween for old tab", "character_creation")
		else:
			tween.set_parallel(false)
			tween.tween_property(old_tab, "modulate:a", 0.0, 0.15)
			await tween.finished
			Logger.debug("Fade-out complete for old tab", "character_creation")
		
		# Remove old tab from scene tree
		if is_instance_valid(content_area) and is_instance_valid(old_tab) and old_tab.is_inside_tree():
			content_area.remove_child(old_tab)
			Logger.debug("Old tab removed from scene tree", "character_creation")
		if is_instance_valid(old_tab):
			old_tab.queue_free()
			Logger.debug("Old tab queued for deletion", "character_creation")
	else:
		Logger.debug("No current_tab_instance to fade out (initial load)", "character_creation")
	
	# Load and instantiate new tab
	var path: String = TAB_SCENES[tab_name]
	var scene := load(path) as PackedScene
	if not scene:
		Logger.error("Failed to load scene: %s" % path, "character_creation")
		return
	
	current_tab_instance = scene.instantiate()
	if not current_tab_instance:
		Logger.error("Failed to instantiate scene: %s" % path, "character_creation")
		return
	
	# Set initial alpha to 0 for fade-in
	current_tab_instance.modulate.a = 0.0
	Logger.debug("New tab created with alpha 0.0: %s" % current_tab_instance.name, "character_creation")
	
	# Add to scene tree
	content_area.add_child(current_tab_instance)
	Logger.debug("New tab added to scene tree", "character_creation")
	
	# FORCED CONNECTION: Connect tab signals immediately after tab is added to tree
	# This ensures signals are connected before any tab logic runs
	_connect_tab_signals(tab_name)
	
	# Fade in new tab
	var fade_in_tween := create_tween()
	if not fade_in_tween:
		Logger.warning("Failed to create fade-in tween for new tab", "character_creation")
		# Fallback: set alpha directly if tween fails
		current_tab_instance.modulate.a = 1.0
	else:
		fade_in_tween.set_parallel(false)
		fade_in_tween.tween_property(current_tab_instance, "modulate:a", 1.0, 0.15)
		await fade_in_tween.finished
		Logger.debug("Fade-in complete for new tab", "character_creation")
	
	Logger.debug("Tab transition complete: %s" % tab_name, "character_creation")

func _connect_tab_signals(tab_name: String) -> void:
	"""FORCED CONNECTION: Connect all tab signals immediately after tab is added to scene tree"""
	if not current_tab_instance:
		Logger.error("CharacterCreationRoot: Cannot connect signals - current_tab_instance is null!", "character_creation")
		return
	
	Logger.debug("CharacterCreationRoot: Connecting signals for tab: %s" % tab_name, "character_creation")
	
	# Tab-specific signal connections
	if tab_name == "Race":
		# CRITICAL: Race tab needs direct connection to enable_next_tab
		if current_tab_instance.has_signal("tab_completed"):
			if not current_tab_instance.tab_completed.is_connected(tab_navigation.enable_next_tab):
				current_tab_instance.tab_completed.connect(tab_navigation.enable_next_tab)
				Logger.debug("CharacterCreationRoot: FORCED connection of %s.tab_completed → TabNavigation.enable_next_tab" % current_tab_instance.name, "character_creation")
				Logger.debug("CharacterCreationRoot: tab_completed now has %d connections" % current_tab_instance.tab_completed.get_connections().size(), "character_creation")
			else:
				Logger.debug("CharacterCreationRoot: %s.tab_completed already connected to TabNavigation.enable_next_tab" % current_tab_instance.name, "character_creation")
		else:
			Logger.error("CharacterCreationRoot: RaceTab does not have tab_completed signal!", "character_creation")
		if current_tab_instance.has_signal("race_selected"):
			if not current_tab_instance.race_selected.is_connected(_on_race_selected):
				current_tab_instance.race_selected.connect(_on_race_selected)
				Logger.debug("CharacterCreationRoot: Connected RaceTab.race_selected signal", "character_creation")
	elif tab_name == "Class":
		if current_tab_instance.has_signal("class_selected"):
			current_tab_instance.class_selected.connect(_on_class_selected)
		if current_tab_instance.has_signal("tab_completed"):
			current_tab_instance.tab_completed.connect(_on_class_tab_completed)
	elif tab_name == "Background":
		if current_tab_instance.has_signal("background_selected"):
			current_tab_instance.background_selected.connect(_on_background_selected)
		if current_tab_instance.has_signal("tab_completed"):
			current_tab_instance.tab_completed.connect(_on_background_tab_completed)
	elif tab_name == "AbilityScore":
		# AbilityScoreTab has point-buy and confirmation
		if current_tab_instance.has_signal("tab_completed"):
			current_tab_instance.tab_completed.connect(_on_ability_score_tab_completed)
	elif tab_name == "Appearance":
		if current_tab_instance.has_signal("appearance_completed"):
			current_tab_instance.appearance_completed.connect(_on_appearance_completed)
		if current_tab_instance.has_signal("tab_completed"):
			current_tab_instance.tab_completed.connect(_on_appearance_tab_completed)
	elif tab_name == "NameConfirm":
		if current_tab_instance.has_signal("character_confirmed"):
			if not current_tab_instance.character_confirmed.is_connected(_on_character_confirmed):
				current_tab_instance.character_confirmed.connect(_on_character_confirmed)
				Logger.debug("CharacterCreationRoot: Connected character_confirmed signal", "character_creation")

func _on_race_selected(race_id: String, subrace_id: String) -> void:
	"""Preview-only flow - race is not confirmed until user clicks Confirm button"""
	Logger.debug("CharacterCreationRoot: _on_race_selected() - race: %s, subrace: %s" % [race_id, subrace_id if subrace_id != "" else "none"], "character_creation")
	
	preview_race = race_id
	preview_subrace = subrace_id if subrace_id != "" else ""
	selected_race = race_id  # kept for backward compat with preview panel
	selected_subrace = subrace_id  # kept for backward compat with preview panel
	
	# Update PlayerData with preview race data so preview panel can calculate final scores
	if PlayerData:
		# Find race data
		var race_data: Dictionary = {}
		for race in GameData.races:
			if race.get("id", "") == race_id:
				race_data = race
				break
		
		if not race_data.is_empty():
			PlayerData.race_id = race_id
			PlayerData.subrace_id = subrace_id if subrace_id != "" else ""
			PlayerData.race_data = race_data
			Logger.debug("CharacterCreationRoot: Updated PlayerData.race_id to %s, emitting racial_bonuses_updated" % race_id, "character_creation")
			PlayerData.racial_bonuses_updated.emit()
		else:
			Logger.warning("CharacterCreationRoot: Race data not found for race_id: %s" % race_id, "character_creation")
	else:
		Logger.error("CharacterCreationRoot: PlayerData is null!", "character_creation")
	
	_update_preview_panel(race_id, subrace_id)

func _on_player_stats_changed() -> void:
	"""Update preview panel when ability scores change"""
	if preview_race != "":
		_update_preview_panel(preview_race, preview_subrace)

func _on_racial_bonuses_updated() -> void:
	"""Update preview panel when racial bonuses change"""
	if preview_race != "":
		_update_preview_panel(preview_race, preview_subrace)

func _on_player_data_race_changed() -> void:
	"""Update AppearanceTab 3D preview when race changes in PlayerData"""
	if not PlayerData or PlayerData.race_id.is_empty():
		Logger.debug("CharacterCreationRoot: _on_player_data_race_changed() - PlayerData is null or race_id is empty", "character_creation")
		return
	
	Logger.debug("CharacterCreationRoot: _on_player_data_race_changed() - race_id: %s" % PlayerData.race_id, "character_creation")
	
	# Find AppearanceTab's CharacterPreview3D instance (dynamically loaded)
	var appearance_tab: Node = null
	if current_tab_instance and current_tab_instance.name == "AppearanceTab":
		appearance_tab = current_tab_instance
		Logger.debug("CharacterCreationRoot: Found AppearanceTab as current_tab_instance", "character_creation")
	else:
		# Search for AppearanceTab in the scene tree
		appearance_tab = get_tree().get_first_node_in_group("appearance_tab")
		if not appearance_tab:
			# Try finding it in content_area
			for child in content_area.get_children():
				if child.name == "AppearanceTab":
					appearance_tab = child
					Logger.debug("CharacterCreationRoot: Found AppearanceTab in content_area", "character_creation")
					break
	
	if appearance_tab:
		var preview: Node = appearance_tab.get_node_or_null("MainSplit/PreviewPanel/SubViewportContainer/CharacterPreview3D")
		if preview and preview.has_method("set_race"):
			Logger.debug("CharacterCreationRoot: Directly updating AppearanceTab preview to race: %s" % PlayerData.race_id, "character_creation")
			preview.set_race(PlayerData.race_id)
		else:
			Logger.warning("CharacterCreationRoot: Preview node not found or doesn't have set_race() method", "character_creation")
	else:
		Logger.debug("CharacterCreationRoot: AppearanceTab not loaded yet - will update when it loads", "character_creation")



func _on_class_selected(class_id: String, subclass_id: String) -> void:
	"""Preview-only flow - class is not confirmed until user clicks Confirm button"""
	selected_class = class_id
	# Store subclass preview if provided
	if subclass_id != "":
		# Subclass preview handling if needed
		pass

func _on_class_tab_completed() -> void:
	tab_navigation.enable_next_tab()

func _on_background_selected(bg_id: String) -> void:
	selected_background = bg_id

func _on_ability_score_tab_completed() -> void:
	"""Handle ability score tab completion"""
	Logger.debug("CharacterCreationRoot: Ability score tab completed", "character_creation")
	tab_navigation.enable_next_tab()

func _on_background_tab_completed() -> void:
	tab_navigation.enable_next_tab()

func _on_ability_scores_finalized(scores: Dictionary) -> void:
	final_ability_scores = scores

func _on_ability_tab_completed() -> void:
	tab_navigation.enable_next_tab()

func _on_appearance_completed(data: Dictionary) -> void:
	appearance_data = data

func _on_appearance_tab_completed() -> void:
	tab_navigation.enable_next_tab()

func _on_character_confirmed(character) -> void:
	# Save character resource
	var dir := DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("characters"):
			dir.make_dir("characters")
	
	var char_name: String = character.name
	var filename: String = char_name.to_lower().replace(" ", "_")
	var path: String = "user://characters/%s.tres" % filename
	var error := ResourceSaver.save(character, path)
	if error != OK:
		Logger.error("Failed to save character: %s" % error, "character_creation")
		return
	
	Logger.info("Character created: %s" % char_name, "character_creation")
	Logger.info("Saved to: %s" % path, "character_creation")
	
	# Return to main menu
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene:
		get_tree().change_scene_to_packed(main_scene)
		Logger.info("Returning to main menu", "character_creation")
	else:
		Logger.error("Main scene not found", "character_creation")

func _update_preview_panel(race_id: String, subrace_id: String) -> void:
	"""Update the right preview panel with race details"""
	var race_data: Dictionary = {}
	
	# Find race by ID
	for race in GameData.races:
		if race.get("id", "") == race_id:
			race_data = race
			break
	
	if race_data.is_empty():
		_show_default_preview()
		return
	
	# Handle subrace
	var display_name: String = race_data.get("name", "")
	var description: String = race_data.get("description", "")
	var features: Array = []
	var bonuses: Dictionary = race_data.get("ability_bonuses", {}).duplicate()
	
	# Initialize features from race data
	var race_features = race_data.get("features", [])
	if race_features is Array:
		for feat in race_features:
			if feat is String:
				features.append(feat)
	
	if subrace_id != "":
		var subraces: Array = race_data.get("subraces", [])
		for subrace in subraces:
			if subrace.get("id", "") == subrace_id:
				display_name = subrace.get("name", display_name)
				if subrace.has("description") and subrace.get("description", "") != "":
					description = subrace.get("description", description)
				if subrace.has("features"):
					var sub_features = subrace.get("features", [])
					if sub_features is Array:
						for feat in sub_features:
							if feat is String:
								features.append(feat)
				if subrace.has("ability_bonuses"):
					var sub_bonuses: Dictionary = subrace.get("ability_bonuses", {})
					for key in sub_bonuses.keys():
						bonuses[key] = bonuses.get(key, 0) + sub_bonuses[key]
				break
	
	# Update preview elements
	if preview_description:
		preview_description.text = description
	
	# Update speed and size
	var speed_value: String = race_data.get("speed", "")
	var size_value: String = race_data.get("size", "")
	if preview_speed_size:
		if speed_value != "" and size_value != "":
			preview_speed_size.text = "Speed: %s  Size: %s" % [speed_value, size_value]
		elif speed_value != "":
			preview_speed_size.text = "Speed: %s" % speed_value
		elif size_value != "":
			preview_speed_size.text = "Size: %s" % size_value
		else:
			preview_speed_size.text = ""
	
	# Build ability scores string with BBCode
	if preview_ability_scores:
		_build_ability_scores_text(bonuses)
	
	# Update features
	if preview_features_list:
		preview_features_list.clear()
		for feat in features:
			if feat is String and feat.length() > 0:
				preview_features_list.add_item("•  " + feat)

func _build_ability_scores_text(_bonuses: Dictionary) -> void:
	"""Build BBCode text for ability scores display - shows FINAL scores (base + racial bonus)"""
	if not PlayerData:
		Logger.warning("CharacterCreationRoot: PlayerData not available for ability scores preview", "character_creation")
		if preview_ability_scores:
			preview_ability_scores.text = ""
		return
	
	# Build BBCode text for all abilities showing FINAL scores
	var score_text := ""
	for abil_short in ABILITIES:
		var abil_key: String = ABILITY_MAP[abil_short]
		
		# Get final ability score (base + racial bonus) from PlayerData
		var final_score: int = PlayerData.get_final_ability_score(abil_key)
		
		# Get racial bonus for display
		var racial_bonus: int = PlayerData.get_racial_bonus(abil_key)
		
		# Defensive check: ensure final_score is valid (not 999 or invalid)
		if final_score < 0 or final_score > 30:
			Logger.error("CharacterCreationRoot: Invalid final_score %d for %s (abil_key: %s)" % [final_score, abil_short, abil_key], "character_creation")
			# Fallback to base score if final score is invalid
			var base_score: int = PlayerData.ability_scores.get(abil_key, 8)
			final_score = base_score + racial_bonus
			Logger.warning("CharacterCreationRoot: Using fallback score %d for %s" % [final_score, abil_short], "character_creation")
		
		# Format: "STR: 10" or "STR: 10 (+2)" if there's a bonus
		score_text += abil_short + ": " + str(final_score)
		
		if racial_bonus > 0:
			score_text += " [color=green](+" + str(racial_bonus) + ")[/color]"
		elif racial_bonus < 0:
			score_text += " [color=red](" + str(racial_bonus) + ")[/color]"
		
		score_text += "  "
	
	if preview_ability_scores:
		preview_ability_scores.text = "[center]" + score_text + "[/center]"
		Logger.debug("CharacterCreationRoot: Updated ability scores preview: %s" % score_text, "character_creation")
	else:
		Logger.warning("CharacterCreationRoot: preview_ability_scores label is null!", "character_creation")

func get_active_race_id() -> String:
	"""Get the active race ID (confirmed if available, otherwise preview)"""
	return confirmed_race if confirmed_race != "" else preview_race

func get_active_subrace_id() -> String:
	"""Get the active subrace ID (confirmed if available, otherwise preview)"""
	return confirmed_subrace if confirmed_subrace != "" else preview_subrace

func _show_default_preview() -> void:
	"""Show default state in preview panel"""
	if preview_subtitle:
		preview_subtitle.text = "Select a race"
	if preview_description:
		preview_description.text = ""
	if preview_speed_size:
		preview_speed_size.text = ""
	if preview_ability_scores:
		preview_ability_scores.text = ""
	if preview_features_list:
		preview_features_list.clear()
		preview_features_list.add_item("Features will appear here when a race is selected")

func _show_validation_error(message: String) -> void:
	"""Display validation error message to user"""
	Logger.warning("Validation error: %s" % message, "character_creation")
	# TODO: Implement proper error popup/notification UI
	# For now, just log the error

