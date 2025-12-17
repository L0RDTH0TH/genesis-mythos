# ╔═══════════════════════════════════════════════════════════
# ║ AppearanceTab.gd
# ║ Desc: Appearance customization tab for character creation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends VBoxContainer

## Signal emitted when appearance changes
signal appearance_changed(appearance_data: Dictionary)

## Appearance data
var appearance_data: Dictionary = {
	"skin_tone": 0,
	"hair_style": 0,
	"hair_color": 0,
	"eye_color": 0
}

## UI references
@onready var appearance_options: VBoxContainer = %AppearanceOptions


func _ready() -> void:
	"""Initialize appearance customization tab."""
	MythosLogger.verbose("UI/CharacterCreation/AppearanceTab", "_ready() called")
	_apply_ui_constants()
	_create_appearance_controls()
	MythosLogger.info("UI/CharacterCreation/AppearanceTab", "Appearance tab initialized")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	if appearance_options != null:
		appearance_options.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
	
	# Apply spacing to container
	add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)


func _create_appearance_controls() -> void:
	"""Create appearance customization controls."""
	if appearance_options == null:
		return
	
	# Skin Tone
	_create_slider_control("Skin Tone", "skin_tone", 0, 10, 0)
	
	# Hair Style
	_create_slider_control("Hair Style", "hair_style", 0, 10, 0)
	
	# Hair Color
	_create_slider_control("Hair Color", "hair_color", 0, 10, 0)
	
	# Eye Color
	_create_slider_control("Eye Color", "eye_color", 0, 10, 0)


func _create_slider_control(label_text: String, key: String, min_val: int, max_val: int, default_val: int) -> void:
	"""Create a slider control for appearance option."""
	var container: HBoxContainer = HBoxContainer.new()
	container.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
	
	var label: Label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
	container.add_child(label)
	
	var slider: HSlider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 1.0
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v): _on_appearance_value_changed(key, int(v)))
	container.add_child(slider)
	
	var value_label: Label = Label.new()
	value_label.text = str(default_val)
	value_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_NARROW, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(value_label)
	
	# Update value label when slider changes
	slider.value_changed.connect(func(v): value_label.text = str(int(v)))
	
	appearance_options.add_child(container)


func _on_appearance_value_changed(key: String, value: int) -> void:
	"""Handle appearance value change."""
	appearance_data[key] = value
	appearance_changed.emit(appearance_data)
	MythosLogger.debug("UI/CharacterCreation/AppearanceTab", "Appearance %s changed to %d" % [key, value])


func get_appearance_data() -> Dictionary:
	"""Get current appearance data."""
	return appearance_data.duplicate()
