# ╔═══════════════════════════════════════════════════════════
# ║ Eryndor.gd
# ║ Desc: Core singleton for Eryndor 4.0 Final - main game controller
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	MythosLogger.verbose("Core", "_ready() called")
	MythosLogger.info("Core", "Authentic engine initialized – the truth awakens.")
	MythosLogger.debug("Core", "Eryndor singleton ready", {"version": "4.0 Final"})
