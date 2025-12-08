# ╔═══════════════════════════════════════════════════════════
# ║ MainMenuController.gd
# ║ Desc: Handles the two main menu buttons and scene navigation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name MainMenuController

extends Control

const CHARACTER_CREATION_SCENE : String = "res://ui/character_creation/CharacterCreation.tscn"
const MAIN_SCENE : String = "res://scenes/main.tscn"
const WORLD_CREATOR_SCENE : String = "res://scenes/WorldCreator.tscn"

# Static variable to tell main.tscn which tab to open
static var initial_tab: int = 0

@onready var character_button : Button = %CharacterCreationButton
@onready var world_button     : Button = %WorldCreationButton

func _ready() -> void:
	world_button.pressed.connect(_on_world_creation_pressed)
	character_button.pressed.connect(_on_character_creation_pressed)

func _on_character_creation_pressed() -> void:
	initial_tab = 0  # Character Creation tab
	get_tree().change_scene_to_file(MAIN_SCENE)

func _on_world_creation_pressed() -> void:
	"""Launch WorldCreator scene instead of skipping to character creation."""
	get_tree().change_scene_to_file(WORLD_CREATOR_SCENE)

