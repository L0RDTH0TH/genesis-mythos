# ╔═══════════════════════════════════════════════════════════
# ║ EntitySim.gd
# ║ Desc: Entity simulation system for NPCs and dynamic entities
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	MythosLogger.verbose("Sim/Entity", "_ready() called")
	MythosLogger.info("Sim/Entity", "Entity simulation system initialized")
