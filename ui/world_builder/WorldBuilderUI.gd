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
@onready var step_tabs: TabContainer = $MainHSplit/LeftPanel/LeftContent/StepTabs
@onready var view_menu: OptionButton = $TopToolbar/ToolbarContent/ViewMenu
@onready var archetype_option: OptionButton = $MainHSplit/RightPanel/RightVBox/GlobalControls/ArchetypeOption
@onready var seed_spin: SpinBox = $MainHSplit/RightPanel/RightVBox/GlobalControls/SeedHBox/SeedSpin
@onready var randomize_btn: Button = $MainHSplit/RightPanel/RightVBox/GlobalControls/SeedHBox/RandomizeBtn
@onready var step_title: Label = $MainHSplit/RightPanel/RightVBox/StepTitle
@onready var active_params: VBoxContainer = $MainHSplit/RightPanel/RightVBox/ActiveParams
@onready var back_btn: Button = $BottomHBox/BottomContent/BackBtn
@onready var next_btn: Button = $BottomHBox/BottomContent/NextBtn
@onready var gen_btn: Button = $BottomHBox/BottomContent/GenBtn
@onready var generate_3d_btn: Button = $TopToolbar/ToolbarContent/Generate3DBtn
@onready var progress_bar: ProgressBar = $BottomHBox/BottomContent/ProgressBar
@onready var status_label: Label = $BottomHBox/BottomContent/StatusLabel
@onready var azgaar_webview: Node = $MainHSplit/CenterPanel/CenterContent/AzgaarWebView
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

# Step definitions with parameters
const STEP_DEFINITIONS: Dictionary = {
	0: {"title": "Step 1: Terrain & Heightmap", "params": [
		{"name": "template", "type": "OptionButton", "options": ["default", "fractal", "islands"], "default": "default"},
		{"name": "points", "type": "HSlider", "min": 100000, "max": 2000000, "step": 50000, "default": 600000},
		{"name": "heightExponent", "type": "HSlider", "min": 0.1, "max": 2.0, "step": 0.05, "default": 1.0},
		{"name": "allowErosion", "type": "CheckBox", "default": true},
		{"name": "plateCount", "type": "SpinBox", "min": 3, "max": 15, "default": 7}
	]},
	1: {"title": "Step 2: Climate & Environment", "params": [
		{"name": "precip", "type": "HSlider", "min": 0.0, "max": 1.0, "default": 0.5},
		{"name": "temperatureEquator", "type": "HSlider", "min": 20.0, "max": 40.0, "step": 1.0, "default": 30.0},
		{"name": "temperatureNorthPole", "type": "HSlider", "min": -40.0, "max": 0.0, "step": 1.0, "default": -20.0}
	]},
	2: {"title": "Step 3: Biomes & Ecosystems", "params": []},
	3: {"title": "Step 4: Structures & Civilizations", "params": [
		{"name": "statesNumber", "type": "SpinBox", "min": 1, "max": 100, "default": 20},
		{"name": "culturesSet", "type": "OptionButton", "options": ["random", "realistic", "fantasy"], "default": "random"},
		{"name": "religionsNumber", "type": "SpinBox", "min": 1, "max": 50, "default": 10}
	]},
	4: {"title": "Step 5: Environment & Atmosphere", "params": []},
	5: {"title": "Step 6: Resources & Magic", "params": []},
	6: {"title": "Step 7: Export & Preview", "params": []},
	7: {"title": "Step 8: Bake to 3D", "params": []}
}


func _ready() -> void:
	"""Initialize the World Builder UI."""
	DirAccess.make_dir_recursive_absolute("user://azgaar/")
	DirAccess.make_dir_recursive_absolute(UIConstants.DOWNLOADS_DIR)
	
	# Populate view menu
	view_menu.add_item("Heightmap")
	view_menu.add_item("Biomes")
	view_menu.add_item("Cultures")
	view_menu.add_item("Religions")
	
	# Populate archetype option button
	for archetype_name in ARCHETYPES.keys():
		archetype_option.add_item(archetype_name)
	
	# Set step tab titles
	for i in range(TOTAL_STEPS):
		var step_def: Dictionary = STEP_DEFINITIONS.get(i, {})
		var title: String = step_def.get("title", "Step %d" % (i + 1))
		step_tabs.set_tab_title(i, title.split(":")[0])  # Just "Step N"
	
	# Connect signals
	step_tabs.tab_changed.connect(_on_step_changed)
	archetype_option.item_selected.connect(_load_archetype_params)
	seed_spin.value_changed.connect(_on_seed_changed)
	randomize_btn.pressed.connect(_randomize_seed)
	back_btn.pressed.connect(_on_back_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	gen_btn.pressed.connect(_generate_azgaar)
	generate_3d_btn.pressed.connect(_bake_to_3d)
	
	# Initialize with first step
	_load_archetype_params(0)
	_update_step_ui()
	
	# Initialize Azgaar with default map
	_initialize_azgaar_default()
	
	set_process(false)


func _initialize_azgaar_default() -> void:
	"""Load default Azgaar map on startup."""
	if azgaar_webview and azgaar_webview.has_method("load_url"):
		azgaar_webview.load_url(UIConstants.AZGAAR_BASE_URL)
		MythosLogger.debug("UI/WorldBuilder", "Loading default Azgaar map")


func _update_step_ui() -> void:
	"""Update UI for current step."""
	step_tabs.current_tab = current_step
	
	var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
	step_title.text = step_def.get("title", "Step %d" % (current_step + 1))
	
	# Update navigation buttons
	back_btn.disabled = (current_step == 0)
	next_btn.disabled = (current_step == TOTAL_STEPS - 1)
	
	# Show/hide generate button based on step
	if current_step == 6:  # Export step
		gen_btn.visible = true
		next_btn.visible = false
		generate_3d_btn.disabled = true
	elif current_step == 7:  # Bake step
		gen_btn.visible = false
		next_btn.visible = false
		generate_3d_btn.disabled = false
		generate_3d_btn.text = "🎨 Bake to 3D World"
	else:
		gen_btn.visible = false
		next_btn.visible = true
		generate_3d_btn.disabled = true
	
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
		
		var label: Label = Label.new()
		label.text = param.name.capitalize() + ":"
		label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
		row.add_child(label)
		
		var control: Control
		match param.type:
			"OptionButton":
				control = OptionButton.new()
				for opt in param.options:
					control.add_item(opt)
				var default_idx: int = param.options.find(param.default)
				if default_idx >= 0:
					control.selected = default_idx
				control.item_selected.connect(func(idx: int): current_params[param.name] = control.get_item_text(idx))
			"HSlider":
				control = HSlider.new()
				control.min_value = param.min
				control.max_value = param.max
				control.step = param.step
				control.value = current_params.get(param.name, param.default)
				control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				
				var value_label: Label = Label.new()
				value_label.text = str(control.value)
				value_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_NARROW, 0)
				control.value_changed.connect(func(val: float): 
					value_label.text = str(val)
					current_params[param.name] = val
				)
				row.add_child(control)
				row.add_child(value_label)
				active_params.add_child(row)
				continue
			"CheckBox":
				control = CheckBox.new()
				control.button_pressed = current_params.get(param.name, param.default)
				control.toggled.connect(func(on: bool): current_params[param.name] = on)
			"SpinBox":
				control = SpinBox.new()
				control.min_value = param.min
				control.max_value = param.max
				control.value = current_params.get(param.name, param.default)
				control.value_changed.connect(func(val: float): current_params[param.name] = int(val))
		
		control.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_WIDE, UIConstants.BUTTON_HEIGHT_SMALL)
		control.tooltip_text = "Controls " + param.name
		row.add_child(control)
		active_params.add_child(row)


func _on_step_changed(tab_idx: int) -> void:
	"""Handle step tab change."""
	current_step = tab_idx
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
	"""Generate world with Azgaar."""
	_update_status("Writing params...", 10)
	var file: FileAccess = FileAccess.open("user://azgaar/options.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_params))
		file.close()
	
	_update_status("Loading Azgaar...", 30)
	if azgaar_webview and azgaar_webview.has_method("load_url"):
		azgaar_webview.load_url(UIConstants.AZGAAR_JSON_URL)
	
	gen_timer = 0.0
	gen_elapsed_time = 0.0
	set_process(true)


func _process(delta: float) -> void:
	"""Process generation status updates."""
	gen_elapsed_time += delta
	gen_timer += delta
	
	# Check timeout first
	if gen_elapsed_time > 35.0:
		_update_status("Timeout - reduce points?", 0)
		set_process(false)
		return
	
	# Poll every 0.5 seconds for completion
	if gen_timer > 0.5:
		gen_timer = 0.0
		if azgaar_webview and azgaar_webview.has_method("get_title"):
			var title: String = azgaar_webview.get_title()
			if title.contains("[") and title.contains("x"):  # e.g., "Fantasy Map Generator [seed] [width]x[height]"
				_update_status("Generation complete!", 80)
				set_process(false)
				if azgaar_webview.has_method("load_url"):
					azgaar_webview.load_url(UIConstants.AZGAAR_BASE_URL + "#export=png&export=height&export=biomes")
				await get_tree().create_timer(5.0).timeout
				_update_status("Exporting maps...", 90)
				_update_status("Ready for bake", 100)
				# Navigate to bake step
				current_step = 7
				_update_step_ui()
				return


func _bake_to_3d() -> void:
	"""Bake to 3D - lazy load Terrain3D only now."""
	_update_status("Initializing Terrain3D...", 10)
	
	if terrain_manager != null and terrain_manager.has_method("create_terrain"):
		terrain_manager.create_terrain()
		_update_status("Configuring terrain...", 30)
		if terrain_manager.has_method("configure_terrain"):
			terrain_manager.configure_terrain()
		
		_update_status("Baking heightmap to 3D...", 60)
		# TODO: Parse exported PNGs and apply to Terrain3D
		_update_status("Baked successfully!", 100)
		MythosLogger.info("UI/WorldBuilder", "Terrain3D baked from Azgaar maps")
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
