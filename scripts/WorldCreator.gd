# ╔═══════════════════════════════════════════════════════════
# ║ WorldCreator.gd
# ║ Desc: Final BG3-perfect world creator – Tabs | 3D Preview | Parameters layout
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends MarginContainer

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"
const CHARACTER_CREATION_SCENE: String = "res://scenes/character/CharacterCreationRoot.tscn"

# Section scene paths (6 tabs: Seed&Size, Terrain, Climate, Biomes, Civilizations, Resources&Magic)
const SECTION_SCENES := [
	"res://scenes/sections/seed_size_section.tscn",
	"res://scenes/sections/terrain_section.tscn",
	"res://scenes/sections/climate_section.tscn",
	"res://scenes/sections/biome_section.tscn",
	"res://scenes/sections/civilization_section.tscn",
	"res://scenes/sections/resources_section.tscn"
]

@onready var tab_buttons: Array[Button] = []
@onready var parameters_container: VBoxContainer = $VBoxContainer/HBoxContainer/RightParametersPanel/ParametersScroll/ParametersVBox
@onready var viewport: SubViewport = $VBoxContainer/HBoxContainer/CenterPreview/WorldPreviewViewport
@onready var world_preview: Node3D = $VBoxContainer/HBoxContainer/CenterPreview/WorldPreviewViewport/WorldPreviewRoot
@onready var terrain_mesh: MeshInstance3D = $VBoxContainer/HBoxContainer/CenterPreview/WorldPreviewViewport/WorldPreviewRoot/terrain_mesh
@onready var new_button: Button = $VBoxContainer/Toolbar/NewButton
@onready var load_button: Button = $VBoxContainer/Toolbar/LoadButton
@onready var save_button: Button = $VBoxContainer/Toolbar/SaveButton
@onready var export_button: Button = $VBoxContainer/Toolbar/ExportButton
@onready var fantasy_style_selector: OptionButton = $VBoxContainer/HBoxContainer/RightParametersPanel/ParametersScroll/ParametersVBox/FantasyStyleContainer/FantasyStyleSelector
@onready var preview_mode_selector: OptionButton = $VBoxContainer/HBoxContainer/RightParametersPanel/ParametersScroll/ParametersVBox/PreviewModeContainer/PreviewModeSelector

var active_section: PanelContainer = null

var world = null  # WorldData - type annotation removed for compatibility
var sections: Array = []  # Array[String] - stores scene paths
var current_tab: int = 0
var regeneration_timer: Timer = null
var is_regenerating: bool = false
var progress_dialog: Window = null
var progress_bar: ProgressBar = null  # Phase 4: Progress bar for chunk generation
const PROGRESS_DIALOG_SCENE = preload("res://scenes/ui/progress_dialog.tscn")
const DEFAULT_WORLD = preload("res://assets/worlds/default_world.tres")
const ExportUtils = preload("res://scripts/utils/export_utils.gd")


func _ready() -> void:
	"""Initialize World Creator UI and setup."""
	# Initialize world first
	if not world:
		world = DEFAULT_WORLD.duplicate()
	
	setup_regeneration_timer()
	setup_toolbar()
	setup_tabs()
	setup_sections()
	setup_preview_controls()
	setup_fantasy_style_selector()
	setup_preview_mode_selector()  # Phase 5: Preview mode selector
	load_world_defaults()
	_on_tab_selected(0)  # Start with seed & size
	update_preview()
	# Initialize map with default values
	if world:
		update_map(world.seed if world.seed > 0 else 12345, world.size_preset)

func setup_regeneration_timer() -> void:
	"""Create debounce timer for regeneration."""
	regeneration_timer = Timer.new()
	regeneration_timer.wait_time = 0.3
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_on_regeneration_timer_timeout)
	add_child(regeneration_timer)

func setup_toolbar() -> void:
	"""Setup toolbar button connections."""
	if new_button:
		new_button.pressed.connect(_on_new_world)
	if load_button:
		load_button.pressed.connect(_on_load_world)
	if save_button:
		save_button.pressed.connect(_on_save_world)
	if export_button:
		export_button.pressed.connect(_on_export_world)

func setup_tabs() -> void:
	"""Setup tab button connections."""
	var tab_list: VBoxContainer = $VBoxContainer/HBoxContainer/LeftPanel/TabList
	tab_buttons.clear()
	
	var tab_names := ["SeedSizeTabButton", "TerrainTabButton", "ClimateTabButton", "BiomesTabButton", "CivilizationsTabButton", "ResourcesMagicTabButton"]
	
	for i in range(tab_names.size()):
		var btn: Button = tab_list.get_node(tab_names[i])
		if btn:
			# Disconnect first to avoid duplicate connections
			if btn.pressed.is_connected(_on_tab_selected.bind(i)):
				btn.pressed.disconnect(_on_tab_selected.bind(i))
			btn.pressed.connect(_on_tab_selected.bind(i))
			tab_buttons.append(btn)
			btn.button_pressed = (i == 0)  # First tab selected by default

func setup_sections() -> void:
	"""Load all section scene paths (will instantiate on demand)."""
	sections.clear()
	
	# Store scene paths instead of instances
	for section_path in SECTION_SCENES:
		sections.append(section_path)

func setup_preview_controls() -> void:
	"""Setup preview panel controls."""
	# Connect world generation signals
	if world:
		if world.generation_complete.is_connected(_on_generation_complete):
			world.generation_complete.disconnect(_on_generation_complete)
		world.generation_complete.connect(_on_generation_complete)
		if world.generation_progress.is_connected(_on_generation_progress):
			world.generation_progress.disconnect(_on_generation_progress)
		world.generation_progress.connect(_on_generation_progress)
		# Phase 4: Connect chunk generation signal
		if world.has_signal("chunk_generated"):
			if world.chunk_generated.is_connected(_on_chunk_generated):
				world.chunk_generated.disconnect(_on_chunk_generated)
			world.chunk_generated.connect(_on_chunk_generated)
		# Connect style applied signal
		if world.style_applied.is_connected(_on_style_applied):
			world.style_applied.disconnect(_on_style_applied)
		world.style_applied.connect(_on_style_applied)
	
	# WorldPreview script should already be attached via scene
	if world_preview and not world_preview.get_script():
		var preview_script = load("res://scripts/preview/world_preview.gd")
		if preview_script:
			world_preview.set_script(preview_script)

func setup_fantasy_style_selector() -> void:
	"""Setup fantasy style selector with all 12 archetypes."""
	if not fantasy_style_selector:
		return
	
	fantasy_style_selector.clear()
	
	# Add items in order: None, Dark Sun, Eberron, then the 12 fantasy styles
	var styles: Array[String] = [
		"None",
		"Dark Sun",
		"Eberron",
		"High Fantasy",
		"Low Fantasy",
		"Grimdark",
		"Dark Fantasy",
		"Sword and Sorcery",
		"Epic Fantasy",
		"Urban Fantasy",
		"Steampunk Fantasy",
		"Weird Fantasy",
		"Fairy Tale Fantasy",
		"Heroic Fantasy",
		"Mythic Fantasy"
	]
	
	for style in styles:
		fantasy_style_selector.add_item(style)
	
	# Default to High Fantasy (index 3)
	fantasy_style_selector.select(3)
	
	# Connect signal
	if fantasy_style_selector.item_selected.is_connected(_on_fantasy_style_selected):
		fantasy_style_selector.item_selected.disconnect(_on_fantasy_style_selected)
	fantasy_style_selector.item_selected.connect(_on_fantasy_style_selected)

func setup_preview_mode_selector() -> void:
	"""Setup preview mode selector with all preview modes."""
	if not preview_mode_selector:
		return
	
	preview_mode_selector.clear()
	
	# Add preview modes
	var modes: Array[String] = [
		"Network",
		"Topographic",
		"Biome Color",
		"Foliage Density",
		"Full Render"
	]
	
	for mode in modes:
		preview_mode_selector.add_item(mode)
	
	# Default to Network (index 0)
	preview_mode_selector.select(0)
	
	# Connect signal
	if preview_mode_selector.item_selected.is_connected(_on_preview_mode_selected):
		preview_mode_selector.item_selected.disconnect(_on_preview_mode_selected)
	preview_mode_selector.item_selected.connect(_on_preview_mode_selected)

func _on_preview_mode_selected(index: int) -> void:
	"""Handle preview mode selection."""
	if not preview_mode_selector or not world_preview:
		return
	
	# Update world params
	if world:
		world.params["preview_mode"] = index
	
	# Update preview
	if world_preview.has_method("set_preview_mode"):
		world_preview.set_preview_mode(index)

func _on_fantasy_style_selected(index: int) -> void:
	"""Handle fantasy style selection."""
	if not fantasy_style_selector or not world:
		return
	
	var style_name: String = fantasy_style_selector.get_item_text(index)
	
	if style_name == "None":
		return
	
	# Check if it's an old preset file (Dark Sun, Eberron) or new fantasy style
	if style_name == "Dark Sun" or style_name == "Eberron":
		# Load old preset JSON file
		var preset_name: String = style_name.to_lower().replace(" ", "_")
		var preset_path: String = "res://assets/presets/" + preset_name + ".json"
		_load_preset_file(preset_path)
		update_preview()
	else:
		# Load new fantasy style preset - this will trigger generation and material update
		world.load_style_preset(style_name)

func _on_style_applied(style_name: String, color_tint: Color, invert_normals: bool) -> void:
	"""Handle style applied signal - update terrain material with style colors."""
	if not terrain_mesh:
		return
	
	var material: Material = terrain_mesh.material_override
	if not material or not material is ShaderMaterial:
		return
	
	var shader_material: ShaderMaterial = material as ShaderMaterial
	shader_material.set_shader_parameter("tint_color", color_tint)
	shader_material.set_shader_parameter("invert_normals", invert_normals)
	
	print("WorldCreator: Applied style '", style_name, "' - tint: ", color_tint, " invert: ", invert_normals)

func load_world_defaults() -> void:
	"""Load default world parameters."""
	# Set default params
	world.params = {
		"elevation": 30.0,
		"elevation_scale": 30.0,
		"terrain_chaos": 50.0,
		"noise_type": "Perlin",
		"frequency": 0.01,
		"humidity": 50.0,
		"temperature": 0.0,
		"precipitation": 50.0,
		"wind_strength": 30.0
	}
	
	world.randomness = {
		"terrain": 0.5,
		"climate": 0.3,
		"biomes": 0.4
	}
	
	# UI controls will be updated when sections are loaded

func _on_tab_selected(tab_idx: int) -> void:
	"""Handle tab selection."""
	for i in range(tab_buttons.size()):
		tab_buttons[i].button_pressed = (i == tab_idx)
	current_tab = tab_idx
	_load_section(tab_idx)

func _load_section(idx: int) -> void:
	"""Load and display the specified section."""
	# Clear previous section content (but preserve FantasyStyleContainer)
	for child in parameters_container.get_children():
		if child.name != "FantasyStyleContainer":
			child.queue_free()
	
	if idx < 0 or idx >= sections.size():
		return
	
	# Load and instance the section scene
	var section_path: String = sections[idx]
	var section_scene: PackedScene = load(section_path)
	if not section_scene:
		return
	
	var section: PanelContainer = section_scene.instantiate()
	if not section:
		return
	
	# Connect param_changed signal
	if section.has_signal("param_changed"):
		section.param_changed.connect(_on_param_changed)
	
	# Add to container
	parameters_container.add_child(section)
	active_section = section
	
	# Update section with current world params if available
	if world and section.has_method("set_params"):
		var section_params: Dictionary = {}
		if idx == 0:  # Seed & Size
			section_params["seed"] = world.seed if world.seed > 0 else 12345
			section_params["size_preset"] = world.size_preset
		else:
			section_params = world.params.duplicate()
		section.set_params(section_params)

func _on_param_changed(param: String, value: Variant) -> void:
	"""Handle parameter change from any section."""
	if not world:
		return
	
	# Handle special params
	if param == "seed":
		world.seed = int(value)
	elif param == "size_preset":
		world.size_preset = value as int
	elif param == "elevation_scale":
		world.params["elevation"] = value
		world.params["elevation_scale"] = value
	elif param == "noise_type":
		world.params["noise_type"] = value
	elif param == "enable_rivers":
		world.params["enable_rivers"] = value
	elif param == "terrain_chaos":
		world.randomness["terrain"] = value / 100.0  # Convert 0-100 to 0-1
	else:
		# Generic param update
		world.params[param] = value
	
	# Auto-propagate dependencies
	world.auto_propagate()
	
	# Queue regeneration with debounce
	queue_regeneration()

func queue_regeneration() -> void:
	"""Queue world regeneration with debounce."""
	if not regeneration_timer:
		return
	
	if regeneration_timer.is_stopped():
		regeneration_timer.start()
	else:
		regeneration_timer.start()  # Restart timer

func _on_regeneration_timer_timeout() -> void:
	"""Trigger regeneration after debounce."""
	if world and not is_regenerating:
		is_regenerating = true
		_show_progress_dialog()  # Phase 4: Show progress for chunk generation
		world.generate(false)  # Use preview resolution

func _on_generation_complete() -> void:
	"""Handle generation completion."""
	is_regenerating = false
	
	# Hide progress dialog
	if progress_dialog:
		progress_dialog.queue_free()
		progress_dialog = null
	
	# Update preview mesh
	if not world_preview:
		print("WorldCreator: ERROR - world_preview node is null")
		return
	
	if not world:
		print("WorldCreator: ERROR - world data is null")
		return
	
	if not world.generated_mesh:
		print("WorldCreator: ERROR - generated_mesh is null")
		return
	
	if world.generated_mesh.get_surface_count() == 0:
		print("WorldCreator: ERROR - generated_mesh has no surfaces")
		return
	
	if world_preview.has_method("update_mesh"):
		world_preview.update_mesh(world.generated_mesh)
	if world_preview.has_method("set_world_data"):
		world_preview.set_world_data(world)

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
	is_regenerating = false

func _on_generation_progress(progress: float) -> void:
	"""Handle generation progress updates."""
	# Phase 4: Update progress bar
	if progress_bar:
		progress_bar.value = progress * 100.0
	elif progress_dialog and progress_dialog.has_method("set_progress"):
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

func _on_chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh) -> void:
	"""Handle chunk generation for incremental preview updates.
	
	Args:
		chunk_x: Chunk X coordinate
		chunk_y: Chunk Y coordinate
		mesh: Generated chunk mesh
	"""
	# Phase 4: Update preview incrementally as chunks are generated
	if world_preview and world_preview.has_method("_on_chunk_generated"):
		world_preview._on_chunk_generated(chunk_x, chunk_y, mesh)

func _refresh_preview() -> void:
	"""Refresh the 3D preview (called when world parameters change)."""
	update_preview()

func update_preview() -> void:
	"""Update the 3D preview with current world data."""
	if world:
		world.generate(false)  # Use preview resolution

func adjust_camera(size: Vector2i) -> void:
	"""Adjust camera size based on world size."""
	var cam: Camera3D = $VBoxContainer/HBoxContainer/CenterPreview/WorldPreviewViewport/WorldPreviewRoot/Camera3D
	if cam:
		cam.size = max(size.x, size.y) * 1.2  # Slightly larger to fit

func update_map(seed: int, size_preset: int) -> void:
	"""Update the 3D topographic map with new seed and size.
	
	Args:
		seed: World generation seed
		size_preset: Size preset index (0=TINY(64), 1=SMALL(256), 2=MEDIUM(512), 3=LARGE(1024), 4=EPIC(2048))
	"""
	if not terrain_mesh:
		return
	
	# Map WorldData size presets to actual sizes
	var sizes: Dictionary = {
		0: Vector2i(64, 64),      # TINY
		1: Vector2i(256, 256),     # SMALL
		2: Vector2i(512, 512),     # MEDIUM
		3: Vector2i(1024, 1024),   # LARGE
		4: Vector2i(2048, 2048)     # EPIC
	}
	
	var world_size: Vector2i = sizes.get(size_preset, Vector2i(512, 512))
	
	# Update terrain generator properties
	if terrain_mesh.has_method("generate_terrain"):
		terrain_mesh.seed_value = seed
		terrain_mesh.world_size = world_size
		terrain_mesh.generate_terrain()
		# Adjust camera after generating terrain
		adjust_camera(world_size)

func _on_back_pressed() -> void:
	"""Return to main menu."""
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_generate_world_pressed() -> void:
	"""Generate final world and transition to character creation."""
	if not world:
		return
	
	# Store world data in singleton for character creation to access
	if GameData:
		GameData.current_world_data = {
			"world": world,
			"seed": world.seed,
			"size_preset": world.size_preset
		}
	
	# Generate world at full resolution
	world.generate(true)  # Force full resolution
	
	# Wait for generation to complete
	await world.generation_complete
	
	# Transition to character creation
	get_tree().change_scene_to_file(CHARACTER_CREATION_SCENE)

# Save/Load functionality
func _on_new_world() -> void:
	"""Create a new world from default."""
	if world:
		world = DEFAULT_WORLD.duplicate()
		load_world_defaults()
		queue_regeneration()

func _on_save_world() -> void:
	"""Save world to user://worlds/ folder with folder-based persistence."""
	var file_dialog: FileDialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.gworld", "World Files")
	file_dialog.title = "Save World"
	file_dialog.current_dir = "user://worlds/"
	file_dialog.file_selected.connect(_save_world_to_path)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _save_world_to_path(path: String) -> void:
	"""Save world to specified path with folder-based persistence."""
	# Ensure path uses .gworld extension
	if not path.ends_with(".gworld"):
		path += ".gworld"
	
	var world_dir: String = path.get_base_dir()
	var world_name: String = path.get_file().get_basename()
	
	# Create world folder if it doesn't exist
	var dir: DirAccess = DirAccess.open("user://")
	var world_folder: String = world_dir.path_join(world_name)
	if not dir.dir_exists(world_folder.trim_prefix("user://")):
		dir.make_dir_recursive(world_folder.trim_prefix("user://"))
	
	# Save binary resource
	var world_path: String = world_folder.path_join("data.gworld")
	var error: Error = ResourceSaver.save(world, world_path, ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		print("Error saving world: ", error)
		return
	
	# Save JSON backup
	var json_path: String = world_folder.path_join("data.json")
	var json_data: Dictionary = {
		"seed": world.seed,
		"size_preset": world.size_preset,
		"params": world.params.duplicate(),
		"randomness": world.randomness.duplicate()
	}
	
	var json_string: String = JSON.stringify(json_data, "\t")
	var file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	
	# Create assets/ and previews/ folders
	dir.make_dir_recursive(world_folder.trim_prefix("user://").path_join("assets"))
	dir.make_dir_recursive(world_folder.trim_prefix("user://").path_join("previews"))
	
	print("World saved to: ", world_path)

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
		world = loaded_world
		# Reload current section to update UI with loaded world params
		_load_section(current_tab)
		queue_regeneration()
	else:
		print("Error loading world from: ", path)

# Export functionality
func _on_export_world() -> void:
	"""Show export options menu."""
	var popup: PopupMenu = PopupMenu.new()
	popup.add_item("Export as Godot Scene (.tscn)")
	popup.add_item("Export as OBJ (.obj)")
	popup.add_item("Export as PDF Atlas (.pdf)")
	popup.add_separator()
	popup.add_item("Export Complete Atlas (Folder)")  # Phase 5: New export option
	popup.id_pressed.connect(_on_export_option_selected)
	add_child(popup)
	popup.popup_on_parent(Rect2i(export_button.global_position, Vector2i(200, 150)))

func _on_export_option_selected(id: int) -> void:
	"""Handle export option selection."""
	if not world or not world.generated_mesh:
		print("Error: No world or mesh to export")
		return
	
	var file_dialog: FileDialog = FileDialog.new()
	
	match id:
		0:  # Godot Scene
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.add_filter("*.tscn", "Godot Scene Files")
			file_dialog.title = "Export as Godot Scene"
			file_dialog.current_dir = "res://exports/"
			file_dialog.file_selected.connect(_export_godot_scene)
		1:  # OBJ
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.add_filter("*.obj", "OBJ Files")
			file_dialog.title = "Export as OBJ"
			file_dialog.current_dir = "res://exports/"
			file_dialog.file_selected.connect(_export_obj)
		2:  # PDF
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.add_filter("*.pdf", "PDF Files")
			file_dialog.title = "Export as PDF Atlas"
			file_dialog.current_dir = "res://exports/"
			file_dialog.file_selected.connect(_export_pdf)
		3:  # Phase 5: Export Atlas (folder)
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
			file_dialog.title = "Export Complete Atlas (Select Folder)"
			file_dialog.current_dir = "res://exports/"
			file_dialog.dir_selected.connect(_export_atlas)
	
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _export_godot_scene(path: String) -> void:
	"""Export world as Godot scene."""
	var base_path: String = path.get_basename()
	var error: Error = ExportUtils.export_godot_scene(world, base_path)
	if error == OK:
		print("Godot scene exported successfully")
	else:
		print("Error exporting Godot scene: ", error)

func _export_obj(path: String) -> void:
	"""Export world as OBJ."""
	if not path.ends_with(".obj"):
		path += ".obj"
	var error: Error = ExportUtils.export_obj(world, path)
	if error == OK:
		print("OBJ file exported successfully")
	else:
		print("Error exporting OBJ: ", error)

func _export_pdf(path: String) -> void:
	"""Export world as PDF atlas."""
	if not path.ends_with(".pdf"):
		path += ".pdf"
	# Take viewport screenshot first
	var screenshot_path: String = path.get_base_dir().path_join("world_map.png")
	viewport.get_viewport().get_texture().get_image().save_png(screenshot_path)
	
	var error: Error = ExportUtils.export_pdf_atlas(world, path, screenshot_path)
	if error == OK:
		print("PDF atlas exported successfully")
	else:
		print("Error exporting PDF: ", error)

func _export_atlas(dir_path: String) -> void:
	"""Export complete atlas to folder (Phase 5).
	
	Args:
		dir_path: Directory path for atlas export
	"""
	var error: Error = ExportUtils.export_atlas(world, dir_path)
	if error == OK:
		print("Complete atlas exported successfully to: ", dir_path)
	else:
		print("Error exporting atlas: ", error)

# Preset functionality (legacy support for Dark Sun and Eberron)

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
	
	# Merge preset params
	if preset_data.has("params"):
		world.params.merge(preset_data["params"], true)
	if preset_data.has("randomness"):
		world.randomness.merge(preset_data["randomness"], true)
	if preset_data.has("seed"):
		world.seed = preset_data["seed"]
	
	# Reload current section to update UI with preset params
	_load_section(current_tab)
	queue_regeneration()
