# ╔═══════════════════════════════════════════════════════════
# ║ biome_section.gd
# ║ Desc: Biome section with humidity and temperature controls
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

signal param_changed(param: String, value: Variant)

@onready var humidity_slider: HSlider = $MarginContainer/VBoxContainer/content/HumidityContainer/HumiditySlider
@onready var humidity_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/HumidityContainer/HumiditySpinBox
@onready var temperature_slider: HSlider = $MarginContainer/VBoxContainer/content/TemperatureContainer/TemperatureSlider
@onready var temperature_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/TemperatureContainer/TemperatureSpinBox

func _ready() -> void:
	"""Initialize biome section controls and connections."""
	# Connect humidity controls
	humidity_slider.value_changed.connect(_on_humidity_changed)
	humidity_spinbox.value_changed.connect(_on_humidity_spinbox_changed)
	
	# Connect temperature controls
	temperature_slider.value_changed.connect(_on_temperature_changed)
	temperature_spinbox.value_changed.connect(_on_temperature_spinbox_changed)
	
	# Sync initial values
	_sync_humidity()
	_sync_temperature()

func _on_humidity_changed(value: float) -> void:
	"""Handle humidity slider change."""
	humidity_spinbox.value = value
	emit_signal("param_changed", "humidity", value)

func _on_humidity_spinbox_changed(value: float) -> void:
	"""Handle humidity spinbox change."""
	humidity_slider.value = value
	emit_signal("param_changed", "humidity", value)

func _on_temperature_changed(value: float) -> void:
	"""Handle temperature slider change."""
	temperature_spinbox.value = value
	emit_signal("param_changed", "temperature", value)

func _on_temperature_spinbox_changed(value: float) -> void:
	"""Handle temperature spinbox change."""
	temperature_slider.value = value
	emit_signal("param_changed", "temperature", value)

func _sync_humidity() -> void:
	"""Sync humidity slider and spinbox."""
	humidity_spinbox.value = humidity_slider.value

func _sync_temperature() -> void:
	"""Sync temperature slider and spinbox."""
	temperature_spinbox.value = temperature_slider.value

func get_params() -> Dictionary:
	"""Get all biome parameters as dictionary."""
	return {
		"humidity": humidity_slider.value,
		"temperature": temperature_slider.value
	}

func set_params(params: Dictionary) -> void:
	"""Set biome parameters from dictionary."""
	if params.has("humidity"):
		var value: float = params["humidity"]
		humidity_slider.value = value
		humidity_spinbox.value = value
	
	if params.has("temperature"):
		var value: float = params["temperature"]
		temperature_slider.value = value
		temperature_spinbox.value = value

