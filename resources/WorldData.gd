# ╔═══════════════════════════════════════════════════════════
# ║ WorldData.gd
# ║ Desc: Pure data container for world state – no generation logic
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name WorldData

extends Resource

@export var seed: int = 666
@export var world_radius_hexes: int = 1000
@export var hex_size_meters: float = 100.0
@export var height_scale: float = 1.0
