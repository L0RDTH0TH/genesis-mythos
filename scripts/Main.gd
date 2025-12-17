# ╔═══════════════════════════════════════════════════════════
# ║ Main.gd
# ║ Desc: Entry point of the game
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Node2D

@onready var new_character_button: Button = $UI/CenterContainer/VBoxContainer/NewCharacterButton

func _ready() -> void:
	MythosLogger.verbose("Bootstrap", "Main _ready() started - testing log write")
	_apply_ui_constants()
	MythosLogger.info("Bootstrap", "Main _ready() complete")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	if new_character_button != null:
		new_character_button.custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_MEDIUM)

