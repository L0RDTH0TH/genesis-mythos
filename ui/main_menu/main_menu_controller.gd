# ╔═══════════════════════════════════════════════════════════
# ║ MainMenuController.gd
# ║ Desc: Handles the main menu buttons and scene navigation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name MainMenuController

extends Control

const MAIN_SCENE : String = "res://scenes/main.tscn"

@onready var character_button : Button = %CharacterCreationButton
@onready var world_button     : Button = %WorldCreationButton

func _ready() -> void:
	# Disable buttons that reference deleted systems
	if character_button:
		character_button.visible = false
	if world_button:
		world_button.visible = false

