# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: Step-by-step wizard-style world building UI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## Reference to terrain manager
var terrain_manager = null  # Terrain3DManager - type hint removed to avoid parser error

## Current step index (0-8)
var current_step: int = 0

## Step definitions
const STEPS: Array[String] = [
	"Seed & Size",
	"2D Map Maker",
	"Terrain",
	"Climate",
	"Biomes",
	"Structures & Civilizations",
	"Environment",
	"Resources & Magic",
	"Export"
]

## Step data storage
var step_data: Dictionary = {}

## Map icons data
var map_icons_data: Dictionary = {}

## Placed icons on 2D map
var placed_icons: Array[IconNode] = []

## Icon groups after clustering
var icon_groups: Array[Array] = []

## Current icon being processed for type selection
var current_icon_group_index: int = 0

## References to UI nodes
@onready var navigation_panel: Panel = $MainContainer/LeftNavigation
@onready var content_area: Control = $MainContainer/ContentArea
@onready var step_labels: Array[Label] = []
@onready var next_button: Button = $MainContainer/ButtonContainer/NextButton
@onready var back_button: Button = $MainContainer/ButtonContainer/BackButton

## Paths
const MAP_ICONS_PATH: String = "res://data/map_icons.json"
const UI_CONFIG_PATH: String = "res://data/config/world_builder_ui.json"
const BIOMES_PATH: String = "res://data/biomes.json"

## Control references
var control_references: Dictionary = {}


func _ready() -> void:
	_load_map_icons()
	_load_biomes()
	_apply_theme()
	_ensure_visibility()
	_setup_navigation()
	_setup_step_content()
	_setup_buttons()
	_update_step_display()
	print("WorldBuilderUI: Wizard-style UI ready")


func _load_map_icons() -> void:
	"""Load map icons configuration from JSON."""
	var file: FileAccess = FileAccess.open(MAP_ICONS_PATH, FileAccess.READ)
	if file == null:
		push_error("WorldBuilderUI: Failed to load map icons from " + MAP_ICONS_PATH)
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("WorldBuilderUI: Failed to parse map icons JSON: " + json.get_error_message())
		return
	
	map_icons_data = json.data
	print("WorldBuilderUI: Loaded ", map_icons_data.get("icons", []).size(), " map icon definitions")


func _apply_theme() -> void:
	"""Apply bg3_theme to this UI."""
	var theme: Theme = load("res://themes/bg3_theme.tres")
	if theme != null:
		self.theme = theme


func _ensure_visibility() -> void:
	"""Ensure UI elements are visible with proper styling."""
	self.visible = true
	self.mouse_filter = Control.MOUSE_FILTER_PASS
	self.modulate = Color(1, 1, 1, 1)


func _setup_navigation() -> void:
	"""Setup left navigation panel with step labels."""
	if navigation_panel == null:
		return
	
	var nav_container: VBoxContainer = VBoxContainer.new()
	nav_container.name = "NavContainer"
	nav_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nav_container.add_theme_constant_override("separation", 10)
	navigation_panel.add_child(nav_container)
	
	# Create step labels
	for i in range(STEPS.size()):
		var step_label: Label = Label.new()
		step_label.name = "Step" + str(i + 1) + "Label"
		step_label.text = str(i + 1) + ". " + STEPS[i]
		step_label.custom_minimum_size = Vector2(0, 40)
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		step_label.add_theme_constant_override("margin_left", 10)
		step_label.add_theme_constant_override("margin_right", 10)
		step_labels.append(step_label)
		nav_container.add_child(step_label)


func _setup_step_content() -> void:
	"""Setup content panels for each step."""
	if content_area == null:
		return
	
	# Create container for step content
	var step_container: VBoxContainer = VBoxContainer.new()
	step_container.name = "StepContainer"
	step_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_area.add_child(step_container)
	
	# Initialize step data
	for step_name: String in STEPS:
		step_data[step_name] = {}
	
	# Create step 1: Seed & Size
	_create_step_seed_size(step_container)
	
	# Create step 2: 2D Map Maker
	_create_step_map_maker(step_container)
	
	# Create step 3: Terrain
	_create_step_terrain(step_container)
	
	# Create step 4: Climate
	_create_step_climate(step_container)
	
	# Create step 5: Biomes
	_create_step_biomes(step_container)
	
	# Create remaining steps (6-9) as placeholders
	for i in range(5, STEPS.size()):
		_create_step_placeholder(step_container, i)


func _create_step_seed_size(parent: VBoxContainer) -> void:
	"""Create Step 1: Seed & Size content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepSeedSize"
	step_panel.visible = (current_step == 0)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Seed input
	var seed_container: HBoxContainer = HBoxContainer.new()
	var seed_label: Label = Label.new()
	seed_label.text = "Seed:"
	seed_label.custom_minimum_size = Vector2(150, 0)
	seed_container.add_child(seed_label)
	
	var seed_spinbox: SpinBox = SpinBox.new()
	seed_spinbox.name = "seed"
	seed_spinbox.min_value = 0
	seed_spinbox.max_value = 999999
	seed_spinbox.value = 12345
	seed_spinbox.value_changed.connect(func(v): _on_seed_changed(int(v)))
	seed_container.add_child(seed_spinbox)
	container.add_child(seed_container)
	control_references["Seed & Size/seed"] = seed_spinbox
	step_data["Seed & Size"]["seed"] = 12345
	
	# Size inputs
	var size_label: Label = Label.new()
	size_label.text = "World Size:"
	container.add_child(size_label)
	
	var size_container: HBoxContainer = HBoxContainer.new()
	var width_label: Label = Label.new()
	width_label.text = "Width:"
	width_label.custom_minimum_size = Vector2(100, 0)
	size_container.add_child(width_label)
	
	var width_spinbox: SpinBox = SpinBox.new()
	width_spinbox.name = "width"
	width_spinbox.min_value = 100
	width_spinbox.max_value = 10000
	width_spinbox.value = 1000
	width_spinbox.value_changed.connect(func(v): step_data["Seed & Size"]["width"] = int(v))
	size_container.add_child(width_spinbox)
	
	var height_label: Label = Label.new()
	height_label.text = "Height:"
	height_label.custom_minimum_size = Vector2(100, 0)
	size_container.add_child(height_label)
	
	var height_spinbox: SpinBox = SpinBox.new()
	height_spinbox.name = "height"
	height_spinbox.min_value = 100
	height_spinbox.max_value = 10000
	height_spinbox.value = 1000
	height_spinbox.value_changed.connect(func(v): step_data["Seed & Size"]["height"] = int(v))
	size_container.add_child(height_spinbox)
	container.add_child(size_container)
	control_references["Seed & Size/width"] = width_spinbox
	control_references["Seed & Size/height"] = height_spinbox
	step_data["Seed & Size"]["width"] = 1000
	step_data["Seed & Size"]["height"] = 1000


func _create_step_map_maker(parent: VBoxContainer) -> void:
	"""Create Step 2: 2D Map Maker content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepMapMaker"
	step_panel.visible = (current_step == 1)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Toolbar for icon selection
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.name = "IconToolbar"
	container.add_child(toolbar)
	
	# Create buttons for each icon type
	var icons: Array = map_icons_data.get("icons", [])
	for icon_data: Dictionary in icons:
		var icon_button: Button = Button.new()
		icon_button.text = icon_data.get("id", "unknown")
		var icon_color_array: Array = icon_data.get("color", [0.5, 0.5, 0.5, 1.0])
		var icon_color: Color = Color(icon_color_array[0], icon_color_array[1], icon_color_array[2], icon_color_array[3])
		icon_button.pressed.connect(func(): _on_icon_toolbar_selected(icon_data.get("id", "")))
		toolbar.add_child(icon_button)
	
	# Map canvas (using Control with custom drawing)
	var canvas_container: Panel = Panel.new()
	canvas_container.name = "MapCanvas"
	canvas_container.custom_minimum_size = Vector2(600, 400)
	canvas_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(canvas_container)
	
	# Create a Control container for icons (will use Control-based icons)
	var icon_container: Control = Control.new()
	icon_container.name = "IconContainer"
	icon_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
	canvas_container.add_child(icon_container)
	
	# Make canvas clickable
	canvas_container.gui_input.connect(_on_canvas_clicked)


func _create_step_terrain(parent: VBoxContainer) -> void:
	"""Create Step 3: Terrain content with full controls."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepTerrain"
	step_panel.visible = (current_step == 2)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Seed field (read-only, auto-filled from Step 1)
	var seed_container: HBoxContainer = HBoxContainer.new()
	var seed_label: Label = Label.new()
	seed_label.text = "Seed (from Step 1):"
	seed_label.custom_minimum_size = Vector2(200, 0)
	seed_container.add_child(seed_label)
	
	var seed_spinbox: SpinBox = SpinBox.new()
	seed_spinbox.name = "seed"
	seed_spinbox.editable = false  # Read-only
	seed_spinbox.min_value = 0
	seed_spinbox.max_value = 999999
	seed_spinbox.value = step_data.get("Seed & Size", {}).get("seed", 12345)
	seed_container.add_child(seed_spinbox)
	container.add_child(seed_container)
	control_references["Terrain/seed"] = seed_spinbox
	step_data["Terrain"] = {}
	step_data["Terrain"]["seed"] = step_data.get("Seed & Size", {}).get("seed", 12345)
	
	# Height Scale
	var height_container: HBoxContainer = HBoxContainer.new()
	var height_label: Label = Label.new()
	height_label.text = "Height Scale:"
	height_label.custom_minimum_size = Vector2(200, 0)
	height_container.add_child(height_label)
	
	var height_slider: HSlider = HSlider.new()
	height_slider.name = "height_scale"
	height_slider.min_value = 0.0
	height_slider.max_value = 100.0
	height_slider.step = 0.1
	height_slider.value = 20.0
	height_slider.value_changed.connect(func(v): _on_terrain_param_changed("height_scale", v))
	height_container.add_child(height_slider)
	
	var height_value_label: Label = Label.new()
	height_value_label.name = "height_scale_value"
	height_value_label.custom_minimum_size = Vector2(80, 0)
	height_value_label.text = "20.00"
	height_container.add_child(height_value_label)
	container.add_child(height_container)
	control_references["Terrain/height_scale"] = height_slider
	control_references["Terrain/height_scale_value"] = height_value_label
	step_data["Terrain"]["height_scale"] = 20.0
	
	# Noise Frequency
	var freq_container: HBoxContainer = HBoxContainer.new()
	var freq_label: Label = Label.new()
	freq_label.text = "Noise Frequency:"
	freq_label.custom_minimum_size = Vector2(200, 0)
	freq_container.add_child(freq_label)
	
	var freq_slider: HSlider = HSlider.new()
	freq_slider.name = "noise_frequency"
	freq_slider.min_value = 0.001
	freq_slider.max_value = 0.1
	freq_slider.step = 0.0001
	freq_slider.value = 0.0005
	freq_slider.value_changed.connect(func(v): _on_terrain_param_changed("noise_frequency", v))
	freq_container.add_child(freq_slider)
	
	var freq_value_label: Label = Label.new()
	freq_value_label.name = "noise_frequency_value"
	freq_value_label.custom_minimum_size = Vector2(80, 0)
	freq_value_label.text = "0.000500"
	freq_container.add_child(freq_value_label)
	container.add_child(freq_container)
	control_references["Terrain/noise_frequency"] = freq_slider
	control_references["Terrain/noise_frequency_value"] = freq_value_label
	step_data["Terrain"]["noise_frequency"] = 0.0005
	
	# Octaves
	var octaves_container: HBoxContainer = HBoxContainer.new()
	var octaves_label: Label = Label.new()
	octaves_label.text = "Octaves:"
	octaves_label.custom_minimum_size = Vector2(200, 0)
	octaves_container.add_child(octaves_label)
	
	var octaves_slider: HSlider = HSlider.new()
	octaves_slider.name = "octaves"
	octaves_slider.min_value = 1.0
	octaves_slider.max_value = 8.0
	octaves_slider.step = 1.0
	octaves_slider.value = 4.0
	octaves_slider.value_changed.connect(func(v): _on_terrain_param_changed("octaves", v))
	octaves_container.add_child(octaves_slider)
	
	var octaves_value_label: Label = Label.new()
	octaves_value_label.name = "octaves_value"
	octaves_value_label.custom_minimum_size = Vector2(80, 0)
	octaves_value_label.text = "4"
	octaves_container.add_child(octaves_value_label)
	container.add_child(octaves_container)
	control_references["Terrain/octaves"] = octaves_slider
	control_references["Terrain/octaves_value"] = octaves_value_label
	step_data["Terrain"]["octaves"] = 4.0
	
	# Persistence
	var persistence_container: HBoxContainer = HBoxContainer.new()
	var persistence_label: Label = Label.new()
	persistence_label.text = "Persistence:"
	persistence_label.custom_minimum_size = Vector2(200, 0)
	persistence_container.add_child(persistence_label)
	
	var persistence_slider: HSlider = HSlider.new()
	persistence_slider.name = "persistence"
	persistence_slider.min_value = 0.0
	persistence_slider.max_value = 1.0
	persistence_slider.step = 0.01
	persistence_slider.value = 0.5
	persistence_slider.value_changed.connect(func(v): _on_terrain_param_changed("persistence", v))
	persistence_container.add_child(persistence_slider)
	
	var persistence_value_label: Label = Label.new()
	persistence_value_label.name = "persistence_value"
	persistence_value_label.custom_minimum_size = Vector2(80, 0)
	persistence_value_label.text = "0.50"
	persistence_container.add_child(persistence_value_label)
	container.add_child(persistence_container)
	control_references["Terrain/persistence"] = persistence_slider
	control_references["Terrain/persistence_value"] = persistence_value_label
	step_data["Terrain"]["persistence"] = 0.5
	
	# Lacunarity
	var lacunarity_container: HBoxContainer = HBoxContainer.new()
	var lacunarity_label: Label = Label.new()
	lacunarity_label.text = "Lacunarity:"
	lacunarity_label.custom_minimum_size = Vector2(200, 0)
	lacunarity_container.add_child(lacunarity_label)
	
	var lacunarity_slider: HSlider = HSlider.new()
	lacunarity_slider.name = "lacunarity"
	lacunarity_slider.min_value = 1.0
	lacunarity_slider.max_value = 4.0
	lacunarity_slider.step = 0.1
	lacunarity_slider.value = 2.0
	lacunarity_slider.value_changed.connect(func(v): _on_terrain_param_changed("lacunarity", v))
	lacunarity_container.add_child(lacunarity_slider)
	
	var lacunarity_value_label: Label = Label.new()
	lacunarity_value_label.name = "lacunarity_value"
	lacunarity_value_label.custom_minimum_size = Vector2(80, 0)
	lacunarity_value_label.text = "2.00"
	lacunarity_container.add_child(lacunarity_value_label)
	container.add_child(lacunarity_container)
	control_references["Terrain/lacunarity"] = lacunarity_slider
	control_references["Terrain/lacunarity_value"] = lacunarity_value_label
	step_data["Terrain"]["lacunarity"] = 2.0
	
	# Noise Type
	var noise_type_container: HBoxContainer = HBoxContainer.new()
	var noise_type_label: Label = Label.new()
	noise_type_label.text = "Noise Type:"
	noise_type_label.custom_minimum_size = Vector2(200, 0)
	noise_type_container.add_child(noise_type_label)
	
	var noise_type_option: OptionButton = OptionButton.new()
	noise_type_option.name = "noise_type"
	noise_type_option.add_item("Simplex")
	noise_type_option.add_item("Simplex Smooth")
	noise_type_option.add_item("Perlin")
	noise_type_option.add_item("Value")
	noise_type_option.add_item("Value Cubic")
	noise_type_option.add_item("Cellular")
	noise_type_option.selected = 2  # Default to Perlin
	noise_type_option.item_selected.connect(func(idx): _on_terrain_param_changed("noise_type", idx))
	noise_type_container.add_child(noise_type_option)
	container.add_child(noise_type_container)
	control_references["Terrain/noise_type"] = noise_type_option
	step_data["Terrain"]["noise_type"] = 2
	
	# Regenerate Terrain button
	var button_container: HBoxContainer = HBoxContainer.new()
	var regenerate_button: Button = Button.new()
	regenerate_button.name = "regenerate_terrain"
	regenerate_button.text = "Regenerate Terrain"
	regenerate_button.pressed.connect(_on_regenerate_terrain_pressed)
	button_container.add_child(regenerate_button)
	container.add_child(button_container)
	control_references["Terrain/regenerate_terrain"] = regenerate_button


func _create_step_climate(parent: VBoxContainer) -> void:
	"""Create Step 4: Climate content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepClimate"
	step_panel.visible = (current_step == 3)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Temperature map intensity
	var temp_container: HBoxContainer = HBoxContainer.new()
	var temp_label: Label = Label.new()
	temp_label.text = "Temperature Intensity:"
	temp_label.custom_minimum_size = Vector2(200, 0)
	temp_container.add_child(temp_label)
	
	var temp_slider: HSlider = HSlider.new()
	temp_slider.name = "temperature_intensity"
	temp_slider.min_value = 0.0
	temp_slider.max_value = 1.0
	temp_slider.step = 0.01
	temp_slider.value = 0.5
	temp_slider.value_changed.connect(func(v): _on_climate_param_changed("temperature_intensity", v))
	temp_container.add_child(temp_slider)
	
	var temp_value_label: Label = Label.new()
	temp_value_label.name = "temperature_intensity_value"
	temp_value_label.custom_minimum_size = Vector2(80, 0)
	temp_value_label.text = "0.50"
	temp_container.add_child(temp_value_label)
	container.add_child(temp_container)
	control_references["Climate/temperature_intensity"] = temp_slider
	control_references["Climate/temperature_intensity_value"] = temp_value_label
	step_data["Climate"] = {}
	step_data["Climate"]["temperature_intensity"] = 0.5
	
	# Rainfall map intensity
	var rain_container: HBoxContainer = HBoxContainer.new()
	var rain_label: Label = Label.new()
	rain_label.text = "Rainfall Intensity:"
	rain_label.custom_minimum_size = Vector2(200, 0)
	rain_container.add_child(rain_label)
	
	var rain_slider: HSlider = HSlider.new()
	rain_slider.name = "rainfall_intensity"
	rain_slider.min_value = 0.0
	rain_slider.max_value = 1.0
	rain_slider.step = 0.01
	rain_slider.value = 0.5
	rain_slider.value_changed.connect(func(v): _on_climate_param_changed("rainfall_intensity", v))
	rain_container.add_child(rain_slider)
	
	var rain_value_label: Label = Label.new()
	rain_value_label.name = "rainfall_intensity_value"
	rain_value_label.custom_minimum_size = Vector2(80, 0)
	rain_value_label.text = "0.50"
	rain_container.add_child(rain_value_label)
	container.add_child(rain_container)
	control_references["Climate/rainfall_intensity"] = rain_slider
	control_references["Climate/rainfall_intensity_value"] = rain_value_label
	step_data["Climate"]["rainfall_intensity"] = 0.5
	
	# Wind strength
	var wind_strength_container: HBoxContainer = HBoxContainer.new()
	var wind_strength_label: Label = Label.new()
	wind_strength_label.text = "Wind Strength:"
	wind_strength_label.custom_minimum_size = Vector2(200, 0)
	wind_strength_container.add_child(wind_strength_label)
	
	var wind_strength_slider: HSlider = HSlider.new()
	wind_strength_slider.name = "wind_strength"
	wind_strength_slider.min_value = 0.0
	wind_strength_slider.max_value = 10.0
	wind_strength_slider.step = 0.1
	wind_strength_slider.value = 1.0
	wind_strength_slider.value_changed.connect(func(v): _on_climate_param_changed("wind_strength", v))
	wind_strength_container.add_child(wind_strength_slider)
	
	var wind_strength_value_label: Label = Label.new()
	wind_strength_value_label.name = "wind_strength_value"
	wind_strength_value_label.custom_minimum_size = Vector2(80, 0)
	wind_strength_value_label.text = "1.0"
	wind_strength_container.add_child(wind_strength_value_label)
	container.add_child(wind_strength_container)
	control_references["Climate/wind_strength"] = wind_strength_slider
	control_references["Climate/wind_strength_value"] = wind_strength_value_label
	step_data["Climate"]["wind_strength"] = 1.0
	
	# Wind direction
	var wind_dir_container: HBoxContainer = HBoxContainer.new()
	var wind_dir_label: Label = Label.new()
	wind_dir_label.text = "Wind Direction:"
	wind_dir_label.custom_minimum_size = Vector2(200, 0)
	wind_dir_container.add_child(wind_dir_label)
	
	var wind_dir_x_label: Label = Label.new()
	wind_dir_x_label.text = "X:"
	wind_dir_x_label.custom_minimum_size = Vector2(30, 0)
	wind_dir_container.add_child(wind_dir_x_label)
	
	var wind_dir_x_spinbox: SpinBox = SpinBox.new()
	wind_dir_x_spinbox.name = "wind_direction_x"
	wind_dir_x_spinbox.min_value = -1.0
	wind_dir_x_spinbox.max_value = 1.0
	wind_dir_x_spinbox.step = 0.1
	wind_dir_x_spinbox.value = 1.0
	wind_dir_x_spinbox.value_changed.connect(func(v): _on_climate_param_changed("wind_direction_x", v))
	wind_dir_container.add_child(wind_dir_x_spinbox)
	
	var wind_dir_y_label: Label = Label.new()
	wind_dir_y_label.text = "Y:"
	wind_dir_y_label.custom_minimum_size = Vector2(30, 0)
	wind_dir_container.add_child(wind_dir_y_label)
	
	var wind_dir_y_spinbox: SpinBox = SpinBox.new()
	wind_dir_y_spinbox.name = "wind_direction_y"
	wind_dir_y_spinbox.min_value = -1.0
	wind_dir_y_spinbox.max_value = 1.0
	wind_dir_y_spinbox.step = 0.1
	wind_dir_y_spinbox.value = 0.0
	wind_dir_y_spinbox.value_changed.connect(func(v): _on_climate_param_changed("wind_direction_y", v))
	wind_dir_container.add_child(wind_dir_y_spinbox)
	container.add_child(wind_dir_container)
	control_references["Climate/wind_direction_x"] = wind_dir_x_spinbox
	control_references["Climate/wind_direction_y"] = wind_dir_y_spinbox
	step_data["Climate"]["wind_direction_x"] = 1.0
	step_data["Climate"]["wind_direction_y"] = 0.0
	
	# Time of Day
	var time_container: HBoxContainer = HBoxContainer.new()
	var time_label: Label = Label.new()
	time_label.text = "Time of Day:"
	time_label.custom_minimum_size = Vector2(200, 0)
	time_container.add_child(time_label)
	
	var time_slider: HSlider = HSlider.new()
	time_slider.name = "time_of_day"
	time_slider.min_value = 0.0
	time_slider.max_value = 24.0
	time_slider.step = 0.1
	time_slider.value = 12.0
	time_slider.value_changed.connect(func(v): _on_climate_param_changed("time_of_day", v))
	time_container.add_child(time_slider)
	
	var time_value_label: Label = Label.new()
	time_value_label.name = "time_of_day_value"
	time_value_label.custom_minimum_size = Vector2(80, 0)
	time_value_label.text = "12.0"
	time_container.add_child(time_value_label)
	container.add_child(time_container)
	control_references["Climate/time_of_day"] = time_slider
	control_references["Climate/time_of_day_value"] = time_value_label
	step_data["Climate"]["time_of_day"] = 12.0


func _create_step_biomes(parent: VBoxContainer) -> void:
	"""Create Step 5: Biomes content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepBiomes"
	step_panel.visible = (current_step == 4)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Biome overlay toggle
	var overlay_container: HBoxContainer = HBoxContainer.new()
	var overlay_label: Label = Label.new()
	overlay_label.text = "Show Biome Overlay:"
	overlay_label.custom_minimum_size = Vector2(200, 0)
	overlay_container.add_child(overlay_label)
	
	var overlay_checkbox: CheckBox = CheckBox.new()
	overlay_checkbox.name = "show_biome_overlay"
	overlay_checkbox.button_pressed = false
	overlay_checkbox.toggled.connect(func(pressed): _on_biome_overlay_toggled(pressed))
	overlay_container.add_child(overlay_checkbox)
	container.add_child(overlay_container)
	control_references["Biomes/show_biome_overlay"] = overlay_checkbox
	step_data["Biomes"] = {}
	step_data["Biomes"]["show_biome_overlay"] = false
	
	# Biome selection list
	var biome_list_label: Label = Label.new()
	biome_list_label.text = "Available Biomes:"
	container.add_child(biome_list_label)
	
	var biome_list: ItemList = ItemList.new()
	biome_list.name = "biome_list"
	biome_list.custom_minimum_size = Vector2(0, 200)
	biome_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Populate biome list from JSON
	var biomes: Array = biomes_data.get("biomes", [])
	for biome_data: Dictionary in biomes:
		var biome_name: String = biome_data.get("name", "Unknown")
		biome_list.add_item(biome_name)
	
	biome_list.item_selected.connect(func(idx): _on_biome_selected(idx))
	container.add_child(biome_list)
	control_references["Biomes/biome_list"] = biome_list
	
	# Generation mode
	var mode_container: HBoxContainer = HBoxContainer.new()
	var mode_label: Label = Label.new()
	mode_label.text = "Generation Mode:"
	mode_label.custom_minimum_size = Vector2(200, 0)
	mode_container.add_child(mode_label)
	
	var mode_option: OptionButton = OptionButton.new()
	mode_option.name = "generation_mode"
	mode_option.add_item("Manual Painting")
	mode_option.add_item("Auto-Generate from Climate")
	mode_option.add_item("Auto-Generate from Height")
	mode_option.selected = 1  # Default to auto-generate from climate
	mode_option.item_selected.connect(func(idx): _on_biome_generation_mode_changed(idx))
	mode_container.add_child(mode_option)
	container.add_child(mode_container)
	control_references["Biomes/generation_mode"] = mode_option
	step_data["Biomes"]["generation_mode"] = 1
	
	# Generate/Auto-Apply button
	var button_container: HBoxContainer = HBoxContainer.new()
	var generate_button: Button = Button.new()
	generate_button.name = "generate_biomes"
	generate_button.text = "Generate Biomes"
	generate_button.pressed.connect(_on_generate_biomes_pressed)
	button_container.add_child(generate_button)
	container.add_child(button_container)
	control_references["Biomes/generate_biomes"] = generate_button


func _create_step_placeholder(parent: VBoxContainer, step_index: int) -> void:
	"""Create placeholder content for steps 6-9."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "Step" + str(step_index + 1)
	step_panel.visible = (current_step == step_index)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	step_panel.add_child(container)
	
	var label: Label = Label.new()
	label.text = STEPS[step_index] + " - Coming Soon"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)


func _setup_buttons() -> void:
	"""Setup Next/Back navigation buttons."""
	if next_button != null:
		next_button.pressed.connect(_on_next_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
		back_button.disabled = (current_step == 0)


func _update_step_display() -> void:
	"""Update UI to show current step."""
	# Update step labels highlighting
	for i in range(step_labels.size()):
		if i == current_step:
			# Highlight current step in gold
			step_labels[i].add_theme_color_override("font_color", Color(1, 0.843137, 0, 1))
		else:
			step_labels[i].remove_theme_color_override("font_color")
	
	# Show/hide step content panels
	var step_container: VBoxContainer = content_area.get_node_or_null("StepContainer")
	if step_container != null:
		for i in range(step_container.get_child_count()):
			var child: Node = step_container.get_child(i)
			child.visible = (i == current_step)
	
	# Update button states
	if back_button != null:
		back_button.disabled = (current_step == 0)
	if next_button != null:
		next_button.disabled = (current_step == STEPS.size() - 1)
	
	# Update seed in Step 3 when entering terrain step
	if current_step == 2:
		_update_terrain_seed_from_step1()


func _on_next_pressed() -> void:
	"""Handle Next button press."""
	if current_step < STEPS.size() - 1:
		# Check if we're leaving step 2 (Map Maker) - trigger 3D conversion
		if current_step == 1:
			_start_3d_conversion()
		else:
			current_step += 1
			_update_step_display()


func _on_back_pressed() -> void:
	"""Handle Back button press."""
	if current_step > 0:
		current_step -= 1
		_update_step_display()


func _on_terrain_param_changed(param_name: String, value: Variant) -> void:
	"""Handle terrain parameter changes with live updates."""
	step_data["Terrain"][param_name] = value
	
	# Update value labels
	match param_name:
		"height_scale":
			var label: Label = control_references.get("Terrain/height_scale_value") as Label
			if label != null:
				label.text = "%.2f" % value
		"noise_frequency":
			var label: Label = control_references.get("Terrain/noise_frequency_value") as Label
			if label != null:
				label.text = "%.6f" % value
		"octaves":
			var label: Label = control_references.get("Terrain/octaves_value") as Label
			if label != null:
				label.text = "%.0f" % value
		"persistence":
			var label: Label = control_references.get("Terrain/persistence_value") as Label
			if label != null:
				label.text = "%.2f" % value
		"lacunarity":
			var label: Label = control_references.get("Terrain/lacunarity_value") as Label
			if label != null:
				label.text = "%.2f" % value
	
	# Live terrain update (throttled to avoid performance issues)
	call_deferred("_update_terrain_live")


func _update_terrain_live() -> void:
	"""Update terrain in real-time with current parameters."""
	if terrain_manager == null:
		return
	
	# Only update if we're on the terrain step
	if current_step != 2:
		return
	
	var terrain_params: Dictionary = step_data.get("Terrain", {})
	if terrain_params.is_empty():
		return
	
	# Get parameters
	var seed_value: int = terrain_params.get("seed", 12345)
	var frequency: float = terrain_params.get("noise_frequency", 0.0005)
	var height_scale: float = terrain_params.get("height_scale", 20.0)
	var min_height: float = 0.0
	var max_height: float = 150.0 * (height_scale / 20.0)
	
	# Generate terrain
	if terrain_manager.has_method("generate_from_noise"):
		terrain_manager.generate_from_noise(seed_value, frequency, min_height, max_height)
	else:
		# Fallback: use generate_initial_terrain if available
		if terrain_manager.has_method("generate_initial_terrain"):
			terrain_manager.generate_initial_terrain()


func _on_regenerate_terrain_pressed() -> void:
	"""Handle Regenerate Terrain button press."""
	_update_terrain_live()
	print("WorldBuilderUI: Terrain regenerated")


func _on_seed_changed(new_seed: int) -> void:
	"""Handle seed change from Step 1."""
	step_data["Seed & Size"]["seed"] = new_seed
	# Update terrain step seed if it exists
	if control_references.has("Terrain/seed"):
		var terrain_seed: SpinBox = control_references["Terrain/seed"] as SpinBox
		if terrain_seed != null:
			terrain_seed.value = new_seed
			step_data["Terrain"]["seed"] = new_seed


func _update_terrain_seed_from_step1() -> void:
	"""Update terrain step seed field from Step 1."""
	var step1_seed: int = step_data.get("Seed & Size", {}).get("seed", 12345)
	if control_references.has("Terrain/seed"):
		var terrain_seed: SpinBox = control_references["Terrain/seed"] as SpinBox
		if terrain_seed != null:
			terrain_seed.value = step1_seed
			step_data["Terrain"]["seed"] = step1_seed


func _on_icon_toolbar_selected(icon_id: String) -> void:
	"""Handle icon selection from toolbar."""
	step_data["2D Map Maker"]["selected_icon"] = icon_id
	print("WorldBuilderUI: Selected icon: ", icon_id)


func _on_canvas_clicked(event: InputEvent) -> void:
	"""Handle clicks on map canvas to place icons."""
	if not event is InputEventMouseButton:
		return
	
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	var step_container: VBoxContainer = content_area.get_node_or_null("StepContainer")
	if step_container == null:
		return
	
	var step_panel: Panel = step_container.get_node_or_null("StepMapMaker")
	if step_panel == null:
		return
	
	var canvas: Panel = step_panel.get_node_or_null("MapCanvas")
	if canvas == null:
		return
	
	var icon_container: Control = canvas.get_node_or_null("IconContainer")
	if icon_container == null:
		return
	
	var selected_icon_id: String = step_data.get("2D Map Maker", {}).get("selected_icon", "")
	if selected_icon_id.is_empty():
		return
	
	# Find icon data
	var icon_data: Dictionary = {}
	var icons: Array = map_icons_data.get("icons", [])
	for icon: Dictionary in icons:
		if icon.get("id", "") == selected_icon_id:
			icon_data = icon
			break
	
	if icon_data.is_empty():
		return
	
	# Get click position relative to canvas
	var click_pos: Vector2 = mouse_event.position
	
	# Create icon visual (using Control-based approach for compatibility)
	var icon_visual: Control = Control.new()
	icon_visual.name = "Icon_" + str(placed_icons.size())
	icon_visual.position = click_pos
	icon_visual.custom_minimum_size = Vector2(32, 32)
	icon_visual.size = Vector2(32, 32)
	
	# Create colored rectangle as icon
	var icon_rect: ColorRect = ColorRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon_color_array: Array = icon_data.get("color", [0.5, 0.5, 0.5, 1.0])
	var icon_color: Color = Color(icon_color_array[0], icon_color_array[1], icon_color_array[2], icon_color_array[3])
	icon_rect.color = icon_color
	icon_visual.add_child(icon_rect)
	
	# Create icon node data structure (simplified for Control-based approach)
	var icon_node: IconNode = IconNode.new()
	icon_node.set_icon_data(selected_icon_id, icon_color)
	icon_node.position = click_pos
	icon_node.map_position = click_pos
	
	# Store reference to visual
	icon_node.sprite = icon_visual
	
	icon_container.add_child(icon_visual)
	placed_icons.append(icon_node)
	
	print("WorldBuilderUI: Placed icon ", selected_icon_id, " at ", click_pos)


func _start_3d_conversion() -> void:
	"""Start 3D conversion process after step 2."""
	print("WorldBuilderUI: Starting 3D conversion process...")
	
	# Cluster icons by proximity
	icon_groups = _cluster_icons(placed_icons, 50.0)
	
	# Process first group/icon
	current_icon_group_index = 0
	_show_icon_type_selection_dialog()


func _cluster_icons(icons: Array[IconNode], distance_threshold: float) -> Array[Array]:
	"""Cluster icons by proximity using DBSCAN-like algorithm."""
	var groups: Array[Array] = []
	var processed: Array[bool] = []
	processed.resize(icons.size())
	
	for i in range(icons.size()):
		if processed[i]:
			continue
		
		var group: Array[IconNode] = [icons[i]]
		processed[i] = true
		
		# Find all nearby icons of the same type
		for j in range(i + 1, icons.size()):
			if processed[j]:
				continue
			
			if icons[i].icon_id == icons[j].icon_id:
				var distance: float = icons[i].get_distance_to(icons[j])
				if distance <= distance_threshold:
					group.append(icons[j])
					processed[j] = true
		
		groups.append(group)
	
	print("WorldBuilderUI: Clustered ", icons.size(), " icons into ", groups.size(), " groups")
	return groups


func _show_icon_type_selection_dialog() -> void:
	"""Show pop-up dialog for icon type selection."""
	if current_icon_group_index >= icon_groups.size():
		# All groups processed, proceed to next step
		current_step += 1
		_update_step_display()
		_generate_3d_world()
		return
	
	var group: Array = icon_groups[current_icon_group_index]
	var first_icon: IconNode = group[0] if group.size() > 0 else null
	if first_icon == null:
		current_icon_group_index += 1
		_show_icon_type_selection_dialog()
		return
	
	# Find icon data
	var icon_data: Dictionary = {}
	var icons: Array = map_icons_data.get("icons", [])
	for icon: Dictionary in icons:
		if icon.get("id", "") == first_icon.icon_id:
			icon_data = icon
			break
	
	if icon_data.is_empty():
		current_icon_group_index += 1
		_show_icon_type_selection_dialog()
		return
	
	# Create pop-up dialog
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Select Type for " + first_icon.icon_id.capitalize()
	dialog.size = Vector2(600, 400)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(vbox)
	
	# Show icon at top
	var icon_preview: ColorRect = ColorRect.new()
	icon_preview.custom_minimum_size = Vector2(64, 64)
	icon_preview.color = first_icon.icon_color
	vbox.add_child(icon_preview)
	
	# Type selection buttons
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	var hbox: HBoxContainer = HBoxContainer.new()
	scroll.add_child(hbox)
	vbox.add_child(scroll)
	
	var types: Array = icon_data.get("types", [])
	for type_name: String in types:
		var type_button: Button = Button.new()
		type_button.text = type_name.capitalize()
		type_button.custom_minimum_size = Vector2(150, 100)
		type_button.pressed.connect(func(): _on_type_selected(type_name, group, dialog))
		hbox.add_child(type_button)
	
	add_child(dialog)
	dialog.popup_centered()


func _on_type_selected(type_name: String, group: Array, dialog: AcceptDialog) -> void:
	"""Handle type selection for icon group."""
	# Set type for all icons in group
	for icon: IconNode in group:
		icon.icon_type = type_name
	
	dialog.queue_free()
	
	# Process next group
	current_icon_group_index += 1
	_show_icon_type_selection_dialog()


func _generate_3d_world() -> void:
	"""Generate 3D world based on selected icon types."""
	print("WorldBuilderUI: Generating 3D world from 2D map...")
	
	if terrain_manager == null:
		push_warning("WorldBuilderUI: No terrain manager assigned")
		return
	
	# Use seed from step 1
	var seed_value: int = step_data.get("Seed & Size", {}).get("seed", 12345)
	
	# Generate terrain
	if terrain_manager.has_method("generate_from_noise"):
		terrain_manager.generate_from_noise(seed_value, 0.0005, 0.0, 150.0)
	
	# Place structures based on icons
	for icon: IconNode in placed_icons:
		if icon.icon_type.is_empty():
			continue
		
		# Convert 2D position to 3D (simplified for now)
		var world_pos: Vector3 = Vector3(icon.map_position.x, 0.0, icon.map_position.y)
		if terrain_manager.has_method("get_height_at"):
			world_pos.y = terrain_manager.get_height_at(world_pos)
		
		# Place structure based on icon type
		if terrain_manager.has_method("place_structure"):
			terrain_manager.place_structure(icon.icon_id + "_" + icon.icon_type, world_pos, 1.0)
	
	print("WorldBuilderUI: 3D world generation complete")


func set_terrain_manager(manager) -> void:  # manager: Terrain3DManager - type hint removed
	"""Set the terrain manager reference."""
	terrain_manager = manager
	
	if terrain_manager != null:
		if terrain_manager.has_method("terrain_generated"):
			terrain_manager.terrain_generated.connect(_on_terrain_generated)
		if terrain_manager.has_method("terrain_updated"):
			terrain_manager.terrain_updated.connect(_on_terrain_updated)


func _on_terrain_generated(_terrain) -> void:  # _terrain: Terrain3D - type hint removed
	"""Handle terrain generation complete signal."""
	pass


func _on_terrain_updated() -> void:
	"""Handle terrain update signal."""
	pass


func _on_climate_param_changed(param_name: String, value: Variant) -> void:
	"""Handle climate parameter changes with live updates."""
	step_data["Climate"][param_name] = value
	
	# Update value labels
	match param_name:
		"temperature_intensity":
			var label: Label = control_references.get("Climate/temperature_intensity_value") as Label
			if label != null:
				label.text = "%.2f" % value
		"rainfall_intensity":
			var label: Label = control_references.get("Climate/rainfall_intensity_value") as Label
			if label != null:
				label.text = "%.2f" % value
		"wind_strength":
			var label: Label = control_references.get("Climate/wind_strength_value") as Label
			if label != null:
				label.text = "%.1f" % value
		"time_of_day":
			var label: Label = control_references.get("Climate/time_of_day_value") as Label
			if label != null:
				label.text = "%.1f" % value
	
	# Live climate update (affects sky in real time)
	call_deferred("_update_climate_live")


func _update_climate_live() -> void:
	"""Update climate effects in real-time."""
	if terrain_manager == null:
		return
	
	# Only update if we're on the climate step
	if current_step != 3:
		return
	
	var climate_params: Dictionary = step_data.get("Climate", {})
	if climate_params.is_empty():
		return
	
	# Update time of day (affects sky)
	var time_of_day: float = climate_params.get("time_of_day", 12.0)
	var wind_strength: float = climate_params.get("wind_strength", 1.0)
	var wind_dir_x: float = climate_params.get("wind_direction_x", 1.0)
	var wind_dir_y: float = climate_params.get("wind_direction_y", 0.0)
	
	# Update environment if terrain manager supports it
	if terrain_manager.has_method("update_environment"):
		terrain_manager.update_environment(time_of_day, 0.1, wind_strength, "clear", Color(0.5, 0.7, 1.0, 1.0), Color(0.3, 0.3, 0.3, 1.0))


func _on_biome_overlay_toggled(pressed: bool) -> void:
	"""Handle biome overlay toggle."""
	step_data["Biomes"]["show_biome_overlay"] = pressed
	print("WorldBuilderUI: Biome overlay ", "enabled" if pressed else "disabled")


func _on_biome_selected(index: int) -> void:
	"""Handle biome selection from list."""
	var biomes: Array = biomes_data.get("biomes", [])
	if index >= 0 and index < biomes.size():
		var biome_data: Dictionary = biomes[index]
		step_data["Biomes"]["selected_biome"] = biome_data.get("id", "")
		print("WorldBuilderUI: Selected biome: ", biome_data.get("name", "Unknown"))


func _on_biome_generation_mode_changed(index: int) -> void:
	"""Handle biome generation mode change."""
	step_data["Biomes"]["generation_mode"] = index
	print("WorldBuilderUI: Biome generation mode changed to: ", index)


func _on_generate_biomes_pressed() -> void:
	"""Handle Generate Biomes button press."""
	var mode: int = step_data.get("Biomes", {}).get("generation_mode", 1)
	
	match mode:
		0:  # Manual Painting
			print("WorldBuilderUI: Manual biome painting mode (not yet implemented)")
		1:  # Auto-Generate from Climate
			_generate_biomes_from_climate()
		2:  # Auto-Generate from Height
			_generate_biomes_from_height()
	
	# Show overlay if enabled
	if step_data.get("Biomes", {}).get("show_biome_overlay", false):
		_show_biome_overlay()


func _generate_biomes_from_climate() -> void:
	"""Generate biomes based on climate parameters."""
	print("WorldBuilderUI: Generating biomes from climate...")
	
	var climate_params: Dictionary = step_data.get("Climate", {})
	var temperature_intensity: float = climate_params.get("temperature_intensity", 0.5)
	var rainfall_intensity: float = climate_params.get("rainfall_intensity", 0.5)
	
	# Map intensity (0-1) to actual ranges
	# Temperature: -50 to 50 degrees
	var temperature: float = lerp(-50.0, 50.0, temperature_intensity)
	# Rainfall: 0 to 300 mm
	var rainfall: float = lerp(0.0, 300.0, rainfall_intensity)
	
	# Find matching biome
	var biomes: Array = biomes_data.get("biomes", [])
	var matched_biome: Dictionary = {}
	
	for biome: Dictionary in biomes:
		var temp_range: Array = biome.get("temperature_range", [])
		var rain_range: Array = biome.get("rainfall_range", [])
		
		if temp_range.size() >= 2 and rain_range.size() >= 2:
			if temperature >= temp_range[0] and temperature <= temp_range[1]:
				if rainfall >= rain_range[0] and rainfall <= rain_range[1]:
					matched_biome = biome
					break
	
	if matched_biome.is_empty() and biomes.size() > 0:
		# Default to first biome if no match
		matched_biome = biomes[0]
	
	if not matched_biome.is_empty():
		step_data["Biomes"]["generated_biome"] = matched_biome.get("id", "")
		print("WorldBuilderUI: Generated biome: ", matched_biome.get("name", "Unknown"))
		
		# Apply biome to terrain if manager supports it
		if terrain_manager != null and terrain_manager.has_method("apply_biome_map"):
			var biome_color_array: Array = matched_biome.get("color", [0.5, 0.5, 0.5, 1.0])
			var biome_color: Color = Color(biome_color_array[0], biome_color_array[1], biome_color_array[2], biome_color_array[3])
			terrain_manager.apply_biome_map(matched_biome.get("id", ""), 0.5, biome_color)


func _generate_biomes_from_height() -> void:
	"""Generate biomes based on terrain height."""
	print("WorldBuilderUI: Generating biomes from height...")
	
	# Simple height-based biome assignment
	# Higher = mountain/tundra, lower = ocean/swamp
	step_data["Biomes"]["generated_biome"] = "mountain"  # Placeholder
	print("WorldBuilderUI: Height-based biome generation (simplified)")


func _show_biome_overlay() -> void:
	"""Show biome overlay on 2D map."""
	print("WorldBuilderUI: Showing biome overlay on 2D map")
	# TODO: Implement visual overlay on map canvas
