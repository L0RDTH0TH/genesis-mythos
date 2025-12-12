# ╔═══════════════════════════════════════════════════════════
# ║ FactionEconomy.gd
# ║ Desc: Faction and economy simulation system
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	Logger.verbose("Sim/Economy", "_ready() called")
	Logger.info("Sim/Economy", "Faction economy system initialized")
