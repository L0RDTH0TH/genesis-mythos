# ╔═══════════════════════════════════════════════════════════
# ║ NameConfirmTab.gd
# ║ Desc: Final confirmation tab for character creation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends VBoxContainer

## Signal emitted when character is confirmed
signal character_confirmed(character_data: Dictionary)

## Character name
var character_name: String = ""

## Character summary data
var character_summary: Dictionary = {}

## UI references
@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var summary_area: VBoxContainer = %SummaryArea
@onready var summary_label: Label = %SummaryLabel


func _ready() -> void:
	"""Initialize name and confirmation tab."""
	MythosLogger.verbose("UI/CharacterCreation/NameConfirmTab", "_ready() called")
	_apply_ui_constants()
	_setup_connections()
	MythosLogger.info("UI/CharacterCreation/NameConfirmTab", "Name & Confirm tab initialized")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	if name_line_edit != null:
		name_line_edit.custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_SMALL)
	
	if summary_area != null:
		summary_area.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
	
	# Apply spacing to container
	add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)


func _setup_connections() -> void:
	"""Setup signal connections."""
	if name_line_edit != null:
		name_line_edit.text_changed.connect(_on_name_changed)


func _on_name_changed(new_text: String) -> void:
	"""Handle character name change."""
	character_name = new_text
	MythosLogger.debug("UI/CharacterCreation/NameConfirmTab", "Character name changed to: %s" % character_name)


func set_character_summary(summary: Dictionary) -> void:
	"""Set the character summary to display."""
	character_summary = summary
	_update_summary_display()


func _update_summary_display() -> void:
	"""Update the character summary display."""
	if summary_label == null:
		return
	
	var summary_lines: Array[String] = []
	summary_lines.append("Character Summary:")
	summary_lines.append("")
	
	if character_summary.has("race"):
		summary_lines.append("Race: %s" % character_summary.get("race", "Unknown"))
	if character_summary.has("class"):
		summary_lines.append("Class: %s" % character_summary.get("class", "Unknown"))
	if character_summary.has("background"):
		summary_lines.append("Background: %s" % character_summary.get("background", "Unknown"))
	
	summary_lines.append("")
	summary_lines.append("Name: %s" % (character_name if character_name != "" else "Unnamed"))
	
	summary_label.text = "\n".join(summary_lines)


func get_character_data() -> Dictionary:
	"""Get complete character data for creation."""
	var data: Dictionary = character_summary.duplicate()
	data["name"] = character_name
	return data


func confirm_character() -> void:
	"""Confirm character creation."""
	var character_data: Dictionary = get_character_data()
	character_confirmed.emit(character_data)
	MythosLogger.info("UI/CharacterCreation/NameConfirmTab", "Character confirmed: %s" % character_name)
