# ╔═══════════════════════════════════════════════════════════
# ║ FactionEconomy.gd
# ║ Desc: Faction and economy simulation system
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	MythosLogger.verbose("Sim/Economy", "_ready() called")
	MythosLogger.info("Sim/Economy", "Faction economy system initialized")
