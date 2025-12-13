# ╔═══════════════════════════════════════════════════════════
# ║ Main.gd
# ║ Desc: Entry point of the game
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Node2D

func _ready() -> void:
	Logger.verbose("Bootstrap", "Main _ready() started - testing log write")
	Logger.info("Bootstrap", "Main _ready() complete")

