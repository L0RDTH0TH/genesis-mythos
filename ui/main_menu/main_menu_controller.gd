# ╔═══════════════════════════════════════════════════════════
# ║ MainMenuController.gd
# ║ Desc: Handles the main menu buttons and scene navigation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name MainMenuController

extends Control

const CHARACTER_CREATION_SCENE: String = "res://scenes/character_creation/CharacterCreationRoot.tscn"
const WORLD_CREATION_SCENE: String = "res://core/scenes/world_root.tscn"

@onready var character_button: Button = %CharacterCreationButton
@onready var world_button: Button = %WorldCreationButton
@onready var vbox_container: VBoxContainer = $CenterContainer/VBoxContainer

func _ready() -> void:
	"""Initialize button connections and visibility."""
	# Apply UIConstants for consistent sizing
	_apply_ui_constants()
	
	if character_button:
		character_button.visible = true
		character_button.pressed.connect(_on_create_character_pressed)
	
	if world_button:
		world_button.visible = true
		world_button.pressed.connect(_on_create_world_pressed)

func _notification(what: int) -> void:
	"""Handle window resize events for responsive UI."""
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_WM_SIZE_CHANGED:
		# Ensure UI elements stay within bounds on resize
		_ensure_ui_bounds()

func _apply_ui_constants() -> void:
	"""Apply UIConstants values to UI elements for consistency."""
	if character_button:
		character_button.custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_MEDIUM)
	if world_button:
		world_button.custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_MEDIUM)
	
	# Apply spacing to GGVBox container using UIConstants
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", UIConstants.SPACING_LARGE)

func _ensure_ui_bounds() -> void:
	"""Ensure UI elements stay within viewport bounds on window resize."""
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	# CenterContainer handles centering automatically, but we ensure root is properly sized
	if size != viewport_size:
		size = viewport_size

func _on_create_character_pressed() -> void:
	"""Transition to character creation scene."""
	# TODO: Add transition animation if needed
	get_tree().change_scene_to_file(CHARACTER_CREATION_SCENE)

func _on_create_world_pressed() -> void:
	"""Transition to world creation scene."""
	# TODO: Add transition animation if needed
	get_tree().change_scene_to_file(WORLD_CREATION_SCENE)
