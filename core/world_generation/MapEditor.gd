# ╔═══════════════════════════════════════════════════════════
# ║ MapEditor.gd
# ║ Desc: Brush-based map editing tools (raise/lower, smooth, paint rivers, presets)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D
class_name MapEditor

## Reference to world map data
var world_map_data: WorldMapData

## Current editing tool
enum EditTool {
	RAISE,      # Raise height
	LOWER,      # Lower height
	SMOOTH,     # Smooth terrain
	SHARPEN,    # Sharpen terrain
	RIVER,      # Paint rivers (force low paths)
	MOUNTAIN,   # Preset: Add mountain
	CRATER,     # Preset: Add crater
	ISLAND      # Preset: Add island
}

var current_tool: EditTool = EditTool.RAISE

## Brush parameters
var brush_radius: float = 50.0
var brush_strength: float = 0.1
var brush_falloff: float = 0.5  # 0.0 = hard edge, 1.0 = smooth falloff

## Is currently painting (mouse held down)
var is_painting: bool = false
var last_paint_position: Vector2 = Vector2.ZERO


func set_world_map_data(data: WorldMapData) -> void:
	"""Set world map data for editing."""
	world_map_data = data


func set_tool(tool: EditTool) -> void:
	"""Set current editing tool."""
	current_tool = tool
	print("MapEditor: Tool set to ", EditTool.keys()[tool])


func set_brush_radius(radius: float) -> void:
	"""Set brush radius in world units."""
	brush_radius = max(1.0, radius)


func set_brush_strength(strength: float) -> void:
	"""Set brush strength (0.0 - 1.0)."""
	brush_strength = clamp(strength, 0.0, 1.0)


func start_paint(world_position: Vector2) -> void:
	"""Start painting at world position."""
	if world_map_data == null or world_map_data.heightmap_image == null:
		return
	
	is_painting = true
	last_paint_position = world_position
	world_map_data.save_heightmap_to_history()
	_apply_paint(world_position)


func continue_paint(world_position: Vector2) -> void:
	"""Continue painting (called while mouse is dragged)."""
	if not is_painting:
		return
	
	# Interpolate between last position and current to avoid gaps
	var distance: float = last_paint_position.distance_to(world_position)
	if distance > brush_radius * 0.5:
		var steps: int = int(distance / (brush_radius * 0.3))
		for i in range(steps + 1):
			var t: float = float(i) / float(steps + 1)
			var pos: Vector2 = last_paint_position.lerp(world_position, t)
			_apply_paint(pos)
	
	last_paint_position = world_position


func end_paint() -> void:
	"""End painting operation."""
	is_painting = false


func _apply_paint(world_position: Vector2) -> void:
	"""Apply brush effect at world position."""
	if world_map_data == null or world_map_data.heightmap_image == null:
		return
	
	var img: Image = world_map_data.heightmap_image
	var size: Vector2i = img.get_size()
	
	# Convert world position to image coordinates
	# World coordinates are centered at origin, image coordinates start at (0,0)
	var world_center: Vector2 = Vector2(world_map_data.world_width / 2.0, world_map_data.world_height / 2.0)
	var normalized_pos: Vector2 = (world_position + world_center) / Vector2(world_map_data.world_width, world_map_data.world_height)
	
	# Clamp to valid range
	normalized_pos.x = clamp(normalized_pos.x, 0.0, 1.0)
	normalized_pos.y = clamp(normalized_pos.y, 0.0, 1.0)
	
	var center_pixel: Vector2i = Vector2i(int(normalized_pos.x * float(size.x)), int((1.0 - normalized_pos.y) * float(size.y)))
	
	# Calculate affected pixel bounds
	var radius_pixels: int = int(brush_radius * float(size.x) / float(world_map_data.world_width))
	radius_pixels = max(1, radius_pixels)  # Ensure at least 1 pixel
	var min_x: int = max(0, center_pixel.x - radius_pixels)
	var max_x: int = min(size.x - 1, center_pixel.x + radius_pixels)
	var min_y: int = max(0, center_pixel.y - radius_pixels)
	var max_y: int = min(size.y - 1, center_pixel.y + radius_pixels)
	
	img.lock()
	
	match current_tool:
		EditTool.RAISE:
			_paint_raise(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
		EditTool.LOWER:
			_paint_lower(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
		EditTool.SMOOTH:
			_paint_smooth(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
		EditTool.SHARPEN:
			_paint_sharpen(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
		EditTool.RIVER:
			_paint_river(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
		EditTool.MOUNTAIN:
			_paint_mountain(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
		EditTool.CRATER:
			_paint_crater(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
		EditTool.ISLAND:
			_paint_island(img, center_pixel, min_x, max_x, min_y, max_y, radius_pixels)
	
	img.unlock()


func _paint_raise(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Raise height in brush area."""
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if distance > radius:
				continue
			
			var falloff: float = 1.0 - (distance / float(radius))
			falloff = pow(falloff, 1.0 / (brush_falloff + 0.1))
			
			var current_color: Color = img.get_pixel(x, y)
			var current_height: float = current_color.r
			var new_height: float = clamp(current_height + brush_strength * falloff * 0.1, 0.0, 1.0)
			img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))


func _paint_lower(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Lower height in brush area."""
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if distance > radius:
				continue
			
			var falloff: float = 1.0 - (distance / float(radius))
			falloff = pow(falloff, 1.0 / (brush_falloff + 0.1))
			
			var current_color: Color = img.get_pixel(x, y)
			var current_height: float = current_color.r
			var new_height: float = clamp(current_height - brush_strength * falloff * 0.1, 0.0, 1.0)
			img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))


func _paint_smooth(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Smooth terrain in brush area."""
	var temp_img: Image = img.duplicate()
	temp_img.lock()
	img.lock()
	
	for y in range(min_y + 1, max_y):
		for x in range(min_x + 1, max_x):
			var distance: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if distance > radius:
				continue
			
			var falloff: float = 1.0 - (distance / float(radius))
			falloff = pow(falloff, 1.0 / (brush_falloff + 0.1))
			
			# Average neighboring pixels
			var sum: float = 0.0
			var count: int = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var px: int = x + dx
					var py: int = y + dy
					if px >= 0 and px < img.get_size().x and py >= 0 and py < img.get_size().y:
						sum += temp_img.get_pixel(px, py).r
						count += 1
			
			var avg_height: float = sum / float(count)
			var current_height: float = temp_img.get_pixel(x, y).r
			var new_height: float = lerp(current_height, avg_height, brush_strength * falloff)
			img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))
	
	temp_img.unlock()


func _paint_sharpen(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Sharpen terrain (increase contrast) in brush area."""
	# Similar to smooth but opposite - increase height differences
	# Simplified: just raise higher areas more
	_paint_raise(img, center, min_x, max_x, min_y, max_y, radius)


func _paint_river(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Paint river (force low height) in brush area."""
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if distance > radius:
				continue
			
			var falloff: float = 1.0 - (distance / float(radius))
			
			var current_color: Color = img.get_pixel(x, y)
			var current_height: float = current_color.r
			# Force height below sea level
			var target_height: float = world_map_data.sea_level * 0.3
			var new_height: float = lerp(current_height, target_height, brush_strength * falloff)
			img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))


func _paint_mountain(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Paint mountain preset (raised cone)."""
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if distance > radius:
				continue
			
			var normalized_distance: float = distance / float(radius)
			var height_contribution: float = (1.0 - normalized_distance) * brush_strength
			
			var current_color: Color = img.get_pixel(x, y)
			var current_height: float = current_color.r
			var new_height: float = clamp(current_height + height_contribution * 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))


func _paint_crater(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Paint crater preset (lowered bowl)."""
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if distance > radius:
				continue
			
			var normalized_distance: float = distance / float(radius)
			var depth_contribution: float = (1.0 - normalized_distance) * brush_strength
			
			var current_color: Color = img.get_pixel(x, y)
			var current_height: float = current_color.r
			var new_height: float = clamp(current_height - depth_contribution * 0.3, 0.0, 1.0)
			img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))


func _paint_island(img: Image, center: Vector2i, min_x: int, max_x: int, min_y: int, max_y: int, radius: int) -> void:
	"""Paint island preset (raised above sea level)."""
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if distance > radius:
				continue
			
			var normalized_distance: float = distance / float(radius)
			var height_contribution: float = (1.0 - normalized_distance) * brush_strength
			
			var current_color: Color = img.get_pixel(x, y)
			var current_height: float = current_color.r
			# Ensure island is above sea level
			var target_height: float = world_map_data.sea_level + 0.2
			var new_height: float = lerp(current_height, target_height, height_contribution)
			img.set_pixel(x, y, Color(new_height, new_height, new_height, 1.0))


func undo() -> bool:
	"""Undo last edit. Returns true if undo was successful."""
	if world_map_data == null:
		return false
	
	return world_map_data.undo_heightmap()