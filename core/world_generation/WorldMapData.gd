# ╔═══════════════════════════════════════════════════════════
# ║ WorldMapData.gd
# ║ Desc: Resource storing world map data (heightmap, parameters, markers, undo history)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Resource
class_name WorldMapData

## World generation seed (main seed)
@export var seed: int = 12345

## Sub-seeds for different systems (allows partial randomization)
var height_seed: int = -1      # -1 = use main seed
var biome_seed: int = -1        # -1 = use main seed
var climate_seed: int = -1      # -1 = use main seed
var erosion_seed: int = -1      # -1 = use main seed
var river_seed: int = -1        # -1 = use main seed

## Seed locks (prevent randomization of specific systems)
var height_seed_locked: bool = false
var biome_seed_locked: bool = false
var climate_seed_locked: bool = false

## World size in units
@export var world_width: int = 1000
@export var world_height: int = 1000

## Heightmap Image (grayscale, 0-255 or float format)
@export var heightmap_image: Image

## Noise generation parameters
@export var noise_type: int = FastNoiseLite.TYPE_PERLIN
@export var noise_frequency: float = 0.0005
@export var noise_octaves: int = 4
@export var noise_persistence: float = 0.5
@export var noise_lacunarity: float = 2.0

## Erosion parameters
@export var erosion_enabled: bool = true
@export var erosion_strength: float = 0.3
@export var erosion_iterations: int = 5

## Sea level (0.0 - 1.0, normalized height)
@export var sea_level: float = 0.4

## Rivers parameters
@export var rivers_enabled: bool = true
@export var river_count: int = 10
@export var river_start_elevation: float = 0.7  # Normalized height to start rivers

## Biome generation parameters
@export var biome_temperature_noise_frequency: float = 0.002
@export var biome_moisture_noise_frequency: float = 0.002

## Climate bias parameters (for regional adjustments)
var temperature_bias: float = 0.0
var moisture_bias: float = 0.0

## Regional climate adjustments (from MapEditor painting)
## Key: "x,y" -> {temp: float, moist: float}
var regional_climate_adjustments: Dictionary = {}

## Landmass type (Continents, Single Island, etc.)
@export var landmass_type: String = "Continents"

## Markers array (Array of Dictionary: {position: Vector2, icon_type: String, label: String, note: String})
@export var markers: Array[Dictionary] = []

## Undo history (Array of Image copies, limited size)
var undo_history: Array[Image] = []
const MAX_UNDO_HISTORY: int = 20

## Biome preview image (optional, cached)
var biome_preview_image: Image


func _init() -> void:
	"""Initialize WorldMapData with default values."""
	if heightmap_image == null:
		heightmap_image = Image.create(1024, 1024, false, Image.FORMAT_RF)
		heightmap_image.fill(Color.BLACK)
	_update_sub_seeds()


func _update_sub_seeds() -> void:
	"""Update sub-seeds from main seed if not locked."""
	if not height_seed_locked or height_seed == -1:
		height_seed = seed if height_seed == -1 else height_seed
	if not biome_seed_locked or biome_seed == -1:
		biome_seed = seed if biome_seed == -1 else biome_seed
	if not climate_seed_locked or climate_seed == -1:
		climate_seed = seed if climate_seed == -1 else climate_seed
	if not erosion_seed == -1:
		erosion_seed = seed if erosion_seed == -1 else erosion_seed
	if not river_seed == -1:
		river_seed = seed if river_seed == -1 else river_seed


func set_seed(new_seed: int, update_sub_seeds: bool = true) -> void:
	"""Set main seed and optionally update sub-seeds."""
	seed = new_seed
	if update_sub_seeds:
		_update_sub_seeds()


func get_effective_seed(system: String) -> int:
	"""Get effective seed for a specific system."""
	match system:
		"height":
			return height_seed if height_seed >= 0 else seed
		"biome":
			return biome_seed if biome_seed >= 0 else seed
		"climate":
			return climate_seed if climate_seed >= 0 else seed
		"erosion":
			return erosion_seed if erosion_seed >= 0 else seed
		"river":
			return river_seed if river_seed >= 0 else seed
		_:
			return seed


func create_heightmap(size_x: int, size_y: int, format: Image.Format = Image.FORMAT_RF) -> Image:
	"""Create a new heightmap Image with specified size and format.
	
	Note: This function creates an image of the specified size. The world_width and world_height
	should be set separately before calling this function if they differ from the image size.
	"""
	var img: Image = Image.create(size_x, size_y, false, format)
	heightmap_image = img
	# Don't overwrite world_width/height - they should be set by the caller
	# This allows the image size to match world dimensions when explicitly set
	return img


func save_heightmap_to_history() -> void:
	"""Save current heightmap to undo history."""
	if heightmap_image == null:
		return
	
	# Duplicate current heightmap
	var copy: Image = heightmap_image.duplicate()
	undo_history.append(copy)
	
	# Limit history size
	if undo_history.size() > MAX_UNDO_HISTORY:
		undo_history.pop_front()


func undo_heightmap() -> bool:
	"""Restore previous heightmap from undo history. Returns true if undo was successful."""
	if undo_history.is_empty():
		return false
	
	heightmap_image = undo_history.pop_back()
	return true


func add_marker(position: Vector2, icon_type: String, label: String = "", note: String = "") -> void:
	"""Add a marker to the map."""
	markers.append({
		"position": position,
		"icon_type": icon_type,
		"label": label,
		"note": note
	})


func remove_marker(index: int) -> void:
	"""Remove a marker by index."""
	if index >= 0 and index < markers.size():
		markers.remove_at(index)


func clear_markers() -> void:
	"""Clear all markers."""
	markers.clear()


func get_elevation_at(position: Vector2) -> float:
	"""Get elevation (0.0 - 1.0) at world position. Returns 0.0 if out of bounds."""
	if heightmap_image == null:
		return 0.0
	
	var img_size: Vector2i = heightmap_image.get_size()
	var x: int = int(position.x + world_width / 2.0)
	var y: int = int(position.y + world_height / 2.0)
	
	if x < 0 or x >= img_size.x or y < 0 or y >= img_size.y:
		return 0.0
	
	# Get pixel color (grayscale height)
	var color: Color = heightmap_image.get_pixel(x, img_size.y - 1 - y)  # Flip Y
	return color.r  # For RF format, use red channel for height


func is_underwater(position: Vector2) -> bool:
	"""Check if position is underwater based on sea level."""
	return get_elevation_at(position) < sea_level


func save_to_file(file_path: String) -> bool:
	"""Save world map data to file (variant format)."""
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		MythosLogger.error("World/Data", "Failed to save WorldMapData to " + file_path)
		return false
	
	# Save as Resource (Godot's native format)
	var error: Error = ResourceSaver.save(self, file_path)
	file.close()
	
	if error != OK:
		MythosLogger.error("World/Data", "Failed to save WorldMapData: " + str(error))
		return false
	
	MythosLogger.info("World/Data", "Saved WorldMapData to " + file_path)
	return true


func load_from_file(file_path: String) -> bool:
	"""Load world map data from file."""
	if not FileAccess.file_exists(file_path):
		MythosLogger.error("World/Data", "File does not exist: " + file_path)
		return false
	
	var loaded_data: Resource = load(file_path)
	if loaded_data == null or not loaded_data is WorldMapData:
		MythosLogger.error("World/Data", "Failed to load WorldMapData from " + file_path)
		return false
	
	# Copy properties from loaded data
	var source: WorldMapData = loaded_data as WorldMapData
	seed = source.seed
	world_width = source.world_width
	world_height = source.world_height
	heightmap_image = source.heightmap_image.duplicate() if source.heightmap_image != null else null
	biome_preview_image = source.biome_preview_image.duplicate() if source.biome_preview_image != null else null
	noise_type = source.noise_type
	noise_frequency = source.noise_frequency
	noise_octaves = source.noise_octaves
	noise_persistence = source.noise_persistence
	noise_lacunarity = source.noise_lacunarity
	sea_level = source.sea_level
	landmass_type = source.landmass_type
	markers = source.markers.duplicate()
	regional_climate_adjustments = source.regional_climate_adjustments.duplicate()
	
	# Copy sub-seeds
	height_seed = source.height_seed
	biome_seed = source.biome_seed
	climate_seed = source.climate_seed
	erosion_seed = source.erosion_seed
	river_seed = source.river_seed
	height_seed_locked = source.height_seed_locked
	biome_seed_locked = source.biome_seed_locked
	climate_seed_locked = source.climate_seed_locked
	
	MythosLogger.info("World/Data", "Loaded WorldMapData from " + file_path)
	return true