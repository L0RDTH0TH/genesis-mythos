# ╔═══════════════════════════════════════════════════════════
# ║ MapRenderer.gd
# ║ Desc: Old map rendering logic – REMOVED (switching to Azgaar integration)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D
class_name MapRenderer

## Reference to world map data (stub - no longer used)
var world_map_data

## Rendering view mode (kept for interface compatibility)
enum ViewMode { HEIGHTMAP, BIOMES, POLITICAL }
var current_view_mode: ViewMode = ViewMode.BIOMES

## Refresh mode for adaptive throttling (kept for interface compatibility)
enum RefreshMode { INTERACTIVE, GENERATION, REGENERATION }
@export var current_refresh_mode: RefreshMode = RefreshMode.INTERACTIVE

## TextureRect, ColorRect, or Sprite2D for rendering (stub - no longer used)
var render_target: Node


func _init() -> void:
	"""Initialize stub - old renderer removed for Azgaar integration."""
	push_warning("MapRenderer: This script is deprecated – old rendering removed for Azgaar integration")


func setup_render_target(target: Node) -> void:
	"""Stub - old rendering disabled."""
	render_target = target
	print("Old map rendering disabled – preparing for Azgaar integration")


func set_world_map_data(data) -> void:
	"""Stub - old rendering disabled."""
	world_map_data = data
	print("Old map rendering disabled – preparing for Azgaar integration")


func set_view_mode(mode: ViewMode) -> void:
	"""Stub - view mode set but rendering disabled."""
	current_view_mode = mode
	print("Old map view mode set (rendering disabled) – preparing for Azgaar integration")


func set_refresh_mode(mode: RefreshMode) -> void:
	"""Stub - refresh mode set but rendering disabled."""
	current_refresh_mode = mode


func refresh(batched_changes: Dictionary = {}) -> void:
	"""Stub - refresh disabled."""
	print("Old map refresh disabled – preparing for Azgaar integration")


func _refresh_mode_to_string(mode: RefreshMode) -> String:
	"""Convert RefreshMode enum to string (kept for interface compatibility)."""
	match mode:
		RefreshMode.INTERACTIVE:
			return "INTERACTIVE"
		RefreshMode.GENERATION:
			return "GENERATION"
		RefreshMode.REGENERATION:
			return "REGENERATION"
		_:
			return "UNKNOWN"
