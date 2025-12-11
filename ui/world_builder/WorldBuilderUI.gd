# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: Step-by-step wizard-style world building UI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## IconNode is available via class_name, no preload needed

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

## Biomes data
var biomes_data: Dictionary = {}

## Civilizations data
var civilizations_data: Dictionary = {}

## Placed icons on 2D map
var placed_icons: Array = []  # Array[IconNode] - using untyped for compatibility

## Icon groups after clustering
var icon_groups: Array[Array] = []

## Current icon being processed for type selection
var current_icon_group_index: int = 0

## References to UI nodes
@onready var left_nav: Panel = $BackgroundPanel/MainContainer/LeftNav
@onready var center_preview: SubViewportContainer = $BackgroundPanel/MainContainer/RightSplit/CenterPreview
@onready var preview_viewport: SubViewport = $BackgroundPanel/MainContainer/RightSplit/CenterPreview/PreviewViewport
@onready var preview_world: Node3D = $BackgroundPanel/MainContainer/RightSplit/CenterPreview/PreviewViewport/PreviewWorld
@onready var preview_camera: Camera3D = $BackgroundPanel/MainContainer/RightSplit/CenterPreview/PreviewViewport/PreviewWorld/PreviewCamera
@onready var map_2d_layer: Node2D = $BackgroundPanel/MainContainer/RightSplit/CenterPreview/PreviewViewport/PreviewWorld/Map2DLayer
@onready var right_content: PanelContainer = $BackgroundPanel/MainContainer/RightSplit/RightContent
@onready var step_buttons: Array[Button] = []
@onready var next_button: Button = $BackgroundPanel/ButtonContainer/NextButton
@onready var back_button: Button = $BackgroundPanel/ButtonContainer/BackButton
@onready var overlay: ColorRect = $Overlay

## Preview terrain reference (will be set when terrain manager is connected)
var preview_terrain: Node = null

## Paths
const MAP_ICONS_PATH: String = "res://data/map_icons.json"
const UI_CONFIG_PATH: String = "res://data/config/world_builder_ui.json"
const BIOMES_PATH: String = "res://data/biomes.json"
const CIVILIZATIONS_PATH: String = "res://data/civilizations.json"

## Control references
var control_references: Dictionary = {}


func _ready() -> void:
	_load_map_icons()
	_load_biomes()
	_load_civilizations()
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


func _load_biomes() -> void:
	"""Load biomes configuration from JSON."""
	var file: FileAccess = FileAccess.open(BIOMES_PATH, FileAccess.READ)
	if file == null:
		push_error("WorldBuilderUI: Failed to load biomes from " + BIOMES_PATH)
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("WorldBuilderUI: Failed to parse biomes JSON: " + json.get_error_message())
		return
	
	biomes_data = json.data
	print("WorldBuilderUI: Loaded ", biomes_data.get("biomes", []).size(), " biome definitions")


func _load_civilizations() -> void:
	"""Load civilizations configuration from JSON."""
	var file: FileAccess = FileAccess.open(CIVILIZATIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("WorldBuilderUI: Failed to load civilizations from " + CIVILIZATIONS_PATH)
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("WorldBuilderUI: Failed to parse civilizations JSON: " + json.get_error_message())
		return
	
	civilizations_data = json.data
	print("WorldBuilderUI: Loaded ", civilizations_data.get("civilizations", []).size(), " civilization definitions")


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
	"""Setup left navigation panel with step buttons."""
	if left_nav == null:
		return
	
	var nav_container: VFlowContainer = VFlowContainer.new()
	nav_container.name = "NavContainer"
	nav_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nav_container.add_theme_constant_override("separation", 10)
	left_nav.add_child(nav_container)
	
	# Create step buttons
	for i in range(STEPS.size()):
		var step_button: Button = Button.new()
		step_button.name = "Step" + str(i + 1) + "Button"
		step_button.text = str(i + 1) + ". " + STEPS[i]
		step_button.custom_minimum_size = Vector2(0, 50)
		step_button.pressed.connect(func(): _on_step_button_pressed(i))
		step_buttons.append(step_button)
		nav_container.add_child(step_button)


func _setup_step_content() -> void:
	"""Setup content panels for each step in right panel."""
	if right_content == null:
		return
	
	# Create container for step content
	var step_container: VBoxContainer = VBoxContainer.new()
	step_container.name = "StepContainer"
	step_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	step_container.add_theme_constant_override("separation", 10)
	right_content.add_child(step_container)
	
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
	
	# Create step 6: Structures & Civilizations
	_create_step_structures(step_container)
	
	# Create step 7: Environment
	_create_step_environment(step_container)
	
	# Create step 8: Resources & Magic
	_create_step_resources(step_container)
	
	# Create step 9: Export
	_create_step_export(step_container)
	
	# Setup camera and preview
	_setup_preview_camera()
	_setup_2d_map_layer()


func _setup_preview_camera() -> void:
	"""Setup preview camera with orthographic top-down view for Steps 1-2."""
	if preview_camera == null:
		return
	
	# Default: Orthographic top-down view
	preview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	preview_camera.size = 200.0
	preview_camera.transform.origin = Vector3(0, 100, 0)
	preview_camera.rotation_degrees = Vector3(-90, 0, 0)  # Look straight down
	preview_camera.current = true


func _setup_2d_map_layer() -> void:
	"""Setup 2D map layer with parchment background and grid."""
	if map_2d_layer == null:
		return
	
	# Get world size for background
	var world_width: float = float(step_data.get("Seed & Size", {}).get("width", 1000))
	var world_height: float = float(step_data.get("Seed & Size", {}).get("height", 1000))
	
	# Create parchment background using Sprite2D with colored quad
	# We'll use a simple approach: create a large colored rectangle using Polygon2D
	var parchment_bg: Polygon2D = Polygon2D.new()
	parchment_bg.name = "ParchmentBackground"
	parchment_bg.color = Color(0.85, 0.75, 0.65, 1.0)  # Parchment color
	# Create rectangle polygon
	parchment_bg.polygon = PackedVector2Array([
		Vector2(-world_width / 2, -world_height / 2),
		Vector2(world_width / 2, -world_height / 2),
		Vector2(world_width / 2, world_height / 2),
		Vector2(-world_width / 2, world_height / 2)
	])
	map_2d_layer.add_child(parchment_bg)
	
	# Try to load parchment texture if available (as overlay)
	var parchment_texture_path: String = "res://assets/ui/parchment_background.png"
	if ResourceLoader.exists(parchment_texture_path):
		var texture: Texture2D = load(parchment_texture_path)
		if texture != null:
			var parchment_sprite: Sprite2D = Sprite2D.new()
			parchment_sprite.name = "ParchmentTexture"
			parchment_sprite.texture = texture
			parchment_sprite.position = Vector2.ZERO
			parchment_sprite.scale = Vector2(world_width / texture.get_width(), world_height / texture.get_height())
			parchment_sprite.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent overlay
			map_2d_layer.add_child(parchment_sprite)
	
	# Create grid lines (using Line2D nodes)
	_create_map_grid()
	
	# Create compass rose placeholder (will be added later)
	_create_compass_rose()


func _create_map_grid() -> void:
	"""Create grid lines for the 2D map."""
	if map_2d_layer == null:
		return
	
	var grid_container: Node2D = Node2D.new()
	grid_container.name = "GridContainer"
	map_2d_layer.add_child(grid_container)
	
	# Get world size from step data
	var world_width: float = float(step_data.get("Seed & Size", {}).get("width", 1000))
	var world_height: float = float(step_data.get("Seed & Size", {}).get("height", 1000))
	
	# Create horizontal grid lines
	var grid_spacing: float = 100.0
	var grid_color: Color = Color(0.6, 0.5, 0.4, 0.3)  # Light ink color
	
	for y in range(0, int(world_height) + 1, int(grid_spacing)):
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(-world_width / 2, y - world_height / 2))
		line.add_point(Vector2(world_width / 2, y - world_height / 2))
		line.width = 1.0
		line.default_color = grid_color
		grid_container.add_child(line)
	
	# Create vertical grid lines
	for x in range(0, int(world_width) + 1, int(grid_spacing)):
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(x - world_width / 2, -world_height / 2))
		line.add_point(Vector2(x - world_width / 2, world_height / 2))
		line.width = 1.0
		line.default_color = grid_color
		grid_container.add_child(line)


func _create_compass_rose() -> void:
	"""Create compass rose decoration for the map."""
	if map_2d_layer == null:
		return
	
	# Create compass rose using simple 2D shapes
	var compass_container: Node2D = Node2D.new()
	compass_container.name = "CompassRose"
	compass_container.position = Vector2(-450, -450)  # Top-left corner
	map_2d_layer.add_child(compass_container)
	
	# Create N marker using Line2D
	var n_marker: Line2D = Line2D.new()
	n_marker.add_point(Vector2(0, -20))
	n_marker.add_point(Vector2(0, 20))
	n_marker.width = 3.0
	n_marker.default_color = Color(0.85, 0.7, 0.4, 1.0)
	compass_container.add_child(n_marker)
	
	# Add N label using a simple approach (we'll use a sprite or draw)
	# For now, just the line marker


func _update_map_grid() -> void:
	"""Update map grid when world size changes."""
	if map_2d_layer == null:
		return
	
	# Remove old grid
	var old_grid: Node2D = map_2d_layer.get_node_or_null("GridContainer")
	if old_grid != null:
		old_grid.queue_free()
	
	# Create new grid with updated size
	_create_map_grid()


func update_camera_for_step(step: int) -> void:
	"""Update camera projection and position based on current step."""
	if preview_camera == null:
		return
	
	match step:
		0, 1:  # Steps 1-2: Orthographic top-down
			preview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			preview_camera.size = 200.0
			preview_camera.transform.origin = Vector3(0, 100, 0)
			preview_camera.rotation_degrees = Vector3(-90, 0, 0)
			# Show 2D map layer
			if map_2d_layer != null:
				map_2d_layer.visible = true
				map_2d_layer.modulate.a = 1.0
			# Hide terrain preview if it exists
			if preview_terrain != null:
				preview_terrain.visible = false
		2, 3, 4, 5, 6, 7, 8:  # Steps 3+: Perspective with orbit
			# Transition to perspective
			preview_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			preview_camera.fov = 70.0
			# Position camera to view terrain
			var world_width: float = float(step_data.get("Seed & Size", {}).get("width", 1000))
			var world_height: float = float(step_data.get("Seed & Size", {}).get("height", 1000))
			var max_dim: float = max(world_width, world_height)
			preview_camera.transform.origin = Vector3(max_dim * 0.5, max_dim * 0.3, max_dim * 0.5)
			preview_camera.look_at(Vector3(world_width / 2, 0, world_height / 2), Vector3.UP)
			# Fade out 2D map layer
			if map_2d_layer != null:
				_fade_out_2d_map()
			# Show terrain preview
			call_deferred("_ensure_terrain_in_preview")


func _fade_out_2d_map() -> void:
	"""Fade out the 2D map layer when transitioning to 3D."""
	if map_2d_layer == null:
		return
	
	# Create tween for smooth fade
	var tween: Tween = create_tween()
	tween.tween_property(map_2d_layer, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): map_2d_layer.visible = false)


func _ensure_terrain_in_preview() -> void:
	"""Ensure terrain is visible in preview viewport for Steps 3+."""
	if terrain_manager == null or preview_world == null:
		return
	
	# For now, terrain is in main scene - preview won't show it directly
	# In a full implementation, we'd duplicate terrain or use ViewportTexture
	# For MVP, we'll show a placeholder or use the main scene's terrain via remote
	# For now, just ensure camera is positioned correctly
	# The actual terrain rendering will happen in the main scene
	print("WorldBuilderUI: Terrain preview ready for Step 3+")


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
	height_spinbox.value_changed.connect(func(v): 
		step_data["Seed & Size"]["height"] = int(v)
		call_deferred("_update_map_grid")
	)
	size_container.add_child(height_spinbox)
	container.add_child(size_container)
	control_references["Seed & Size/width"] = width_spinbox
	control_references["Seed & Size/height"] = height_spinbox
	step_data["Seed & Size"]["width"] = 1000
	step_data["Seed & Size"]["height"] = 1000
	
	# Update width change handler too
	width_spinbox.value_changed.connect(func(v): 
		step_data["Seed & Size"]["width"] = int(v)
		call_deferred("_update_map_grid")
	)


func _create_step_map_maker(parent: VBoxContainer) -> void:
	"""Create Step 2: 2D Map Maker content - now integrated in central viewport."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepMapMaker"
	step_panel.visible = (current_step == 1)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Info label
	var info_label: Label = Label.new()
	info_label.text = "Click on the central map preview to place icons.\nSelect an icon type from the toolbar below, then click on the map."
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(info_label)
	
	# Toolbar for icon selection
	var toolbar_label: Label = Label.new()
	toolbar_label.text = "Icon Tools:"
	container.add_child(toolbar_label)
	
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.name = "IconToolbar"
	toolbar.add_theme_constant_override("separation", 5)
	container.add_child(toolbar)
	
	# Create buttons for each icon type
	var icons: Array = map_icons_data.get("icons", [])
	for icon_data: Dictionary in icons:
		var icon_button: Button = Button.new()
		icon_button.text = icon_data.get("id", "unknown")
		icon_button.pressed.connect(func(): _on_icon_toolbar_selected(icon_data.get("id", "")))
		icon_button.custom_minimum_size = Vector2(80, 40)
		toolbar.add_child(icon_button)
	
	# Delete/Erase tool
	var delete_button: Button = Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(func(): _on_icon_toolbar_selected("delete"))
	delete_button.custom_minimum_size = Vector2(80, 40)
	toolbar.add_child(delete_button)
	
	# Zoom controls
	var zoom_label: Label = Label.new()
	zoom_label.text = "Zoom:"
	container.add_child(zoom_label)
	
	var zoom_container: HBoxContainer = HBoxContainer.new()
	var zoom_out_button: Button = Button.new()
	zoom_out_button.text = "-"
	zoom_out_button.pressed.connect(func(): _on_zoom_changed(-0.1))
	zoom_container.add_child(zoom_out_button)
	
	var zoom_reset_button: Button = Button.new()
	zoom_reset_button.text = "Reset"
	zoom_reset_button.pressed.connect(func(): _on_zoom_changed(0.0))
	zoom_container.add_child(zoom_reset_button)
	
	var zoom_in_button: Button = Button.new()
	zoom_in_button.text = "+"
	zoom_in_button.pressed.connect(func(): _on_zoom_changed(0.1))
	zoom_container.add_child(zoom_in_button)
	container.add_child(zoom_container)
	
	# Make preview viewport clickable for icon placement
	if center_preview != null:
		center_preview.gui_input.connect(_on_preview_clicked)


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


func _create_step_structures(parent: VBoxContainer) -> void:
	"""Create Step 6: Structures & Civilizations content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepStructures"
	step_panel.visible = (current_step == 5)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Info label
	var info_label: Label = Label.new()
	info_label.text = "City/Town/Village icons from Step 2 will be processed here.\nClick 'Process Cities' to assign civilizations."
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(info_label)
	
	# Process cities button
	var process_button: Button = Button.new()
	process_button.name = "process_cities"
	process_button.text = "Process Cities from Map"
	process_button.pressed.connect(_on_process_cities_pressed)
	container.add_child(process_button)
	control_references["Structures & Civilizations/process_cities"] = process_button
	
	# City list (will be populated when processing)
	var city_list_label: Label = Label.new()
	city_list_label.text = "Cities:"
	container.add_child(city_list_label)
	
	var city_list: ItemList = ItemList.new()
	city_list.name = "city_list"
	city_list.custom_minimum_size = Vector2(0, 200)
	city_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	city_list.item_selected.connect(_on_city_selected)
	container.add_child(city_list)
	control_references["Structures & Civilizations/city_list"] = city_list
	
	step_data["Structures & Civilizations"] = {}
	step_data["Structures & Civilizations"]["cities"] = []


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
	# Update step button highlighting
	for i in range(step_buttons.size()):
		if i == current_step:
			# Highlight current step in gold (use theme override)
			step_buttons[i].add_theme_color_override("font_color", Color(1, 0.843137, 0, 1))
			step_buttons[i].add_theme_color_override("font_hover_color", Color(1, 0.95, 0.75, 1))
		else:
			step_buttons[i].remove_theme_color_override("font_color")
			step_buttons[i].remove_theme_color_override("font_hover_color")
		# Disable future steps until previous ones are complete
		step_buttons[i].disabled = (i > current_step)
	
	# Show/hide step content panels
	var step_container: VBoxContainer = right_content.get_node_or_null("StepContainer")
	if step_container != null:
		for i in range(step_container.get_child_count()):
			var child: Node = step_container.get_child(i)
			child.visible = (i == current_step)
	
	# Update button states
	if back_button != null:
		back_button.disabled = (current_step == 0)
	if next_button != null:
		next_button.disabled = (current_step == STEPS.size() - 1)
	
	# Update camera for current step
	update_camera_for_step(current_step)
	
	# Update seed in Step 3 when entering terrain step
	if current_step == 2:
		_update_terrain_seed_from_step1()
	
	# Update export summary when entering export step
	if current_step == 8:
		_update_export_summary()


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


func _on_step_button_pressed(step_index: int) -> void:
	"""Handle step button press - jump to step if allowed."""
	# Only allow jumping to completed steps or current step
	if step_index <= current_step:
		current_step = step_index
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
		# Update preview
		call_deferred("_update_preview_terrain")
	else:
		# Fallback: use generate_initial_terrain if available
		if terrain_manager.has_method("generate_initial_terrain"):
			terrain_manager.generate_initial_terrain()
			call_deferred("_update_preview_terrain")


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
	# Update grid if world size changed
	call_deferred("_update_map_grid")


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


func _on_preview_clicked(event: InputEvent) -> void:
	"""Handle clicks on preview viewport to place icons on 2D map."""
	if current_step != 1:  # Only allow placement in Step 2
		return
	
	if not event is InputEventMouseButton:
		return
	
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if map_2d_layer == null:
		return
	
	var selected_icon_id: String = step_data.get("2D Map Maker", {}).get("selected_icon", "")
	if selected_icon_id.is_empty() or selected_icon_id == "delete":
		# Handle delete mode - remove icon at click position
		if selected_icon_id == "delete":
			_remove_icon_at_position(mouse_event.position)
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
	
	# Convert screen position to world position in Map2DLayer
	var world_pos: Vector2 = _screen_to_map_position(mouse_event.position)
	
	# Create icon node as Sprite2D in Map2DLayer
	var icon_node: IconNode = IconNode.new()
	icon_node.name = "Icon_" + str(placed_icons.size())
	icon_node.position = world_pos
	icon_node.map_position = world_pos
	
	var icon_color_array: Array = icon_data.get("color", [0.5, 0.5, 0.5, 1.0])
	var icon_color: Color = Color(icon_color_array[0], icon_color_array[1], icon_color_array[2], icon_color_array[3])
	icon_node.set_icon_data(selected_icon_id, icon_color)
	
	map_2d_layer.add_child(icon_node)
	placed_icons.append(icon_node)
	
	print("WorldBuilderUI: Placed icon ", selected_icon_id, " at ", world_pos)


func _screen_to_map_position(screen_pos: Vector2) -> Vector2:
	"""Convert screen position to world position in Map2DLayer coordinates."""
	if preview_camera == null or map_2d_layer == null:
		return Vector2.ZERO
	
	# Get viewport size
	var viewport_size: Vector2 = preview_viewport.size if preview_viewport != null else Vector2(1920, 1080)
	
	# Normalize screen position to -1..1 range
	var normalized: Vector2 = (screen_pos / viewport_size) * 2.0 - Vector2(1.0, 1.0)
	normalized.y = -normalized.y  # Flip Y axis
	
	# Get world size from step data
	var world_width: float = float(step_data.get("Seed & Size", {}).get("width", 1000))
	var world_height: float = float(step_data.get("Seed & Size", {}).get("height", 1000))
	
	# Convert to world coordinates (orthographic camera view)
	var camera_size: float = preview_camera.size if preview_camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 100.0
	var world_pos: Vector2 = Vector2(
		normalized.x * camera_size,
		normalized.y * camera_size
	)
	
	return world_pos


func _remove_icon_at_position(screen_pos: Vector2) -> void:
	"""Remove icon closest to click position."""
	if map_2d_layer == null or placed_icons.is_empty():
		return
	
	var world_pos: Vector2 = _screen_to_map_position(screen_pos)
	var min_distance: float = 50.0  # Click radius
	var closest_icon: IconNode = null
	var closest_index: int = -1
	
	for i in range(placed_icons.size()):
		var icon: IconNode = placed_icons[i]
		if icon == null:
			continue
		var distance: float = icon.map_position.distance_to(world_pos)
		if distance < min_distance:
			min_distance = distance
			closest_icon = icon
			closest_index = i
	
	if closest_icon != null:
		placed_icons.remove_at(closest_index)
		closest_icon.queue_free()
		print("WorldBuilderUI: Removed icon at ", world_pos)


func _on_zoom_changed(zoom_delta: float) -> void:
	"""Handle zoom changes for the 2D map."""
	if preview_camera == null:
		return
	
	if zoom_delta == 0.0:
		# Reset zoom
		preview_camera.size = 200.0
	else:
		# Adjust zoom
		preview_camera.size = clamp(preview_camera.size * (1.0 - zoom_delta), 50.0, 500.0)
	
	print("WorldBuilderUI: Camera size: ", preview_camera.size)


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
	var first_icon = group[0] if group.size() > 0 else null
	if first_icon == null:
		current_icon_group_index += 1
		_show_icon_type_selection_dialog()
		return
	
	# Find icon data
	var icon_data: Dictionary = {}
	var icons: Array = map_icons_data.get("icons", [])
	var first_icon_id: String = str(first_icon.get("icon_id", "")) if first_icon.has("icon_id") else ""
	for icon: Dictionary in icons:
		if icon.get("id", "") == first_icon_id:
			icon_data = icon
			break
	
	if icon_data.is_empty():
		current_icon_group_index += 1
		_show_icon_type_selection_dialog()
		return
	
	# Create pop-up dialog
	var dialog: AcceptDialog = AcceptDialog.new()
	var first_icon_id_str: String = str(first_icon.get("icon_id", "")) if first_icon.has("icon_id") else "icon"
	dialog.title = "Select Type for " + first_icon_id_str.capitalize()
	dialog.size = Vector2(600, 400)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(vbox)
	
	# Show icon at top
	var icon_preview: ColorRect = ColorRect.new()
	icon_preview.custom_minimum_size = Vector2(64, 64)
	var icon_color_val = first_icon.get("icon_color") if first_icon.has("icon_color") else Color.WHITE
	icon_preview.color = icon_color_val
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
	for icon in group:
		if icon and icon.has("icon_type"):
			icon.set("icon_type", type_name)
	
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
	for icon in placed_icons:
		if not icon.has("icon_type") or icon.get("icon_type", "").is_empty():
			continue
		
		# Convert 2D position to 3D (simplified for now)
		var icon_pos: Vector2 = icon.get("map_position", Vector2.ZERO) if icon is Dictionary else icon.map_position
		var world_pos: Vector3 = Vector3(icon_pos.x, 0.0, icon_pos.y)
		if terrain_manager.has_method("get_height_at"):
			world_pos.y = terrain_manager.get_height_at(world_pos)
		
		# Place structure based on icon type
		if terrain_manager.has_method("place_structure"):
			var icon_id: String = icon.get("icon_id", "") if icon is Dictionary else icon.icon_id
			var icon_type: String = icon.get("icon_type", "") if icon is Dictionary else icon.icon_type
			terrain_manager.place_structure(icon_id + "_" + icon_type, world_pos, 1.0)
	
	print("WorldBuilderUI: 3D world generation complete")


func _create_step_environment(parent: VBoxContainer) -> void:
	"""Create Step 7: Environment content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepEnvironment"
	step_panel.visible = (current_step == 6)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Fog density
	var fog_density_container: HBoxContainer = HBoxContainer.new()
	var fog_density_label: Label = Label.new()
	fog_density_label.text = "Fog Density:"
	fog_density_label.custom_minimum_size = Vector2(200, 0)
	fog_density_container.add_child(fog_density_label)
	
	var fog_density_slider: HSlider = HSlider.new()
	fog_density_slider.name = "fog_density"
	fog_density_slider.min_value = 0.0
	fog_density_slider.max_value = 1.0
	fog_density_slider.step = 0.01
	fog_density_slider.value = 0.1
	fog_density_slider.value_changed.connect(func(v): _on_environment_param_changed("fog_density", v))
	fog_density_container.add_child(fog_density_slider)
	
	var fog_density_value_label: Label = Label.new()
	fog_density_value_label.name = "fog_density_value"
	fog_density_value_label.custom_minimum_size = Vector2(80, 0)
	fog_density_value_label.text = "0.10"
	fog_density_container.add_child(fog_density_value_label)
	container.add_child(fog_density_container)
	control_references["Environment/fog_density"] = fog_density_slider
	control_references["Environment/fog_density_value"] = fog_density_value_label
	step_data["Environment"] = {}
	step_data["Environment"]["fog_density"] = 0.1
	
	# Fog color
	var fog_color_container: HBoxContainer = HBoxContainer.new()
	var fog_color_label: Label = Label.new()
	fog_color_label.text = "Fog Color:"
	fog_color_label.custom_minimum_size = Vector2(200, 0)
	fog_color_container.add_child(fog_color_label)
	
	var fog_color_picker: ColorPickerButton = ColorPickerButton.new()
	fog_color_picker.name = "fog_color"
	fog_color_picker.color = Color(0.8, 0.8, 0.9, 1.0)
	fog_color_picker.color_changed.connect(func(c): _on_environment_param_changed("fog_color", c))
	fog_color_container.add_child(fog_color_picker)
	container.add_child(fog_color_container)
	control_references["Environment/fog_color"] = fog_color_picker
	step_data["Environment"]["fog_color"] = Color(0.8, 0.8, 0.9, 1.0)
	
	# Sky type
	var sky_type_container: HBoxContainer = HBoxContainer.new()
	var sky_type_label: Label = Label.new()
	sky_type_label.text = "Sky Type:"
	sky_type_label.custom_minimum_size = Vector2(200, 0)
	sky_type_container.add_child(sky_type_label)
	
	var sky_type_option: OptionButton = OptionButton.new()
	sky_type_option.name = "sky_type"
	sky_type_option.add_item("Procedural")
	sky_type_option.add_item("HDRI")
	sky_type_option.add_item("Custom Gradient")
	sky_type_option.selected = 0
	sky_type_option.item_selected.connect(func(idx): _on_environment_param_changed("sky_type", idx))
	sky_type_container.add_child(sky_type_option)
	container.add_child(sky_type_container)
	control_references["Environment/sky_type"] = sky_type_option
	step_data["Environment"]["sky_type"] = 0
	
	# Ambient light intensity
	var ambient_intensity_container: HBoxContainer = HBoxContainer.new()
	var ambient_intensity_label: Label = Label.new()
	ambient_intensity_label.text = "Ambient Light Intensity:"
	ambient_intensity_label.custom_minimum_size = Vector2(200, 0)
	ambient_intensity_container.add_child(ambient_intensity_label)
	
	var ambient_intensity_slider: HSlider = HSlider.new()
	ambient_intensity_slider.name = "ambient_intensity"
	ambient_intensity_slider.min_value = 0.0
	ambient_intensity_slider.max_value = 2.0
	ambient_intensity_slider.step = 0.01
	ambient_intensity_slider.value = 0.3
	ambient_intensity_slider.value_changed.connect(func(v): _on_environment_param_changed("ambient_intensity", v))
	ambient_intensity_container.add_child(ambient_intensity_slider)
	
	var ambient_intensity_value_label: Label = Label.new()
	ambient_intensity_value_label.name = "ambient_intensity_value"
	ambient_intensity_value_label.custom_minimum_size = Vector2(80, 0)
	ambient_intensity_value_label.text = "0.30"
	ambient_intensity_container.add_child(ambient_intensity_value_label)
	container.add_child(ambient_intensity_container)
	control_references["Environment/ambient_intensity"] = ambient_intensity_slider
	control_references["Environment/ambient_intensity_value"] = ambient_intensity_value_label
	step_data["Environment"]["ambient_intensity"] = 0.3
	
	# Ambient light color
	var ambient_color_container: HBoxContainer = HBoxContainer.new()
	var ambient_color_label: Label = Label.new()
	ambient_color_label.text = "Ambient Light Color:"
	ambient_color_label.custom_minimum_size = Vector2(200, 0)
	ambient_color_container.add_child(ambient_color_label)
	
	var ambient_color_picker: ColorPickerButton = ColorPickerButton.new()
	ambient_color_picker.name = "ambient_color"
	ambient_color_picker.color = Color(0.3, 0.3, 0.3, 1.0)
	ambient_color_picker.color_changed.connect(func(c): _on_environment_param_changed("ambient_color", c))
	ambient_color_container.add_child(ambient_color_picker)
	container.add_child(ambient_color_container)
	control_references["Environment/ambient_color"] = ambient_color_picker
	step_data["Environment"]["ambient_color"] = Color(0.3, 0.3, 0.3, 1.0)
	
	# Water level
	var water_level_container: HBoxContainer = HBoxContainer.new()
	var water_level_label: Label = Label.new()
	water_level_label.text = "Water Level:"
	water_level_label.custom_minimum_size = Vector2(200, 0)
	water_level_container.add_child(water_level_label)
	
	var water_level_slider: HSlider = HSlider.new()
	water_level_slider.name = "water_level"
	water_level_slider.min_value = -50.0
	water_level_slider.max_value = 50.0
	water_level_slider.step = 0.1
	water_level_slider.value = 0.0
	water_level_slider.value_changed.connect(func(v): _on_environment_param_changed("water_level", v))
	water_level_container.add_child(water_level_slider)
	
	var water_level_value_label: Label = Label.new()
	water_level_value_label.name = "water_level_value"
	water_level_value_label.custom_minimum_size = Vector2(80, 0)
	water_level_value_label.text = "0.0"
	water_level_container.add_child(water_level_value_label)
	container.add_child(water_level_container)
	control_references["Environment/water_level"] = water_level_slider
	control_references["Environment/water_level_value"] = water_level_value_label
	step_data["Environment"]["water_level"] = 0.0
	
	# Ocean shader toggle
	var ocean_shader_container: HBoxContainer = HBoxContainer.new()
	var ocean_shader_label: Label = Label.new()
	ocean_shader_label.text = "Enable Ocean Shader:"
	ocean_shader_label.custom_minimum_size = Vector2(200, 0)
	ocean_shader_container.add_child(ocean_shader_label)
	
	var ocean_shader_checkbox: CheckBox = CheckBox.new()
	ocean_shader_checkbox.name = "ocean_shader"
	ocean_shader_checkbox.button_pressed = true
	ocean_shader_checkbox.toggled.connect(func(pressed): _on_environment_param_changed("ocean_shader", pressed))
	ocean_shader_container.add_child(ocean_shader_checkbox)
	container.add_child(ocean_shader_container)
	control_references["Environment/ocean_shader"] = ocean_shader_checkbox
	step_data["Environment"]["ocean_shader"] = true


func _create_step_resources(parent: VBoxContainer) -> void:
	"""Create Step 8: Resources & Magic content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepResources"
	step_panel.visible = (current_step == 7)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# Resource overlay toggle
	var overlay_container: HBoxContainer = HBoxContainer.new()
	var overlay_label: Label = Label.new()
	overlay_label.text = "Show Resource Overlay:"
	overlay_label.custom_minimum_size = Vector2(200, 0)
	overlay_container.add_child(overlay_label)
	
	var overlay_checkbox: CheckBox = CheckBox.new()
	overlay_checkbox.name = "show_resource_overlay"
	overlay_checkbox.button_pressed = false
	overlay_checkbox.toggled.connect(func(pressed): step_data["Resources & Magic"]["show_resource_overlay"] = pressed)
	overlay_container.add_child(overlay_checkbox)
	container.add_child(overlay_container)
	control_references["Resources & Magic/show_resource_overlay"] = overlay_checkbox
	step_data["Resources & Magic"] = {}
	step_data["Resources & Magic"]["show_resource_overlay"] = false
	
	# Magic density
	var magic_density_container: HBoxContainer = HBoxContainer.new()
	var magic_density_label: Label = Label.new()
	magic_density_label.text = "Magic Density:"
	magic_density_label.custom_minimum_size = Vector2(200, 0)
	magic_density_container.add_child(magic_density_label)
	
	var magic_density_slider: HSlider = HSlider.new()
	magic_density_slider.name = "magic_density"
	magic_density_slider.min_value = 0.0
	magic_density_slider.max_value = 1.0
	magic_density_slider.step = 0.01
	magic_density_slider.value = 0.5
	magic_density_slider.value_changed.connect(func(v): step_data["Resources & Magic"]["magic_density"] = v)
	magic_density_container.add_child(magic_density_slider)
	
	var magic_density_value_label: Label = Label.new()
	magic_density_value_label.name = "magic_density_value"
	magic_density_value_label.custom_minimum_size = Vector2(80, 0)
	magic_density_value_label.text = "0.50"
	magic_density_container.add_child(magic_density_value_label)
	container.add_child(magic_density_container)
	control_references["Resources & Magic/magic_density"] = magic_density_slider
	control_references["Resources & Magic/magic_density_value"] = magic_density_value_label
	step_data["Resources & Magic"]["magic_density"] = 0.5
	
	# Ley line placement info
	var ley_line_label: Label = Label.new()
	ley_line_label.text = "Ley Line Placement: Drag on 2D map to place ley lines"
	ley_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(ley_line_label)
	step_data["Resources & Magic"]["ley_lines"] = []


func _create_step_export(parent: VBoxContainer) -> void:
	"""Create Step 9: Export content."""
	var step_panel: Panel = Panel.new()
	step_panel.name = "StepExport"
	step_panel.visible = (current_step == 8)
	parent.add_child(step_panel)
	
	var container: VBoxContainer = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	step_panel.add_child(container)
	
	# World name
	var name_container: HBoxContainer = HBoxContainer.new()
	var name_label: Label = Label.new()
	name_label.text = "World Name:"
	name_label.custom_minimum_size = Vector2(200, 0)
	name_container.add_child(name_label)
	
	var name_edit: LineEdit = LineEdit.new()
	name_edit.name = "world_name"
	name_edit.placeholder_text = "Enter world name..."
	name_edit.text = "MyWorld"
	name_edit.text_changed.connect(func(text): step_data["Export"]["world_name"] = text)
	name_container.add_child(name_edit)
	container.add_child(name_container)
	control_references["Export/world_name"] = name_edit
	step_data["Export"] = {}
	step_data["Export"]["world_name"] = "MyWorld"
	
	# Summary panel
	var summary_label: Label = Label.new()
	summary_label.text = "World Summary:"
	container.add_child(summary_label)
	
	var summary_text: RichTextLabel = RichTextLabel.new()
	summary_text.name = "summary_text"
	summary_text.custom_minimum_size = Vector2(0, 200)
	summary_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_text.bbcode_enabled = true
	container.add_child(summary_text)
	control_references["Export/summary_text"] = summary_text
	
	# Update summary when entering this step
	call_deferred("_update_export_summary")
	
	# Export buttons
	var buttons_container: VBoxContainer = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 5)
	
	var save_config_button: Button = Button.new()
	save_config_button.text = "Save World Config"
	save_config_button.pressed.connect(_on_save_world_config_pressed)
	buttons_container.add_child(save_config_button)
	
	var export_heightmap_button: Button = Button.new()
	export_heightmap_button.text = "Export Heightmap"
	export_heightmap_button.pressed.connect(_on_export_heightmap_pressed)
	buttons_container.add_child(export_heightmap_button)
	
	var export_biome_map_button: Button = Button.new()
	export_biome_map_button.text = "Export Biome Map"
	export_biome_map_button.pressed.connect(_on_export_biome_map_pressed)
	buttons_container.add_child(export_biome_map_button)
	
	var generate_scene_button: Button = Button.new()
	generate_scene_button.text = "Generate Full 3D Scene"
	generate_scene_button.pressed.connect(_on_generate_scene_pressed)
	buttons_container.add_child(generate_scene_button)
	
	container.add_child(buttons_container)


func set_terrain_manager(manager) -> void:  # manager: Terrain3DManager - type hint removed
	"""Set the terrain manager reference."""
	terrain_manager = manager
	
	if terrain_manager != null:
		if terrain_manager.has_method("terrain_generated"):
			terrain_manager.terrain_generated.connect(_on_terrain_generated)
		if terrain_manager.has_method("terrain_updated"):
			terrain_manager.terrain_updated.connect(_on_terrain_updated)
		
		# Connect terrain to preview viewport
		_connect_terrain_to_preview()


func _connect_terrain_to_preview() -> void:
	"""Connect terrain from terrain manager to preview viewport."""
	if terrain_manager == null or preview_world == null:
		return
	
	# For Steps 1-2, we show 2D map only
	# For Steps 3+, terrain will be generated and shown
	# The terrain from Terrain3DManager is in the main scene
	# We'll create a preview instance when terrain is generated
	print("WorldBuilderUI: Terrain manager connected, preview will update when terrain is generated")


func _update_preview_terrain() -> void:
	"""Update preview viewport with terrain when it's generated."""
	if terrain_manager == null or preview_world == null:
		return
	
	# Check if terrain exists in manager
	if terrain_manager.has("terrain") and terrain_manager.terrain != null:
		var terrain_node: Node = terrain_manager.terrain
		preview_terrain = terrain_node
		
		# For now, terrain is in main scene - preview camera will look at it
		# In future, we could duplicate terrain for preview if needed
		# Adjust camera to show terrain properly
		if current_step >= 2:  # Step 3+
			update_camera_for_step(current_step)


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


func _on_process_cities_pressed() -> void:
	"""Process city icons from Step 2 and show civilization selection dialogs."""
	print("WorldBuilderUI: Processing cities from map...")
	
	# Find all city icons from Step 2
	var city_icons: Array = []
	for icon in placed_icons:
		if not icon:
			continue
		var icon_id: String = icon.get("icon_id") if icon.has("icon_id") else ""
		if icon_id == "city":
			city_icons.append(icon)
	
	if city_icons.is_empty():
		print("WorldBuilderUI: No city icons found on map")
		return
	
	# Store city data
	var cities: Array = []
	for icon in city_icons:
		var icon_pos: Vector2 = icon.get("map_position") if icon.has("map_position") else Vector2.ZERO
		cities.append({
			"icon": icon,
			"position": icon_pos,
			"name": "",
			"civilization": ""
		})
	
	step_data["Structures & Civilizations"]["cities"] = cities
	
	# Show civilization selection for first city
	if cities.size() > 0:
		_show_civilization_selection_dialog(0)


func _show_civilization_selection_dialog(city_index: int) -> void:
	"""Show civilization selection dialog for a city."""
	var cities: Array = step_data.get("Structures & Civilizations", {}).get("cities", [])
	if city_index >= cities.size():
		# All cities processed
		_update_city_list()
		return
	
	var city_data: Dictionary = cities[city_index]
	
	# Create dialog
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Select Civilization for City " + str(city_index + 1)
	dialog.size = Vector2(500, 400)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(vbox)
	
	# City name input
	var name_label: Label = Label.new()
	name_label.text = "City Name:"
	vbox.add_child(name_label)
	
	var name_edit: LineEdit = LineEdit.new()
	name_edit.name = "city_name"
	name_edit.placeholder_text = "Enter city name or click Generate"
	name_edit.text = city_data.get("name", "")
	vbox.add_child(name_edit)
	
	# Generate name button
	var generate_name_button: Button = Button.new()
	generate_name_button.text = "Generate Random Name"
	generate_name_button.pressed.connect(func(): _on_generate_city_name(name_edit, city_index))
	vbox.add_child(generate_name_button)
	
	# Civilization selection
	var civ_label: Label = Label.new()
	civ_label.text = "Civilization:"
	vbox.add_child(civ_label)
	
	var civ_list: ItemList = ItemList.new()
	civ_list.custom_minimum_size = Vector2(0, 200)
	var civilizations: Array = civilizations_data.get("civilizations", [])
	for civ: Dictionary in civilizations:
		civ_list.add_item(civ.get("name", "Unknown"))
	civ_list.item_selected.connect(func(idx): _on_civilization_selected(idx, city_index, dialog, name_edit))
	vbox.add_child(civ_list)
	
	add_child(dialog)
	dialog.popup_centered()


func _on_generate_city_name(name_edit: LineEdit, city_index: int) -> void:
	"""Generate a random city name."""
	var name_prefixes: Array = ["North", "South", "East", "West", "New", "Old", "Great", "Little"]
	var name_suffixes: Array = ["port", "haven", "burg", "ton", "ford", "bridge", "hill", "vale"]
	
	var prefix: String = name_prefixes[randi() % name_prefixes.size()]
	var suffix: String = name_suffixes[randi() % name_suffixes.size()]
	var generated_name: String = prefix + suffix.capitalize()
	
	name_edit.text = generated_name
	var cities: Array = step_data.get("Structures & Civilizations", {}).get("cities", [])
	if city_index < cities.size():
		cities[city_index]["name"] = generated_name


func _on_civilization_selected(index: int, city_index: int, dialog: AcceptDialog, name_edit: LineEdit) -> void:
	"""Handle civilization selection for a city."""
	var civilizations: Array = civilizations_data.get("civilizations", [])
	if index >= 0 and index < civilizations.size():
		var civ_data: Dictionary = civilizations[index]
		var cities: Array = step_data.get("Structures & Civilizations", {}).get("cities", [])
		if city_index < cities.size():
			cities[city_index]["civilization"] = civ_data.get("id", "")
			cities[city_index]["name"] = name_edit.text if not name_edit.text.is_empty() else "City " + str(city_index + 1)
			print("WorldBuilderUI: City ", city_index + 1, " assigned to ", civ_data.get("name", "Unknown"))
	
	dialog.queue_free()
	
	# Process next city
	_show_civilization_selection_dialog(city_index + 1)


func _on_city_selected(index: int) -> void:
	"""Handle city selection from list."""
	var cities: Array = step_data.get("Structures & Civilizations", {}).get("cities", [])
	if index >= 0 and index < cities.size():
		var city_data: Dictionary = cities[index]
		print("WorldBuilderUI: Selected city: ", city_data.get("name", "Unknown"))


func _update_city_list() -> void:
	"""Update the city list display."""
	var city_list: ItemList = control_references.get("Structures & Civilizations/city_list") as ItemList
	if city_list == null:
		return
	
	city_list.clear()
	var cities: Array = step_data.get("Structures & Civilizations", {}).get("cities", [])
	for city_data: Dictionary in cities:
		var city_name: String = city_data.get("name", "Unnamed City")
		var civ_id: String = city_data.get("civilization", "")
		if not civ_id.is_empty():
			# Find civilization name
			var civilizations: Array = civilizations_data.get("civilizations", [])
			for civ: Dictionary in civilizations:
				if civ.get("id", "") == civ_id:
					city_name += " (" + civ.get("name", "") + ")"
					break
		city_list.add_item(city_name)


func _on_environment_param_changed(param_name: String, value: Variant) -> void:
	"""Handle environment parameter changes with live updates."""
	step_data["Environment"][param_name] = value
	
	# Update value labels
	match param_name:
		"fog_density":
			var label: Label = control_references.get("Environment/fog_density_value") as Label
			if label != null:
				label.text = "%.2f" % value
		"ambient_intensity":
			var label: Label = control_references.get("Environment/ambient_intensity_value") as Label
			if label != null:
				label.text = "%.2f" % value
		"water_level":
			var label: Label = control_references.get("Environment/water_level_value") as Label
			if label != null:
				label.text = "%.1f" % value
	
	# Live environment update
	call_deferred("_update_environment_live")


func _update_environment_live() -> void:
	"""Update environment effects in real-time."""
	if terrain_manager == null:
		return
	
	# Only update if we're on the environment step
	if current_step != 6:
		return
	
	var env_params: Dictionary = step_data.get("Environment", {})
	if env_params.is_empty():
		return
	
	# Get parameters
	var fog_density: float = env_params.get("fog_density", 0.1)
	var ambient_intensity: float = env_params.get("ambient_intensity", 0.3)
	var ambient_color: Color = env_params.get("ambient_color", Color(0.3, 0.3, 0.3, 1.0))
	
	# Get time of day from climate step
	var time_of_day: float = step_data.get("Climate", {}).get("time_of_day", 12.0)
	
	# Update environment if terrain manager supports it
	if terrain_manager.has_method("update_environment"):
		terrain_manager.update_environment(time_of_day, fog_density, 1.0, "clear", Color(0.5, 0.7, 1.0, 1.0), ambient_color * ambient_intensity)


func _update_export_summary() -> void:
	"""Update export summary panel with world data."""
	var summary_text: RichTextLabel = control_references.get("Export/summary_text") as RichTextLabel
	if summary_text == null:
		return
	
	var summary: String = "[b]World Summary[/b]\n\n"
	summary += "Seed: " + str(step_data.get("Seed & Size", {}).get("seed", 12345)) + "\n"
	summary += "Size: " + str(step_data.get("Seed & Size", {}).get("width", 1000)) + "x" + str(step_data.get("Seed & Size", {}).get("height", 1000)) + "\n"
	summary += "Icons Placed: " + str(placed_icons.size()) + "\n"
	summary += "Cities: " + str(step_data.get("Structures & Civilizations", {}).get("cities", []).size()) + "\n"
	summary_text.text = summary


func _on_save_world_config_pressed() -> void:
	"""Save world configuration to .world resource."""
	var world_name: String = step_data.get("Export", {}).get("world_name", "MyWorld")
	var save_path: String = "user://worlds/" + world_name + ".json"
	
	DirAccess.make_dir_recursive_absolute("user://worlds/")
	
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("WorldBuilderUI: Failed to save world config to " + save_path)
		return
	
	var save_data: Dictionary = {
		"world_name": world_name,
		"step_data": step_data.duplicate(true),
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	print("WorldBuilderUI: Saved world config to " + save_path)


func _on_export_heightmap_pressed() -> void:
	"""Export terrain heightmap as 16-bit PNG."""
	if terrain_manager == null or terrain_manager.terrain == null:
		push_warning("WorldBuilderUI: No terrain available for export")
		return
	
	var world_name: String = step_data.get("Export", {}).get("world_name", "MyWorld")
	var export_path: String = "user://exports/" + world_name + "_heightmap.png"
	
	DirAccess.make_dir_recursive_absolute("user://exports/")
	
	# TODO: Implement actual heightmap export from Terrain3D
	print("WorldBuilderUI: Heightmap export to " + export_path + " (not yet implemented)")


func _on_export_biome_map_pressed() -> void:
	"""Export biome map as PNG."""
	var world_name: String = step_data.get("Export", {}).get("world_name", "MyWorld")
	var export_path: String = "user://exports/" + world_name + "_biomes.png"
	
	DirAccess.make_dir_recursive_absolute("user://exports/")
	
	# TODO: Implement biome map export
	print("WorldBuilderUI: Biome map export to " + export_path + " (not yet implemented)")


func _on_generate_scene_pressed() -> void:
	"""Generate full 3D scene in res://worlds/."""
	var world_name: String = step_data.get("Export", {}).get("world_name", "MyWorld")
	var scene_path: String = "res://worlds/" + world_name + ".tscn"
	
	DirAccess.make_dir_recursive_absolute("res://worlds/")
	
	# TODO: Implement scene generation
	print("WorldBuilderUI: Generating 3D scene at " + scene_path + " (not yet implemented)")
