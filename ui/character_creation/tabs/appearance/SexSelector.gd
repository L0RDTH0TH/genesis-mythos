# ╔═══════════════════════════════════════════════════════════
# ║ SexSelector.gd
# ║ Desc: OptionButton that switches between male/female base models
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name SexSelector
extends HBoxContainer

signal sex_changed(sex_id: int)

@onready var option_button: OptionButton = $OptionButton
@onready var label: Label = $Label

var sex_data: Array[Dictionary] = []

func _ready() -> void:
	label.text = "Sex"
	_load_sex_data()
	_populate_options()
	option_button.item_selected.connect(_on_sex_selected)

func _load_sex_data() -> void:
	"""Load sex variant data from JSON"""
	var file: FileAccess = FileAccess.open("res://data/character/sex_variants.json", FileAccess.READ)
	if not file:
		Logger.error("SexSelector: Cannot load sex_variants.json", "character_creation")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		Logger.error("SexSelector: Failed to parse sex_variants.json - Line %d: %s" % [json.get_error_line(), json.get_error_message()], "character_creation")
		return
	
	if not json.data is Dictionary:
		Logger.error("SexSelector: sex_variants.json root is not a Dictionary", "character_creation")
		return
	
	if not json.data.has("variants") or not json.data["variants"] is Array:
		Logger.error("SexSelector: sex_variants.json missing 'variants' array", "character_creation")
		return
	
	# Manually convert to typed array
	var variants_array: Array = json.data["variants"] as Array
	sex_data.clear()
	for variant in variants_array:
		if variant is Dictionary:
			sex_data.append(variant as Dictionary)
	
	Logger.debug("SexSelector: Loaded %d sex variants" % sex_data.size(), "character_creation")

func _populate_options() -> void:
	"""Populate OptionButton with sex variant options"""
	for variant in sex_data:
		if not variant is Dictionary:
			continue
		var variant_id: int = variant.get("id", -1)
		var display_name: String = variant.get("display_name", "Unknown")
		
		option_button.add_item(display_name, variant_id)
		
		# Set icon if available
		var icon_path: String = variant.get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			var icon_texture: Texture2D = load(icon_path)
			if icon_texture:
				var item_index: int = option_button.get_item_count() - 1
				option_button.set_item_icon(item_index, icon_texture)
	
	Logger.debug("SexSelector: Populated %d options" % option_button.item_count, "character_creation")

func _on_sex_selected(index: int) -> void:
	"""Handle sex selection change"""
	var selected_id: int = option_button.get_item_id(index)
	Logger.debug("SexSelector: Sex changed to ID %d" % selected_id, "character_creation")
	sex_changed.emit(selected_id)

func get_current_sex_id() -> int:
	"""Get the currently selected sex ID"""
	if option_button.selected < 0:
		return 0
	return option_button.get_item_id(option_button.selected)

func set_sex_without_signal(sex_id: int) -> void:
	"""Set the sex without emitting the signal"""
	for i in range(option_button.item_count):
		if option_button.get_item_id(i) == sex_id:
			option_button.select(i)
			break

func get_variant_data(sex_id: int) -> Dictionary:
	"""Get variant data dictionary for a given sex ID"""
	if sex_id < 0 or sex_id >= sex_data.size():
		return {}
	return sex_data[sex_id]

func get_variant_count() -> int:
	"""Get the number of available variants"""
	return sex_data.size()

