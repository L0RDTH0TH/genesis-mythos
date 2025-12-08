# ╔═══════════════════════════════════════════════════════════
# ║ seed_size_section.gd
# ║ Desc: Seed & size section with seed input and world size preset selector
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

signal param_changed(param: String, value: Variant)

@onready var seed_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/SeedContainer/SeedSpinBox
@onready var fresh_seed_button: Button = $MarginContainer/VBoxContainer/content/SeedContainer/FreshSeedButton
@onready var size_option: OptionButton = $MarginContainer/VBoxContainer/content/SizeContainer/SizeOptionButton
@onready var shape_option: OptionButton = $MarginContainer/VBoxContainer/content/ShapeContainer/ShapeOptionButton

const SIZE_PRESET_NAMES := ["Tiny (256×256)", "Small (384×384)", "Medium (512×512)", "Large (768×768)", "Huge (1024×1024)"]
var shape_preset_names: Array[String] = []

func _ready() -> void:
	"""Initialize seed & size section controls and connections."""
	# Populate size preset option button
	if size_option:
		size_option.clear()
		for preset_name in SIZE_PRESET_NAMES:
			size_option.add_item(preset_name)
		size_option.selected = 2  # Default to MEDIUM (512×512)
		size_option.item_selected.connect(_on_size_changed)
	
	# Load and populate shape preset option button
	_load_shape_presets()
	if shape_option:
		shape_option.clear()
		for preset_name in shape_preset_names:
			shape_option.add_item(preset_name)
		shape_option.selected = 0  # Default to "Square"
		shape_option.item_selected.connect(_on_shape_changed)
	
	# Connect seed controls
	if seed_spinbox:
		seed_spinbox.value_changed.connect(_on_seed_changed)
	
	if fresh_seed_button:
		fresh_seed_button.pressed.connect(_on_fresh_seed_pressed)
	
	# Setup tooltips
	_setup_tooltips()
	_setup_keyboard_navigation()

func _load_shape_presets() -> void:
	"""Load shape preset names from JSON file."""
	var file: FileAccess = FileAccess.open("res://assets/presets/shape_presets.json", FileAccess.READ)
	if not file:
		print("seed_size_section.gd: ERROR - Failed to open shape_presets.json, using defaults")
		shape_preset_names = ["Square", "Continent", "Island Chain", "Coastline", "Trench"]
		return
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_text)
	if error != OK:
		print("seed_size_section.gd: ERROR - JSON parse error: ", json.get_error_message())
		shape_preset_names = ["Square", "Continent", "Island Chain", "Coastline", "Trench"]
		return
	
	var presets: Dictionary = json.data
	shape_preset_names.clear()
	for key in presets.keys():
		shape_preset_names.append(str(key))
	shape_preset_names.sort()  # Sort alphabetically for consistent ordering

func _setup_tooltips() -> void:
	"""Set tooltips for all controls."""
	if seed_spinbox:
		seed_spinbox.tooltip_text = "World generation seed. Same seed produces identical worlds. Change for variation."
	if fresh_seed_button:
		fresh_seed_button.tooltip_text = "Generate a random new seed for world generation."
	if size_option:
		size_option.tooltip_text = "Select world size preset. Larger sizes take longer to generate but provide more detail."
	if shape_option:
		shape_option.tooltip_text = "Select map shape preset. Controls the overall shape of the generated terrain (e.g., continent, island chain, coastline)."

func _setup_keyboard_navigation() -> void:
	"""Setup keyboard navigation."""
	# Enable focus on all controls - Godot will handle navigation automatically
	# in containers like VBoxContainer
	if seed_spinbox:
		seed_spinbox.focus_mode = Control.FOCUS_ALL
	if fresh_seed_button:
		fresh_seed_button.focus_mode = Control.FOCUS_ALL
	if size_option:
		size_option.focus_mode = Control.FOCUS_ALL
	if shape_option:
		shape_option.focus_mode = Control.FOCUS_ALL

func _on_seed_changed(value: float) -> void:
	"""Handle seed input change."""
	param_changed.emit("seed", int(value))

func _on_fresh_seed_pressed() -> void:
	"""Generate a fresh random seed."""
	var new_seed: int = randi()
	if seed_spinbox:
		seed_spinbox.value = new_seed
	param_changed.emit("seed", new_seed)

func _on_size_changed(index: int) -> void:
	"""Handle size selector change."""
	# Map UI index to WorldData.SizePreset enum values
	# WorldData uses: 0=TINY(64), 1=SMALL(256), 2=MEDIUM(512), 3=LARGE(1024), 4=EPIC(2048)
	# UI shows: 0=Tiny(256), 1=Small(384), 2=Medium(512), 3=Large(768), 4=Huge(1024)
	# Mapping: UI 0→1(SMALL), 1→1(SMALL), 2→2(MEDIUM), 3→3(LARGE), 4→3(LARGE)
	var preset_map := [1, 1, 2, 3, 3]
	if index < preset_map.size():
		param_changed.emit("size_preset", preset_map[index])
	else:
		param_changed.emit("size_preset", 2)  # Default to MEDIUM

func _on_shape_changed(index: int) -> void:
	"""Handle shape preset selector change."""
	if shape_option and index >= 0 and index < shape_preset_names.size():
		var preset_name: String = shape_preset_names[index]
		param_changed.emit("shape_preset", preset_name)

func get_params() -> Dictionary:
	"""Get all seed & size parameters as dictionary."""
	var params := {}
	if seed_spinbox:
		params["seed"] = int(seed_spinbox.value)
	if size_option:
		var index: int = size_option.selected
		var preset_map := [1, 1, 2, 3, 3]
		if index < preset_map.size():
			params["size_preset"] = preset_map[index]
		else:
			params["size_preset"] = 2
	return params

func set_params(params: Dictionary) -> void:
	"""Set seed & size parameters from dictionary."""
	if params.has("seed") and seed_spinbox:
		seed_spinbox.value = params["seed"]
	
	if params.has("size_preset") and size_option:
		var preset_value: int = params["size_preset"]
		# Reverse map: WorldData preset → UI index
		var reverse_map := {1: 1, 2: 2, 3: 3, 4: 3}  # Map WorldData preset to UI index
		if reverse_map.has(preset_value):
			size_option.selected = reverse_map[preset_value]
		else:
			size_option.selected = 2  # Default to MEDIUM
	
	if params.has("shape_preset") and shape_option:
		var preset_name: String = params["shape_preset"]
		var index: int = shape_preset_names.find(preset_name)
		if index >= 0:
			shape_option.selected = index
		else:
			shape_option.selected = 0  # Default to "Square"
