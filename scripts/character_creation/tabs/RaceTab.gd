# ╔═══════════════════════════════════════════════════════════
# ║ RaceTab.gd
# ║ Desc: Race selection tab for character creation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends VBoxContainer

## Signal emitted when race is selected
signal race_selected(race_id: String, race_data: Dictionary)

## Selected race data
var selected_race: Dictionary = {}

## UI references
@onready var race_list: ItemList = %RaceList
@onready var description_label: Label = %DescriptionLabel
@onready var traits_label: Label = %TraitsLabel

## Races data
var races_data: Array = []


func _ready() -> void:
	"""Initialize race selection tab."""
	MythosLogger.verbose("UI/CharacterCreation/RaceTab", "_ready() called")
	_load_races_data()
	_apply_ui_constants()
	_populate_race_list()
	_setup_connections()
	MythosLogger.info("UI/CharacterCreation/RaceTab", "Race tab initialized")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	if race_list != null:
		race_list.custom_minimum_size = Vector2(0, UIConstants.LIST_HEIGHT_STANDARD)
	
	if description_label != null:
		description_label.add_theme_constant_override("line_spacing", UIConstants.SPACING_SMALL)
	
	# Apply spacing to container
	add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)


func _load_races_data() -> void:
	"""Load races data from JSON file."""
	var file_path: String = "res://data/races.json"
	var data: Variant = DataCache.get_json_data(file_path)
	if data == null:
		MythosLogger.error("UI/CharacterCreation/RaceTab", "Failed to load races.json")
		return
	
	if not data is Dictionary:
		MythosLogger.error("UI/CharacterCreation/RaceTab", "Invalid races.json format")
		return
	
	races_data = data.get("races", [])
	MythosLogger.debug("UI/CharacterCreation/RaceTab", "Loaded %d races" % races_data.size())


func _populate_race_list() -> void:
	"""Populate the race list with available races."""
	if race_list == null:
		return
	
	race_list.clear()
	for race: Dictionary in races_data:
		var race_name: String = race.get("name", "Unknown")
		race_list.add_item(race_name)
	
	if race_list.get_item_count() > 0:
		race_list.select(0)
		_on_race_item_selected(0)


func _setup_connections() -> void:
	"""Setup signal connections."""
	if race_list != null:
		race_list.item_selected.connect(_on_race_item_selected)


func _on_race_item_selected(index: int) -> void:
	"""Handle race selection."""
	if index < 0 or index >= races_data.size():
		return
	
	var race: Dictionary = races_data[index]
	selected_race = race
	
	# Update description
	if description_label != null:
		description_label.text = race.get("description", "No description available.")
	
	# Update traits
	if traits_label != null:
		var traits: Array = race.get("traits", [])
		if traits.size() > 0:
			traits_label.text = "Traits: " + ", ".join(traits)
		else:
			traits_label.text = ""
	
	# Emit signal
	var race_id: String = race.get("id", "")
	race_selected.emit(race_id, race)
	MythosLogger.debug("UI/CharacterCreation/RaceTab", "Race selected: %s" % race_id)


func get_selected_race() -> Dictionary:
	"""Get the currently selected race data."""
	return selected_race
