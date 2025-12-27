# ╔═══════════════════════════════════════════════════════════
# ║ CharacterCreationRoot.gd
# ║ Desc: Main controller for character creation wizard
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## Character creation steps (wizard-style flow)
const STEPS: Array[String] = [
	"Race",
	"Class",
	"Background",
	"Ability Scores",
	"Appearance",
	"Name & Confirm"
]

## Tab scene paths
const TAB_SCENES: Array[String] = [
	"res://scenes/character_creation/tabs/RaceTab.tscn",
	"res://scenes/character_creation/tabs/ClassTab.tscn",
	"res://scenes/character_creation/tabs/BackgroundTab.tscn",
	"res://scenes/character_creation/tabs/AbilityScoreTab.tscn",
	"res://scenes/character_creation/tabs/AppearanceTab.tscn",
	"res://scenes/character_creation/tabs/NameConfirmTab.tscn"
]

## Current step index
var current_step: int = 0

## Step data storage
var step_data: Dictionary = {}

## UI node references
@onready var options_container: VBoxContainer = $MainContainer/ContentArea/LeftPanel/LeftContent/OptionsContainer
@onready var preview_viewport: SubViewport = $MainContainer/ContentArea/RightPanel/PreviewContainer/PreviewViewport
@onready var preview_world: Node3D = $MainContainer/ContentArea/RightPanel/PreviewContainer/PreviewViewport/PreviewWorld
@onready var preview_camera: Camera3D = $MainContainer/ContentArea/RightPanel/PreviewContainer/PreviewViewport/PreviewWorld/PreviewCamera
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton

## Current tab instance
var current_tab_instance: Control = null


func _ready() -> void:
	"""Initialize character creation UI."""
	MythosLogger.verbose("UI/CharacterCreation", "_ready() called")
	_apply_ui_constants()
	_setup_navigation()
	_setup_step_content()
	_update_navigation_buttons()
	MythosLogger.info("UI/CharacterCreation", "Character creation wizard ready")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	# Set right panel width to ~40% using split offset
	var content_area: HSplitContainer = $MainContainer/ContentArea
	if content_area != null:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		content_area.split_offset = int(viewport_size.x * 0.6)  # Left panel gets 60%, right gets 40%
	
	# Apply button heights
	if back_button != null:
		back_button.custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_MEDIUM)
	if next_button != null:
		next_button.custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_MEDIUM)
	
	# Apply spacing to containers
	if options_container != null:
		options_container.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)
	
	# GUI Performance Fix: Apply title styling via modulate (not theme overrides)
	var title_label: Label = $MainContainer/TitleArea/TitleLabel
	if title_label:
		title_label.modulate = Color(1.0, 0.843, 0.0, 1.0)  # Gold color


func _setup_navigation() -> void:
	"""Setup navigation button connections."""
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if next_button != null:
		next_button.pressed.connect(_on_next_pressed)


func _setup_step_content() -> void:
	"""Setup content for current step."""
	_load_step(current_step)


func _load_step(step_index: int) -> void:
	"""Load content for a specific step."""
	if step_index < 0 or step_index >= STEPS.size():
		MythosLogger.error("UI/CharacterCreation", "Invalid step index: %d" % step_index)
		return
	
	# Clear current tab
	if current_tab_instance != null:
		current_tab_instance.queue_free()
		current_tab_instance = null
	
	# Load actual tab scene
	var step_name: String = STEPS[step_index]
	var tab_scene_path: String = TAB_SCENES[step_index]
	
	var tab_scene: PackedScene = load(tab_scene_path)
	if tab_scene == null:
		MythosLogger.error("UI/CharacterCreation", "Failed to load tab scene: %s" % tab_scene_path)
		_create_placeholder_tab(step_name)
		return
	
	current_tab_instance = tab_scene.instantiate()
	if current_tab_instance == null:
		MythosLogger.error("UI/CharacterCreation", "Failed to instantiate tab scene: %s" % tab_scene_path)
		_create_placeholder_tab(step_name)
		return
	
	# Connect tab signals
	_connect_tab_signals(current_tab_instance, step_index)
	
	options_container.add_child(current_tab_instance)
	MythosLogger.debug("UI/CharacterCreation", "Loaded step: %s" % step_name)


func _create_placeholder_tab(step_name: String) -> void:
	"""Create placeholder tab content (fallback if tab scene fails to load)."""
	var container: VBoxContainer = VBoxContainer.new()
	container.add_theme_constant_override("separation", UIConstants.SPACING_LARGE)
	
	var title_label: Label = Label.new()
	title_label.text = step_name
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1, 0.843137, 0, 1))
	container.add_child(title_label)
	
	var description_label: Label = Label.new()
	description_label.text = "This step will be implemented in future updates."
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(description_label)
	
	options_container.add_child(container)
	current_tab_instance = container


func _connect_tab_signals(tab_instance: Control, step_index: int) -> void:
	"""Connect signals from tab instance to root controller."""
	if tab_instance.has_signal("race_selected"):
		tab_instance.race_selected.connect(_on_race_selected)
	if tab_instance.has_signal("class_selected"):
		tab_instance.class_selected.connect(_on_class_selected)
	if tab_instance.has_signal("background_selected"):
		tab_instance.background_selected.connect(_on_background_selected)
	if tab_instance.has_signal("ability_scores_changed"):
		tab_instance.ability_scores_changed.connect(_on_ability_scores_changed)
	if tab_instance.has_signal("appearance_changed"):
		tab_instance.appearance_changed.connect(_on_appearance_changed)
	if tab_instance.has_signal("character_confirmed"):
		tab_instance.character_confirmed.connect(_on_character_confirmed)


func _update_navigation_buttons() -> void:
	"""Update navigation button states based on current step."""
	if back_button != null:
		back_button.visible = current_step > 0
		back_button.disabled = current_step == 0
	
	if next_button != null:
		if current_step == STEPS.size() - 1:
			next_button.text = "Confirm"
		else:
			next_button.text = "Next"


func _on_back_pressed() -> void:
	"""Handle back button press."""
	if current_step > 0:
		current_step -= 1
		_load_step(current_step)
		_update_navigation_buttons()
		MythosLogger.debug("UI/CharacterCreation", "Navigated to step: %d" % current_step)


func _on_next_pressed() -> void:
	"""Handle next/confirm button press."""
	if current_step < STEPS.size() - 1:
		# Save current step data
		_save_step_data()
		current_step += 1
		_load_step(current_step)
		_update_navigation_buttons()
		MythosLogger.debug("UI/CharacterCreation", "Navigated to step: %d" % current_step)
	else:
		# Final confirmation
		_confirm_character_creation()


func _save_step_data() -> void:
	"""Save data from current step."""
	var step_name: String = STEPS[current_step]
	# Data is saved automatically via signal handlers
	MythosLogger.debug("UI/CharacterCreation", "Saved data for step: %s" % step_name)
	
	# Update NameConfirmTab summary if we're moving to it
	if current_step == STEPS.size() - 2:  # Next step is Name & Confirm
		_update_name_confirm_summary()


func _update_name_confirm_summary() -> void:
	"""Update the summary in NameConfirmTab."""
	if current_tab_instance != null and current_tab_instance.has_method("set_character_summary"):
		var summary: Dictionary = {
			"race": step_data.get("race", "Unknown"),
			"class": step_data.get("class", "Unknown"),
			"background": step_data.get("background", "Unknown")
		}
		current_tab_instance.set_character_summary(summary)


func _confirm_character_creation() -> void:
	"""Handle final character creation confirmation."""
	MythosLogger.info("UI/CharacterCreation", "Character creation confirmed")
	# TODO: Implement character creation completion logic
	# For now, return to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_race_selected(race_id: String, race_data: Dictionary) -> void:
	"""Handle race selection from RaceTab."""
	step_data["race"] = race_id
	step_data["race_data"] = race_data
	MythosLogger.debug("UI/CharacterCreation", "Race selected: %s" % race_id)
	# Update ability scores with racial bonuses if AbilityScoreTab is loaded
	_update_racial_bonuses(race_data.get("ability_bonuses", {}))


func _on_class_selected(class_id: String, class_data: Dictionary) -> void:
	"""Handle class selection from ClassTab."""
	step_data["class"] = class_id
	step_data["class_data"] = class_data
	MythosLogger.debug("UI/CharacterCreation", "Class selected: %s" % class_id)


func _on_background_selected(background_id: String, background_data: Dictionary) -> void:
	"""Handle background selection from BackgroundTab."""
	step_data["background"] = background_id
	step_data["background_data"] = background_data
	MythosLogger.debug("UI/CharacterCreation", "Background selected: %s" % background_id)


func _on_ability_scores_changed(scores: Dictionary) -> void:
	"""Handle ability score changes from AbilityScoreTab."""
	step_data["ability_scores"] = scores
	MythosLogger.debug("UI/CharacterCreation", "Ability scores updated")


func _on_appearance_changed(appearance_data: Dictionary) -> void:
	"""Handle appearance changes from AppearanceTab."""
	step_data["appearance"] = appearance_data
	MythosLogger.debug("UI/CharacterCreation", "Appearance updated")
	# Update 3D preview
	_update_preview_appearance(appearance_data)


func _on_character_confirmed(character_data: Dictionary) -> void:
	"""Handle character confirmation from NameConfirmTab."""
	# Merge character data into step_data
	for key: String in character_data.keys():
		step_data[key] = character_data[key]
	_confirm_character_creation()


func _update_racial_bonuses(bonuses: Dictionary) -> void:
	"""Update ability scores with racial bonuses."""
	# Find AbilityScoreTab if it's the current tab
	if current_step == 3 and current_tab_instance != null:  # Ability Scores is step 3
		if current_tab_instance.has_method("set_racial_bonuses"):
			current_tab_instance.set_racial_bonuses(bonuses)


func _update_preview_appearance(appearance_data: Dictionary) -> void:
	"""Update 3D preview with appearance changes."""
	var preview_3d: Node3D = preview_world.get_node_or_null("CharacterPreview3D")
	if preview_3d != null and preview_3d.has_method("update_appearance"):
		preview_3d.update_appearance(appearance_data)


func _notification(what: int) -> void:
	"""Handle window resize events for responsive UI."""
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_RESIZED:
		_update_preview_viewport_size()


func _update_preview_viewport_size() -> void:
	"""Update preview viewport size dynamically."""
	if preview_viewport == null or preview_viewport.get_parent() == null:
		return
	
	var container: SubViewportContainer = preview_viewport.get_parent() as SubViewportContainer
	if container != null and container.stretch:
		# Viewport size is managed automatically by SubViewportContainer.stretch
		return
	
	# Only update if stretch is disabled
	var container_size: Vector2 = container.size if container != null else Vector2(512, 512)
	if container_size.x > 0 and container_size.y > 0:
		preview_viewport.size = Vector2i(int(container_size.x), int(container_size.y))
		MythosLogger.debug("UI/CharacterCreation", "Preview viewport size updated to: %s" % container_size)

