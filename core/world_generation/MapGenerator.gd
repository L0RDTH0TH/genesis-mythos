# ╔═══════════════════════════════════════════════════════════
# ║ MapGenerator.gd
# ║ Desc: Old 2D procedural map generation logic – REMOVED (switching to Azgaar integration)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name MapGenerator

## Generation thread (stub - no longer used)
var generation_thread: Thread

## Progress callback (stub - no longer used)
var progress_callback: Callable

## Biome transition width (stub - no longer used)
var biome_transition_width: float = 0.05

## Post-processing pipeline configuration (stub - no longer used)
var post_processing_config: Dictionary = {}


func _init() -> void:
	"""Initialize stub - old generator removed for Azgaar integration."""
	push_warning("MapGenerator: This script is deprecated – old generator removed for Azgaar integration")


func generate_map(world_map_data, use_thread: bool = true, preview_mode: bool = false) -> void:
	"""Stub - old procedural generation disabled."""
	print("Old procedural generation disabled – preparing for Azgaar integration")
	push_warning("MapGenerator.generate_map() called but old generation is disabled – Azgaar integration in progress")


func generate_biome_preview(world_map_data) -> void:
	"""Stub - old biome preview generation disabled."""
	print("Old biome preview generation disabled – preparing for Azgaar integration")
	push_warning("MapGenerator.generate_biome_preview() called but old generation is disabled – Azgaar integration in progress")
