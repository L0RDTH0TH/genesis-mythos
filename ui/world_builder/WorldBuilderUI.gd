# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: DM-driven world shaping UI controller for Terrain3D
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## Reference to terrain manager
var terrain_manager: Terrain3DManager = null

## UI Controls
@onready var height_scale_slider: HSlider = $VBoxContainer/HeightScaleContainer/HeightScaleSlider
@onready var height_scale_label: Label = $VBoxContainer/HeightScaleContainer/HeightScaleValue
@onready var noise_frequency_slider: HSlider = $VBoxContainer/NoiseFrequencyContainer/NoiseFrequencySlider
@onready var noise_frequency_label: Label = $VBoxContainer/NoiseFrequencyContainer/NoiseFrequencyValue
@onready var noise_seed_spinbox: SpinBox = $VBoxContainer/NoiseSeedContainer/NoiseSeedSpinBox
@onready var regenerate_button: Button = $VBoxContainer/RegenerateButton

## Current parameter values
var current_height_scale: float = 1.0
var current_noise_frequency: float = 0.0005
var current_noise_seed: int = 12345


func _ready() -> void:
	_setup_ui_connections()
	_update_ui_values()


func _setup_ui_connections() -> void:
	if height_scale_slider != null:
		height_scale_slider.value_changed.connect(_on_height_scale_changed)
	
	if noise_frequency_slider != null:
		noise_frequency_slider.value_changed.connect(_on_noise_frequency_changed)
	
	if noise_seed_spinbox != null:
		noise_seed_spinbox.value_changed.connect(_on_noise_seed_changed)
	
	if regenerate_button != null:
		regenerate_button.pressed.connect(_on_regenerate_pressed)


func _update_ui_values() -> void:
	if height_scale_slider != null:
		height_scale_slider.value = current_height_scale
	if height_scale_label != null:
		height_scale_label.text = "%.2f" % current_height_scale
	
	if noise_frequency_slider != null:
		noise_frequency_slider.value = current_noise_frequency
	if noise_frequency_label != null:
		noise_frequency_label.text = "%.6f" % current_noise_frequency
	
	if noise_seed_spinbox != null:
		noise_seed_spinbox.value = current_noise_seed


func _on_height_scale_changed(value: float) -> void:
	current_height_scale = value
	if height_scale_label != null:
		height_scale_label.text = "%.2f" % value
	
	if terrain_manager != null:
		terrain_manager.scale_heights(value)


func _on_noise_frequency_changed(value: float) -> void:
	current_noise_frequency = value
	if noise_frequency_label != null:
		noise_frequency_label.text = "%.6f" % value
	
	# Frequency changes require regeneration
	# Store value but don't regenerate immediately (wait for button press)


func _on_noise_seed_changed(value: float) -> void:
	current_noise_seed = int(value)
	# Seed changes require regeneration
	# Store value but don't regenerate immediately (wait for button press)


func _on_regenerate_pressed() -> void:
	if terrain_manager == null:
		push_warning("WorldBuilderUI: No terrain manager assigned")
		return
	
	# Regenerate terrain with current parameters
	terrain_manager.generate_from_noise(
		current_noise_seed,
		current_noise_frequency,
		0.0,
		150.0 * current_height_scale
	)


func set_terrain_manager(manager: Terrain3DManager) -> void:
	terrain_manager = manager
	
	if terrain_manager != null:
		terrain_manager.terrain_generated.connect(_on_terrain_generated)
		terrain_manager.terrain_updated.connect(_on_terrain_updated)


func _on_terrain_generated(_terrain: Terrain3D) -> void:
	# Terrain generation complete
	pass


func _on_terrain_updated() -> void:
	# Terrain updated (can add visual feedback here)
	pass
