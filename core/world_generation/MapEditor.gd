# ╔═══════════════════════════════════════════════════════════
# ║ MapEditor.gd
# ║ Desc: Old brush-based map editing logic – REMOVED (switching to Azgaar integration)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D
class_name MapEditor

## Reference to world map data (stub - no longer used)
var world_map_data

## Current editing tool (kept for interface compatibility)
enum EditTool {
	RAISE,           # Raise height
	LOWER,           # Lower height
	SMOOTH,          # Smooth terrain
	SHARPEN,         # Sharpen terrain
	RIVER,           # Paint rivers (force low paths)
	MOUNTAIN,        # Preset: Add mountain
	CRATER,          # Preset: Add crater
	ISLAND,          # Preset: Add island
	BIOME_PAINT,     # Paint biome colors directly
	TEMPERATURE,     # Paint temperature adjustments
	MOISTURE         # Paint moisture adjustments
}

var current_tool: EditTool = EditTool.RAISE

## Brush parameters (stub - no longer used)
var brush_radius: float = 50.0
var brush_strength: float = 0.1
var brush_falloff: float = 0.5

## Is currently painting (stub - no longer used)
var is_painting: bool = false


func _init() -> void:
	"""Initialize stub - old editor removed for Azgaar integration."""
	push_warning("MapEditor: This script is deprecated – old editing removed for Azgaar integration")


func set_world_map_data(data) -> void:
	"""Stub - old editing disabled."""
	world_map_data = data
	print("Old map editing disabled – preparing for Azgaar integration")


func set_tool(tool: EditTool) -> void:
	"""Stub - tool set but editing disabled."""
	current_tool = tool
	print("Old map tool set (editing disabled) – preparing for Azgaar integration")


func set_brush_radius(radius: float) -> void:
	"""Stub - brush radius set but editing disabled."""
	brush_radius = max(1.0, radius)


func set_brush_strength(strength: float) -> void:
	"""Stub - brush strength set but editing disabled."""
	brush_strength = clamp(strength, 0.0, 1.0)


func start_paint(world_position: Vector2) -> void:
	"""Stub - old editing disabled."""
	is_painting = true
	print("Old map painting disabled – preparing for Azgaar integration")


func continue_paint(world_position: Vector2) -> void:
	"""Stub - old editing disabled."""
	if not is_painting:
		return
	print("Old map painting disabled – preparing for Azgaar integration")


func end_paint() -> void:
	"""Stub - old editing disabled."""
	is_painting = false
	print("Old map painting disabled – preparing for Azgaar integration")
