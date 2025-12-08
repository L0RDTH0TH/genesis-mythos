# ╔═══════════════════════════════════════════════════════════
# ║ SkyrimSlider.gd
# ║ Desc: Single Skyrim-style labeled slider with live value display
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

@tool
extends HBoxContainer

@export var slider_id: String = ""
@export var label_text: String = "Slider" : set = _set_label
@export var min_value: float = 0.0 : set = _set_min
@export var max_value: float = 1.0 : set = _set_max
@export var default_value: float = 0.5
@export var step_size: float = 0.01

@onready var slider_label: Label = $SliderLabel
@onready var value_slider: HSlider = $ValueSlider
@onready var value_label: Label = $ValueLabel

signal value_changed(id: String, value: float)

func _ready() -> void:
	_set_label(label_text)
	_set_min(min_value)
	_set_max(max_value)
	value_slider.step = step_size
	value_slider.value = default_value
	_update_value_label()
	value_slider.value_changed.connect(_on_slider_changed)

func _set_label(text: String) -> void:
	label_text = text
	if slider_label:
		slider_label.text = text + ":"

func _set_min(val: float) -> void:
	min_value = val
	if value_slider:
		value_slider.min_value = val

func _set_max(val: float) -> void:
	max_value = val
	if value_slider:
		value_slider.max_value = val

func _on_slider_changed(new_value: float) -> void:
	_update_value_label()
	value_changed.emit(slider_id, new_value)

func _update_value_label() -> void:
	if value_label:
		value_label.text = "%.3f" % value_slider.value

func set_value_without_signal(val: float) -> void:
	value_slider.value = val

