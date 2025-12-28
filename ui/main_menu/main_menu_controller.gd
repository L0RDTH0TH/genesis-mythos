# ╔═══════════════════════════════════════════════════════════
# ║ MainMenuController.gd
# ║ Desc: Handles the main menu buttons and scene navigation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name MainMenuController

extends Control

const CHARACTER_CREATION_SCENE: String = "res://scenes/character_creation/CharacterCreationRoot.tscn"
const WORLD_CREATION_SCENE: String = "res://scenes/ui/WorldBuilderUI.tscn"

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
	
	# OLD: WorldGenerator instantiation removed (old generation disabled for Azgaar integration)
	# Create progress bar UI (kept for interface compatibility, but won't be used)
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
	
	# GUI Performance Fix: Apply title styling via modulate (not theme overrides)
	var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
	if title_label:
		title_label.modulate = Color(0.95, 0.85, 0.6, 1.0)  # Gold-tinted color

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
	"""Transition to world builder with async loading and progress updates."""
	# Show loading overlay immediately for instant visual feedback
	LoadingOverlay.show_loading("Loading World Builder...", 0.0)
	
	# Critical: yield to ensure overlay draws before any blocking work
	await get_tree().process_frame
	
	# Start threaded scene loading
	ResourceLoader.load_threaded_request(WORLD_CREATION_SCENE)
	
	# Poll for load completion with progress updates
	var load_stage: int = 0
	var total_stages: int = 10  # Estimate: 10 stages for loading
	
	while true:
		var load_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(WORLD_CREATION_SCENE)
		
		match load_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# Update progress: 0-30% during scene loading
				load_stage += 1
				var progress: float = min((float(load_stage) / float(total_stages)) * 30.0, 30.0)
				LoadingOverlay.update_progress("Loading World Builder...", progress)
				await get_tree().process_frame
			
			ResourceLoader.THREAD_LOAD_LOADED:
				# Scene loaded successfully
				LoadingOverlay.update_progress("Initializing world...", 30.0)
				await get_tree().process_frame
				
				# Get the loaded scene
				var packed_scene: PackedScene = ResourceLoader.load_threaded_get(WORLD_CREATION_SCENE)
				if packed_scene == null:
					MythosLogger.error("MainMenuController", "Failed to get loaded scene")
					LoadingOverlay.hide_loading()
					return
				
				# Change to loaded scene
				get_tree().change_scene_to_packed(packed_scene)
				break
			
			ResourceLoader.THREAD_LOAD_FAILED:
				# Loading failed
				MythosLogger.error("MainMenuController", "Failed to load world scene")
				LoadingOverlay.update_progress("Failed to load world scene", 0.0)
				await get_tree().create_timer(2.0).timeout
				LoadingOverlay.hide_loading()
				return
			
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				# Invalid resource path
				MythosLogger.error("MainMenuController", "Invalid scene path: %s" % WORLD_CREATION_SCENE)
				LoadingOverlay.update_progress("Invalid scene path", 0.0)
				await get_tree().create_timer(2.0).timeout
				LoadingOverlay.hide_loading()
				return
			
			_:
				# Unknown status, wait and retry
				await get_tree().process_frame


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
	# GUI Performance Fix: Font size handled by theme, no override needed
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
	"""Stub - old generation progress handling disabled (preparing for Azgaar integration)."""
	print("Old generation progress disabled – preparing for Azgaar integration")


func _on_generation_complete(data: Dictionary) -> void:
	"""Stub - old generation completion handling disabled (preparing for Azgaar integration)."""
	print("Old generation completion disabled – preparing for Azgaar integration")
