# ╔═══════════════════════════════════════════════════════════
# ║ IconNode.gd
# ║ Desc: 2D icon node for map canvas representing terrain features
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D
class_name IconNode

## Icon ID from map_icons.json
var icon_id: String = ""

## Icon type (e.g., "jungle", "pine", "redwood")
var icon_type: String = ""

## Position on map canvas
var map_position: Vector2 = Vector2.ZERO

## Icon color from JSON
var icon_color: Color = Color.WHITE

## Reference to visual representation (can be Control or Sprite2D)
var sprite: Node = null


func _ready() -> void:
	"""Initialize icon visual representation."""
	_create_visual()


func _create_visual() -> void:
	"""Create visual representation of icon."""
	# Create a simple colored rectangle as placeholder
	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(32, 32)
	rect.position = Vector2(-16, -16)  # Center the rect
	rect.color = icon_color
	add_child(rect)
	
	# Add a simple border
	var border: ColorRect = ColorRect.new()
	border.size = Vector2(34, 34)
	border.position = Vector2(-17, -17)
	border.color = Color(0.85, 0.7, 0.4, 1.0)  # Gold border from theme
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	border.move_child(rect, -1)  # Move border behind rect


func set_icon_data(id: String, color: Color, type: String = "") -> void:
	"""Set icon data from JSON configuration."""
	icon_id = id
	icon_color = color
	icon_type = type
	if sprite != null:
		sprite.modulate = icon_color


func get_distance_to(other: IconNode) -> float:
	"""Calculate distance to another icon node."""
	if sprite != null and sprite is Control:
		var this_pos: Vector2 = (sprite as Control).position
		var other_pos: Vector2 = (other.sprite as Control).position if other.sprite is Control else other.position
		return this_pos.distance_to(other_pos)
	return position.distance_to(other.position)
