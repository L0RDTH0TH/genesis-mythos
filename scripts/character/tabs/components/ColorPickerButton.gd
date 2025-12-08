# ╔═══════════════════════════════════════════════════════════
# ║ ColorPickerButton.gd
# ║ Desc: Color swatch button with popup picker
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Button

signal color_changed(new_color: Color)

@onready var swatch: ColorRect = $ColorSwatch

var current_color: Color = Color.WHITE

func _ready() -> void:
	swatch.color = current_color
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var picker := ColorPicker.new()
	picker.color = current_color
	picker.color_changed.connect(_on_color_picked)
	var popup := PopupPanel.new()
	popup.custom_minimum_size = Vector2(400, 500)
	var container := MarginContainer.new()
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	container.add_child(picker)
	popup.add_child(container)
	add_child(popup)
	popup.popup_centered(Vector2(400, 500))
	popup.popup_hide.connect(func(): popup.queue_free())

func _on_color_picked(color: Color) -> void:
	current_color = color
	swatch.color = color
	color_changed.emit(color)

