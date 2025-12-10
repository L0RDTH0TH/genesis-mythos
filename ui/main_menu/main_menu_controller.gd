# ╔═══════════════════════════════════════════════════════════
# ║ MainMenuController.gd
# ║ Desc: Handles the main menu buttons and scene navigation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name MainMenuController

extends Control

const CHARACTER_CREATION_SCENE : String = "res://scenes/character_creation/CharacterCreationRoot.tscn"
const WORLD_CREATION_SCENE : String = "res://core/scenes/world_root.tscn"

@onready var character_button : Button = %CharacterCreationButton
@onready var world_button     : Button = %WorldCreationButton

func _ready() -> void:
	"""Initialize button connections and visibility."""
	if character_button:
		character_button.visible = true
		character_button.pressed.connect(_on_create_character_pressed)
	
	if world_button:
		world_button.visible = true
		world_button.pressed.connect(_on_create_world_pressed)

func _on_create_character_pressed() -> void:
	"""Transition to character creation scene."""
	# TODO: Add transition animation if needed
	get_tree().change_scene_to_file(CHARACTER_CREATION_SCENE)

func _on_create_world_pressed() -> void:
	"""Transition to world creation scene."""
	# TODO: Add transition animation if needed
	get_tree().change_scene_to_file(WORLD_CREATION_SCENE)

