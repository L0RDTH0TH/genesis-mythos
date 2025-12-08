# ╔═══════════════════════════════════════════════════════════
# ║ ClassEntry.gd
# ║ Desc: BG3-style class button with icon, name, and description
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name ClassEntry
extends PanelContainer

@onready var panel: PanelContainer = self
@onready var icon: TextureRect = %Icon
@onready var class_name_label: Label = %ClassNameLabel
@onready var description_label: RichTextLabel = %DescriptionLabel

var class_data: Dictionary = {}
var subclass_data: Dictionary = {}
var is_selected: bool = false

signal class_selected(class_id: String, subclass_id: String)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	
	# Set initial style
	_update_style()
	
	# Update display if data is already set
	if not class_data.is_empty():
		_update_display()

func setup(class_dict: Dictionary, subclass_dict: Dictionary = {}) -> void:
	"""Setup the entry with class and optional subclass data"""
	class_data = class_dict
	subclass_data = subclass_dict
	
	# Update display
	_update_display()

func _update_display() -> void:
	"""Update the visual display of the entry"""
	if not is_inside_tree():
		call_deferred("_update_display")
		return
	
	# Determine display name (subclass name if present, otherwise class name)
	var display_name: String = ""
	if not subclass_data.is_empty() and subclass_data.has("name"):
		display_name = subclass_data.get("name", "")
	else:
		display_name = class_data.get("name", "")
	
	if class_name_label:
		class_name_label.text = display_name
	
	# Build description text
	_build_description()
	
	# Set icon placeholder
	_setup_icon()

func _build_description() -> void:
	"""Build the description text from class/subclass data"""
	if not description_label:
		return
	
	var desc_text: String = ""
	
	# Use subclass description if available, otherwise class description
	if not subclass_data.is_empty() and subclass_data.has("description"):
		desc_text = subclass_data.get("description", "")
	elif class_data.has("description"):
		desc_text = class_data.get("description", "")
	
	# Format with BBCode
	if desc_text != "":
		description_label.text = "[center]%s[/center]" % desc_text
	else:
		description_label.text = ""

func _setup_icon() -> void:
	"""Setup the icon placeholder"""
	if not icon:
		return
	
	# Remove existing placeholder if any
	for child in icon.get_children():
		if child.name == "Placeholder":
			child.queue_free()
	
	# Create colored placeholder based on class name hash
	var color_seed: int = class_data.get("name", "Unknown").hash()
	var hue: float = abs(color_seed % 360) / 360.0
	var color := Color.from_hsv(hue, 0.6, 0.8)
	
	var placeholder := ColorRect.new()
	placeholder.name = "Placeholder"
	placeholder.color = color
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(placeholder)
	
	# Set placeholder to fill the icon
	placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)

func _on_gui_input(event: InputEvent) -> void:
	"""Handle mouse input"""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_class()

func _on_mouse_entered() -> void:
	"""Handle mouse enter"""
	if not is_selected:
		_update_style("hover")

func _on_mouse_exited() -> void:
	"""Handle mouse exit"""
	_update_style()

func _select_class() -> void:
	"""Handle class selection"""
	is_selected = true
	_update_style("selected")
	
	var class_id: String = class_data.get("id", "")
	var subclass_id: String = subclass_data.get("id", "") if not subclass_data.is_empty() else ""
	class_selected.emit(class_id, subclass_id)

func set_selected(value: bool) -> void:
	"""Set the selected state of this entry"""
	is_selected = value
	_update_style()

func _update_style(state: String = "normal") -> void:
	"""Update the visual style based on state"""
	if is_selected:
		state = "selected"
	
	var theme_resource := load("res://themes/bg3_theme.tres") as Theme
	if not theme_resource:
		return
	
	var style_name: String = "race_button_" + state  # Reuse race button styles
	var stylebox := theme_resource.get_stylebox(style_name, "PanelContainer")
	if stylebox:
		add_theme_stylebox_override("panel", stylebox)
