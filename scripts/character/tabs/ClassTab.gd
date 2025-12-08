# ╔═══════════════════════════════════════════════════════════
# ║ ClassTab.gd
# ║ Desc: Two-stage class → subclass selection (BG3 style)
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends Control

signal class_selected(class_id: String, subclass_id: String)
signal tab_completed()

const MODE_CLASS: int = 0
const MODE_SUBCLASS: int = 1

@onready var class_grid: GridContainer = %ClassGrid
@onready var unified_scroll: ScrollContainer = %UnifiedScroll
@onready var confirm_class_button: Button = %ConfirmClassButton
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel

var class_entry_scene: PackedScene = preload("res://scenes/character/tabs/components/ClassEntry.tscn")
var current_mode: int = MODE_CLASS
var pending_class: Dictionary = {}
var selected_class: String = ""
var selected_subclass: String = ""
var selected_entry: PanelContainer = null
var all_entries: Array = []

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame  # double await = 100% safe after full tree + autoloads
	
	if not GameData.classes or GameData.classes.is_empty():
		Logger.error("ClassTab: GameData.classes is empty! Aborting population.", "character_creation")
		return
	
	# Restore previous selection if returning from another tab
	_restore_selection_state()
	
	# Initialize UI state
	_update_ui_for_mode()
	_populate_list()
	
	# Restore visual selection after population completes
	if selected_class != "":
		await get_tree().process_frame  # Wait for entries to be fully created
		_restore_visual_selection()

func _populate_list() -> void:
	"""Populate grid based on current mode"""
	if not class_grid:
		push_error("ClassTab: ClassGrid node missing!")
		return
	
	# Clear existing entries
	for child in class_grid.get_children():
		child.queue_free()
	all_entries.clear()
	selected_entry = null
	
	if GameData.classes.is_empty():
		Logger.error("ClassTab: No class items to display!", "character_creation")
		return
	
	# Ensure GridContainer is properly configured
	if class_grid:
		class_grid.columns = 3
		class_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		class_grid.visible = true
	
	# Wait for layout to update before adding children
	await get_tree().process_frame
	
	if current_mode == MODE_CLASS:
		_populate_classes()
	elif current_mode == MODE_SUBCLASS:
		_populate_subclasses()
	
	# Wait for all entries to be added and processed
	await get_tree().process_frame
	
	# Force layout updates
	if class_grid:
		class_grid.update_minimum_size()
		class_grid.queue_sort()
	
	# Update unified scroll container
	await get_tree().process_frame
	if unified_scroll:
		unified_scroll.update_minimum_size()
		unified_scroll.queue_sort()
		unified_scroll.scroll_vertical = 0

func _populate_classes() -> void:
	"""Populate grid with base classes only (ignore subclasses)"""
	for class_dict in GameData.classes:
		var entry := class_entry_scene.instantiate()
		if not entry:
			Logger.error("ClassTab: Failed to instantiate class_entry_scene!", "character_creation")
			continue
		
		class_grid.add_child(entry)
		all_entries.append(entry)
		
		if entry.has_method("setup"):
			entry.setup(class_dict)
		
		if entry.has_signal("class_selected"):
			entry.class_selected.connect(_on_class_selected)
		
		Logger.debug("ClassTab: Added class entry: %s" % class_dict.get("name", ""), "character_creation")

func _populate_subclasses() -> void:
	"""Populate grid with subclasses of pending_class"""
	if pending_class.is_empty():
		Logger.error("ClassTab: Cannot populate subclasses - pending_class is empty!", "character_creation")
		return
	
	var subclasses: Array = pending_class.get("subclasses", [])
	if subclasses.is_empty():
		Logger.warning("ClassTab: Class %s has no subclasses!" % pending_class.get("name", ""), "character_creation")
		return
	
	for subclass in subclasses:
		var entry := class_entry_scene.instantiate()
		if not entry:
			Logger.error("ClassTab: Failed to instantiate class_entry_scene!", "character_creation")
			continue
		
		class_grid.add_child(entry)
		all_entries.append(entry)
		
		if entry.has_method("setup"):
			entry.setup(pending_class, subclass)
		
		if entry.has_signal("class_selected"):
			entry.class_selected.connect(_on_class_selected)
		
		Logger.debug("ClassTab: Added subclass entry: %s" % subclass.get("name", ""), "character_creation")

func _update_ui_for_mode() -> void:
	"""Update UI elements based on current mode"""
	if current_mode == MODE_CLASS:
		title_label.text = "CHOOSE YOUR CLASS"
		back_button.visible = false
		selected_class = ""
		selected_subclass = ""
	elif current_mode == MODE_SUBCLASS:
		title_label.text = "CHOOSE YOUR SUBCLASS"
		back_button.visible = true
	
	_update_class_confirm_button_state()

func _go_back_to_classes() -> void:
	"""Return to class selection mode"""
	current_mode = MODE_CLASS
	pending_class = {}
	selected_class = ""
	selected_subclass = ""
	selected_entry = null
	_update_ui_for_mode()
	_populate_list()
	
	Logger.info("ClassTab: Returned to class selection", "character_creation")

func _on_back_button_pressed() -> void:
	"""Handle back button press"""
	_go_back_to_classes()

func _notification(what: int) -> void:
	"""Handle resize notifications to update layout."""
	if what == NOTIFICATION_RESIZED:
		if class_grid:
			class_grid.update_minimum_size()
			class_grid.queue_sort()
		if unified_scroll:
			unified_scroll.queue_sort()
		queue_redraw()

func _on_class_selected(class_id: String, subclass_id: String) -> void:
	"""Handle class/subclass selection"""
	Logger.log_user_action("select_class", class_id, "character_creation", {
		"subclass": subclass_id if subclass_id != "" else "none"
	})
	
	# Deselect all entries
	for entry in all_entries:
		if entry and entry.has_method("set_selected"):
			entry.set_selected(false)
	
	# Find and select the clicked entry
	for entry in all_entries:
		if not entry:
			continue
		
		# Check if entry has class_data property (ClassEntry instances have this)
		var entry_class_data = entry.get("class_data")
		if not entry_class_data or not (entry_class_data is Dictionary):
			continue
		
		if entry_class_data.get("id", "") == class_id:
			var entry_subclass_data = entry.get("subclass_data")
			if subclass_id == "" or (entry_subclass_data is Dictionary and not entry_subclass_data.is_empty() and entry_subclass_data.get("id", "") == subclass_id):
				if entry.has_method("set_selected"):
					entry.set_selected(true)
				selected_entry = entry
				break
	
	selected_class = class_id
	selected_subclass = subclass_id if subclass_id != "" else ""
	
	Logger.debug("ClassTab: Class selected (preview) - class: %s, subclass: %s" % [class_id, subclass_id if subclass_id != "" else "none"], "character_creation")
	
	# Emit signal for preview (CharacterCreationRoot handles preview panel update)
	class_selected.emit(class_id, subclass_id)
	
	# Update confirm button state
	_update_class_confirm_button_state()
	
	Logger.info("ClassTab: Class previewed - %s%s" % [class_id, " (%s)" % subclass_id if subclass_id != "" else ""], "character_creation")

func _update_class_confirm_button_state() -> void:
	"""Update the confirm button state based on selection and mode"""
	if not confirm_class_button:
		return
	
	if current_mode == MODE_CLASS:
		if selected_class.is_empty():
			confirm_class_button.disabled = true
			confirm_class_button.text = "Select a Class"
		else:
			confirm_class_button.disabled = false
			confirm_class_button.text = "Confirm Class →"
	elif current_mode == MODE_SUBCLASS:
		if selected_subclass.is_empty():
			confirm_class_button.disabled = true
			confirm_class_button.text = "Select a Subclass"
		else:
			confirm_class_button.disabled = false
			confirm_class_button.text = "Confirm Subclass →"

func _on_confirm_button_pressed() -> void:
	"""Handle confirm button press - behavior depends on mode"""
	# Disable button immediately to prevent spam clicks
	if confirm_class_button:
		confirm_class_button.disabled = true
	
	if current_mode == MODE_CLASS:
		_confirm_class()
	elif current_mode == MODE_SUBCLASS:
		_confirm_subclass()

func _confirm_class() -> void:
	"""Confirm base class selection"""
	if selected_class.is_empty():
		Logger.warning("ClassTab: Confirm pressed but no class selected", "character_creation")
		return
	
	# Find the selected class data
	var class_data: Dictionary = {}
	for cls in GameData.classes:
		if cls.get("id", "") == selected_class:
			class_data = cls
			break
	
	if class_data.is_empty():
		Logger.error("ClassTab: Selected class not found in GameData!", "character_creation")
		return
	
	var subclasses: Array = class_data.get("subclasses", [])
	
	# If class has subclasses, switch to subclass selection mode
	if subclasses.size() > 0:
		current_mode = MODE_SUBCLASS
		pending_class = class_data
		selected_subclass = ""
		selected_entry = null
		_update_ui_for_mode()
		_populate_list()
		
		# Keep the class preview active
		class_selected.emit(selected_class, "")
		
		Logger.info("ClassTab: Switched to subclass selection for %s" % class_data.get("name", ""), "character_creation")
	else:
		# No subclasses - store and advance immediately
		_store_class_data(class_data, "")
		
		Logger.info("ClassTab: Class confirmed (no subclasses) - emitting tab_completed signal", "character_creation")
		Logger.debug("ClassTab: tab_completed signal has %d connections" % tab_completed.get_connections().size(), "character_creation")
		
		# Explicitly emit the signal with logging
		if tab_completed.get_connections().is_empty():
			Logger.error("ClassTab: tab_completed signal has no connections! Tab advancement will fail.", "character_creation")
		else:
			for conn in tab_completed.get_connections():
				Logger.debug("ClassTab: tab_completed connected to: %s" % str(conn), "character_creation")
		
		tab_completed.emit()
		Logger.info("ClassTab: tab_completed signal emitted - awaiting tab transition", "character_creation")

func _confirm_subclass() -> void:
	"""Confirm subclass selection and advance to next tab"""
	if selected_subclass.is_empty():
		Logger.warning("ClassTab: Confirm pressed but no subclass selected", "character_creation")
		return
	
	if pending_class.is_empty():
		Logger.error("ClassTab: Cannot confirm subclass - pending_class is empty!", "character_creation")
		return
	
	_store_class_data(pending_class, selected_subclass)
	
	Logger.info("ClassTab: Subclass confirmed - emitting tab_completed signal", "character_creation")
	Logger.debug("ClassTab: tab_completed signal has %d connections" % tab_completed.get_connections().size(), "character_creation")
	
	# Explicitly emit the signal with logging
	if tab_completed.get_connections().is_empty():
		Logger.error("ClassTab: tab_completed signal has no connections! Tab advancement will fail.", "character_creation")
	else:
		for conn in tab_completed.get_connections():
			Logger.debug("ClassTab: tab_completed connected to: %s" % str(conn), "character_creation")
	
	tab_completed.emit()
	Logger.info("ClassTab: tab_completed signal emitted - awaiting tab transition", "character_creation")

func _store_class_data(class_dict: Dictionary, subclass_id: String) -> void:
	"""Store class and subclass data in PlayerData"""
	PlayerData.class_id = class_dict.get("id", "")
	PlayerData.subclass_id = subclass_id if subclass_id != "" else ""
	
	# Create merged class data
	var class_data: Dictionary = class_dict.duplicate()
	if subclass_id != "":
		var subclasses: Array = class_data.get("subclasses", [])
		for subclass in subclasses:
			if subclass.get("id", "") == subclass_id:
				# Merge subclass data
				if subclass.has("name"):
					class_data["subclass_name"] = subclass.get("name", "")
				if subclass.has("description") and subclass.get("description", "") != "":
					class_data["subclass_description"] = subclass.get("description", "")
				if subclass.has("features"):
					class_data["subclass_features"] = subclass.get("features", [])
				break
	
	PlayerData.class_data = class_data
	
	Logger.log_user_action("confirm_class", class_dict.get("id", ""), "character_creation", {
		"subclass": subclass_id if subclass_id != "" else "none"
	})
	Logger.info("ClassTab: Class data stored in PlayerData", "character_creation")

func _restore_selection_state() -> void:
	"""Restore class/subclass selection from PlayerData when navigating back"""
	if PlayerData.class_id.is_empty():
		return  # No previous selection to restore
	
	selected_class = PlayerData.class_id
	selected_subclass = PlayerData.subclass_id
	
	# Find the class data from GameData
	for cls in GameData.classes:
		if cls.get("id", "") == selected_class:
			if selected_subclass != "":
				# We have a subclass - set mode and pending class
				current_mode = MODE_SUBCLASS
				pending_class = cls
			else:
				# Just class selected, check if it has subclasses
				var subclasses: Array = cls.get("subclasses", [])
				if subclasses.size() > 0:
					# Class has subclasses but none selected - stay in class mode
					current_mode = MODE_CLASS
				else:
					# Class has no subclasses - confirmed state
					current_mode = MODE_CLASS
			break
	
	Logger.debug("ClassTab: Restored selection state - class: %s, subclass: %s, mode: %s" % [
		selected_class,
		selected_subclass if selected_subclass != "" else "none",
		"SUBCLASS" if current_mode == MODE_SUBCLASS else "CLASS"
	], "character_creation")

func _restore_visual_selection() -> void:
	"""Restore visual highlighting of selected class/subclass entry"""
	if all_entries.is_empty():
		return
	
	var target_class_id: String = selected_class
	var target_subclass_id: String = selected_subclass if selected_subclass != "" else ""
	
	# Find and highlight the matching entry
	for entry in all_entries:
		if not entry:
			continue
		
		var entry_class_data = entry.get("class_data")
		if not entry_class_data or not (entry_class_data is Dictionary):
			continue
		
		if entry_class_data.get("id", "") == target_class_id:
			var entry_subclass_data = entry.get("subclass_data")
			var entry_subclass_id: String = ""
			if entry_subclass_data is Dictionary and not entry_subclass_data.is_empty():
				entry_subclass_id = entry_subclass_data.get("id", "")
			
			# Match subclass if needed
			if target_subclass_id == "" or entry_subclass_id == target_subclass_id:
				if entry.has_method("set_selected"):
					entry.set_selected(true)
				selected_entry = entry
				
				# Emit preview signal to update preview panel
				class_selected.emit(target_class_id, target_subclass_id)
				
				Logger.debug("ClassTab: Restored visual selection for %s%s" % [
					target_class_id,
					" (%s)" % target_subclass_id if target_subclass_id != "" else ""
				], "character_creation")
				break
