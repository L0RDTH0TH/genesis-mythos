# ╔═══════════════════════════════════════════════════════════
# ║ main_controller.gd
# ║ Desc: Main controller for switching between Character Creation and World Builder modes
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends Control

var current_mode: int = 0

var world = null  # WorldData - type annotation removed for compatibility

var character_root: Node  # instance of current character creation scene

var world_builder_root: VBoxContainer  # World Builder sections container

var world_preview: Node3D  # Instance of world preview scene

@onready var mode_tabs: TabBar = $MarginContainer/root_layout/mode_tabs
@onready var toolbar: HBoxContainer = $MarginContainer/root_layout/toolbar
@onready var new_world_button: Button = $MarginContainer/root_layout/toolbar/NewWorldButton
@onready var save_world_button: Button = $MarginContainer/root_layout/toolbar/SaveWorldButton
@onready var load_world_button: Button = $MarginContainer/root_layout/toolbar/LoadWorldButton
@onready var preset_option: OptionButton = $MarginContainer/root_layout/toolbar/PresetOptionButton
@onready var content_panel: PanelContainer = $MarginContainer/root_layout/content_panel
@onready var preview_panel: SubViewportContainer = $preview_panel
@onready var viewport_3d: SubViewport = $preview_panel/viewport_3d
@onready var biome_overlay_toggle: CheckBox = $preview_panel/PreviewControls/BiomeOverlayToggle

const CHARACTER_CREATION_SCENE = preload("res://scenes/character/CharacterCreationRoot.tscn")
const DEFAULT_WORLD = preload("res://assets/worlds/default_world.tres")
const TERRAIN_SECTION_SCENE = preload("res://scenes/sections/terrain_section.tscn")
const BIOME_SECTION_SCENE = preload("res://scenes/sections/biome_section.tscn")
const WORLD_PREVIEW_SCENE = preload("res://scenes/preview/world_preview.tscn")
const PROGRESS_DIALOG_SCENE = preload("res://scenes/ui/progress_dialog.tscn")

var regeneration_timer: Timer
var progress_dialog: Window
var world_signals_connected: bool = false
var undo_redo: UndoRedo
var terrain_sections: Array[PanelContainer] = []
var biome_sections: Array[PanelContainer] = []

func _ready() -> void:
	"""Initialize main controller and load default world."""
	# Load default world
	world = DEFAULT_WORLD.duplicate()
	
	# Instance character creation scene
	var character_instance: Node = CHARACTER_CREATION_SCENE.instantiate()
	content_panel.add_child(character_instance)
	character_root = character_instance
	
	# Connect mode tabs signal
	mode_tabs.tab_changed.connect(_on_mode_changed)
	
	# Hide preview panel initially (Character Creation mode)
	preview_panel.visible = false
	
	# Check if we came from main menu with a specific tab request
	# Note: MainMenuController tab switching is handled at runtime via scene change
	# The initial tab will be set by the main menu before changing scenes
	
	# Setup regeneration timer
	regeneration_timer = Timer.new()
	regeneration_timer.wait_time = 0.3
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_on_regeneration_timeout)
	add_child(regeneration_timer)
	
	# Connect world generation signals
	_connect_world_signals()
	
	# Setup undo/redo
	undo_redo = UndoRedo.new()
	
	# Setup toolbar
	_setup_toolbar()
	
	# Load presets
	_load_presets()

func _set_initial_tab(tab_index: int) -> void:
	"""Set the initial tab when coming from main menu."""
	mode_tabs.current_tab = tab_index
	_on_mode_changed(tab_index)

func _on_mode_changed(tab: int) -> void:
	"""Handle mode switching between Character Creation and World Builder."""
	current_mode = tab
	
	# Free current content
	for child in content_panel.get_children():
		child.queue_free()
	
	# Free world preview if exists
	if world_preview:
		world_preview.queue_free()
		world_preview = null
	
	# Clear references
	character_root = null
	world_builder_root = null
	terrain_sections.clear()
	biome_sections.clear()
	
	if tab == 0:
		# Character Creation mode
		var character_instance: Node = CHARACTER_CREATION_SCENE.instantiate()
		content_panel.add_child(character_instance)
		character_root = character_instance
		preview_panel.visible = false
		toolbar.visible = false
	elif tab == 1:
		# World Builder mode
		# Create world builder root container
		var builder_container: VBoxContainer = VBoxContainer.new()
		builder_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		builder_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_panel.add_child(builder_container)
		world_builder_root = builder_container
		
		# Instance terrain section
		var terrain_section: PanelContainer = TERRAIN_SECTION_SCENE.instantiate()
		builder_container.add_child(terrain_section)
		terrain_section.param_changed.connect(_on_param_changed_with_undo)
		terrain_sections.append(terrain_section)
		
		# Initialize terrain section with current world params
		if terrain_section.has_method("set_params"):
			var section_params: Dictionary = {}
			if world.params.has("elevation"):
				section_params["elevation_scale"] = world.params["elevation"]
			if world.randomness.has("terrain"):
				section_params["terrain_chaos"] = world.randomness["terrain"] * 100.0
			if world.params.has("noise_type"):
				section_params["noise_type"] = world.params["noise_type"]
			if world.params.has("enable_rivers"):
				section_params["enable_rivers"] = world.params["enable_rivers"]
			section_params["size_preset"] = world.size_preset as int
			terrain_section.set_params(section_params)
		
		# Instance biome section
		var biome_section: PanelContainer = BIOME_SECTION_SCENE.instantiate()
		builder_container.add_child(biome_section)
		biome_section.param_changed.connect(_on_param_changed_with_undo)
		biome_sections.append(biome_section)
		
		# Instance world preview in viewport
		var preview_instance: Node3D = WORLD_PREVIEW_SCENE.instantiate()
		viewport_3d.add_child(preview_instance)
		world_preview = preview_instance
		world_preview.set_world_data(world)
		
		# Connect biome overlay toggle
		biome_overlay_toggle.toggled.connect(_on_biome_overlay_toggled)
		
		preview_panel.visible = true
		toolbar.visible = true
		
		# Connect world signals if not already connected
		_connect_world_signals()
		
		# Initial generation
		queue_regeneration()

func _connect_world_signals() -> void:
	"""Connect world generation signals."""
	if world and not world_signals_connected:
		world.generation_progress.connect(_on_generation_progress)
		world.generation_complete.connect(_on_generation_complete)
		world_signals_connected = true

func _on_param_changed(param: String, value: Variant) -> void:
	"""Handle parameter changes from sections."""
	# Update world params
	if param == "elevation_scale":
		world.params["elevation"] = value
	elif param == "terrain_chaos":
		world.randomness["terrain"] = value / 100.0  # Convert 0-100 to 0-1.0
	elif param == "noise_type":
		world.params["noise_type"] = value
	elif param == "enable_rivers":
		world.params["enable_rivers"] = value
	elif param == "size_preset":
		world.size_preset = value
	
	# Queue regeneration with debounce
	queue_regeneration()

func queue_regeneration(force_full_res: bool = false) -> void:
	"""Queue world regeneration with debouncing.
	
	Args:
		force_full_res: If true, generate at full size_preset resolution instead of preview
	"""
	if regeneration_timer:
		regeneration_timer.start()
		regeneration_timer.set_meta("force_full_res", force_full_res)

func _on_regeneration_timeout() -> void:
	"""Handle regeneration timer timeout - actually generate world."""
	if world:
		var force_full_res: bool = regeneration_timer.get_meta("force_full_res", false) if regeneration_timer else false
		_show_progress_dialog()
		world.generate(force_full_res)

func _show_progress_dialog() -> void:
	"""Show progress dialog during generation."""
	if progress_dialog:
		progress_dialog.queue_free()
	
	progress_dialog = PROGRESS_DIALOG_SCENE.instantiate()
	add_child(progress_dialog)
	progress_dialog.popup_centered(Vector2i(400, 120))

func _on_generation_cancelled() -> void:
	"""Handle generation cancellation."""
	if world:
		world.abort_generation()
	if progress_dialog:
		progress_dialog.queue_free()
		progress_dialog = null

func _on_generation_progress(progress: float) -> void:
	"""Update progress bar during generation."""
	if progress_dialog:
		progress_dialog.set_progress(progress)
		
		# Update status text based on progress
		if progress < 0.125:
			progress_dialog.set_status("Generating heightmap...")
		elif progress < 0.25:
			progress_dialog.set_status("Applying shape mask...")
		elif progress < 0.375:
			progress_dialog.set_status("Applying erosion...")
		elif progress < 0.5:
			progress_dialog.set_status("Generating rivers...")
		elif progress < 0.625:
			progress_dialog.set_status("Assigning biomes...")
		elif progress < 0.75:
			progress_dialog.set_status("Generating foliage & POIs...")
		elif progress < 0.975:
			progress_dialog.set_status("Building mesh geometry...")
		else:
			progress_dialog.set_status("Finalizing world...")

func _on_generation_complete() -> void:
	"""Handle generation completion."""
	# Hide progress dialog
	if progress_dialog:
		progress_dialog.queue_free()
		progress_dialog = null
	
	# Update preview mesh
	if world_preview and world and world.generated_mesh:
		world_preview.update_mesh(world.generated_mesh)
		world_preview.set_world_data(world)
		# Auto-fit camera to mesh bounds
		world_preview.auto_fit_camera()

func _on_biome_overlay_toggled(enabled: bool) -> void:
	"""Handle biome overlay toggle."""
	if world_preview:
		world_preview.toggle_biome_overlay(enabled)

func _setup_toolbar() -> void:
	"""Setup toolbar button connections."""
	new_world_button.pressed.connect(_on_new_world)
	save_world_button.pressed.connect(_on_save_world)
	load_world_button.pressed.connect(_on_load_world)
	preset_option.item_selected.connect(_on_preset_selected)
	
	# Hide toolbar initially (only show in World Builder mode)
	toolbar.visible = false

func _load_presets() -> void:
	"""Load preset files and populate OptionButton."""
	preset_option.clear()
	preset_option.add_item("None")
	
	var preset_dir: String = "res://assets/presets/"
	var dir: DirAccess = DirAccess.open(preset_dir)
	if dir:
		var files: PackedStringArray = dir.get_files()
		for file in files:
			if file.ends_with(".json"):
				var preset_name: String = file.get_basename()
				preset_option.add_item(preset_name.capitalize())

func _on_new_world() -> void:
	"""Create a new world from default."""
	if world:
		undo_redo.create_action("New World")
		undo_redo.add_do_method(_apply_world_data.bind(DEFAULT_WORLD.duplicate()))
		undo_redo.add_undo_method(_apply_world_data.bind(world.duplicate()))
		undo_redo.commit_action()
		
		world = DEFAULT_WORLD.duplicate()
		_apply_world_data(world)
		queue_regeneration()

func _on_save_world() -> void:
	"""Save world to user://worlds/MyWorld/ folder."""
	var file_dialog: FileDialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.gworld", "World Files")
	file_dialog.title = "Save World"
	file_dialog.current_dir = "user://worlds/"
	file_dialog.file_selected.connect(_save_world_to_path)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _save_world_to_path(path: String) -> void:
	"""Save world to specified path."""
	# Ensure path uses .gworld extension
	if not path.ends_with(".gworld"):
		path += ".gworld"
	
	var world_dir: String = path.get_base_dir()
	var world_name: String = path.get_file().get_basename()
	
	# Create directory if it doesn't exist
	var dir: DirAccess = DirAccess.open("user://")
	if not dir.dir_exists(world_dir.trim_prefix("user://")):
		dir.make_dir_recursive(world_dir.trim_prefix("user://"))
	
	# Save binary resource
	var error: Error = ResourceSaver.save(world, path, ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		print("Error saving world: ", error)
		return
	
	# Save JSON backup in same directory
	var json_path: String = world_dir.path_join(world_name + ".json")
	var json_data: Dictionary = {
		"seed": world.seed,
		"size": {"x": world.size.x, "y": world.size.y},
		"params": world.params.duplicate(),
		"randomness": world.randomness.duplicate()
	}
	
	var json_string: String = JSON.stringify(json_data, "\t")
	var file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("World saved to: ", path)

func _on_load_world() -> void:
	"""Load world from user://worlds/ folder."""
	var file_dialog: FileDialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.gworld", "World Files")
	file_dialog.title = "Load World"
	file_dialog.current_dir = "user://worlds/"
	file_dialog.file_selected.connect(_load_world_from_path)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _load_world_from_path(path: String) -> void:
	"""Load world from specified path."""
	var loaded_world = load(path)
	if loaded_world:
		var old_world = world.duplicate()
		
		undo_redo.create_action("Load World")
		undo_redo.add_do_method(_apply_world_data.bind(loaded_world))
		undo_redo.add_undo_method(_apply_world_data.bind(old_world))
		undo_redo.commit_action()
		
		world = loaded_world
		_apply_world_data(world)
		queue_regeneration()
	else:
		print("Error loading world from: ", path)

func _on_preset_selected(index: int) -> void:
	"""Handle preset selection."""
	if index == 0:  # "None"
		return
	
	var preset_name: String = preset_option.get_item_text(index).to_lower().replace(" ", "_")
	var preset_path: String = "res://assets/presets/" + preset_name + ".json"
	_load_preset_file(preset_path)

func _load_preset_file(preset_path: String) -> void:
	"""Load preset JSON and apply to world."""
	var file: FileAccess = FileAccess.open(preset_path, FileAccess.READ)
	if not file:
		print("Error loading preset: ", preset_path)
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		print("Error parsing preset JSON: ", json.get_error_message())
		return
	
	var preset_data: Dictionary = json.data
	
	# Store old state for undo
	var old_params: Dictionary = world.params.duplicate()
	var old_randomness: Dictionary = world.randomness.duplicate()
	var old_seed: int = world.seed
	
	# Merge preset params
	if preset_data.has("params"):
		world.params.merge(preset_data["params"], true)
	if preset_data.has("randomness"):
		world.randomness.merge(preset_data["randomness"], true)
	if preset_data.has("seed"):
		world.seed = preset_data["seed"]
	
	# Create undo action
	undo_redo.create_action("Load Preset: " + preset_data.get("name", "Unknown"))
	undo_redo.add_do_method(_apply_world_params_wrapper.bind([world.params, world.randomness, world.seed]))
	undo_redo.add_undo_method(_apply_world_params_wrapper.bind([old_params, old_randomness, old_seed]))
	undo_redo.commit_action()
	
	# Apply to UI sections
	_apply_world_params(world.params, world.randomness, world.seed)
	queue_regeneration()

func _apply_world_data(new_world) -> void:
	"""Apply world data to current world."""
	world = new_world
	_apply_world_params(world.params, world.randomness, world.seed)

func _apply_world_params_wrapper(args: Array) -> void:
	"""Wrapper for _apply_world_params to work with UndoRedo bind()."""
	if args.size() >= 3:
		_apply_world_params(args[0] as Dictionary, args[1] as Dictionary, args[2] as int)

func _apply_world_params(params: Dictionary, randomness: Dictionary, seed_value: int) -> void:
	"""Apply parameters to world and emit param_changed for all sections."""
	world.params = params
	world.randomness = randomness
	world.seed = seed_value
	
	# Emit param_changed for each section to update UI
	for section in terrain_sections:
		if section.has_method("set_params"):
			var section_params: Dictionary = {}
			
			# Map world params to section params
			if params.has("elevation"):
				section_params["elevation_scale"] = params["elevation"]
			if randomness.has("terrain"):
				section_params["terrain_chaos"] = randomness["terrain"] * 100.0  # Convert 0-1.0 to 0-100
			if params.has("noise_type"):
				section_params["noise_type"] = params["noise_type"]
			if params.has("enable_rivers"):
				section_params["enable_rivers"] = params["enable_rivers"]
			
			# Include size_preset from world
			section_params["size_preset"] = world.size_preset as int
			
			section.set_params(section_params)

func _on_param_changed_with_undo(param: String, value: Variant) -> void:
	"""Handle parameter changes with undo/redo support."""
	var old_value: Variant
	var param_key: String
	
	# Get old value and determine param key
	if param == "elevation_scale":
		old_value = world.params.get("elevation", 100.0)
		param_key = "elevation"
		world.params["elevation"] = value
	elif param == "terrain_chaos":
		old_value = world.randomness.get("terrain", 0.0) * 100.0
		param_key = "terrain"
		world.randomness["terrain"] = value / 100.0
	elif param == "noise_type":
		old_value = world.params.get("noise_type", "Perlin")
		param_key = "noise_type"
		world.params["noise_type"] = value
	elif param == "enable_rivers":
		old_value = world.params.get("enable_rivers", false)
		param_key = "enable_rivers"
		world.params["enable_rivers"] = value
	elif param == "size_preset":
		old_value = world.size_preset
		param_key = "size_preset"
		world.size_preset = value
	else:
		_on_param_changed(param, value)
		return
	
	# Create undo action
	undo_redo.create_action("Change " + param)
	undo_redo.add_do_method(_set_param_value.bind(param_key, value, param))
	undo_redo.add_undo_method(_set_param_value.bind(param_key, old_value, param))
	undo_redo.commit_action()
	
	# Apply change
	_on_param_changed(param, value)

func _set_param_value(param_key: String, value: Variant, section_param: String) -> void:
	"""Set parameter value (used by undo/redo)."""
	if param_key == "elevation":
		world.params["elevation"] = value
		# Update UI
		for section in terrain_sections:
			if section.has_method("set_params"):
				section.set_params({"elevation_scale": value})
	elif param_key == "terrain":
		world.randomness["terrain"] = value / 100.0 if section_param == "terrain_chaos" else value
		# Update UI
		for section in terrain_sections:
			if section.has_method("set_params"):
				section.set_params({"terrain_chaos": value if section_param == "terrain_chaos" else value * 100.0})
	elif param_key == "noise_type":
		world.params["noise_type"] = value
		# Update UI
		for section in terrain_sections:
			if section.has_method("set_params"):
				section.set_params({"noise_type": value})
	elif param_key == "enable_rivers":
		world.params["enable_rivers"] = value
		# Update UI
		for section in terrain_sections:
			if section.has_method("set_params"):
				section.set_params({"enable_rivers": value})
	elif param_key == "size_preset":
		world.size_preset = value
		# Update UI
		for section in terrain_sections:
			if section.has_method("set_params"):
				section.set_params({"size_preset": value})
	
	queue_regeneration()

