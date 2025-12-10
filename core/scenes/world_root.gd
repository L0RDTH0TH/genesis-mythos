# ╔═══════════════════════════════════════════════════════════
# ║ WorldRoot.gd
# ║ Desc: Main world root scene - entry point for Eryndor 4.0 Final
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node3D

## Preload terrain classes
const Terrain3DManager = preload("res://core/world_generation/Terrain3DManager.gd")
const TerrainGenerationConfig = preload("res://core/world_generation/TerrainGenerationConfig.gd")

## Terrain3D manager instance
var terrain_manager: Terrain3DManager = null

## World builder UI instance
var world_builder_ui = null

## Path to terrain generation config
const TERRAIN_CONFIG_PATH: String = "res://data/config/terrain_generation.json"


func _ready() -> void:
	_initialize_terrain_system()
	_setup_world_builder_ui()


func _initialize_terrain_system() -> void:
	# Create terrain manager (load class explicitly)
	var manager_class = load("res://core/world_generation/Terrain3DManager.gd")
	terrain_manager = manager_class.new()
	
	# Initialize terrain (creates Terrain3D node programmatically)
	var data_directory: String = "user://terrain3d/"
	var terrain = terrain_manager.initialize_terrain(self, data_directory)
	
	# Load config from JSON
	var config_class = load("res://core/world_generation/TerrainGenerationConfig.gd")
	var config: Dictionary = config_class.load_from_json(TERRAIN_CONFIG_PATH)
	
	if not config.is_empty():
		# Apply terrain settings from config
		var terrain_settings: Dictionary = config_class.get_terrain_settings(config)
		terrain.region_size = terrain_settings.get("region_size", 1024)
		terrain.mesh_size = terrain_settings.get("mesh_size", 64)
		terrain.vertex_spacing = terrain_settings.get("vertex_spacing", 1.0)
		
		# Generate initial terrain from config
		var noise_config: Dictionary = config_class.get_noise_config(config)
		var height_config: Dictionary = config_class.get_height_config(config)
		
		terrain_manager.generate_from_noise(
			noise_config.get("seed", 0),
			noise_config.get("frequency", 0.0005),
			height_config.get("min", 0.0),
			height_config.get("max", 150.0)
		)
	else:
		# Fallback: generate with default parameters
		terrain_manager.generate_from_noise(12345, 0.0005, 0.0, 150.0)
	
	# Enable dynamic collision for player movement
	terrain_manager.enable_dynamic_collision(true)


func _setup_world_builder_ui() -> void:
	"""Setup and display the world builder UI overlay."""
	print("WorldRoot: Setting up WorldBuilderUI...")
	
	# Load and instance WorldBuilderUI scene
	var ui_scene: PackedScene = load("res://ui/world_builder/WorldBuilderUI.tscn")
	if ui_scene == null:
		push_error("WorldRoot: Failed to load WorldBuilderUI scene")
		return
	
	world_builder_ui = ui_scene.instantiate()
	if world_builder_ui == null:
		push_error("WorldRoot: Failed to instantiate WorldBuilderUI")
		return
	
	print("WorldRoot: WorldBuilderUI instantiated successfully")
	
	# Verify it's the correct type
	if not world_builder_ui.has_method("set_terrain_manager"):
		push_error("WorldRoot: Instantiated node is not WorldBuilderUI")
		return
	
	# Add UI to scene tree as a CanvasLayer child for proper overlay
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "UICanvasLayer"
	add_child(canvas_layer, true)
	canvas_layer.add_child(world_builder_ui, true)
	
	print("WorldRoot: WorldBuilderUI added to scene tree")
	
	# Apply project theme
	var theme: Theme = load("res://themes/bg3_theme.tres")
	if theme != null:
		world_builder_ui.theme = theme
		print("WorldRoot: Theme applied to WorldBuilderUI")
	else:
		push_warning("WorldRoot: Failed to load bg3_theme.tres")
	
	# Connect UI to terrain manager
	world_builder_ui.set_terrain_manager(terrain_manager)
	print("WorldRoot: Terrain manager connected to WorldBuilderUI")
	
	# Position UI - make it larger and more visible (80% width, 80% height)
	world_builder_ui.anchor_left = 0.0
	world_builder_ui.anchor_top = 0.0
	world_builder_ui.anchor_right = 0.8
	world_builder_ui.anchor_bottom = 0.8
	world_builder_ui.offset_left = 10.0
	world_builder_ui.offset_top = 10.0
	
	# Ensure UI is visible
	world_builder_ui.visible = true
	world_builder_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	
	print("WorldRoot: WorldBuilderUI positioned and made visible")
	print("WorldRoot: UI size: ", world_builder_ui.size, " position: ", world_builder_ui.position)


func _exit_tree() -> void:
	# Cleanup terrain manager
	if terrain_manager != null:
		terrain_manager.cleanup()
		terrain_manager = null
