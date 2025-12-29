# ╔═══════════════════════════════════════════════════════════
# ║ AzgaarDataConverter.gd
# ║ Desc: Utility for converting Azgaar fork JSON data to Godot Images and extracted features
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name AzgaarDataConverter
extends RefCounted

const BUCKET_COUNT: int = 32
const MIN_LAND_HEIGHT: int = 20
const MAX_HEIGHT: int = 100
const FORMAT_HEIGHTMAP: int = Image.FORMAT_RF

"""
Converts Azgaar JSON height data to a rasterized Godot Image.
Uses spatial hashing for efficient nearest-neighbor lookup during rasterization.
:param json_data: Dictionary from getMapData() with 'settings', 'grid' keys
:return: Image with normalized heights (0.0-1.0 float in red channel)
"""
func convert_to_heightmap(json_data: Dictionary) -> Image:
	var settings: Dictionary = json_data.get("settings", {})
	var width: int = settings.get("width", 1024)
	var height: int = settings.get("height", 1024)
	
	var grid: Dictionary = json_data.get("grid", {})
	var cells: Dictionary = grid.get("cells", {})
	var points: Array = grid.get("points", [])  # Array of [x: float, y: float]
	var heights: Array = cells.get("h", [])  # Array of int (0-100)
	
	var num_cells: int = heights.size()
	if num_cells == 0 or points.size() != num_cells:
		push_error("Invalid Azgaar data: mismatched points and heights")
		return Image.new()
	
	# Build spatial hash: buckets[Vector2i] = Array[cell_id]
	var bucket_size_x: float = float(width) / BUCKET_COUNT
	var bucket_size_y: float = float(height) / BUCKET_COUNT
	var buckets: Dictionary = {}
	for cell_id in num_cells:
		var pt: Array = points[cell_id]
		var bx: int = floor(pt[0] / bucket_size_x)
		var by: int = floor(pt[1] / bucket_size_y)
		var key: Vector2i = Vector2i(bx, by)
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(cell_id)
	
	# Create and fill image
	var img: Image = Image.create(width, height, false, FORMAT_HEIGHTMAP)
	for px in width:
		for py in height:
			var bx: int = floor(px / bucket_size_x)
			var by: int = floor(py / bucket_size_y)
			
			# Collect candidates from 3x3 buckets
			var candidates: Array = []
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var nkey: Vector2i = Vector2i(bx + dx, by + dy)
					if buckets.has(nkey):
						candidates += buckets[nkey]
			
			if candidates.is_empty():
				continue  # Fallback to 0 if no cells (rare)
			
			# Find nearest cell
			var min_dist: float = INF
			var closest_h: int = 0
			for cid in candidates:
				var pt: Array = points[cid]
				var dist: float = (pt[0] - px) * (pt[0] - px) + (pt[1] - py) * (pt[1] - py)
				if dist < min_dist:
					min_dist = dist
					closest_h = heights[cid]
			
			# Normalize: water=0, land remapped 0-1
			var norm: float = 0.0
			if closest_h >= MIN_LAND_HEIGHT:
				norm = remap(closest_h, MIN_LAND_HEIGHT, MAX_HEIGHT, 0.0, 1.0)
			
			img.set_pixel(px, py, Color(norm, 0.0, 0.0, 1.0))
	
	return img

"""
Extracts biome data per cell.
:return: Dictionary {cell_id: biome_name} using pack.biomes for names
"""
func extract_biomes(json_data: Dictionary) -> Dictionary:
	var pack: Dictionary = json_data.get("pack", {})
	var cells: Dictionary = pack.get("cells", {})
	var biomes_data: Array = pack.get("biomes", [])  # Array of biome names
	var cell_biomes: Array = cells.get("biome", [])  # Array of biome indices per cell
	
	var result: Dictionary = {}
	for cell_id in cell_biomes.size():
		var biome_idx: int = cell_biomes[cell_id]
		if biome_idx >= 0 and biome_idx < biomes_data.size():
			result[cell_id] = biomes_data[biome_idx]
	
	return result

"""
Extracts river data as array of river objects.
:return: Array of Dictionaries, each with 'cells' (array of cell_ids), 'name', etc.
"""
func extract_rivers(json_data: Dictionary) -> Array:
	var pack: Dictionary = json_data.get("pack", {})
	var rivers: Array = pack.get("rivers", [])  # Array of river dicts from Azgaar
	
	return rivers  # Direct return; can process further if needed (e.g., paths)
