# ╔═══════════════════════════════════════════════════════════
# ║ BackgroundTab.gd
# ║ Desc: Background selection tab using RaceTab's clean 3-column grid pattern
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends Control

signal background_selected(background_id: String)
signal tab_completed()

@onready var title_label: Label = %TitleLabel
@onready var grid: GridContainer = %BackgroundGrid
@onready var confirm_button: Button = %ConfirmBackgroundButton
@onready var back_button: Button = %BackButton

var entry_scene: PackedScene = preload("res://scenes/character/tabs/components/BackgroundEntry.tscn")
var selected_background: String = ""
var all_entries: Array = []
var selected_entry: PanelContainer = null

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame  # double await = 100% safe after full tree + autoloads
	
	if not GameData.backgrounds or GameData.backgrounds.is_empty():
		Logger.error("BackgroundTab: GameData.backgrounds is empty! Aborting population.", "character_creation")
		return
	
	# Restore previous selection if returning from another tab
	_restore_selection_state()
	
	# Initialize UI state
	_populate_list()
	_update_confirm_button_state()
	
	# Restore visual selection after population completes
	if selected_background != "":
		await get_tree().process_frame  # Wait for entries to be fully created
		_restore_visual_selection()

func _populate_list() -> void:
	"""Populate grid with backgrounds"""
	if not grid:
		push_error("BackgroundTab: BackgroundGrid node missing!")
		return
	
	# Clear existing entries
	for child in grid.get_children():
		child.queue_free()
	all_entries.clear()
	selected_entry = null
	
	if GameData.backgrounds.is_empty():
		Logger.error("BackgroundTab: No background items to display!", "character_creation")
		return
	
	# Ensure GridContainer is properly configured
	if grid:
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.visible = true
	
	# Wait for layout to update before adding children
	await get_tree().process_frame
	
	for bg in GameData.backgrounds:
		var entry := entry_scene.instantiate()
		if not entry:
			Logger.error("BackgroundTab: Failed to instantiate background_entry_scene!", "character_creation")
			continue
		
		grid.add_child(entry)
		all_entries.append(entry)
		
		if entry.has_method("setup"):
			entry.setup(bg)
		
		if entry.has_signal("background_selected"):
			entry.background_selected.connect(_on_background_selected)
		
		Logger.debug("BackgroundTab: Added background entry: %s" % bg.get("name", ""), "character_creation")
	
	# Wait for all entries to be added and processed
	await get_tree().process_frame
	
	# Force layout updates
	if grid:
		grid.update_minimum_size()
		grid.queue_sort()
	
	# Update unified scroll container
	await get_tree().process_frame
	var unified_scroll: ScrollContainer = %UnifiedScroll
	if unified_scroll:
		unified_scroll.update_minimum_size()
		unified_scroll.queue_sort()
		unified_scroll.scroll_vertical = 0

func _on_background_selected(bg_id: String) -> void:
	"""Handle background selection"""
	Logger.log_user_action("select_background", bg_id, "character_creation")
	
	# Deselect all entries
	for entry in all_entries:
		if entry and entry.has_method("set_selected"):
			entry.set_selected(false)
	
	# Find and select the clicked entry
	for entry in all_entries:
		if not entry:
			continue
		
		# Check if entry has background_data property
		var entry_bg_data = entry.get("background_data")
		if not entry_bg_data or not (entry_bg_data is Dictionary):
			continue
		
		if entry_bg_data.get("id", "") == bg_id:
			if entry.has_method("set_selected"):
				entry.set_selected(true)
			selected_entry = entry
			break
	
	selected_background = bg_id
	
	Logger.debug("BackgroundTab: Background selected (preview) - %s" % bg_id, "character_creation")
	
	# Emit signal for preview (CharacterCreationRoot handles preview panel update)
	background_selected.emit(bg_id)
	
	# Update confirm button state
	_update_confirm_button_state()
	
	Logger.info("BackgroundTab: Background previewed - %s" % bg_id, "character_creation")

func _update_confirm_button_state() -> void:
	"""Update the confirm button state based on selection"""
	if not confirm_button:
		return
	
	if selected_background.is_empty():
		confirm_button.disabled = true
		confirm_button.text = "Select a Background"
	else:
		confirm_button.disabled = false
		confirm_button.text = "Confirm Background →"

func _on_confirm_button_pressed() -> void:
	"""Handle confirm button press"""
	# Disable button immediately to prevent spam clicks
	if confirm_button:
		confirm_button.disabled = true
	
	if selected_background.is_empty():
		Logger.warning("BackgroundTab: Confirm pressed but no background selected", "character_creation")
		return
	
	# Find the selected background data
	var bg_data: Dictionary = {}
	for bg in GameData.backgrounds:
		if bg.get("id", "") == selected_background:
			bg_data = bg
			break
	
	if bg_data.is_empty():
		Logger.error("BackgroundTab: Selected background not found in GameData!", "character_creation")
		return
	
	# Store background data
	_store_background_data(bg_data)
	
	Logger.info("BackgroundTab: Background confirmed - emitting tab_completed signal", "character_creation")
	Logger.debug("BackgroundTab: tab_completed signal has %d connections" % tab_completed.get_connections().size(), "character_creation")
	
	# Explicitly emit the signal with logging
	if tab_completed.get_connections().is_empty():
		Logger.error("BackgroundTab: tab_completed signal has no connections! Tab advancement will fail.", "character_creation")
	else:
		for conn in tab_completed.get_connections():
			Logger.debug("BackgroundTab: tab_completed connected to: %s" % str(conn), "character_creation")
	
	tab_completed.emit()
	Logger.info("BackgroundTab: tab_completed signal emitted - awaiting tab transition", "character_creation")

func _store_background_data(bg: Dictionary) -> void:
	"""Store background data in PlayerData"""
	PlayerData.background_id = bg.get("id", "")
	PlayerData.background_data = bg.duplicate(true)
	
	Logger.log_user_action("confirm_background", bg.get("id", ""), "character_creation")
	Logger.info("BackgroundTab: Background data stored in PlayerData", "character_creation")

func _restore_selection_state() -> void:
	"""Restore background selection from PlayerData when navigating back"""
	if PlayerData.background_id.is_empty():
		return  # No previous selection to restore
	
	selected_background = PlayerData.background_id
	
	Logger.debug("BackgroundTab: Restored selection state - background: %s" % selected_background, "character_creation")

func _restore_visual_selection() -> void:
	"""Restore visual highlighting of selected background entry"""
	if all_entries.is_empty():
		return
	
	var target_bg_id: String = selected_background
	
	# Find and highlight the matching entry
	for entry in all_entries:
		if not entry:
			continue
		
		var entry_bg_data = entry.get("background_data")
		if not entry_bg_data or not (entry_bg_data is Dictionary):
			continue
		
		if entry_bg_data.get("id", "") == target_bg_id:
			if entry.has_method("set_selected"):
				entry.set_selected(true)
			selected_entry = entry
			
			# Emit preview signal to update preview panel
			background_selected.emit(target_bg_id)
			
			Logger.debug("BackgroundTab: Restored visual selection for %s" % target_bg_id, "character_creation")
			break

func _on_back_button_pressed() -> void:
	"""Handle back button press - no sub-mode for backgrounds"""
	pass  # Backgrounds don't have sub-modes, so this is unused

func _notification(what: int) -> void:
	"""Handle resize notifications to update layout."""
	if what == NOTIFICATION_RESIZED:
		if grid:
			grid.update_minimum_size()
			grid.queue_sort()
		var unified_scroll: ScrollContainer = %UnifiedScroll
		if unified_scroll:
			unified_scroll.queue_sort()
		queue_redraw()
