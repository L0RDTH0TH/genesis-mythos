# ╔═══════════════════════════════════════════════════════════
# ║ Main.gd
# ║ Desc: Entry point of the game
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Node2D

func _ready() -> void:
	MythosLogger.verbose("Bootstrap", "Main _ready() started - testing log write")
	MythosLogger.info("Bootstrap", "Main _ready() complete")

