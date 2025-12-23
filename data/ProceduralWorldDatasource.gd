# ╔═══════════════════════════════════════════════════════════
# ║ ProceduralWorldDatasource.gd
# ║ Desc: Old custom datasource for ProceduralWorldMap addon – REMOVED (switching to Azgaar integration)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends "res://addons/procedural_world_map/datasource.gd"

## Fantasy archetype configuration (stub - no longer used)
var archetype: Dictionary = {}

## Landmass type (stub - no longer used)
var landmass_type: String = "Continents"

## Landmass type configurations (stub - no longer used)
var landmass_configs: Dictionary = {}


func _init() -> void:
	"""Initialize stub - old datasource removed for Azgaar integration."""
	push_warning("ProceduralWorldDatasource: This script is deprecated – old generator removed for Azgaar integration")
	super._init()


func configure_from_archetype(arch: Dictionary, landmass: String, seed_value: int) -> void:
	"""Stub - old configuration disabled."""
	print("Old procedural datasource configuration disabled – preparing for Azgaar integration")
	push_warning("ProceduralWorldDatasource.configure_from_archetype() called but old generation is disabled – Azgaar integration in progress")


func get_biome_image(camera_zoomed_size: Vector2i) -> ImageTexture:
	"""Stub - returns empty blue texture."""
	var default_img: Image = Image.create(camera_zoomed_size.x, camera_zoomed_size.y, false, Image.FORMAT_RGB8)
	default_img.fill(Color.BLUE)
	return ImageTexture.create_from_image(default_img)
