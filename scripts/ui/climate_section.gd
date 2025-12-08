# ╔═══════════════════════════════════════════════════════════
# ║ climate_section.gd
# ║ Desc: Climate section with temperature, humidity, precipitation, and wind controls
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

signal param_changed(param: String, value: Variant)

@onready var temperature_slider: HSlider = $MarginContainer/VBoxContainer/content/TemperatureContainer/TemperatureSlider
@onready var temperature_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/TemperatureContainer/TemperatureSpinBox
@onready var humidity_slider: HSlider = $MarginContainer/VBoxContainer/content/HumidityContainer/HumiditySlider
@onready var humidity_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/HumidityContainer/HumiditySpinBox
@onready var precipitation_slider: HSlider = $MarginContainer/VBoxContainer/content/PrecipitationContainer/PrecipitationSlider
@onready var precipitation_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/PrecipitationContainer/PrecipitationSpinBox
@onready var wind_strength_slider: HSlider = $MarginContainer/VBoxContainer/content/WindStrengthContainer/WindStrengthSlider
@onready var wind_strength_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/WindStrengthContainer/WindStrengthSpinBox

func _ready() -> void:
	"""Initialize climate section controls and connections."""
	# Connect temperature controls
	temperature_slider.value_changed.connect(_on_temperature_changed)
	temperature_spinbox.value_changed.connect(_on_temperature_spinbox_changed)
	
	# Connect humidity controls
	humidity_slider.value_changed.connect(_on_humidity_changed)
	humidity_spinbox.value_changed.connect(_on_humidity_spinbox_changed)
	
	# Connect precipitation controls
	precipitation_slider.value_changed.connect(_on_precipitation_changed)
	precipitation_spinbox.value_changed.connect(_on_precipitation_spinbox_changed)
	
	# Connect wind strength controls
	wind_strength_slider.value_changed.connect(_on_wind_strength_changed)
	wind_strength_spinbox.value_changed.connect(_on_wind_strength_spinbox_changed)
	
	# Setup tooltips and accessibility
	_setup_tooltips()
	_setup_keyboard_navigation()
	
	# Sync initial values
	_sync_temperature()
	_sync_humidity()
	_sync_precipitation()
	_sync_wind_strength()

func _setup_tooltips() -> void:
	"""Set tooltips for all controls."""
	if temperature_slider:
		temperature_slider.tooltip_text = "Controls average temperature. Negative values create cold climates, positive values create warm climates."
	if temperature_spinbox:
		temperature_spinbox.tooltip_text = "Numeric input for temperature. Use slider or type directly."
	if humidity_slider:
		humidity_slider.tooltip_text = "Controls atmospheric humidity. Higher values create wetter climates with more precipitation."
	if humidity_spinbox:
		humidity_spinbox.tooltip_text = "Numeric input for humidity. Use slider or type directly."
	if precipitation_slider:
		precipitation_slider.tooltip_text = "Controls rainfall and precipitation levels. Affects biome distribution and water features."
	if precipitation_spinbox:
		precipitation_spinbox.tooltip_text = "Numeric input for precipitation. Use slider or type directly."
	if wind_strength_slider:
		wind_strength_slider.tooltip_text = "Controls wind strength and atmospheric movement. Affects climate patterns and weather systems."
	if wind_strength_spinbox:
		wind_strength_spinbox.tooltip_text = "Numeric input for wind strength. Use slider or type directly."

func _setup_keyboard_navigation() -> void:
	"""Setup keyboard navigation with focus_next and focus_prev."""
	# Set focus mode for all interactive controls
	if temperature_slider:
		temperature_slider.focus_mode = Control.FOCUS_ALL
	if temperature_spinbox:
		temperature_spinbox.focus_mode = Control.FOCUS_ALL
	if humidity_slider:
		humidity_slider.focus_mode = Control.FOCUS_ALL
	if humidity_spinbox:
		humidity_spinbox.focus_mode = Control.FOCUS_ALL
	if precipitation_slider:
		precipitation_slider.focus_mode = Control.FOCUS_ALL
	if precipitation_spinbox:
		precipitation_spinbox.focus_mode = Control.FOCUS_ALL
	if wind_strength_slider:
		wind_strength_slider.focus_mode = Control.FOCUS_ALL
	if wind_strength_spinbox:
		wind_strength_spinbox.focus_mode = Control.FOCUS_ALL
	
	# Setup focus chain (top to bottom)
	var controls: Array[Control] = [
		temperature_slider, temperature_spinbox,
		humidity_slider, humidity_spinbox,
		precipitation_slider, precipitation_spinbox,
		wind_strength_slider, wind_strength_spinbox
	]
	
	for i in range(controls.size() - 1):
		if controls[i] and controls[i + 1]:
			controls[i].focus_next = NodePath(controls[i].get_path_to(controls[i + 1]))
			# Note: focus_prev is not available on all Control types in Godot 4.3
			# focus_next is sufficient for tab navigation

func _on_temperature_changed(value: float) -> void:
	"""Handle temperature slider change."""
	temperature_spinbox.value = value
	emit_signal("param_changed", "temperature", value)

func _on_temperature_spinbox_changed(value: float) -> void:
	"""Handle temperature spinbox change."""
	temperature_slider.value = value
	emit_signal("param_changed", "temperature", value)

func _on_humidity_changed(value: float) -> void:
	"""Handle humidity slider change."""
	humidity_spinbox.value = value
	emit_signal("param_changed", "humidity", value)

func _on_humidity_spinbox_changed(value: float) -> void:
	"""Handle humidity spinbox change."""
	humidity_slider.value = value
	emit_signal("param_changed", "humidity", value)

func _on_precipitation_changed(value: float) -> void:
	"""Handle precipitation slider change."""
	precipitation_spinbox.value = value
	emit_signal("param_changed", "precipitation", value)

func _on_precipitation_spinbox_changed(value: float) -> void:
	"""Handle precipitation spinbox change."""
	precipitation_slider.value = value
	emit_signal("param_changed", "precipitation", value)

func _on_wind_strength_changed(value: float) -> void:
	"""Handle wind strength slider change."""
	wind_strength_spinbox.value = value
	emit_signal("param_changed", "wind_strength", value)

func _on_wind_strength_spinbox_changed(value: float) -> void:
	"""Handle wind strength spinbox change."""
	wind_strength_slider.value = value
	emit_signal("param_changed", "wind_strength", value)

func _sync_temperature() -> void:
	"""Sync temperature slider and spinbox."""
	temperature_spinbox.value = temperature_slider.value

func _sync_humidity() -> void:
	"""Sync humidity slider and spinbox."""
	humidity_spinbox.value = humidity_slider.value

func _sync_precipitation() -> void:
	"""Sync precipitation slider and spinbox."""
	precipitation_spinbox.value = precipitation_slider.value

func _sync_wind_strength() -> void:
	"""Sync wind strength slider and spinbox."""
	wind_strength_spinbox.value = wind_strength_slider.value

func get_params() -> Dictionary:
	"""Get all climate parameters as dictionary."""
	return {
		"temperature": temperature_slider.value,
		"humidity": humidity_slider.value,
		"precipitation": precipitation_slider.value,
		"wind_strength": wind_strength_slider.value
	}

func set_params(params: Dictionary) -> void:
	"""Set climate parameters from dictionary."""
	if params.has("temperature"):
		var value: float = params["temperature"]
		temperature_slider.value = value
		temperature_spinbox.value = value
	
	if params.has("humidity"):
		var value: float = params["humidity"]
		humidity_slider.value = value
		humidity_spinbox.value = value
	
	if params.has("precipitation"):
		var value: float = params["precipitation"]
		precipitation_slider.value = value
		precipitation_spinbox.value = value
	
	if params.has("wind_strength"):
		var value: float = params["wind_strength"]
		wind_strength_slider.value = value
		wind_strength_spinbox.value = value
