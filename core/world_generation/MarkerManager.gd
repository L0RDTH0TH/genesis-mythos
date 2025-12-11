# ╔═══════════════════════════════════════════════════════════
# ║ MarkerManager.gd
# ║ Desc: Manages map markers (cities, ruins, forests, etc.) with icons and labels
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D
class_name MarkerManager

## Reference to world map data
var world_map_data: WorldMapData

## Marker scene/icon cache
var marker_icon_cache: Dictionary = {}  # icon_type -> Texture2D

## Marker nodes container
var markers_container: Node2D

## Visible marker groups (filters)
var visible_groups: Array[String] = []  # Empty = all visible


func _init() -> void:
	"""Initialize MarkerManager."""
	markers_container = Node2D.new()
	markers_container.name = "MarkersContainer"
	add_child(markers_container)


func set_world_map_data(data: WorldMapData) -> void:
	"""Set world map data and refresh markers."""
	world_map_data = data
	_refresh_markers()


func add_marker(position: Vector2, icon_type: String, label: String = "", note: String = "") -> void:
	"""Add a new marker to the map."""
	if world_map_data == null:
		push_error("MarkerManager: world_map_data is null")
		return
	
	# Add to data
	world_map_data.add_marker(position, icon_type, label, note)
	
	# Create visual marker node
	_create_marker_node(position, icon_type, label, world_map_data.markers.size() - 1)


func remove_marker(index: int) -> void:
	"""Remove marker by index."""
	if world_map_data == null:
		return
	
	world_map_data.remove_marker(index)
	_refresh_markers()


func clear_markers() -> void:
	"""Clear all markers."""
	if world_map_data != null:
		world_map_data.clear_markers()
	
	_clear_marker_nodes()


func set_group_visible(group_name: String, visible: bool) -> void:
	"""Show/hide marker group (e.g., "settlements", "resources")."""
	if visible and not visible_groups.has(group_name):
		visible_groups.append(group_name)
	elif not visible and visible_groups.has(group_name):
		visible_groups.erase(group_name)
	
	_update_marker_visibility()


func _refresh_markers() -> void:
	"""Refresh all marker nodes from world_map_data."""
	_clear_marker_nodes()
	
	if world_map_data == null:
		return
	
	for i in range(world_map_data.markers.size()):
		var marker_data: Dictionary = world_map_data.markers[i]
		_create_marker_node(
			marker_data.get("position", Vector2.ZERO),
			marker_data.get("icon_type", "default"),
			marker_data.get("label", ""),
			i
		)


func _create_marker_node(position: Vector2, icon_type: String, label: String, index: int) -> void:
	"""Create a visual marker node."""
	var marker_node: Marker2D = Marker2D.new()
	marker_node.name = "Marker_" + str(index)
	marker_node.position = position
	marker_node.set_meta("marker_index", index)
	marker_node.set_meta("icon_type", icon_type)
	
	# Try to load icon texture
	var icon_texture: Texture2D = _get_icon_texture(icon_type)
	if icon_texture != null:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = icon_texture
		sprite.scale = Vector2(0.5, 0.5)  # Scale down icons
		marker_node.add_child(sprite)
	else:
		# Fallback: use colored circle
		var color_rect: ColorRect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(16, 16)
		color_rect.color = _get_icon_color(icon_type)
		color_rect.position = Vector2(-8, -8)
		marker_node.add_child(color_rect)
	
	# Add label if provided
	if not label.is_empty():
		var label_node: Label = Label.new()
		label_node.text = label
		label_node.position = Vector2(0, -20)
		label_node.add_theme_color_override("font_color", Color.WHITE)
		label_node.add_theme_color_override("font_outline_color", Color.BLACK)
		label_node.add_theme_constant_override("outline_size", 2)
		marker_node.add_child(label_node)
	
	markers_container.add_child(marker_node)
	
	# Set visibility based on groups
	_update_marker_visibility_for_node(marker_node, icon_type)


func _get_icon_texture(icon_type: String) -> Texture2D:
	"""Get icon texture for marker type. Returns null if not found."""
	if marker_icon_cache.has(icon_type):
		return marker_icon_cache[icon_type]
	
	# Try to load from assets
	var icon_path: String = "res://assets/icons/map_" + icon_type + ".png"
	if ResourceLoader.exists(icon_path):
		var texture: Texture2D = load(icon_path)
		if texture != null:
			marker_icon_cache[icon_type] = texture
			return texture
	
	# Try alternative paths
	var alt_paths: Array[String] = [
		"res://assets/ui/" + icon_type + ".png",
		"res://assets/textures/" + icon_type + ".png"
	]
	
	for path in alt_paths:
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path)
			if texture != null:
				marker_icon_cache[icon_type] = texture
				return texture
	
	return null


func _get_icon_color(icon_type: String) -> Color:
	"""Get fallback color for marker type."""
	match icon_type:
		"city", "town", "village":
			return Color(1.0, 0.8, 0.0, 1.0)  # Gold
		"ruin":
			return Color(0.5, 0.5, 0.5, 1.0)  # Gray
		"forest":
			return Color(0.2, 0.6, 0.2, 1.0)  # Green
		"mountain":
			return Color(0.7, 0.7, 0.7, 1.0)  # Light gray
		"water":
			return Color(0.2, 0.4, 0.8, 1.0)  # Blue
		"desert":
			return Color(0.8, 0.7, 0.5, 1.0)  # Tan
		"swamp":
			return Color(0.3, 0.5, 0.3, 1.0)  # Dark green
		_:
			return Color(1.0, 1.0, 1.0, 1.0)  # White default


func _clear_marker_nodes() -> void:
	"""Clear all marker nodes."""
	for child in markers_container.get_children():
		child.queue_free()


func _update_marker_visibility() -> void:
	"""Update visibility of all markers based on visible_groups."""
	if visible_groups.is_empty():
		# Show all
		for child in markers_container.get_children():
			child.visible = true
		return
	
	# Show only markers in visible groups
	for child in markers_container.get_children():
		var icon_type: String = child.get_meta("icon_type", "")
		_update_marker_visibility_for_node(child, icon_type)


func _update_marker_visibility_for_node(node: Node, icon_type: String) -> void:
	"""Update visibility for a single marker node."""
	if visible_groups.is_empty():
		node.visible = true
		return
	
	# Determine marker group from icon type
	var marker_group: String = _get_marker_group(icon_type)
	node.visible = visible_groups.has(marker_group)


func _get_marker_group(icon_type: String) -> String:
	"""Get marker group name from icon type."""
	match icon_type:
		"city", "town", "village":
			return "settlements"
		"ruin", "forest", "mountain":
			return "features"
		"water", "desert", "swamp":
			return "terrain"
		_:
			return "other"


func get_marker_at_position(position: Vector2, radius: float = 50.0) -> int:
	"""Get marker index at position, or -1 if none found."""
	if world_map_data == null:
		return -1
	
	for i in range(world_map_data.markers.size()):
		var marker_data: Dictionary = world_map_data.markers[i]
		var marker_pos: Vector2 = marker_data.get("position", Vector2.ZERO)
		if marker_pos.distance_to(position) < radius:
			return i
	
	return -1