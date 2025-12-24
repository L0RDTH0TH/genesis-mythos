# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: Manages the UI for Azgaar-based world generation with dynamic panels
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderUI
extends Control

## Reference to terrain manager (optional, for future 3D baking)
var terrain_manager: Node = null

@onready var category_tabs: TabContainer = $MainHSplit/LeftPanel/CategoryTabs
@onready var archetype_option: OptionButton = $MainHSplit/RightPanel/RightVBox/GlobalControls/ArchetypeOption
@onready var seed_spin: SpinBox = $MainHSplit/RightPanel/RightVBox/GlobalControls/SeedHBox/SeedSpin
@onready var randomize_btn: Button = $MainHSplit/RightPanel/RightVBox/GlobalControls/SeedHBox/RandomizeBtn
@onready var section_title: Label = $MainHSplit/RightPanel/RightVBox/SectionTitle
@onready var active_params: VBoxContainer = $MainHSplit/RightPanel/RightVBox/ActiveParams
@onready var gen_btn: Button = $BottomHBox/GenBtn
@onready var bake_btn: Button = $BottomHBox/BakeBtn
@onready var progress_bar: ProgressBar = $BottomHBox/ProgressBar
@onready var status_label: Label = $BottomHBox/StatusLabel
@onready var azgaar_webview: Node = $MainHSplit/CenterPanel/AzgaarWebView

var current_params: Dictionary = {}
var current_category: String = ""
var gen_timer: float = 0.0
var gen_elapsed_time: float = 0.0

const ARCHETYPES: Dictionary = {
	"High Fantasy": {"points": 800000, "heightExponent": 1.2, "allowErosion": true, "plateCount": 8, "burgs": 500, "precip": 0.6},
	"Low Fantasy": {"points": 600000, "heightExponent": 0.8, "allowErosion": true, "plateCount": 5, "burgs": 200, "precip": 0.5},
	"Dark Fantasy": {"points": 400000, "heightExponent": 1.5, "allowErosion": false, "plateCount": 12, "burgs": 100, "precip": 0.8},
	"Realistic": {"points": 1000000, "heightExponent": 1.0, "allowErosion": true, "plateCount": 7, "burgs": 800},
	"Custom": {}
}

const CATEGORY_PARAMS: Dictionary = {
	"Terrain & Heightmap": [
		{"name": "template", "type": "OptionButton", "options": ["default", "fractal", "islands"], "default": "default"},
		{"name": "points", "type": "HSlider", "min": 100000, "max": 2000000, "step": 50000, "default": 600000},
		{"name": "heightExponent", "type": "HSlider", "min": 0.1, "max": 2.0, "step": 0.05, "default": 1.0},
		{"name": "allowErosion", "type": "CheckBox", "default": true},
		{"name": "plateCount", "type": "SpinBox", "min": 3, "max": 15, "default": 7}
	],
	"Climate & Environment": [
		{"name": "precip", "type": "HSlider", "min": 0.0, "max": 1.0, "default": 0.5}
	],
	"Societies & Politics": [],
	"Settlements & Scale": [],
	"Advanced / Visual": []
}


func _ready() -> void:
	"""Initialize the World Builder UI."""
	DirAccess.make_dir_recursive_absolute("user://azgaar/")
	DirAccess.make_dir_recursive_absolute(UIConstants.DOWNLOADS_DIR)
	
	# Populate archetype option button
	for archetype_name in ARCHETYPES.keys():
		archetype_option.add_item(archetype_name)
	
	# Set category tab titles
	category_tabs.set_tab_title(0, "Terrain & Heightmap")
	category_tabs.set_tab_title(1, "Climate & Environment")
	category_tabs.set_tab_title(2, "Societies & Politics")
	category_tabs.set_tab_title(3, "Settlements & Scale")
	category_tabs.set_tab_title(4, "Advanced / Visual")
	
	archetype_option.item_selected.connect(_load_archetype_params)
	seed_spin.value_changed.connect(_on_seed_changed)
	randomize_btn.pressed.connect(_randomize_seed)
	category_tabs.tab_changed.connect(_on_category_changed)
	gen_btn.pressed.connect(_generate_azgaar)
	bake_btn.pressed.connect(_bake_to_3d)
	
	_load_archetype_params(0)
	set_process(false)


func _load_archetype_params(idx: int) -> void:
	"""Load params for selected archetype."""
	var archetype: String = archetype_option.get_item_text(idx)
	current_params = ARCHETYPES[archetype].duplicate()
	for key in current_params:
		if key == "points":
			current_params[key] = UIConstants.get_clamped_points(current_params[key])
	_on_category_changed(category_tabs.current_tab)


func _on_seed_changed(value: float) -> void:
	"""Update seed in params."""
	current_params["seed"] = int(value)


func _randomize_seed() -> void:
	"""Randomize seed."""
	seed_spin.value = randi()


func _on_category_changed(tab_idx: int) -> void:
	"""Update right panel for selected category."""
	current_category = category_tabs.get_tab_title(tab_idx)
	section_title.text = current_category
	for child in active_params.get_children():
		child.queue_free()
	
	var params_list: Array = CATEGORY_PARAMS.get(current_category, [])
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
				# Scan DOWNLOADS_DIR and parse (stub)
				_update_status("Ready for bake", 100)
				bake_btn.disabled = false
				return


func _bake_to_3d() -> void:
	"""Bake to 3D (stub)."""
	_update_status("Baking to Terrain3D...", 0)
	# Stub: Load PNGs, parse to heightmap, etc.
	_update_status("Baked!", 100)


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
	var manager_name: String = manager.name if manager != null else "null"
	MythosLogger.debug("UI/WorldBuilder", "Terrain manager set", {"manager": manager_name})
