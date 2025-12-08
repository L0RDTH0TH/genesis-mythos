# ╔══════════════════════════════════════════════════════════════════════════════
# ║ NameConfirmTab.gd
# ║ Desc: Final tab for name entry, voice selection, choices summary, and confirmation
# ║ Author: Grok + Cursor
# ╚══════════════════════════════════════════════════════════════════════════════
extends Control

const CharacterData = preload("res://resources/CharacterData.gd")
const CharacterCreationRoot = preload("res://scripts/character/CharacterCreationRoot.gd")

signal character_confirmed(character)

@onready var race_summary: Label = $MainSplit/SummaryPanel/MarginContainer/SummaryBox/RaceSummary
@onready var class_summary: Label = $MainSplit/SummaryPanel/MarginContainer/SummaryBox/ClassSummary
@onready var background_summary: Label = $MainSplit/SummaryPanel/MarginContainer/SummaryBox/BackgroundSummary
@onready var abilities_grid: GridContainer = $MainSplit/SummaryPanel/MarginContainer/SummaryBox/AbilitiesGrid
@onready var appearance_details: RichTextLabel = $MainSplit/SummaryPanel/MarginContainer/SummaryBox/AppearanceDetails
@onready var name_entry: LineEdit = $MainSplit/RightColumn/NameEntry
@onready var voice_grid: GridContainer = $MainSplit/RightColumn/ScrollContainer/VoiceGrid
@onready var confirm_btn: Button = $MainSplit/RightColumn/ConfirmButton

var voice_entry_scene: PackedScene = preload("res://scenes/character/tabs/components/VoiceEntry.tscn")
var selected_voice: String = ""
var character_name: String = ""

func _ready() -> void:
	Logger.debug("NameConfirmTab: _ready() called", "character_creation")
	
	# Null check for button before connecting signals
	if not confirm_btn:
		Logger.error("NameConfirmTab: ConfirmButton node not found!", "character_creation")
		return
	
	_populate_summary()
	_populate_voices()
	
	# Connect signals with null checks
	if name_entry:
		name_entry.text_changed.connect(_on_name_changed)
	else:
		Logger.error("NameConfirmTab: NameEntry node not found!", "character_creation")
	
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm)
		Logger.debug("NameConfirmTab: ConfirmButton signal connected", "character_creation")
	else:
		Logger.error("NameConfirmTab: ConfirmButton node not found for signal connection!", "character_creation")
	
	# Initialize button state (critical fix)
	_update_confirm_button()
	Logger.debug("NameConfirmTab: Initialization complete - button state: disabled=%s" % confirm_btn.disabled, "character_creation")

func _populate_summary() -> void:
	Logger.debug("NameConfirmTab: Populating summary", "character_creation")
	var root: Node = get_tree().get_first_node_in_group("character_creation_root")
	if not root:
		# Try to find CharacterCreationRoot by traversing up the tree
		var node: Node = get_parent()
		while node and not node.is_in_group("character_creation_root"):
			node = node.get_parent()
		root = node
	
	if not root:
		Logger.error("Could not find CharacterCreationRoot", "character_creation")
		return
	
	Logger.debug("NameConfirmTab: Found CharacterCreationRoot", "character_creation")
	
	var race_text: String = root.get("selected_race").capitalize()
	if root.get("selected_subrace") != "":
		race_text += " (%s)" % root.get("selected_subrace").capitalize()
	race_summary.text = "Race: %s" % race_text
	Logger.debug("NameConfirmTab: Race summary set to: %s" % race_text, "character_creation")
	
	class_summary.text = "Class: %s" % root.get("selected_class").capitalize()
	Logger.debug("NameConfirmTab: Class summary set to: %s" % root.get("selected_class"), "character_creation")
	background_summary.text = "Background: %s" % root.get("selected_background").capitalize()
	Logger.debug("NameConfirmTab: Background summary set to: %s" % root.get("selected_background"), "character_creation")
	
	for child in abilities_grid.get_children():
		child.queue_free()
	
	var final_scores: Dictionary = root.get("final_ability_scores") as Dictionary
	if not final_scores:
		final_scores = {}
	for abil in GameData.abilities.keys():
		var label := Label.new()
		label.text = "%s: " % GameData.abilities[abil].short
		label.add_theme_font_size_override("font_size", 28)
		abilities_grid.add_child(label)
		
		var value_label := Label.new()
		var score: int = final_scores.get(abil, 10)
		var mod: int = floor((score - 10) / 2.0)
		value_label.text = "%d (%+d)" % [score, mod]
		value_label.add_theme_font_size_override("font_size", 28)
		value_label.add_theme_color_override("font_color", Color("#ffd700") if mod >= 0 else Color("#ff6b6b"))
		abilities_grid.add_child(value_label)
	
	var appearance_data: Dictionary = root.get("appearance_data") as Dictionary
	if not appearance_data:
		appearance_data = {}
	var app_text := "[b]Appearance:[/b]\n"
	app_text += "Head: %s\n" % appearance_data.get("head", "N/A")
	app_text += "Hair: %s\n" % appearance_data.get("hair", "N/A")
	var skin_color: Color = appearance_data.get("skin_color", Color.WHITE)
	var hair_color: Color = appearance_data.get("hair_color", Color.WHITE)
	var eye_color: Color = appearance_data.get("eye_color", Color.WHITE)
	app_text += "Skin Color: %s\n" % skin_color.to_html()
	app_text += "Hair Color: %s\n" % hair_color.to_html()
	app_text += "Eye Color: %s" % eye_color.to_html()
	appearance_details.text = app_text

func _populate_voices() -> void:
	for voice in GameData.voices:
		var entry := voice_entry_scene.instantiate()
		entry.setup(voice)
		entry.voice_selected.connect(_on_voice_selected)
		voice_grid.add_child(entry)

func _on_voice_selected(voice_id: String) -> void:
	selected_voice = voice_id
	Logger.log_user_action("select_voice", voice_id, "character_creation")
	_update_confirm_button()

func _on_name_changed(new_text: String) -> void:
	character_name = new_text.strip_edges()
	Logger.debug("NameConfirmTab: Name changed to: %s" % character_name, "character_creation")
	_update_confirm_button()

func _update_confirm_button() -> void:
	"""Update confirm button state based on name and voice selection"""
	if not confirm_btn:
		Logger.warning("NameConfirmTab: Cannot update button state - button is null", "character_creation")
		return
	
	var was_disabled: bool = confirm_btn.disabled
	var should_disable: bool = character_name.is_empty() or selected_voice.is_empty()
	confirm_btn.disabled = should_disable
	
	# Log state change for debugging
	if was_disabled != should_disable:
		Logger.debug("NameConfirmTab: Button state changed - disabled=%s (name='%s', voice='%s')" % [
			should_disable, character_name, selected_voice
		], "character_creation")

func _on_confirm() -> void:
	"""Handle confirm button press - validates and creates character"""
	Logger.info("NameConfirmTab: Character confirmation initiated", "character_creation")
	
	# Validate inputs before proceeding
	if character_name.is_empty():
		Logger.warning("NameConfirmTab: Cannot confirm - name is empty", "character_creation")
		return
	
	if selected_voice.is_empty():
		Logger.warning("NameConfirmTab: Cannot confirm - voice not selected", "character_creation")
		return
	
	# Disable button immediately to prevent double-clicks
	if confirm_btn:
		confirm_btn.disabled = true
		Logger.debug("NameConfirmTab: Button disabled after confirmation click", "character_creation")
	
	Logger.log_user_action("confirm_character", "", "character_creation", {
		"name": character_name,
		"voice": selected_voice
	})
	
	# Find CharacterCreationRoot
	var root: Node = get_tree().get_first_node_in_group("character_creation_root")
	if not root:
		var node: Node = get_parent()
		while node and not node.is_in_group("character_creation_root"):
			node = node.get_parent()
		root = node
	
	if not root:
		Logger.error("NameConfirmTab: Could not find CharacterCreationRoot", "character_creation")
		# Re-enable button if error occurs
		if confirm_btn:
			confirm_btn.disabled = false
		return
	
	Logger.debug("NameConfirmTab: CharacterCreationRoot found, creating character data", "character_creation")
	
	# Create character resource
	var character: Resource = CharacterData.new()
	character.set("name", character_name)
	
	# Get values from root with null checks
	var race_val = root.get("selected_race")
	var subrace_val = root.get("selected_subrace")
	var class_val = root.get("selected_class")
	var background_val = root.get("selected_background")
	
	character.set("race", race_val if race_val else "")
	character.set("subrace", subrace_val if subrace_val else "")
	character.set("character_class", class_val if class_val else "")
	character.set("background", background_val if background_val else "")
	
	var ability_scores: Dictionary = root.get("final_ability_scores") as Dictionary
	if not ability_scores:
		ability_scores = {}
	character.set("ability_scores", ability_scores.duplicate())
	
	var appearance: Dictionary = root.get("appearance_data") as Dictionary
	if not appearance:
		appearance = {}
	character.set("appearance", appearance.duplicate())
	character.set("voice", selected_voice)
	
	Logger.log_structured(Logger.LOG_LEVEL.INFO, "CharacterCreated", "character_creation", {
		"name": character_name,
		"race": race_val if race_val else "",
		"subrace": subrace_val if subrace_val else "",
		"class": class_val if class_val else "",
		"background": background_val if background_val else ""
	})
	
	Logger.debug("NameConfirmTab: Emitting character_confirmed signal", "character_creation")
	character_confirmed.emit(character)
	Logger.debug("NameConfirmTab: character_confirmed signal emitted", "character_creation")

