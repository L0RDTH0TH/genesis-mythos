# ╔═══════════════════════════════════════════════════════════
# ║ WorldGenerator.gd
# ║ Desc: Old threaded world generation manager – REMOVED (switching to Azgaar integration)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node
class_name WorldGenerator

## Generation thread (stub - no longer used)
var generation_thread: Thread

## Signal emitted when generation completes with result data
signal generation_complete(data: Dictionary)

## Signal emitted during generation with phase name and progress (0.0-1.0)
signal progress_update(phase: String, percent: float)

## Current generation config loaded from JSON (stub - no longer used)
var current_config: Dictionary = {}

## Internal MapGenerator instance (stub - no longer used)
var map_generator

## Current WorldMapData being generated (stub - no longer used)
var current_world_data


func _ready() -> void:
	"""Initialize stub - old generator removed for Azgaar integration."""
	push_warning("WorldGenerator: This script is deprecated – old generator removed for Azgaar integration")


func start_generation() -> void:
	"""Stub - old generation disabled."""
	print("Old world generation disabled – preparing for Azgaar integration")
	push_warning("WorldGenerator.start_generation() called but old generation is disabled – Azgaar integration in progress")


func is_generating() -> bool:
	"""Stub - always returns false."""
	return false


func _exit_tree() -> void:
	"""Clean up thread on exit (stub - no-op)."""
	pass
