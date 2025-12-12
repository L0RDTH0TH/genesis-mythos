# ╔═══════════════════════════════════════════════════════════
# ║ Eryndor.gd
# ║ Desc: Core singleton for Eryndor 4.0 Final - main game controller
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	Logger.verbose("Core", "_ready() called")
	Logger.info("Core", "Authentic engine initialized – the truth awakens.")
	Logger.debug("Core", "Eryndor singleton ready", {"version": "4.0 Final"})
