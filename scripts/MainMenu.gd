# ╔═══════════════════════════════════════════════════════════
# ║ MainMenu.gd
# ║ Desc: Main menu scene entry point
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Control

func _ready() -> void:
	MythosLogger.verbose("UI/MainMenu", "_ready() called")
	MythosLogger.info("UI/MainMenu", "Main menu scene initialized")

