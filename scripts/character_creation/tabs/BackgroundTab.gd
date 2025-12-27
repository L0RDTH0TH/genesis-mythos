# ╔═══════════════════════════════════════════════════════════
# ║ BackgroundTab.gd
# ║ Desc: Background selection tab for character creation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends VBoxContainer

## Signal emitted when background is selected
signal background_selected(background_id: String, background_data: Dictionary)

## Selected background data
var selected_background: Dictionary = {}

## UI references
@onready var background_list: ItemList = %BackgroundList
@onready var description_label: Label = %DescriptionLabel
@onready var details_label: Label = %DetailsLabel

## Backgrounds data
var backgrounds_data: Array = []


func _ready() -> void:
	"""Initialize background selection tab."""
	MythosLogger.verbose("UI/CharacterCreation/BackgroundTab", "_ready() called")
	_load_backgrounds_data()
	_apply_ui_constants()
	_populate_background_list()
	_setup_connections()
	MythosLogger.info("UI/CharacterCreation/BackgroundTab", "Background tab initialized")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	if background_list != null:
		background_list.custom_minimum_size = Vector2(0, UIConstants.LIST_HEIGHT_STANDARD)
	
	if description_label != null:
		description_label.add_theme_constant_override("line_spacing", UIConstants.SPACING_SMALL)
	
	# Apply spacing to container
	add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)


func _load_backgrounds_data() -> void:
	"""Load backgrounds data from JSON file."""
	var file_path: String = "res://data/backgrounds.json"
	var data: Variant = DataCache.get_json_data(file_path)
	if data == null:
		MythosLogger.error("UI/CharacterCreation/BackgroundTab", "Failed to load backgrounds.json")
		return
	
	if not data is Dictionary:
		MythosLogger.error("UI/CharacterCreation/BackgroundTab", "Invalid backgrounds.json format")
		return
	
	backgrounds_data = data.get("backgrounds", [])
	MythosLogger.debug("UI/CharacterCreation/BackgroundTab", "Loaded %d backgrounds" % backgrounds_data.size())


func _populate_background_list() -> void:
	"""Populate the background list with available backgrounds."""
	if background_list == null:
		return
	
	background_list.clear()
	for background: Dictionary in backgrounds_data:
		var background_name: String = background.get("name", "Unknown")
		background_list.add_item(background_name)
	
	if background_list.get_item_count() > 0:
		background_list.select(0)
		_on_background_item_selected(0)


func _setup_connections() -> void:
	"""Setup signal connections."""
	if background_list != null:
		background_list.item_selected.connect(_on_background_item_selected)


func _on_background_item_selected(index: int) -> void:
	"""Handle background selection."""
	if index < 0 or index >= backgrounds_data.size():
		return
	
	var background: Dictionary = backgrounds_data[index]
	selected_background = background
	
	# Update description
	if description_label != null:
		description_label.text = background.get("description", "No description available.")
	
	# Update details
	if details_label != null:
		var details: Array[String] = []
		var feature: String = background.get("feature", "")
		if feature != "":
			details.append("Feature: " + feature)
		
		var skills: Array = background.get("skill_proficiencies", [])
		if skills.size() > 0:
			details.append("Skills: " + ", ".join(skills))
		
		details_label.text = "\n".join(details) if details.size() > 0 else ""
	
	# Emit signal
	var background_id: String = background.get("id", "")
	background_selected.emit(background_id, background)
	MythosLogger.debug("UI/CharacterCreation/BackgroundTab", "Background selected: %s" % background_id)


func get_selected_background() -> Dictionary:
	"""Get the currently selected background data."""
	return selected_background
