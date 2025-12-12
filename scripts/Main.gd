# ╔═══════════════════════════════════════════════════════════
# ║ Main.gd
# ║ Desc: Entry point of the game
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Node2D

func _ready() -> void:
	Logger.verbose("Core/Main", "_ready() called")
	Logger.info("Core/Main", "Main scene initialized")

