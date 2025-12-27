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
@onready var archetype_option: OptionButton = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/ArchetypeOption
@onready var seed_spin: SpinBox = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/SeedHBox/SeedSpin
@onready var randomize_btn: Button = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/SeedHBox/RandomizeBtn
@onready var step_title: Label = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/StepTitle
@onready var param_tree: Tree = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/ParamTree
@onready var bottom_hbox: HBoxContainer = $MainVBox/BottomBar/BottomContent
@onready var back_btn: Button = $MainVBox/BottomBar/BottomContent/BackBtn
@onready var next_btn: Button = $MainVBox/BottomBar/BottomContent/NextBtn
@onready var gen_btn: Button = $MainVBox/BottomBar/BottomContent/GenBtn
@onready var bake_to_3d_btn: Button = $MainVBox/BottomBar/BottomContent/BakeTo3DBtn
@onready var progress_bar: ProgressBar = $MainVBox/BottomBar/BottomContent/ProgressBar
@onready var status_label: Label = $MainVBox/BottomBar/BottomContent/StatusLabel
@onready var left_panel: PanelContainer = $MainVBox/MainHSplit/LeftPanel
@onready var step_sidebar: VBoxContainer = $MainVBox/MainHSplit/LeftPanel/LeftContent/StepSidebar
@onready var center_panel: PanelContainer = $MainVBox/MainHSplit/CenterPanel
@onready var right_panel: PanelContainer = $MainVBox/MainHSplit/RightPanel
@onready var right_scroll: ScrollContainer = $MainVBox/MainHSplit/RightPanel/RightScroll
@onready var right_vbox: VBoxContainer = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox

# GUI Performance Fix: Tree storage for parameter metadata (for value updates)
var param_tree_items: Dictionary = {}  # Maps azgaar_key -> TreeItem
# DIAGNOSTIC: WebView nodes temporarily removed to test presentation throttling
# @onready var webview_margin: MarginContainer = $MainVBox/MainHSplit/CenterPanel/CenterContent/WebViewMargin
# @onready var azgaar_webview: Node = $MainVBox/MainHSplit/CenterPanel/CenterContent/WebViewMargin/AzgaarWebView
var webview_margin: MarginContainer = null
var azgaar_webview: Node = null
@onready var world_builder_azgaar: Node = $MainVBox/MainHSplit/CenterPanel/CenterContent  # WorldBuilderAzgaar script
@onready var overlay_placeholder: TextureRect = $MainVBox/MainHSplit/CenterPanel/CenterContent/OverlayPlaceholder

var current_params: Dictionary = {}
var gen_timer: float = 0.0
var gen_elapsed_time: float = 0.0

# GUI Performance Fix: Throttle resize updates
var _resize_pending: bool = false

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
	
	# GUI Performance Fix: Setup Tree for parameters
	_setup_param_tree()
	
	# Initialize with first step
	_load_archetype_params(0)
	_update_step_ui()
	
	# Initialize Azgaar with default map
	_initialize_azgaar_default()
	
	# Apply responsive layout on initial load
	call_deferred("_update_responsive_layout")
	
	# GUI Performance Fix: _process() is conditionally enabled only during generation
	# (see _generate_azgaar() and generation complete/failed handlers)
	set_process(false)


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements for responsive sizing."""
	# Left panel
	left_panel.custom_minimum_size = Vector2(UIConstants.LEFT_PANEL_WIDTH, 0)
	
	# Step buttons
	for btn in step_sidebar.get_children():
		if btn is Button:
			btn.custom_minimum_size = Vector2(0, UIConstants.STEP_BUTTON_HEIGHT)
	
	# Right panel
	right_panel.custom_minimum_size = Vector2(UIConstants.RIGHT_PANEL_WIDTH, 0)
	
	# Bottom bar (now in MainVBox)
	var bottom_bar: PanelContainer = $MainVBox/BottomBar
	bottom_bar.custom_minimum_size = Vector2(0, UIConstants.BOTTOM_BAR_HEIGHT)
	
	# WebView margin for bottom bar space (reserve space for bottom overlay bar)
	if webview_margin:
		webview_margin.add_theme_constant_override("margin_bottom", UIConstants.BOTTOM_BAR_HEIGHT)
	
	# Buttons
	back_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_SMALL, 0)
	next_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_SMALL, 0)
	gen_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_LARGE, 0)
	bake_to_3d_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_MEDIUM, 0)
	
	# Seed controls (now in RightVBox, always visible)
	seed_spin.custom_minimum_size = Vector2(UIConstants.SEED_SPIN_WIDTH, 0)
	randomize_btn.custom_minimum_size = UIConstants.RANDOMIZE_BTN_SIZE
	
	# Archetype control sizing
	archetype_option.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_WIDE, UIConstants.BUTTON_HEIGHT_SMALL)
	
	# Progress bar and status
	progress_bar.custom_minimum_size = Vector2(UIConstants.PROGRESS_BAR_WIDTH, 0)
	status_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
	
	# GUI Performance Fix: Apply separation constants via script (not theme overrides)
	var main_vbox: VBoxContainer = $MainVBox
	main_vbox.add_theme_constant_override("separation", 0)
	
	var left_content: VBoxContainer = $MainVBox/MainHSplit/LeftPanel/LeftContent
	left_content.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
	
	step_sidebar.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
	
	right_vbox.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
	
	var seed_hbox: HBoxContainer = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/SeedHBox
	seed_hbox.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
	
	# Tree node doesn't need separation override (uses built-in item spacing)
	
	var bottom_content: HBoxContainer = $MainVBox/BottomBar/BottomContent
	bottom_content.add_theme_constant_override("separation", UIConstants.SPACING_LARGE)
	
	# GUI Performance Fix: Apply title styling via modulate (not theme overrides)
	var title_label: Label = $MainVBox/TopBar/TopBarContent/TitleLabel
	if title_label:
		title_label.modulate = Color(1.0, 0.843, 0.0, 1.0)  # Gold color
	
	if step_title:
		step_title.modulate = Color(1.0, 0.843, 0.0, 1.0)  # Gold color
	
	# Set initial split offset
	var main_hsplit: HSplitContainer = $MainVBox/MainHSplit
	main_hsplit.split_offset = UIConstants.LEFT_PANEL_WIDTH


func _notification(what: int) -> void:
	"""Handle window resize for responsive layout."""
	if what == NOTIFICATION_RESIZED:
		# GUI Performance Fix: Throttle resize updates with deferred batching
		if not _resize_pending:
			_resize_pending = true
			call_deferred("_update_responsive_layout")


func _update_responsive_layout() -> void:
	"""Update layout based on viewport size."""
	# GUI Performance Fix: Reset resize pending flag
	_resize_pending = false
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	
	# Calculate panel widths as percentages, clamped to min/max
	var main_hsplit: HSplitContainer = $MainVBox/MainHSplit
	
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
		
		# Convert parameter definitions to format expected by _populate_param_tree()
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
	gen_timer = 0.0
	gen_elapsed_time = 0.0
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
	gen_timer = 0.0
	gen_elapsed_time = 0.0
	set_process(false)
	MythosLogger.error("UI/WorldBuilder", "Azgaar generation failed", {"reason": reason})


func _update_step_ui() -> void:
	"""Update UI for current step."""
	# Update step button highlights
	for i in range(step_buttons.size()):
		var btn: Button = step_buttons[i]
		if i == current_step:
			# Active step - orange highlight (GUI Performance Fix: use modulate instead of theme overrides)
			btn.modulate = Color(1.0, 0.7, 0.3, 1.0)  # Orange tint
		else:
			# Inactive step - dim
			btn.modulate = Color(0.6, 0.6, 0.6, 1.0)  # Dimmed
	
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
	_populate_param_tree()


func _setup_param_tree() -> void:
	"""Setup Tree for parameter display (GUI Performance Fix - replaces pooling)."""
	if not param_tree:
		MythosLogger.error("UI/WorldBuilder", "ParamTree not found")
		return
	
	# Connect Tree signals
	param_tree.item_selected.connect(_on_tree_item_selected)
	param_tree.item_edited.connect(_on_tree_item_edited)
	param_tree.cell_selected.connect(_on_tree_cell_selected)
	
	# Configure Tree columns
	param_tree.columns = 3
	param_tree.column_titles_visible = false
	param_tree.hide_root = true
	param_tree.allow_reselect = true
	param_tree.allow_rmb_select = false
	
	# Set column widths (proportional)
	param_tree.set_column_expand(0, true)   # Label column
	param_tree.set_column_expand(1, true)   # Control column (slider/option)
	param_tree.set_column_expand(2, false)  # Value column (fixed width)
	
	var value_column_width: int = UIConstants.LABEL_WIDTH_NARROW
	param_tree.set_column_custom_minimum_width(2, value_column_width)
	
	MythosLogger.debug("UI/WorldBuilder", "ParamTree setup complete")


func _populate_param_tree() -> void:
	"""Populate Tree with parameters for current step (GUI Performance Fix)."""
	if not param_tree:
		return
	
	# Clear existing items
	param_tree.clear()
	param_tree_items.clear()
	
	var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
	var params_list: Array = step_def.get("params", [])
	
	if params_list.is_empty():
		MythosLogger.debug("UI/WorldBuilder", "No parameters for step", {"step": current_step})
		return
	
	# Create root (hidden)
	var root: TreeItem = param_tree.create_item()
	
	# Create items for each parameter
	for param in params_list:
		var azgaar_key: String = param.get("azgaar_key", param.get("name", ""))
		var param_name: String = param.get("name", "")
		var param_type: String = param.get("type", param.get("ui_type", "HSlider"))
		
		# Create TreeItem
		var item: TreeItem = param_tree.create_item(root)
		
		# Column 0: Parameter name
		item.set_text(0, param_name.capitalize() + ":")
		
		# Column 1: Control (slider, option, checkbox, etc.)
		# Column 2: Value display
		var current_value: Variant = current_params.get(azgaar_key)
		if current_value == null:
			current_value = param.get("default", 0)
			current_params[azgaar_key] = current_value
		
		match param_type:
			"HSlider":
				# Use RANGE cell mode for sliders
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				var min_val: float = param.get("min", 0.0)
				var max_val: float = param.get("max", 100.0)
				var step_val: float = param.get("step", 1.0)
				item.set_range_config(1, min_val, max_val, step_val, false)
				item.set_range(1, float(current_value))
				item.set_text(2, str(current_value))
				item.set_editable(1, true)
				item.set_editable(2, false)
			
			"OptionButton":
				# Use RANGE cell mode as dropdown (values are indices)
				if param.has("options"):
					var options: Array = param.options
					item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
					item.set_range_config(1, 0, options.size() - 1, 1, false)
					var selected_idx: int = options.find(current_value)
					if selected_idx < 0:
						selected_idx = 0
					item.set_range(1, selected_idx)
					item.set_text(2, str(options[selected_idx]))
					item.set_editable(1, true)
					item.set_editable(2, false)
				else:
					item.set_text(1, "No options")
					item.set_text(2, str(current_value))
			
			"CheckBox":
				# Use CHECK cell mode
				item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
				item.set_checked(1, bool(current_value))
				item.set_text(2, "Yes" if bool(current_value) else "No")
				item.set_editable(1, true)
				item.set_editable(2, false)
			
			"SpinBox":
				# Use RANGE cell mode for spinbox
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				var min_val: float = param.get("min", 0.0)
				var max_val: float = param.get("max", 100.0)
				var step_val: float = param.get("step", 1.0)
				item.set_range_config(1, min_val, max_val, step_val, false)
				item.set_range(1, float(current_value))
				item.set_text(2, str(int(current_value)))
				item.set_editable(1, true)
				item.set_editable(2, false)
			
			_:
				# Default: text display
				item.set_text(1, str(current_value))
				item.set_text(2, "")
				item.set_editable(1, false)
				item.set_editable(2, false)
		
		# Store metadata in TreeItem (azgaar_key and param data)
		item.set_metadata(0, {"azgaar_key": azgaar_key, "param": param})
		
		# Store mapping for quick lookup
		param_tree_items[azgaar_key] = item
	
	MythosLogger.debug("UI/WorldBuilder", "Populated ParamTree", {
		"step": current_step,
		"param_count": params_list.size()
	})


func _on_tree_item_selected() -> void:
	"""Handle Tree item selection (for focus/highlighting)."""
	pass  # Selection not needed for parameter editing


func _on_tree_item_edited() -> void:
	"""Handle Tree item edit (when user changes a value)."""
	var edited_item: TreeItem = param_tree.get_selected()
	if not edited_item:
		return
	
	var metadata: Dictionary = edited_item.get_metadata(0)
	if not metadata or not metadata.has("azgaar_key"):
		return
	
	var azgaar_key: String = metadata.azgaar_key
	var param: Dictionary = metadata.param
	var param_type: String = param.get("type", param.get("ui_type", "HSlider"))
	
	# Get edited value from column 1
	var new_value: Variant = null
	match param_type:
		"HSlider", "SpinBox":
			new_value = edited_item.get_range(1)
			# Update value display in column 2
			edited_item.set_text(2, str(new_value))
		
		"OptionButton":
			if param.has("options"):
				var options: Array = param.options
				var selected_idx: int = int(edited_item.get_range(1))
				if selected_idx >= 0 and selected_idx < options.size():
					new_value = options[selected_idx]
					edited_item.set_text(2, str(new_value))
		
		"CheckBox":
			new_value = edited_item.is_checked(1)
			edited_item.set_text(2, "Yes" if bool(new_value) else "No")
	
	if new_value != null:
		_on_parameter_changed(azgaar_key, new_value)


func _on_tree_cell_selected() -> void:
	"""Handle Tree cell selection (for editing)."""
	pass  # Editing handled by _on_tree_item_edited


func _on_parameter_changed(azgaar_key: String, value: Variant) -> void:
	"""Handle parameter value change (from Tree or other sources)."""
	current_params[azgaar_key] = value
	
	# Update Tree display if item exists (for programmatic updates)
	if param_tree_items.has(azgaar_key):
		var item: TreeItem = param_tree_items[azgaar_key]
		var metadata: Dictionary = item.get_metadata(0)
		if metadata and metadata.has("param"):
			var param: Dictionary = metadata.param
			var param_type: String = param.get("type", param.get("ui_type", "HSlider"))
			
			match param_type:
				"HSlider", "SpinBox":
					item.set_range(1, float(value))
					item.set_text(2, str(value))
				
				"OptionButton":
					if param.has("options"):
						var options: Array = param.options
						var selected_idx: int = options.find(value)
						if selected_idx >= 0:
							item.set_range(1, selected_idx)
							item.set_text(2, str(value))
				
				"CheckBox":
					item.set_checked(1, bool(value))
					item.set_text(2, "Yes" if bool(value) else "No")
	
	MythosLogger.debug("UI/WorldBuilder", "Parameter changed", {"key": azgaar_key, "value": value})


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
	_populate_param_tree()


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
	# GUI Performance Fix: Enable _process() only when generation starts
	set_process(true)


func _process(delta: float) -> void:
	"""Process generation status updates (fallback polling if signals don't work)."""
	# GUI Performance Fix: Early exit if generation is not active
	if gen_timer <= 0.0:
		set_process(false)  # Disable when no longer needed
		return
	
	# Generation logic (gen_timer > 0.0 guaranteed at this point)
	gen_elapsed_time += delta
	gen_timer += delta
	
	# Check timeout first (increased to 60s to match timeout timer)
	if gen_elapsed_time > 60.0:
		_update_status("Timeout - reduce points?", 0)
		gen_timer = 0.0
		gen_elapsed_time = 0.0
		set_process(false)  # Disable when timeout occurs
		return
	
	# Poll every 2 seconds for completion (reduced frequency)
	if gen_timer > 2.0:
		gen_timer = 0.0  # Reset timer for next polling cycle
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
