# ╔═══════════════════════════════════════════════════════════
# ║ BackgroundEntry.gd
# ║ Desc: BG3-style background button with icon, name, and skills preview
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name BackgroundEntry
extends PanelContainer

@onready var panel: PanelContainer = self
@onready var icon: TextureRect = %Icon
@onready var background_name_label: Label = %BackgroundNameLabel
@onready var skills_preview_label: RichTextLabel = %SkillsPreviewLabel

var background_data: Dictionary = {}
var is_selected: bool = false

signal background_selected(background_id: String)

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
	if not background_data.is_empty():
		_update_display()

func setup(data: Dictionary) -> void:
	background_data = data
	
	# Update display
	_update_display()

func _update_display() -> void:
	if not is_inside_tree():
		call_deferred("_update_display")
		return
	
	if background_name_label:
		background_name_label.text = background_data.get("name", "")
	
	# Build skills preview text
	_build_skills_preview()
	
	# Set icon placeholder (ColorRect for now)
	_setup_icon()

func _build_skills_preview() -> void:
	if not skills_preview_label:
		return
	
	var skills: Array = background_data.get("skill_proficiencies", [])
	
	if skills.is_empty():
		skills_preview_label.text = ""
		return
	
	var skills_text := ""
	for i in range(skills.size()):
		if i > 0:
			skills_text += ", "
		skills_text += skills[i]
	
	skills_preview_label.text = "[center][b]Skills:[/b] %s[/center]" % skills_text

func _setup_icon() -> void:
	if not icon:
		return
	
	# Create a placeholder ColorRect as child of icon
	# Remove existing placeholder if any
	for child in icon.get_children():
		if child.name == "Placeholder":
			child.queue_free()
	
	# Create colored placeholder based on background name hash
	var color_seed: int = background_data.get("name", "Unknown").hash()
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
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_background()

func _on_mouse_entered() -> void:
	if not is_selected:
		_update_style("hover")

func _on_mouse_exited() -> void:
	_update_style()

func _select_background() -> void:
	is_selected = true
	_update_style("selected")
	
	var background_id: String = background_data.get("id", "")
	background_selected.emit(background_id)

func set_selected(value: bool) -> void:
	is_selected = value
	_update_style()

func _update_style(state: String = "normal") -> void:
	if is_selected:
		state = "selected"
	
	var theme_resource := load("res://themes/bg3_theme.tres") as Theme
	if not theme_resource:
		return
	
	var style_name: String = "background_button_" + state
	var stylebox := theme_resource.get_stylebox(style_name, "PanelContainer")
	if stylebox:
		add_theme_stylebox_override("panel", stylebox)
