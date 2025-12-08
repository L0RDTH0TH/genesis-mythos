# ╔══════════════════════════════════════════════════════════════════════════════
# ║ AppearanceTab.gd
# ║ Desc: Full 3D character appearance customization matching Skyrim style
# ║ Author: Lordthoth
# ╚══════════════════════════════════════════════════════════════════════════════
extends Control

const SkyrimSliderScene = preload("res://scenes/ui/components/SkyrimSlider.tscn")
const SexSelectorScript = preload("res://ui/character_creation/tabs/appearance/SexSelector.gd")
const CharacterPreview3DScript = preload("res://scripts/character/CharacterPreview3D.gd")

signal appearance_completed(data: Dictionary)
signal tab_completed()

@onready var appearance_tabs: TabContainer = $MainSplit/RightColumn/ContentVBox/AppearanceTabs
@onready var next_btn: Button = $MainSplit/RightColumn/ContentVBox/NextButton
@onready var preview: SubViewport = $MainSplit/PreviewPanel/SubViewportContainer/CharacterPreview3D
@onready var sex_selector: Node = $MainSplit/RightColumn/ContentVBox/SexSelector

var selected_data: Dictionary = {}
var slider_presets: Dictionary = {}
var current_race_id: String = ""
var current_subrace_id: String = ""
var slider_instances: Dictionary = {}  # id -> HBoxContainer instance
var current_character_model: Node3D = null

func _ready() -> void:
	Logger.debug("AppearanceTab: _ready() called", "character_creation")
	
	# Load slider presets
	_load_slider_presets()
	
	# Connect tab switching signal
	appearance_tabs.tab_changed.connect(_on_tab_changed)
	next_btn.pressed.connect(_on_continue)
	
	# Listen to race changes from PlayerData
	if PlayerData:
		if not PlayerData.racial_bonuses_updated.is_connected(_on_race_changed):
			PlayerData.racial_bonuses_updated.connect(_on_race_changed)
	
	# Listen to CharacterCreationRoot race_confirmed signal
	var root: Node = get_tree().get_first_node_in_group("character_creation_root")
	if root and root.has_signal("race_confirmed"):
		if not root.race_confirmed.is_connected(_on_race_confirmed):
			root.race_confirmed.connect(_on_race_confirmed)
	
	# Initialize current race from PlayerData
	if PlayerData and PlayerData.race_id != "":
		current_race_id = PlayerData.race_id
		current_subrace_id = PlayerData.subrace_id
		Logger.debug("AppearanceTab: Initialized race from PlayerData - race: %s, subrace: %s" % [current_race_id, current_subrace_id], "character_creation")
	
	# Connect preview signals
	if preview:
		if preview.has_signal("preview_ready"):
			if not preview.preview_ready.is_connected(_on_preview_ready):
				preview.preview_ready.connect(_on_preview_ready)
		# Wait one frame to ensure preview is fully initialized
		await get_tree().process_frame
		# Set initial race/gender (will be called again in _on_preview_ready if preview emits signal)
		_update_preview_race_gender()
	else:
		Logger.warning("AppearanceTab: Preview node not found!", "character_creation")
	
	# Connect sex selector
	if sex_selector:
		sex_selector.sex_changed.connect(_on_sex_changed)
		# Initial load
		_on_sex_changed(sex_selector.get_current_sex_id())
	
	# Populate all tabs with sliders
	_populate_all_tabs()
	
	# Check if ready and enable next button
	_check_ready()
	
	# Initialize with first tab
	_on_tab_changed(0)
	
	Logger.debug("AppearanceTab: Initialization complete", "character_creation")

func _load_slider_presets() -> void:
	"""Load slider presets from JSON"""
	var file := FileAccess.open("res://data/appearance/sliders/slider_presets.json", FileAccess.READ)
	if not file:
		Logger.error("AppearanceTab: Cannot load slider_presets.json", "character_creation")
		return
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		Logger.error("AppearanceTab: Failed to parse slider_presets.json - Line %d: %s" % [json.get_error_line(), json.get_error_message()], "character_creation")
		return
	
	if not json.data is Dictionary:
		Logger.error("AppearanceTab: slider_presets.json root is not a Dictionary", "character_creation")
		return
	
	slider_presets = json.data as Dictionary
	Logger.debug("AppearanceTab: Loaded slider presets", "character_creation")

func _populate_all_tabs() -> void:
	"""Populate all appearance tabs with sliders from JSON"""
	_populate_tab("Body", "global")
	_populate_tab("Head", "head")
	_populate_tab("Face", "face")
	_populate_tab("Hair", [])  # Hair tab empty for now

func _populate_tab(tab_name: String, preset_keys: Variant) -> void:
	"""Populate a specific tab with sliders"""
	var tab_node: Control = appearance_tabs.get_node_or_null(tab_name)
	if not tab_node:
		Logger.error("AppearanceTab: Tab '%s' not found" % tab_name, "character_creation")
		return
	
	var sliders_container: VBoxContainer = tab_node.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer/SlidersContainer")
	if not sliders_container:
		Logger.error("AppearanceTab: SlidersContainer not found in tab '%s'" % tab_name, "character_creation")
		return
	
	# Clear existing sliders
	for child in sliders_container.get_children():
		child.queue_free()
	
	# Handle different preset key types
	var sliders_to_add: Array = []
	
	if preset_keys is String:
		# Single category
		if slider_presets.has(preset_keys):
			sliders_to_add = slider_presets[preset_keys] as Array
	elif preset_keys is Array:
		# Multiple categories
		for key in preset_keys:
			if slider_presets.has(key):
				sliders_to_add.append_array(slider_presets[key] as Array)
	
	# Add race-specific sliders if applicable
	if current_race_id != "" and slider_presets.has("race_specific"):
		var race_specific: Dictionary = slider_presets["race_specific"] as Dictionary
		if race_specific.has(current_race_id):
			sliders_to_add.append_array(race_specific[current_race_id] as Array)
	
	# Create slider instances
	for slider_data in sliders_to_add:
		if not slider_data is Dictionary:
			continue
		
		var slider_id: String = slider_data.get("id", "")
		if slider_id.is_empty():
			continue
		
		var slider_instance = SkyrimSliderScene.instantiate()
		slider_instance.slider_id = slider_id
		slider_instance.label_text = slider_data.get("label", slider_id)
		slider_instance.min_value = slider_data.get("min", 0.0)
		slider_instance.max_value = slider_data.get("max", 1.0)
		slider_instance.default_value = slider_data.get("default", 0.5)
		slider_instance.step_size = slider_data.get("step", 0.01)
		
		# Connect value_changed signal
		slider_instance.value_changed.connect(_on_slider_value_changed)
		
		sliders_container.add_child(slider_instance)
		slider_instances[slider_id] = slider_instance
		
		Logger.debug("AppearanceTab: Created slider '%s' in tab '%s'" % [slider_id, tab_name], "character_creation")
	
	Logger.info("AppearanceTab: Populated tab '%s' with %d sliders" % [tab_name, sliders_to_add.size()], "character_creation")

func _on_slider_value_changed(id: String, value: float) -> void:
	"""Handle slider value changes"""
	selected_data[id] = value
	
	# Forward to preview for real-time morphing
	if preview and preview.has_method("apply_slider"):
		# Normalize value to 0-1 range for preview
		var slider_instance = slider_instances.get(id)
		if slider_instance:
			var normalized_value: float = (value - slider_instance.min_value) / (slider_instance.max_value - slider_instance.min_value)
			preview.apply_slider(id, normalized_value)
	
	Logger.debug("AppearanceTab: Slider '%s' changed to %.3f" % [id, value], "character_creation")

func _on_race_changed() -> void:
	"""Handle race change from PlayerData"""
	if not PlayerData:
		Logger.warning("AppearanceTab: _on_race_changed() called but PlayerData is null", "character_creation")
		return
	
	var new_race: String = PlayerData.race_id
	var new_subrace: String = PlayerData.subrace_id
	
	Logger.debug("AppearanceTab: _on_race_changed() - new_race: %s, new_subrace: %s, current_race: %s" % [new_race, new_subrace, current_race_id], "character_creation")
	
	if new_race != current_race_id or new_subrace != current_subrace_id:
		current_race_id = new_race
		current_subrace_id = new_subrace
		_update_preview_race_gender()
		_rebuild_sliders_for_race()
		Logger.info("AppearanceTab: Race changed to %s%s" % [current_race_id, " (%s)" % current_subrace_id if current_subrace_id != "" else ""], "character_creation")
	else:
		Logger.debug("AppearanceTab: Race unchanged, skipping update", "character_creation")

func _on_race_confirmed(race_id: String, subrace_id: String) -> void:
	"""Handle race confirmation from CharacterCreationRoot"""
	current_race_id = race_id
	current_subrace_id = subrace_id
	_update_preview_race_gender()
	_rebuild_sliders_for_race()
	Logger.info("AppearanceTab: Race confirmed - %s%s" % [current_race_id, " (%s)" % current_subrace_id if current_subrace_id != "" else ""], "character_creation")

func _rebuild_sliders_for_race() -> void:
	"""Rebuild all sliders to include/exclude race-specific ones"""
	# Clear all slider instances
	for slider_id in slider_instances.keys():
		var slider = slider_instances[slider_id]
		if is_instance_valid(slider):
			slider.queue_free()
	slider_instances.clear()
	
	# Repopulate all tabs
	_populate_all_tabs()
	_check_ready()

func _on_tab_changed(tab_index: int) -> void:
	"""Handle tab switching in AppearanceTabs TabContainer"""
	var tab_name: String = appearance_tabs.get_tab_title(tab_index)
	Logger.debug("AppearanceTab: Switched to tab: %s (index: %d)" % [tab_name, tab_index], "character_creation")
	
	# Reset preview sliders when leaving appearance tab (optional - can be removed if not desired)
	# if preview:
	# 	preview.reset_all_sliders()

func _check_ready() -> void:
	"""Check if appearance customization is complete"""
	# Enable next button when sliders are populated
	if slider_instances.size() > 0:
		next_btn.disabled = false

func _on_continue() -> void:
	"""Emit completion signal with appearance data"""
	Logger.info("AppearanceTab: Appearance customization completed", "character_creation")
	
	# Store appearance data in PlayerData
	if PlayerData:
		PlayerData.appearance_data = selected_data.duplicate()
	
	Logger.log_structured(Logger.LOG_LEVEL.INFO, "AppearanceCompleted", "character_creation", selected_data)
	
	appearance_completed.emit(selected_data)
	tab_completed.emit()
	Logger.info("AppearanceTab: Appearance data emitted", "character_creation")

func _on_preview_ready() -> void:
	"""Handle preview ready signal"""
	Logger.debug("AppearanceTab: Preview is ready", "character_creation")
	_update_preview_race_gender()

func _update_preview_race_gender() -> void:
	"""Update preview with current race and gender"""
	if not preview:
		Logger.warning("AppearanceTab: _update_preview_race_gender() called but preview is null", "character_creation")
		return
	
	if not preview.has_method("set_race"):
		Logger.warning("AppearanceTab: Preview does not have set_race() method", "character_creation")
		return
	
	# Map race_id to preview race format (lowercase, no subrace prefix)
	var preview_race: String = current_race_id.to_lower() if current_race_id != "" else "human"
	
	# Determine gender from PlayerData or default to male
	var preview_gender: String = "male"
	if PlayerData and PlayerData.gender != "":
		preview_gender = PlayerData.gender.to_lower()
	
	Logger.debug("AppearanceTab: Calling preview.set_race(%s) and set_gender(%s)" % [preview_race, preview_gender], "character_creation")
	preview.set_race(preview_race)
	preview.set_gender(preview_gender)
	
	Logger.info("AppearanceTab: Updated preview - race: %s, gender: %s" % [preview_race, preview_gender], "character_creation")

func _on_sex_changed(sex_id: int) -> void:
	"""Handle sex selection change - swap the entire 3D preview model"""
	if not sex_selector:
		Logger.error("AppearanceTab: SexSelector not available", "character_creation")
		return
	
	# Check if SexSelector has the required methods
	if not sex_selector.has_method("get_variant_data"):
		Logger.error("AppearanceTab: SexSelector script not properly loaded", "character_creation")
		return
	
	# Get variant data using helper method
	var variant: Dictionary = sex_selector.get_variant_data(sex_id)
	if variant.is_empty():
		Logger.error("AppearanceTab: Invalid sex_id %d or variant data not found" % sex_id, "character_creation")
		return
	var model_scene_path: String = variant.get("model_scene", "")
	var gender_name: String = variant.get("display_name", "Male").to_lower()
	
	# Store gender in PlayerData first
	if PlayerData:
		PlayerData.gender = gender_name
	
	# Try to load custom model scene from JSON if it exists
	if model_scene_path != "" and ResourceLoader.exists(model_scene_path):
		var new_model_scene: PackedScene = load(model_scene_path) as PackedScene
		if new_model_scene:
			# Get the character root from the preview
			var character_root: Node3D = preview.get_node_or_null("CharacterRoot")
			if character_root:
				# Remove old model
				if current_character_model != null and is_instance_valid(current_character_model):
					current_character_model.queue_free()
					current_character_model = null
				
				# Clear all existing character model children
				for child in character_root.get_children():
					child.queue_free()
				
				# Instance and add new model
				current_character_model = new_model_scene.instantiate()
				character_root.add_child(current_character_model)
				
				# Update preview skeleton/mesh references
				if preview.has_method("_update_skeleton_references"):
					preview._update_skeleton_references()
				
				Logger.info("AppearanceTab: Sex changed to %s (ID: %d) - custom model loaded" % [variant.get("display_name", "Unknown"), sex_id], "character_creation")
				return
	
	# Fallback to existing gender system (uses default model path pattern)
	if preview and preview.has_method("set_gender"):
		preview.set_gender(gender_name)
		Logger.info("AppearanceTab: Sex changed to %s (ID: %d) - using default model" % [variant.get("display_name", "Unknown"), sex_id], "character_creation")
	else:
		Logger.error("AppearanceTab: Preview does not have set_gender method", "character_creation")
