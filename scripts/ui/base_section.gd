# ╔═══════════════════════════════════════════════════════════
# ║ base_section.gd
# ║ Desc: Base collapsible section with animated toggle
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

@onready var toggle_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/Button
@onready var title_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Label
@onready var content_container: VBoxContainer = $MarginContainer/VBoxContainer/content

var is_expanded: bool = false
var tween: Tween

func _ready() -> void:
	"""Initialize section with collapsed state."""
	if not Engine.is_editor_hint():
		content_container.visible = false
		content_container.modulate.a = 0.0
		is_expanded = false
		_update_toggle_icon()
		toggle_button.pressed.connect(_on_toggle_pressed)

func _on_toggle_pressed() -> void:
	"""Handle collapse/expand toggle with animation."""
	is_expanded = !is_expanded
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if is_expanded:
		content_container.visible = true
		content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tween.tween_property(content_container, "modulate:a", 1.0, 0.3)
	else:
		content_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tween.tween_property(content_container, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): content_container.visible = false)
	
	_update_toggle_icon()

func _update_toggle_icon() -> void:
	"""Update toggle button icon based on expanded state."""
	if is_expanded:
		toggle_button.text = "▼"
	else:
		toggle_button.text = "▶"

