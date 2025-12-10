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

## Control references
var control_references: Dictionary = {}


func _ready() -> void:
	_load_map_icons()
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
	
	# Create remaining steps (3-9) as placeholders
	for i in range(2, STEPS.size()):
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
	seed_spinbox.value_changed.connect(func(v): step_data["Seed & Size"]["seed"] = int(v))
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


func _create_step_placeholder(parent: VBoxContainer, step_index: int) -> void:
	"""Create placeholder content for steps 3-9."""
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
