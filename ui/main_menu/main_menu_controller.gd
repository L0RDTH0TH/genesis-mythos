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

## WorldGenerator instance (stub - no longer used, kept for interface compatibility)
var world_generator

## Progress bar for world generation (stub - no longer used)
var progress_bar: ProgressBar
var progress_label: Label

func _ready() -> void:
	"""Initialize button connections and visibility."""
	# Apply UIConstants for consistent sizing
	_apply_ui_constants()
	
	# Progress bar UI is now pre-created in .tscn (see ProgressContainer)
	# Get references if they exist
	progress_bar = get_node_or_null("ProgressContainer/ProgressBar") as ProgressBar
	progress_label = get_node_or_null("ProgressContainer/ProgressLabel") as Label
	if progress_bar:
		progress_bar.visible = false
	if progress_label:
		progress_label.visible = false
	
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
	
	# Apply spacing to VBoxContainer using UIConstants
	# Note: Theme constant override for separation is acceptable for container spacing
	# (documented exception for layout constants)
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", UIConstants.SPACING_LARGE)
	
	# Apply UIConstants to progress container (pre-created in .tscn)
	var progress_container: VBoxContainer = get_node_or_null("ProgressContainer") as VBoxContainer
	if progress_container:
		progress_container.custom_minimum_size = Vector2(UIConstants.PROGRESS_BAR_WIDTH, 0)
		progress_container.offset_top = UIConstants.PROGRESS_BAR_MARGIN_TOP
		progress_container.offset_left = -UIConstants.PROGRESS_BAR_WIDTH / 2
		progress_container.offset_right = UIConstants.PROGRESS_BAR_WIDTH / 2
	if progress_bar:
		progress_bar.custom_minimum_size = Vector2(UIConstants.PROGRESS_BAR_WIDTH, UIConstants.PROGRESS_BAR_HEIGHT)

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
	"""Stub - old world generation disabled (preparing for Azgaar integration)."""
	print("World Builder: Old generator disabled – Azgaar integration in progress")
	push_warning("MainMenuController._on_create_world_pressed() called but old generation is disabled – Azgaar integration in progress")
	# Transition to world scene (UI still works, just generation is disabled)
	get_tree().change_scene_to_file(WORLD_CREATION_SCENE)


# GUI Performance Fix: Progress bar UI is now pre-created in .tscn file
# This method is kept for compatibility but no longer creates nodes at runtime
func _setup_progress_bar() -> void:
	"""Setup progress bar UI for world generation (nodes pre-created in .tscn)."""
	# Progress bar nodes are now pre-created in .tscn to avoid runtime node creation
	# References are obtained in _ready() via get_node_or_null()
	pass


func _on_generation_progress(phase: String, percent: float) -> void:
	"""Stub - old generation progress handling disabled (preparing for Azgaar integration)."""
	print("Old generation progress disabled – preparing for Azgaar integration")


func _on_generation_complete(data: Dictionary) -> void:
	"""Stub - old generation completion handling disabled (preparing for Azgaar integration)."""
	print("Old generation completion disabled – preparing for Azgaar integration")
