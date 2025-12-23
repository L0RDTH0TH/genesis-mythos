# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: Azgaar-first single-screen world building UI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## Reference to terrain manager
var terrain_manager = null  # Terrain3DManager - type hint removed to avoid parser error

## Azgaar parameter mapping and archetype presets
var azgaar_mapping: Dictionary = {}
var archetype_presets: Dictionary = {}

## Step data storage (only for Azgaar parameters)
var step_data: Dictionary = {"Azgaar": {}}

## Azgaar UI references
@onready var archetype_option_button: OptionButton = $MainSplit/LeftPanel/LeftVBox/ArchetypeOptionButton
@onready var azgaar_tab_container: TabContainer = $MainSplit/LeftPanel/LeftVBox/AzgaarParamsTabContainer
@onready var generate_azgaar_button: Button = $MainSplit/LeftPanel/LeftVBox/GenerateButton
@onready var azgaar_status_label: Label = $MainSplit/LeftPanel/LeftVBox/StatusLabel
@onready var world_builder_azgaar: Node = $MainSplit/RightPanel/AzgaarContainer
@onready var bake_button: Button = $BottomButtons/BakeButton
@onready var back_button: Button = $BottomButtons/BackButton

## Azgaar parameter controls storage (param_name -> Control)
var azgaar_parameter_controls: Dictionary = {}

## Hardware profiler for adaptive quality
const HardwareProfilerScript = preload("res://core/utils/HardwareProfiler.gd")
var hardware_profiler


func _ready() -> void:
	"""Initialize Azgaar World Builder UI."""
	MythosLogger.verbose("UI/WorldBuilder", "_ready() called")
	
	# Initialize hardware profiler for adaptive quality
	hardware_profiler = HardwareProfilerScript.new()
	var quality_name: String = ["LOW", "MEDIUM", "HIGH"][hardware_profiler.detected_quality]
	MythosLogger.info("UI/WorldBuilder", "Hardware profiler initialized", {
		"quality": quality_name,
		"cpu_count": hardware_profiler.cpu_count,
		"benchmark_ms": hardware_profiler.benchmark_result_ms
	})
	
	# Load Azgaar configs
	_load_azgaar_configs()
	
	# Setup Azgaar UI
	_setup_azgaar_ui()
	
	# Connect buttons
	if bake_button != null:
		bake_button.pressed.connect(_on_bake_to_3d_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_to_menu_pressed)
	
	MythosLogger.info("UI/WorldBuilder", "Azgaar World Builder UI ready")


func _load_azgaar_configs() -> void:
	"""Load Azgaar parameter mapping and archetype presets from JSON configs."""
	var mapping_path: String = "res://data/config/azgaar_parameter_mapping.json"
	var presets_path: String = "res://data/config/archetype_azgaar_presets.json"
	
	MythosLogger.verbose("UI/WorldBuilder", "_load_azgaar_configs() called", {"mapping_path": mapping_path, "presets_path": presets_path})
	
	# Load parameter mapping
	if FileAccess.file_exists(mapping_path):
		var file: FileAccess = FileAccess.open(mapping_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(json_string)
			if parsed is Dictionary:
				azgaar_mapping = parsed.get("parameters", {})
				MythosLogger.info("UI/WorldBuilder", "Loaded Azgaar parameter mapping", {"count": azgaar_mapping.size()})
			else:
				MythosLogger.error("UI/WorldBuilder", "Failed to parse Azgaar parameter mapping JSON")
		else:
			MythosLogger.warn("UI/WorldBuilder", "Failed to open Azgaar parameter mapping file", {"path": mapping_path})
	else:
		MythosLogger.warn("UI/WorldBuilder", "Azgaar parameter mapping file not found", {"path": mapping_path})
	
	# Load archetype presets
	if FileAccess.file_exists(presets_path):
		var file: FileAccess = FileAccess.open(presets_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(json_string)
			if parsed is Dictionary:
				archetype_presets = parsed
				MythosLogger.info("UI/WorldBuilder", "Loaded archetype Azgaar presets", {"count": archetype_presets.size()})
			else:
				MythosLogger.error("UI/WorldBuilder", "Failed to parse archetype Azgaar presets JSON")
		else:
			MythosLogger.warn("UI/WorldBuilder", "Failed to open archetype Azgaar presets file", {"path": presets_path})
	else:
		MythosLogger.warn("UI/WorldBuilder", "Archetype Azgaar presets file not found", {"path": presets_path})
	
	# Initialize step_data for Azgaar
	step_data["Azgaar"] = {}


func _setup_azgaar_ui() -> void:
	"""Setup Azgaar UI: populate archetype dropdown, build parameter UI, connect signals."""
	if archetype_option_button == null or azgaar_tab_container == null:
		MythosLogger.warn("UI/WorldBuilder", "Azgaar UI nodes not found, skipping setup")
		return
	
	if world_builder_azgaar == null:
		MythosLogger.warn("UI/WorldBuilder", "WorldBuilderAzgaar node not found")
		return
	if not world_builder_azgaar.has_method("trigger_generation_with_options"):
		MythosLogger.warn("UI/WorldBuilder", "WorldBuilderAzgaar script methods not available")
		return
	
	# Populate archetype dropdown (sorted alphabetically)
	archetype_option_button.clear()
	var preset_names: Array[String] = []
	for preset_name: String in archetype_presets.keys():
		preset_names.append(preset_name)
	preset_names.sort()
	for preset_name: String in preset_names:
		archetype_option_button.add_item(preset_name)
	
	# Connect archetype selection
	archetype_option_button.item_selected.connect(_on_archetype_selected)
	
	if preset_names.size() > 0:
		archetype_option_button.selected = 0
		# Apply first preset
		call_deferred("_apply_archetype_preset", preset_names[0])
	
	# Build parameter UI from mapping
	_build_azgaar_parameter_ui()
	
	# Connect Generate button
	if generate_azgaar_button != null:
		generate_azgaar_button.pressed.connect(_on_generate_azgaar_pressed)
	
	# Connect WorldBuilderAzgaar signals
	if world_builder_azgaar.has_signal("generation_started"):
		world_builder_azgaar.generation_started.connect(_on_azgaar_generation_started)
	if world_builder_azgaar.has_signal("generation_complete"):
		world_builder_azgaar.generation_complete.connect(_on_azgaar_generation_complete)
	if world_builder_azgaar.has_signal("generation_failed"):
		world_builder_azgaar.generation_failed.connect(_on_azgaar_generation_failed)
	
	MythosLogger.info("UI/WorldBuilder", "Azgaar UI setup complete", {
		"archetypes": archetype_presets.size(),
		"parameters": azgaar_mapping.size()
	})


func _build_azgaar_parameter_ui() -> void:
	"""Build the Azgaar parameter UI from mapping, grouped by category."""
	if azgaar_tab_container == null or azgaar_mapping.is_empty():
		MythosLogger.warn("UI/WorldBuilder", "Cannot build Azgaar UI: tab container or mapping missing")
		return
	
	# Clear existing tabs
	for child: Node in azgaar_tab_container.get_children():
		child.queue_free()
	
	azgaar_parameter_controls.clear()
	
	# Group parameters by category (azgaar_mapping contains "parameters" key)
	var parameters: Dictionary = azgaar_mapping.get("parameters", azgaar_mapping)
	var category_params: Dictionary = {}
	for param_name: String in parameters.keys():
		var param: Dictionary = parameters[param_name]
		var category: String = param.get("category", "Other")
		if not category_params.has(category):
			category_params[category] = []
		category_params[category].append(param_name)
	
	# Create tabs for each category
	var category_order: Array[String] = [
		"Terrain & Heightmap",
		"Climate & Environment",
		"Societies & Politics",
		"Settlements & Scale"
	]
	
	# Add any other categories not in the order
	for category: String in category_params.keys():
		if category not in category_order:
			category_order.append(category)
	
	# Create tab for each category
	for category: String in category_order:
		if not category_params.has(category):
			continue
		
		# Create ScrollContainer + VBoxContainer for the tab
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.name = category.replace(" ", "").replace("&", "")
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
		scroll.add_child(vbox)
		azgaar_tab_container.add_child(scroll)
		azgaar_tab_container.set_tab_title(azgaar_tab_container.get_tab_count() - 1, category)
		
		# Add parameters for this category
		for param_name: String in category_params[category]:
			var param: Dictionary = parameters[param_name]
			
			# Create parameter row
			var param_row: HBoxContainer = HBoxContainer.new()
			param_row.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
			
			# Label
			var label: Label = Label.new()
			label.text = param_name.replace("Input", "").replace("Number", "").replace("Set", "")
			label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
			param_row.add_child(label)
			
			# Create control using helper
			var control: Control = _create_control_for_param(param_name, param)
			if control == null:
				continue
			
			# Add value label for sliders
			if control is HSlider:
				var value_label: Label = Label.new()
				value_label.name = param_name + "_value"
				value_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_NARROW, 0)
				value_label.text = str((control as HSlider).value)
				param_row.add_child(control)
				param_row.add_child(value_label)
				# Update value label when slider changes
				control.value_changed.connect(func(v): value_label.text = str(v))
			else:
				param_row.add_child(control)
			
			azgaar_parameter_controls[param_name] = control
			vbox.add_child(param_row)
			
			# Store initial value in step_data
			var initial_value: Variant = ""
			if control is HSlider:
				initial_value = (control as HSlider).value
			elif control is SpinBox:
				initial_value = (control as SpinBox).value
			elif control is CheckBox:
				initial_value = (control as CheckBox).button_pressed
			elif control is OptionButton:
				var option_button: OptionButton = control as OptionButton
				if option_button.get_item_count() > 0:
					initial_value = option_button.get_item_text(option_button.selected)
			step_data["Azgaar"][param_name] = initial_value
	
	MythosLogger.info("UI/WorldBuilder", "Azgaar parameter UI built", {
		"tabs": azgaar_tab_container.get_tab_count(),
		"controls": azgaar_parameter_controls.size()
	})


func _create_control_for_param(param_name: String, param_data: Dictionary) -> Control:
	"""Create the appropriate control for a parameter based on its ui_type."""
	var ui_type: String = param_data.get("ui_type", "SpinBox")
	
	match ui_type:
		"HSlider":
			return _create_slider(param_data, param_name)
		"SpinBox":
			return _create_spinbox(param_data, param_name)
		"CheckBox":
			return _create_checkbox(param_data, param_name)
		"OptionButton":
			return _create_option_button(param_data, param_name)
		_:
			MythosLogger.warn("UI/WorldBuilder", "Unknown UI type for parameter", {"param": param_name, "ui_type": ui_type})
			return _create_spinbox(param_data, param_name)  # Fallback to SpinBox


func _create_slider(param_data: Dictionary, param_name: String) -> HSlider:
	"""Create an HSlider control for a parameter."""
	var slider: HSlider = HSlider.new()
	slider.name = param_name
	slider.min_value = param_data.get("min", 0.0)
	slider.max_value = param_data.get("max", 100.0)
	slider.step = param_data.get("step", 0.01)
	slider.value = param_data.get("default", slider.min_value)
	slider.custom_minimum_size = Vector2(200, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Store param_name in metadata
	slider.set_meta("param_name", param_name)
	
	# Connect value changed
	slider.value_changed.connect(func(v): _on_param_value_changed(param_name, v))
	
	return slider


func _create_spinbox(param_data: Dictionary, param_name: String) -> SpinBox:
	"""Create a SpinBox control for a parameter."""
	var spinbox: SpinBox = SpinBox.new()
	spinbox.name = param_name
	spinbox.min_value = param_data.get("min", 0.0)
	spinbox.max_value = param_data.get("max", 100.0)
	spinbox.step = param_data.get("step", 1.0) if param_data.has("step") else 1.0
	spinbox.value = param_data.get("default", spinbox.min_value)
	spinbox.custom_minimum_size = Vector2(100, 0)
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Store param_name in metadata
	spinbox.set_meta("param_name", param_name)
	
	# Connect value changed
	spinbox.value_changed.connect(func(v): _on_param_value_changed(param_name, v))
	
	return spinbox


func _create_checkbox(param_data: Dictionary, param_name: String) -> CheckBox:
	"""Create a CheckBox control for a parameter."""
	var checkbox: CheckBox = CheckBox.new()
	checkbox.name = param_name
	checkbox.button_pressed = param_data.get("default", false)
	
	# Store param_name in metadata
	checkbox.set_meta("param_name", param_name)
	
	# Connect toggled
	checkbox.toggled.connect(func(pressed): _on_param_value_changed(param_name, pressed))
	
	return checkbox


func _create_option_button(param_data: Dictionary, param_name: String) -> OptionButton:
	"""Create an OptionButton control for a parameter."""
	var option_button: OptionButton = OptionButton.new()
	option_button.name = param_name
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add options
	var options: Array = param_data.get("options", [])
	if options.is_empty():
		# For templateInput, add common templates from AZGAAR_PARAMETERS.md
		if param_name == "templateInput":
			options = [
				"pangea", "continents", "archipelago", "highIsland", "lowIsland",
				"mediterranean", "peninsula", "isthmus", "atoll", "volcano",
				"shattered", "world", "africa-centric", "arabia", "atlantics",
				"britain", "caribbean", "east-asia", "eurasia", "europe",
				"europe-accented", "europe-and-central-asia", "europe-central",
				"europe-north", "greenland", "hellenica", "iceland", "indian-ocean",
				"mediterranean-sea", "middle-east", "north-america", "us-centric",
				"us-mainland", "world-from-pacific"
			]
		else:
			MythosLogger.warn("UI/WorldBuilder", "OptionButton parameter has no options", {"param": param_name})
			options = ["option1", "option2"]
	
	for option: String in options:
		option_button.add_item(option)
	
	# Set default
	var default_value: String = param_data.get("default", "")
	if default_value != "":
		var default_idx: int = options.find(default_value)
		if default_idx >= 0:
			option_button.selected = default_idx
		else:
			option_button.selected = 0
	
	# Store param_name in metadata
	option_button.set_meta("param_name", param_name)
	
	# Connect item selected - pass the selected text value
	option_button.item_selected.connect(func(idx): _on_param_value_changed(param_name, option_button.get_item_text(idx)))
	
	return option_button


func _apply_archetype_preset(preset_name: String) -> void:
	"""Apply an archetype preset to all parameter controls."""
	if not archetype_presets.has(preset_name):
		MythosLogger.warn("UI/WorldBuilder", "Archetype preset not found", {"preset": preset_name})
		return
	
	var preset: Dictionary = archetype_presets[preset_name]
	MythosLogger.info("UI/WorldBuilder", "Applying archetype preset", {"preset": preset_name})
	
	# Apply each parameter value from preset
	for param_name: String in preset.keys():
		var value: Variant = preset[param_name]
		
		# Clamp value based on hardware
		value = _clamp_parameter(param_name, value)
		
		# Set control value
		if azgaar_parameter_controls.has(param_name):
			var control: Control = azgaar_parameter_controls[param_name]
			if control is HSlider:
				(control as HSlider).value = value
			elif control is SpinBox:
				(control as SpinBox).value = value
			elif control is CheckBox:
				(control as CheckBox).button_pressed = value
			elif control is OptionButton:
				var option_button: OptionButton = control as OptionButton
				var value_str: String = str(value)
				var idx: int = -1
				for i in range(option_button.get_item_count()):
					if option_button.get_item_text(i) == value_str:
						idx = i
						break
				if idx >= 0:
					option_button.selected = idx
				else:
					MythosLogger.warn("UI/WorldBuilder", "Option value not found in options", {
						"param": param_name,
						"value": value_str
					})
		
		# Store in step_data
		step_data["Azgaar"][param_name] = value


func _clamp_parameter(param_name: String, value: Variant) -> Variant:
	"""Clamp parameter value based on hardware capabilities."""
	if param_name != "pointsInput":
		return value
	
	# Get parameters from mapping (handle both direct dict and nested "parameters" key)
	var parameters: Dictionary = azgaar_mapping.get("parameters", azgaar_mapping)
	var param: Dictionary = parameters.get(param_name, {})
	if param.get("performance_impact", "") != "high":
		return value
	
	# Get hardware quality level
	var quality_level: int = hardware_profiler.detected_quality
	var max_points: int = 13  # Default max
	
	match quality_level:
		HardwareProfiler.QualityLevel.LOW:
			max_points = 3
		HardwareProfiler.QualityLevel.MEDIUM:
			max_points = 6
		HardwareProfiler.QualityLevel.HIGH:
			max_points = 13
	
	var int_value: int = int(value)
	if int_value > max_points:
		# Show ConfirmationDialog warning
		var quality_name: String = ["LOW", "MEDIUM", "HIGH"][quality_level]
		MythosLogger.warn("UI/WorldBuilder", "Clamped pointsInput for hardware", {
			"requested": int_value,
			"clamped": max_points,
			"quality": quality_name
		})
		
		var dialog: ConfirmationDialog = ConfirmationDialog.new()
		dialog.dialog_text = "Parameter clamped for performance on your hardware.\n\npointsInput was reduced from %d to %d for %s hardware quality." % [int_value, max_points, quality_name]
		dialog.title = "Parameter Clamped"
		add_child(dialog)
		dialog.popup_centered()
		dialog.confirmed.connect(func(): dialog.queue_free())
		dialog.canceled.connect(func(): dialog.queue_free())
		
		return max_points
	
	return int_value


func _on_param_value_changed(param_name: String, value: Variant) -> void:
	"""Handle parameter value change."""
	# Clamp if needed
	var original_value: Variant = value
	value = _clamp_parameter(param_name, value)
	
	# Store in step_data
	step_data["Azgaar"][param_name] = value
	
	MythosLogger.debug("UI/WorldBuilder", "Azgaar parameter changed", {"param": param_name, "value": value})


func _on_archetype_selected(idx: int) -> void:
	"""Handle archetype preset selection."""
	if idx < 0 or idx >= archetype_option_button.get_item_count():
		return
	
	var preset_name: String = archetype_option_button.get_item_text(idx)
	_apply_archetype_preset(preset_name)


func _on_generate_azgaar_pressed() -> void:
	"""Handle Generate with Azgaar button press."""
	if world_builder_azgaar == null:
		MythosLogger.error("UI/WorldBuilder", "WorldBuilderAzgaar node not available")
		return
	
	# Collect current options from controls
	var options: Dictionary = {}
	for param_name: String in azgaar_parameter_controls.keys():
		var control: Control = azgaar_parameter_controls[param_name]
		var value: Variant = null
		if control is HSlider:
			value = (control as HSlider).value
		elif control is SpinBox:
			value = (control as SpinBox).value
		elif control is CheckBox:
			value = (control as CheckBox).button_pressed
		elif control is OptionButton:
			var option_button: OptionButton = control as OptionButton
			value = option_button.get_item_text(option_button.selected)
		
		if value != null:
			options[param_name] = value
	
	# Include seed (use default if not set)
	var seed_value: int = step_data.get("Azgaar", {}).get("optionsSeed", 12345)
	options["optionsSeed"] = seed_value
	
	MythosLogger.info("UI/WorldBuilder", "Triggering Azgaar generation", {"options_count": options.size()})
	
	# Disable button and change text
	if generate_azgaar_button != null:
		generate_azgaar_button.disabled = true
		generate_azgaar_button.text = "Generating..."
	if azgaar_status_label != null:
		azgaar_status_label.text = "Generating world..."
	
	# Trigger generation with auto_generate=true
	world_builder_azgaar.trigger_generation_with_options(options, true)


func _on_azgaar_generation_started() -> void:
	"""Handle Azgaar generation started signal."""
	MythosLogger.info("UI/WorldBuilder", "Azgaar generation started")
	if azgaar_status_label != null:
		azgaar_status_label.text = "Generating world..."


func _on_azgaar_generation_complete() -> void:
	"""Handle Azgaar generation complete signal."""
	MythosLogger.info("UI/WorldBuilder", "Azgaar generation complete")
	if generate_azgaar_button != null:
		generate_azgaar_button.disabled = false
		generate_azgaar_button.text = "Generate with Azgaar"
	if azgaar_status_label != null:
		azgaar_status_label.text = "Generation complete!"


func _on_azgaar_generation_failed(reason: String) -> void:
	"""Handle Azgaar generation failed signal."""
	MythosLogger.error("UI/WorldBuilder", "Azgaar generation failed", {"reason": reason})
	if generate_azgaar_button != null:
		generate_azgaar_button.disabled = false
		generate_azgaar_button.text = "Generate with Azgaar"
	if azgaar_status_label != null:
		azgaar_status_label.text = "Generation failed: " + reason
	
	# Show error dialog
	_show_error_dialog("Azgaar Generation Failed", reason)


func _show_error_dialog(title: String, message: String) -> void:
	"""Show an error dialog to the user."""
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())


func _on_bake_to_3d_pressed() -> void:
	"""Bake generated map to Terrain3D."""
	# TODO: Extract heightmap from Azgaar WebView when that functionality is implemented
	# For now, show a message that this feature requires heightmap extraction
	MythosLogger.info("UI/WorldBuilder", "Bake to 3D pressed - heightmap extraction from Azgaar not yet implemented")
	
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Bake to 3D"
	dialog.dialog_text = "Heightmap extraction from Azgaar is not yet implemented.\n\nThis feature will extract the generated heightmap from Azgaar and convert it to Terrain3D."
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())


func _on_back_to_menu_pressed() -> void:
	"""Return to main menu."""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
