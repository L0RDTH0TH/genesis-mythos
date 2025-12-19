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

## WorldGenerator instance for threaded world generation
var world_generator

## Preload WorldGenerator to ensure it's available
const WorldGeneratorScript = preload("res://core/world_generation/WorldGenerator.gd")

## Progress bar for world generation
var progress_bar: ProgressBar
var progress_label: Label

func _ready() -> void:
	"""Initialize button connections and visibility."""
	# Apply UIConstants for consistent sizing
	_apply_ui_constants()
	
	# Create WorldGenerator instance
	world_generator = WorldGeneratorScript.new()
	add_child(world_generator)
	world_generator.progress_update.connect(_on_generation_progress)
	world_generator.generation_complete.connect(_on_generation_complete)
	
	# Create progress bar UI
	_setup_progress_bar()
	
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
	"""Start threaded world generation."""
	if world_generator == null:
		MythosLogger.error("MainMenuController", "WorldGenerator is null, cannot start generation")
		return
	
	if world_generator.is_generating():
		MythosLogger.warn("MainMenuController", "Generation already in progress")
		return
	
	# Show progress bar
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0.0
	if progress_label:
		progress_label.visible = true
		progress_label.text = "Initializing..."
	
	# Disable world button during generation
	if world_button:
		world_button.disabled = true
	
	# Start generation
	world_generator.start_generation()
	MythosLogger.info("MainMenuController", "World generation started")


func _setup_progress_bar() -> void:
	"""Setup progress bar UI for world generation."""
	# Create container for progress bar
	var progress_container: VBoxContainer = VBoxContainer.new()
	progress_container.name = "ProgressContainer"
	progress_container.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
	
	# Position container (centered, below buttons)
	progress_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progress_container.offset_top = UIConstants.PROGRESS_BAR_MARGIN_TOP
	progress_container.custom_minimum_size = Vector2(UIConstants.PROGRESS_BAR_WIDTH, 0)
	add_child(progress_container)
	
	# Create progress label
	progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "Ready"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.visible = false
	progress_container.add_child(progress_label)
	
	# Create progress bar
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(UIConstants.PROGRESS_BAR_WIDTH, UIConstants.PROGRESS_BAR_HEIGHT)
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.visible = false
	progress_container.add_child(progress_bar)


func _on_generation_progress(phase: String, percent: float) -> void:
	"""Handle generation progress updates."""
	if progress_bar:
		progress_bar.value = percent
	if progress_label:
		progress_label.text = "%s: %.0f%%" % [phase, percent * 100.0]
	MythosLogger.debug("MainMenuController", "Generation progress: %s - %.1f%%" % [phase, percent * 100.0])


func _on_generation_complete(data: Dictionary) -> void:
	"""Handle generation completion."""
	MythosLogger.info("MainMenuController", "World generation complete", {
		"total_time_ms": data.get("total_time_ms", 0.0)
	})
	
	# Hide progress bar
	if progress_bar:
		progress_bar.visible = false
	if progress_label:
		progress_label.visible = false
	
	# Re-enable world button
	if world_button:
		world_button.disabled = false
	
	# Store generated world data (could be passed to world scene)
	# For now, transition to world scene
	# TODO: Pass generated data to world scene
	get_tree().change_scene_to_file(WORLD_CREATION_SCENE)
