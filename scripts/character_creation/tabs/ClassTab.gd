# ╔═══════════════════════════════════════════════════════════
# ║ ClassTab.gd
# ║ Desc: Class selection tab for character creation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends VBoxContainer

## Signal emitted when class is selected
signal class_selected(class_id: String, class_data: Dictionary)

## Selected class data
var selected_class: Dictionary = {}

## UI references
@onready var class_list: ItemList = %ClassList
@onready var description_label: Label = %DescriptionLabel
@onready var features_label: Label = %FeaturesLabel

## Classes data
var classes_data: Array = []


func _ready() -> void:
	"""Initialize class selection tab."""
	MythosLogger.verbose("UI/CharacterCreation/ClassTab", "_ready() called")
	_load_classes_data()
	_apply_ui_constants()
	_populate_class_list()
	_setup_connections()
	MythosLogger.info("UI/CharacterCreation/ClassTab", "Class tab initialized")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	if class_list != null:
		class_list.custom_minimum_size = Vector2(0, UIConstants.LIST_HEIGHT_STANDARD)
	
	if description_label != null:
		description_label.add_theme_constant_override("line_spacing", UIConstants.SPACING_SMALL)
	
	# Apply spacing to container
	add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)


func _load_classes_data() -> void:
	"""Load classes data from JSON file."""
	var file_path: String = "res://data/classes.json"
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		MythosLogger.error("UI/CharacterCreation/ClassTab", "Failed to load classes.json")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.error("UI/CharacterCreation/ClassTab", "Failed to parse classes.json: %s" % json.get_error_message())
		return
	
	var data: Dictionary = json.data
	classes_data = data.get("classes", [])
	MythosLogger.debug("UI/CharacterCreation/ClassTab", "Loaded %d classes" % classes_data.size())


func _populate_class_list() -> void:
	"""Populate the class list with available classes."""
	if class_list == null:
		return
	
	class_list.clear()
	for class_data: Dictionary in classes_data:
		var class_name: String = class_data.get("name", "Unknown")
		class_list.add_item(class_name)
	
	if class_list.get_item_count() > 0:
		class_list.select(0)
		_on_class_item_selected(0)


func _setup_connections() -> void:
	"""Setup signal connections."""
	if class_list != null:
		class_list.item_selected.connect(_on_class_item_selected)


func _on_class_item_selected(index: int) -> void:
	"""Handle class selection."""
	if index < 0 or index >= classes_data.size():
		return
	
	var class_data: Dictionary = classes_data[index]
	selected_class = class_data
	
	# Update description
	if description_label != null:
		description_label.text = class_data.get("description", "No description available.")
	
	# Update features
	if features_label != null:
		var features: Array = class_data.get("features", [])
		if features.size() > 0:
			features_label.text = "Features: " + ", ".join(features)
		else:
			features_label.text = ""
	
	# Emit signal
	var class_id: String = class_data.get("id", "")
	class_selected.emit(class_id, class_data)
	MythosLogger.debug("UI/CharacterCreation/ClassTab", "Class selected: %s" % class_id)


func get_selected_class() -> Dictionary:
	"""Get the currently selected class data."""
	return selected_class
