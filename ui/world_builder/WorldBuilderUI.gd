# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: Complete data-driven world building UI with tabs
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## Reference to terrain manager
var terrain_manager: Terrain3DManager = null

## UI configuration loaded from JSON
var ui_config: Dictionary = {}

## Path to UI configuration JSON
const UI_CONFIG_PATH: String = "res://data/config/world_builder_ui.json"

## Reference to TabContainer
@onready var tab_container: TabContainer = $BackgroundPanel/TabContainer

## Store references to dynamically created controls
var control_references: Dictionary = {}

## Current parameter values
var current_params: Dictionary = {}


func _ready() -> void:
	_load_ui_config()
	_apply_theme()
	_ensure_visibility()
	_build_ui_from_config()
	_setup_ui_connections()
	print("WorldBuilderUI: Ready and visible")


func _load_ui_config() -> void:
	"""Load UI configuration from JSON file."""
	var file: FileAccess = FileAccess.open(UI_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("WorldBuilderUI: Failed to load UI config from " + UI_CONFIG_PATH)
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("WorldBuilderUI: Failed to parse UI config JSON: " + json.get_error_message())
		return
	
	ui_config = json.data
	if not ui_config.has("tabs"):
		push_error("WorldBuilderUI: UI config missing 'tabs' key")
		return


func _apply_theme() -> void:
	"""Apply bg3_theme to this UI."""
	var theme: Theme = load("res://themes/bg3_theme.tres")
	if theme != null:
		self.theme = theme
		if tab_container != null:
			tab_container.theme = theme


func _ensure_visibility() -> void:
	"""Ensure UI elements are visible with proper styling."""
	# Ensure root Control is visible
	self.visible = true
	self.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Get background panel and ensure it's visible
	var background_panel: Panel = $BackgroundPanel
	if background_panel != null:
		background_panel.visible = true
		# Apply a visible background style
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = Color(0.15, 0.12, 0.1, 0.95)  # Dark brown with high opacity
		style_box.border_width_left = 3
		style_box.border_width_top = 3
		style_box.border_width_right = 3
		style_box.border_width_bottom = 3
		style_box.border_color = Color(0.85, 0.7, 0.4, 1.0)  # Gold border
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_right = 8
		style_box.corner_radius_bottom_left = 8
		background_panel.add_theme_stylebox_override("panel", style_box)
		print("WorldBuilderUI: Background panel styled and visible")


func _build_ui_from_config() -> void:
	"""Build UI elements dynamically from JSON configuration."""
	if not ui_config.has("tabs"):
		return
	
	var tabs: Dictionary = ui_config["tabs"]
	
	for tab_name: String in tabs:
		var tab_index: int = _get_tab_index_by_name(tab_name)
		if tab_index == -1:
			push_warning("WorldBuilderUI: Tab '" + tab_name + "' not found in TabContainer")
			continue
		
		var tab_content: VBoxContainer = tab_container.get_child(tab_index) as VBoxContainer
		if tab_content == null:
			continue
		
		var tab_config: Dictionary = tabs[tab_name]
		if not tab_config.has("elements"):
			continue
		
		var elements: Array = tab_config["elements"]
		for element_config: Dictionary in elements:
			_create_ui_element(tab_content, element_config, tab_name)


func _get_tab_index_by_name(tab_name: String) -> int:
	"""Get tab index by name."""
	if tab_container == null:
		return -1
	
	for i in range(tab_container.get_tab_count()):
		if tab_container.get_tab_title(i) == tab_name:
			return i
	
	return -1


func _create_ui_element(parent: VBoxContainer, config: Dictionary, tab_name: String) -> void:
	"""Create a single UI element from configuration."""
	var element_type: String = config.get("type", "")
	var element_name: String = config.get("name", "")
	var element_label: String = config.get("label", element_name)
	
	if element_name.is_empty():
		push_warning("WorldBuilderUI: Element missing 'name' field")
		return
	
	# Create container for label and control
	var container: HBoxContainer = HBoxContainer.new()
	container.name = element_name + "Container"
	parent.add_child(container)
	
	# Create label
	var label: Label = Label.new()
	label.name = element_name + "Label"
	label.text = element_label + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(150, 0)
	container.add_child(label)
	
	# Create control based on type
	var control: Control = null
	match element_type:
		"Slider":
			control = _create_slider(config, element_name)
		"SpinBox":
			control = _create_spinbox(config, element_name)
		"OptionButton":
			control = _create_option_button(config, element_name)
		"Button":
			control = _create_button(config, element_name)
		"ItemList":
			control = _create_item_list(config, element_name)
		"ColorPicker":
			control = _create_color_picker(config, element_name)
		"LineEdit":
			control = _create_line_edit(config, element_name)
		_:
			push_warning("WorldBuilderUI: Unknown element type: " + element_type)
			return
	
	if control != null:
		control.name = element_name
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(control)
		
		# Store reference with full path
		var full_path: String = tab_name + "/" + element_name
		control_references[full_path] = control
		
		# Store default value
		var default_value: Variant = config.get("default", null)
		if default_value != null:
			current_params[element_name] = default_value
			
			# Set initial value on control
			if control is HSlider:
				control.value = default_value
			elif control is SpinBox:
				control.value = default_value
			elif control is OptionButton:
				control.selected = default_value
			elif control is LineEdit:
				control.text = str(default_value)
			elif control is ColorPickerButton:
				var color_array: Array = default_value
				if color_array.size() >= 4:
					control.color = Color(color_array[0], color_array[1], color_array[2], color_array[3])
		
		# Create value label for sliders
		if control is HSlider:
			var value_label: Label = Label.new()
			value_label.name = element_name + "Value"
			value_label.custom_minimum_size = Vector2(80, 0)
			value_label.size_flags_horizontal = 0
			var format_string: String = config.get("format", "%.2f")
			value_label.text = format_string % default_value
			container.add_child(value_label)
			control_references[tab_name + "/" + element_name + "Value"] = value_label


func _create_slider(config: Dictionary, name: String) -> HSlider:
	"""Create a slider control."""
	var slider: HSlider = HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 100.0)
	slider.step = config.get("step", 0.01)
	slider.value = config.get("default", slider.min_value)
	return slider


func _create_spinbox(config: Dictionary, name: String) -> SpinBox:
	"""Create a spinbox control."""
	var spinbox: SpinBox = SpinBox.new()
	spinbox.min_value = config.get("min", 0)
	spinbox.max_value = config.get("max", 100)
	spinbox.step = config.get("step", 1)
	spinbox.value = config.get("default", spinbox.min_value)
	return spinbox


func _create_option_button(config: Dictionary, name: String) -> OptionButton:
	"""Create an option button control."""
	var option_button: OptionButton = OptionButton.new()
	var options: Array = config.get("options", [])
	for option: String in options:
		option_button.add_item(option)
	option_button.selected = config.get("default", 0)
	return option_button


func _create_button(config: Dictionary, name: String) -> Button:
	"""Create a button control."""
	var button: Button = Button.new()
	button.text = config.get("label", name)
	return button


func _create_item_list(config: Dictionary, name: String) -> ItemList:
	"""Create an item list control."""
	var item_list: ItemList = ItemList.new()
	item_list.custom_minimum_size = Vector2(0, 200)
	var items: Array = config.get("items", [])
	for item: String in items:
		item_list.add_item(item)
	item_list.select(config.get("default_selection", 0))
	return item_list


func _create_color_picker(config: Dictionary, name: String) -> ColorPickerButton:
	"""Create a color picker button control."""
	var color_picker: ColorPickerButton = ColorPickerButton.new()
	var default_color: Array = config.get("default", [0.5, 0.5, 0.5, 1.0])
	if default_color.size() >= 4:
		color_picker.color = Color(default_color[0], default_color[1], default_color[2], default_color[3])
	return color_picker


func _create_line_edit(config: Dictionary, name: String) -> LineEdit:
	"""Create a line edit control."""
	var line_edit: LineEdit = LineEdit.new()
	line_edit.placeholder_text = config.get("placeholder", "")
	line_edit.text = str(config.get("default", ""))
	return line_edit


func _setup_ui_connections() -> void:
	"""Connect all UI element signals to handlers."""
	for full_path: String in control_references:
		var control: Control = control_references[full_path]
		var parts: Array = full_path.split("/")
		var tab_name: String = parts[0]
		var element_name: String = parts[1]
		
		if control is HSlider:
			control.value_changed.connect(func(value): _on_slider_changed(tab_name, element_name, value))
		elif control is SpinBox:
			control.value_changed.connect(func(value): _on_spinbox_changed(tab_name, element_name, value))
		elif control is OptionButton:
			control.item_selected.connect(func(index): _on_option_selected(tab_name, element_name, index))
		elif control is Button:
			var action: String = ui_config.get("tabs", {}).get(tab_name, {}).get("elements", [])
			for element_config: Dictionary in ui_config.get("tabs", {}).get(tab_name, {}).get("elements", []):
				if element_config.get("name") == element_name:
					var button_action: String = element_config.get("action", "")
					control.pressed.connect(func(): _on_button_pressed(tab_name, element_name, button_action))
					break
		elif control is ItemList:
			control.item_selected.connect(func(index): _on_item_selected(tab_name, element_name, index))
		elif control is ColorPickerButton:
			control.color_changed.connect(func(color): _on_color_changed(tab_name, element_name, color))


func _on_slider_changed(tab_name: String, element_name: String, value: float) -> void:
	"""Handle slider value change."""
	current_params[element_name] = value
	
	# Update value label if it exists
	var value_label_path: String = tab_name + "/" + element_name + "Value"
	if control_references.has(value_label_path):
		var value_label: Label = control_references[value_label_path] as Label
		if value_label != null:
			# Get format from config
			var format_string: String = "%.2f"
			for element_config: Dictionary in ui_config.get("tabs", {}).get(tab_name, {}).get("elements", []):
				if element_config.get("name") == element_name:
					format_string = element_config.get("format", "%.2f")
					break
			value_label.text = format_string % value
	
	# Apply real-time updates for terrain tab
	if tab_name == "Terrain" and terrain_manager != null:
		match element_name:
			"height_scale":
				terrain_manager.scale_heights(value / 20.0)  # Normalize to reasonable scale
	
	# Apply real-time updates for environment tab
	if tab_name == "Environment" and terrain_manager != null:
		var time_of_day: float = current_params.get("time_of_day", 12.0)
		var fog_density: float = current_params.get("fog_density", 0.1)
		var wind_strength: float = current_params.get("wind_strength", 1.0)
		var weather_index: int = current_params.get("weather_type", 0)
		var weather_names: Array = ["clear", "rain", "snow", "fog", "storm"]
		var weather: String = weather_names[weather_index] if weather_index < weather_names.size() else "clear"
		var sky_color: Color = current_params.get("sky_color", Color(0.5, 0.7, 1.0, 1.0))
		var ambient_light: Color = current_params.get("ambient_light", Color(0.3, 0.3, 0.3, 1.0))
		
		terrain_manager.update_environment(time_of_day, fog_density, wind_strength, weather, sky_color, ambient_light)


func _on_spinbox_changed(tab_name: String, element_name: String, value: float) -> void:
	"""Handle spinbox value change."""
	current_params[element_name] = int(value)


func _on_option_selected(tab_name: String, element_name: String, index: int) -> void:
	"""Handle option button selection."""
	current_params[element_name] = index


func _on_item_selected(tab_name: String, element_name: String, index: int) -> void:
	"""Handle item list selection."""
	current_params[element_name] = index


func _on_color_changed(tab_name: String, element_name: String, color: Color) -> void:
	"""Handle color picker change."""
	current_params[element_name] = color


func _on_button_pressed(tab_name: String, element_name: String, action: String) -> void:
	"""Handle button press."""
	match action:
		"regenerate":
			_regenerate_terrain()
		"apply_biome":
			_apply_biome_map()
		"place_structure":
			_place_structure()
		"remove_structures":
			_remove_all_structures()
		"save_config":
			_save_world_config()
		"export_heightmap":
			_export_heightmap()
		"reset_all":
			_reset_all()


func _regenerate_terrain() -> void:
	"""Regenerate terrain with current parameters."""
	if terrain_manager == null:
		push_warning("WorldBuilderUI: No terrain manager assigned")
		return
	
	var seed_value: int = current_params.get("seed", 12345)
	var frequency: float = current_params.get("noise_frequency", 0.0005)
	var height_scale: float = current_params.get("height_scale", 20.0)
	
	terrain_manager.generate_from_noise(
		seed_value,
		frequency,
		0.0,
		150.0 * (height_scale / 20.0)
	)


func _apply_biome_map() -> void:
	"""Apply biome map to terrain."""
	if terrain_manager == null:
		push_warning("WorldBuilderUI: No terrain manager assigned")
		return
	
	var biome_index: int = current_params.get("available_biomes", 0)
	var biome_names: Array = ["forest", "desert", "mountain", "plains", "swamp", "tundra", "volcanic", "ocean"]
	var biome_type: String = biome_names[biome_index] if biome_index < biome_names.size() else "forest"
	var blending: float = current_params.get("biome_blending", 0.5)
	var color: Color = current_params.get("biome_color", Color.WHITE)
	
	terrain_manager.apply_biome_map(biome_type, blending, color)


func _place_structure() -> void:
	"""Place selected structure on terrain."""
	if terrain_manager == null:
		push_warning("WorldBuilderUI: No terrain manager assigned")
		return
	
	var structure_index: int = current_params.get("placeable_structures", 0)
	var structure_names: Array = ["tree", "rock", "building", "crystal", "ruin", "shrine"]
	var structure_type: String = structure_names[structure_index] if structure_index < structure_names.size() else "tree"
	var density: float = current_params.get("density", 0.3)
	
	# Place at center of terrain for now (can be enhanced with click-to-place)
	var terrain_center: Vector3 = Vector3(0.0, 0.0, 0.0)
	if terrain_manager.terrain != null:
		terrain_center.y = terrain_manager.get_height_at(terrain_center)
	
	terrain_manager.place_structure(structure_type, terrain_center, 1.0)


func _remove_all_structures() -> void:
	"""Remove all placed structures."""
	if terrain_manager == null:
		push_warning("WorldBuilderUI: No terrain manager assigned")
		return
	
	terrain_manager.remove_all_structures()


func _save_world_config() -> void:
	"""Save current world configuration to JSON."""
	var world_name: String = current_params.get("world_name", "MyWorld")
	var save_path: String = "user://worlds/" + world_name + ".json"
	
	# Create directory if it doesn't exist
	DirAccess.make_dir_recursive_absolute("user://worlds/")
	
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("WorldBuilderUI: Failed to save world config to " + save_path)
		return
	
	var save_data: Dictionary = {
		"world_name": world_name,
		"parameters": current_params.duplicate(),
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	print("WorldBuilderUI: Saved world config to " + save_path)


func _export_heightmap() -> void:
	"""Export terrain heightmap as PNG."""
	if terrain_manager == null or terrain_manager.terrain == null:
		push_warning("WorldBuilderUI: No terrain available for export")
		return
	
	# TODO: Implement heightmap export
	push_warning("WorldBuilderUI: Heightmap export not yet implemented")


func _reset_all() -> void:
	"""Reset all parameters to defaults."""
	# Reload defaults from config
	for tab_name: String in ui_config.get("tabs", {}):
		var elements: Array = ui_config["tabs"][tab_name].get("elements", [])
		for element_config: Dictionary in elements:
			var element_name: String = element_config.get("name", "")
			if element_name.is_empty():
				continue
			
			var default_value: Variant = element_config.get("default", null)
			if default_value != null:
				current_params[element_name] = default_value
				
				var full_path: String = tab_name + "/" + element_name
				if control_references.has(full_path):
					var control: Control = control_references[full_path]
					if control is HSlider:
						control.value = default_value
					elif control is SpinBox:
						control.value = default_value
					elif control is OptionButton:
						control.selected = default_value
					elif control is LineEdit:
						control.text = str(default_value)
					elif control is ColorPickerButton:
						var color_array: Array = default_value
						if color_array.size() >= 4:
							control.color = Color(color_array[0], color_array[1], color_array[2], color_array[3])


func set_terrain_manager(manager: Terrain3DManager) -> void:
	"""Set the terrain manager reference."""
	terrain_manager = manager
	
	if terrain_manager != null:
		terrain_manager.terrain_generated.connect(_on_terrain_generated)
		terrain_manager.terrain_updated.connect(_on_terrain_updated)


func _on_terrain_generated(_terrain: Terrain3D) -> void:
	"""Handle terrain generation complete signal."""
	pass


func _on_terrain_updated() -> void:
	"""Handle terrain update signal."""
	pass
