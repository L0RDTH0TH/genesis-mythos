# ╔═══════════════════════════════════════════════════════════
# ║ WorldMapData.gd
# ║ Desc: Resource storing world map data (heightmap, parameters, markers, undo history)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Resource
class_name WorldMapData

## World generation seed
@export var seed: int = 12345

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


func create_heightmap(size_x: int, size_y: int, format: Image.Format = Image.FORMAT_RF) -> Image:
	"""Create a new heightmap Image with specified size and format."""
	var img: Image = Image.create(size_x, size_y, false, format)
	heightmap_image = img
	world_width = size_x
	world_height = size_y
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