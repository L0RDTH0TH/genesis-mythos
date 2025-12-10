# ╔═══════════════════════════════════════════════════════════
# ║ Terrain3DManager.gd
# ║ Desc: Manages procedural world terrain using Terrain3D (GDExtension-safe)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends Node3D
class_name Terrain3DManager

const TERRAIN_CONFIG_PATH: String = "res://config/terrain_config.json"

@export var data_directory: String = "res://terrain_data/"
@export var assets_resource: Resource

var terrain = null  # Intentionally untyped – avoids parser error

func _ready() -> void:
	load_config()
	create_terrain()
	configure_terrain()

func load_config() -> void:
	if ResourceLoader.exists(TERRAIN_CONFIG_PATH):
		var file := FileAccess.open(TERRAIN_CONFIG_PATH, FileAccess.READ)
		var json_text := file.get_as_text()
		var parsed: Variant = JSON.parse_string(json_text)
		if parsed is Dictionary:
			data_directory = parsed.get("data_dir", data_directory)
			# add more config keys here in the future
	else:
		# default config
		DirAccess.make_dir_recursive_absolute("res://config")
		var default := { "data_dir": data_directory }
		var file := FileAccess.open(TERRAIN_CONFIG_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(default, "  "))

func create_terrain() -> void:
	if terrain:
		terrain.queue_free()

	# Check if Terrain3D class exists before trying to instantiate
	if not ClassDB.class_exists("Terrain3D"):
		push_error("FATAL: Terrain3D GDExtension not loaded! Check plugin is enabled in Project Settings > Plugins")
		return
	
	terrain = ClassDB.instantiate("Terrain3D")
	if not terrain:
		push_error("FATAL: Terrain3D instantiation failed!")
		return

	add_child(terrain)
	terrain.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	terrain.name = "WorldTerrain"
	print("Terrain3DManager: Successfully created Terrain3D node")

func configure_terrain() -> void:
	if not terrain:
		return

	# Basic settings – make these data-driven later
	terrain.vertex_spacing = 1.0
	terrain.region_size = 1024

	# Data directory
	if data_directory:
		DirAccess.make_dir_recursive_absolute(data_directory)
		terrain.data_directory = data_directory

	# Assets (materials, textures, etc.)
	if assets_resource:
		terrain.assets = assets_resource

# Example public method for procedural generation later
func generate_initial_terrain() -> void:
	if terrain and ResourceLoader.exists("res://assets/heightmap.png"):
		var img := load("res://assets/heightmap.png") as Image
		if img:
			terrain.create_from_heightmap_image(img)
