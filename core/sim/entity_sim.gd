# ╔═══════════════════════════════════════════════════════════
# ║ EntitySim.gd
# ║ Desc: Entity simulation system for NPCs and dynamic entities
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	Logger.verbose("Sim/Entity", "_ready() called")
	Logger.info("Sim/Entity", "Entity simulation system initialized")
