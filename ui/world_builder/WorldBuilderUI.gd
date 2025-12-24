# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: Wizard-style UI for Azgaar-based world generation with 8 steps
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderUI
extends Control

## Reference to terrain manager (optional, for future 3D baking)
var terrain_manager: Node = null

# Wizard flow
var current_step: int = 0
const TOTAL_STEPS: int = 8

# UI References
@onready var step_buttons: Array[Button] = []
@onready var archetype_option: OptionButton = $MainHSplit/RightPanel/RightVBox/GlobalControls/ArchetypeOption
@onready var seed_spin: SpinBox = $MainHSplit/RightPanel/RightVBox/GlobalControls/SeedHBox/SeedSpin
@onready var randomize_btn: Button = $MainHSplit/RightPanel/RightVBox/GlobalControls/SeedHBox/RandomizeBtn
@onready var step_title: Label = $MainHSplit/RightPanel/RightVBox/StepTitle
@onready var active_params: VBoxContainer = $MainHSplit/RightPanel/RightVBox/ActiveParams
@onready var back_btn: Button = $MainHSplit/CenterPanel/BottomHBox/BottomContent/BackBtn
@onready var next_btn: Button = $MainHSplit/CenterPanel/BottomHBox/BottomContent/NextBtn
@onready var gen_btn: Button = $MainHSplit/CenterPanel/BottomHBox/BottomContent/GenBtn
@onready var bake_to_3d_btn: Button = $MainHSplit/CenterPanel/BottomHBox/BottomContent/BakeTo3DBtn
@onready var progress_bar: ProgressBar = $MainHSplit/CenterPanel/BottomHBox/BottomContent/ProgressBar
@onready var status_label: Label = $MainHSplit/CenterPanel/BottomHBox/BottomContent/StatusLabel
@onready var azgaar_webview: Node = $MainHSplit/CenterPanel/CenterContent/AzgaarWebView
@onready var world_builder_azgaar: Node = $MainHSplit/CenterPanel/CenterContent  # WorldBuilderAzgaar script
@onready var overlay_placeholder: TextureRect = $MainHSplit/CenterPanel/CenterContent/OverlayPlaceholder

var current_params: Dictionary = {}
var gen_timer: float = 0.0
var gen_elapsed_time: float = 0.0

# Archetype presets
const ARCHETYPES: Dictionary = {
	"High Fantasy": {"points": 800000, "heightExponent": 1.2, "allowErosion": true, "plateCount": 8, "burgs": 500, "precip": 0.6},
	"Low Fantasy": {"points": 600000, "heightExponent": 0.8, "allowErosion": true, "plateCount": 5, "burgs": 200, "precip": 0.5},
	"Dark Fantasy": {"points": 400000, "heightExponent": 1.5, "allowErosion": false, "plateCount": 12, "burgs": 100, "precip": 0.8},
	"Realistic": {"points": 1000000, "heightExponent": 1.0, "allowErosion": true, "plateCount": 7, "burgs": 800},
	"Custom": {}
}

# Step definitions loaded from JSON
var STEP_DEFINITIONS: Dictionary = {}
const STEP_PARAMETERS_PATH: String = "res://data/config/azgaar_step_parameters.json"


func _ready() -> void:
	"""Initialize the World Builder UI."""
	DirAccess.make_dir_recursive_absolute("user://azgaar/")
	DirAccess.make_dir_recursive_absolute(UIConstants.DOWNLOADS_DIR)
	
	# Load step definitions from JSON
	_load_step_definitions()
	
	# Apply UIConstants to UI elements
	_apply_ui_constants()
	
	# Populate archetype option button
	for archetype_name in ARCHETYPES.keys():
		archetype_option.add_item(archetype_name)
	
	# Collect step buttons and connect signals
	var step_sidebar: VBoxContainer = $MainHSplit/LeftPanel/LeftContent/StepSidebar
	for i in range(TOTAL_STEPS):
		var btn: Button = step_sidebar.get_child(i) as Button
		if btn:
			step_buttons.append(btn)
			btn.pressed.connect(func(): _on_step_button_pressed(i))
	
	# Connect signals
	archetype_option.item_selected.connect(_load_archetype_params)
	seed_spin.value_changed.connect(_on_seed_changed)
	randomize_btn.pressed.connect(_randomize_seed)
	back_btn.pressed.connect(_on_back_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	gen_btn.pressed.connect(_generate_azgaar)
	bake_to_3d_btn.pressed.connect(_bake_to_3d)
	
	# Initialize with first step
	_load_archetype_params(0)
	_update_step_ui()
	
	# Initialize Azgaar with default map
	_initialize_azgaar_default()
	
	set_process(false)


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements for responsive sizing."""
	# Left panel
	var left_panel: VBoxContainer = $MainHSplit/LeftPanel
	left_panel.custom_minimum_size = Vector2(UIConstants.LEFT_PANEL_WIDTH, 0)
	
	# Step buttons
	var step_sidebar: VBoxContainer = $MainHSplit/LeftPanel/LeftContent/StepSidebar
	for btn in step_sidebar.get_children():
		if btn is Button:
			btn.custom_minimum_size = Vector2(0, UIConstants.STEP_BUTTON_HEIGHT)
	
	# Right panel
	var right_panel: ScrollContainer = $MainHSplit/RightPanel
	right_panel.custom_minimum_size = Vector2(UIConstants.RIGHT_PANEL_WIDTH, 0)
	
	# Bottom bar
	var bottom_hbox: HBoxContainer = $MainHSplit/CenterPanel/BottomHBox
	bottom_hbox.custom_minimum_size = Vector2(0, UIConstants.BOTTOM_BAR_HEIGHT)
	bottom_hbox.offset_top = -UIConstants.BOTTOM_BAR_HEIGHT
	
	# Buttons
	back_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_SMALL, 0)
	next_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_SMALL, 0)
	gen_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_LARGE, 0)
	bake_to_3d_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_MEDIUM, 0)
	
	# Seed controls
	seed_spin.custom_minimum_size = Vector2(UIConstants.SEED_SPIN_WIDTH, 0)
	randomize_btn.custom_minimum_size = UIConstants.RANDOMIZE_BTN_SIZE
	
	# Progress bar and status
	progress_bar.custom_minimum_size = Vector2(UIConstants.PROGRESS_BAR_WIDTH, 0)
	status_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
	
	# Set initial split offset
	var main_hsplit: HSplitContainer = $MainHSplit
	main_hsplit.split_offset = UIConstants.LEFT_PANEL_WIDTH


func _notification(what: int) -> void:
	"""Handle window resize for responsive layout."""
	if what == NOTIFICATION_RESIZED:
		_update_responsive_layout()


func _update_responsive_layout() -> void:
	"""Update layout based on viewport size."""
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	
	# Calculate panel widths as percentages, clamped to min/max
	var left_panel: VBoxContainer = $MainHSplit/LeftPanel
	var right_panel: ScrollContainer = $MainHSplit/RightPanel
	var main_hsplit: HSplitContainer = $MainHSplit
	
	# Left panel: 15-20% of width, clamped
	var left_width_percent: float = 0.175  # 17.5% default
	var left_width: int = int(viewport_size.x * left_width_percent)
	left_width = clamp(left_width, UIConstants.LEFT_PANEL_WIDTH_MIN, UIConstants.LEFT_PANEL_WIDTH_MAX)
	left_panel.custom_minimum_size = Vector2(left_width, 0)
	
	# Right panel: 20-25% of width, clamped
	var right_width_percent: float = 0.225  # 22.5% default
	var right_width: int = int(viewport_size.x * right_width_percent)
	right_width = clamp(right_width, UIConstants.RIGHT_PANEL_WIDTH_MIN, UIConstants.RIGHT_PANEL_WIDTH_MAX)
	right_panel.custom_minimum_size = Vector2(right_width, 0)
	
	# Update split offset to match left panel width
	main_hsplit.split_offset = left_width
	
	MythosLogger.debug("UI/WorldBuilder", "Layout updated for resize", {
		"viewport": viewport_size,
		"left_width": left_width,
		"right_width": right_width
	})


func _load_step_definitions() -> void:
	"""Load step definitions from JSON file."""
	var file: FileAccess = FileAccess.open(STEP_PARAMETERS_PATH, FileAccess.READ)
	if not file:
		MythosLogger.error("UI/WorldBuilder", "Failed to load step parameters", {"path": STEP_PARAMETERS_PATH})
		# Fallback to empty definitions
		for i in range(TOTAL_STEPS):
			STEP_DEFINITIONS[i] = {"title": "Step %d" % (i + 1), "params": []}
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.error("UI/WorldBuilder", "Failed to parse step parameters JSON", {"error": parse_result})
		# Fallback to empty definitions
		for i in range(TOTAL_STEPS):
			STEP_DEFINITIONS[i] = {"title": "Step %d" % (i + 1), "params": []}
		return
	
	var data: Dictionary = json.data
	if not data.has("steps") or not data.steps is Array:
		MythosLogger.error("UI/WorldBuilder", "Invalid step parameters JSON structure")
		return
	
	# Convert JSON array to dictionary indexed by step index
	for step_data in data.steps:
		if not step_data is Dictionary or not step_data.has("index"):
			continue
		var step_idx: int = step_data.index
		var params_list: Array = []
		
		# Convert parameter definitions to format expected by _populate_params()
		if step_data.has("parameters") and step_data.parameters is Array:
			for param_data in step_data.parameters:
				if not param_data is Dictionary:
					continue
				var param: Dictionary = {}
				param.name = param_data.get("name", "")
				param.type = param_data.get("ui_type", "HSlider")
				param.azgaar_key = param_data.get("azgaar_key", param.name)
				
				# Copy type-specific properties
				if param_data.has("options"):
					param.options = param_data.options
				if param_data.has("min"):
					param.min = param_data.min
				if param_data.has("max"):
					param.max = param_data.max
				if param_data.has("step"):
					param.step = param_data.step
				if param_data.has("default"):
					param.default = param_data.default
				
				params_list.append(param)
		
		STEP_DEFINITIONS[step_idx] = {
			"title": step_data.get("title", "Step %d" % (step_idx + 1)),
			"params": params_list
		}
	
	MythosLogger.info("UI/WorldBuilder", "Loaded step definitions", {"count": STEP_DEFINITIONS.size()})


func _initialize_azgaar_default() -> void:
	"""Load default Azgaar map on startup."""
	# Azgaar is initialized by WorldBuilderAzgaar._initialize_webview()
	# This method is kept for compatibility but may not be needed
	MythosLogger.debug("UI/WorldBuilder", "Azgaar initialization handled by WorldBuilderAzgaar")

func _on_azgaar_generation_complete() -> void:
	"""Handle Azgaar generation completion signal."""
	_update_status("Generation complete!", 80)
	set_process(false)
	
	# Wait a moment for final rendering
	await get_tree().create_timer(1.0).timeout
	_update_status("Ready for export", 100)
	
	# Navigate to bake step
	current_step = 7
	_update_step_ui()

func _on_azgaar_generation_failed(reason: String) -> void:
	"""Handle Azgaar generation failure signal."""
	_update_status("Generation failed: %s" % reason, 0)
	set_process(false)
	MythosLogger.error("UI/WorldBuilder", "Azgaar generation failed", {"reason": reason})


func _update_step_ui() -> void:
	"""Update UI for current step."""
	# Update step button highlights
	for i in range(step_buttons.size()):
		var btn: Button = step_buttons[i]
		if i == current_step:
			# Active step - orange highlight
			btn.modulate = Color(1.0, 0.7, 0.3, 1.0)  # Orange tint
			btn.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.4, 1.0))
		else:
			# Inactive step - dim
			btn.modulate = Color(0.6, 0.6, 0.6, 1.0)  # Dimmed
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_hover_color")
	
	var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
	step_title.text = step_def.get("title", "Step %d" % (current_step + 1))
	
	# Update navigation buttons
	back_btn.disabled = (current_step == 0)
	next_btn.disabled = (current_step == TOTAL_STEPS - 1)
	
	# Show/hide buttons based on step
	if current_step == 6:  # Export step
		gen_btn.visible = true
		next_btn.visible = false
		bake_to_3d_btn.visible = false
		bake_to_3d_btn.disabled = true
	elif current_step == 7:  # Bake step
		gen_btn.visible = false
		next_btn.visible = false
		bake_to_3d_btn.visible = true
		bake_to_3d_btn.disabled = false
	else:
		gen_btn.visible = false
		next_btn.visible = true
		bake_to_3d_btn.visible = false
		bake_to_3d_btn.disabled = true
	
	# Populate parameters for current step
	_populate_params()


func _populate_params() -> void:
	"""Populate parameter controls for current step."""
	# Clear existing params
	for child in active_params.get_children():
		child.queue_free()
	
	var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
	var params_list: Array = step_def.get("params", [])
	
	if params_list.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No parameters for this step"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		active_params.add_child(empty_label)
		return
	
		for param in params_list:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
		
		var param_name: String = param.get("name", "")
		var azgaar_key: String = param.get("azgaar_key", param_name)
		var param_type: String = param.get("type", "HSlider")
		
		var label: Label = Label.new()
		label.text = param_name.capitalize() + ":"
		label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
		row.add_child(label)
		
		var control: Control
		match param_type:
			"OptionButton":
				control = OptionButton.new()
				if param.has("options"):
					for opt in param.options:
						control.add_item(opt)
					var default_val = param.get("default", "")
					var default_idx: int = param.options.find(default_val)
					if default_idx >= 0:
						control.selected = default_idx
				control.item_selected.connect(func(idx: int): 
					current_params[azgaar_key] = control.get_item_text(idx)
				)
			"HSlider":
				control = HSlider.new()
				if param.has("min"):
					control.min_value = param.min
				if param.has("max"):
					control.max_value = param.max
				if param.has("step"):
					control.step = param.step
				control.value = current_params.get(azgaar_key, param.get("default", 0.0))
				control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				
				var value_label: Label = Label.new()
				value_label.text = str(control.value)
				value_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_NARROW, 0)
				control.value_changed.connect(func(val: float): 
					value_label.text = str(val)
					current_params[azgaar_key] = val
				)
				row.add_child(control)
				row.add_child(value_label)
				active_params.add_child(row)
				continue
			"CheckBox":
				control = CheckBox.new()
				control.button_pressed = current_params.get(azgaar_key, param.get("default", false))
				control.toggled.connect(func(on: bool): current_params[azgaar_key] = on)
			"SpinBox":
				control = SpinBox.new()
				if param.has("min"):
					control.min_value = param.min
				if param.has("max"):
					control.max_value = param.max
				if param.has("step"):
					control.step = param.step
				control.value = current_params.get(azgaar_key, param.get("default", 0))
				control.value_changed.connect(func(val: float): current_params[azgaar_key] = int(val))
		
		control.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_WIDE, UIConstants.BUTTON_HEIGHT_SMALL)
		control.tooltip_text = "Controls " + param_name
		row.add_child(control)
		active_params.add_child(row)


func _on_step_button_pressed(step_idx: int) -> void:
	"""Handle step button press."""
	current_step = step_idx
	_update_step_ui()


func _on_back_pressed() -> void:
	"""Navigate to previous step."""
	if current_step > 0:
		current_step -= 1
		_update_step_ui()


func _on_next_pressed() -> void:
	"""Navigate to next step."""
	if current_step < TOTAL_STEPS - 1:
		current_step += 1
		_update_step_ui()


func _load_archetype_params(idx: int) -> void:
	"""Load params for selected archetype."""
	var archetype: String = archetype_option.get_item_text(idx)
	current_params = ARCHETYPES[archetype].duplicate()
	for key in current_params:
		if key == "points":
			current_params[key] = UIConstants.get_clamped_points(current_params[key])
	_populate_params()


func _on_seed_changed(value: float) -> void:
	"""Update seed in params."""
	current_params["seed"] = int(value)


func _randomize_seed() -> void:
	"""Randomize seed."""
	seed_spin.value = randi()


func _generate_azgaar() -> void:
	"""Generate world with Azgaar using JS injection."""
	_update_status("Syncing parameters...", 10)
	
	# Get WorldBuilderAzgaar script reference (it's attached to CenterContent)
	var azgaar_controller: Node = world_builder_azgaar
	if not azgaar_controller or not azgaar_controller.has_method("trigger_generation_with_options"):
		_update_status("Error: Azgaar controller not found", 0)
		MythosLogger.error("UI/WorldBuilder", "Cannot find WorldBuilderAzgaar controller on CenterContent")
		return
	
	# Connect to generation signals if not already connected
	if not azgaar_controller.generation_complete.is_connected(_on_azgaar_generation_complete):
		azgaar_controller.generation_complete.connect(_on_azgaar_generation_complete)
	if not azgaar_controller.generation_failed.is_connected(_on_azgaar_generation_failed):
		azgaar_controller.generation_failed.connect(_on_azgaar_generation_failed)
	
	# Trigger generation with current parameters
	_update_status("Injecting parameters...", 20)
	azgaar_controller.trigger_generation_with_options(current_params, true)
	
	_update_status("Generating map...", 40)
	gen_timer = 0.0
	gen_elapsed_time = 0.0
	set_process(true)


func _process(delta: float) -> void:
	"""Process generation status updates (fallback polling if signals don't work)."""
	gen_elapsed_time += delta
	gen_timer += delta
	
	# Check timeout first (increased to 60s to match timeout timer)
	if gen_elapsed_time > 60.0:
		_update_status("Timeout - reduce points?", 0)
		set_process(false)
		return
	
	# Poll every 2 seconds for completion (reduced frequency)
	if gen_timer > 2.0:
		gen_timer = 0.0
		# Update progress based on elapsed time
		var progress = min(40 + (gen_elapsed_time / 60.0 * 40.0), 80.0)
		_update_status("Generating map... (%d%%)" % int(progress), progress)


func _bake_to_3d() -> void:
	"""Bake to 3D - export heightmap from Azgaar and feed to Terrain3D."""
	_update_status("Exporting heightmap from Azgaar...", 10)
	
	# Get WorldBuilderAzgaar script reference
	var azgaar_controller: Node = world_builder_azgaar
	if not azgaar_controller or not azgaar_controller.has_method("export_heightmap"):
		_update_status("Error: Azgaar controller not found", 0)
		MythosLogger.error("UI/WorldBuilder", "Cannot find WorldBuilderAzgaar controller")
		return
	
	# Export heightmap
	var heightmap_image: Image = azgaar_controller.export_heightmap()
	if not heightmap_image:
		_update_status("Failed to export heightmap", 0)
		MythosLogger.error("UI/WorldBuilder", "Heightmap export failed")
		return
	
	_update_status("Heightmap exported, initializing Terrain3D...", 30)
	
	# Feed to terrain manager if available
	if terrain_manager != null:
		# Ensure terrain is created and configured
		if terrain_manager.has_method("create_terrain"):
			terrain_manager.create_terrain()
		_update_status("Configuring terrain...", 50)
		if terrain_manager.has_method("configure_terrain"):
			terrain_manager.configure_terrain()
		
		_update_status("Baking heightmap to 3D...", 70)
		# Use Terrain3DManager.generate_from_heightmap()
		if terrain_manager.has_method("generate_from_heightmap"):
			# Default height range: -50 to 300 (meters)
			terrain_manager.generate_from_heightmap(heightmap_image, -50.0, 300.0, Vector3.ZERO)
			_update_status("Baked successfully!", 100)
			MythosLogger.info("UI/WorldBuilder", "Terrain3D baked from Azgaar heightmap", {
				"size": heightmap_image.get_size(),
				"height_range": [-50.0, 300.0]
			})
		else:
			_update_status("Terrain manager missing generate_from_heightmap method", 0)
			MythosLogger.error("UI/WorldBuilder", "Terrain3DManager.generate_from_heightmap() not found")
	else:
		_update_status("Terrain manager not available", 0)
		MythosLogger.warn("UI/WorldBuilder", "Cannot bake - terrain manager missing")


func _update_status(text: String, progress: float) -> void:
	"""Update status and progress."""
	status_label.text = text
	if progress >= 0:
		progress_bar.value = progress
		progress_bar.visible = true
	else:
		progress_bar.visible = false


func set_terrain_manager(manager: Node) -> void:
	"""Set the terrain manager reference (called by world_root.gd)."""
	terrain_manager = manager
	var manager_name: String = String(manager.name) if manager != null else "null"
	MythosLogger.debug("UI/WorldBuilder", "Terrain manager set", {"manager": manager_name})
