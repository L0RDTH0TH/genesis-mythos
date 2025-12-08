# ╔═══════════════════════════════════════════════════════════
# ║ AbilityScoreTab.gd
# ║ Desc: BG3-style ability score selection with point-buy (matches Race/Class visual style)
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name AbilityScoreTab
extends Control

signal tab_completed

const ABILITY_ORDER := ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"]
const LEFT_COLUMN_ABILITIES := ["strength", "dexterity", "constitution"]
const RIGHT_COLUMN_ABILITIES := ["intelligence", "wisdom", "charisma"]

const POINT_BUY_TOTAL := 27

@onready var left_column: VBoxContainer = %LeftColumn
@onready var right_column: VBoxContainer = %RightColumn
@onready var preview_panel: PanelContainer = %PreviewPanel
@onready var total_spent_label: Label = %TotalSpentLabel
@onready var remaining_label: Label = %RemainingLabel
@onready var spent_breakdown: VBoxContainer = %SpentBreakdown
@onready var unified_scroll: ScrollContainer = %UnifiedScroll
@onready var confirm_button: Button = %ConfirmAbilityButton
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel

var ability_entry_scene: PackedScene = preload("res://scenes/character/tabs/components/AbilityScoreEntry.tscn")
var all_entries: Array[Node] = []  # Array of AbilityScoreEntry nodes (typed as Node to avoid class loading order issues)

# Point-buy system
var current_points_spent: int = 0
var point_buy_table: Resource

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame  # double await = 100% safe after full tree + autoloads
	
	if not GameData.abilities or GameData.abilities.is_empty():
		Logger.error("AbilityScoreTab: GameData.abilities is empty! Aborting population.", "character_creation")
		return
	
	# Load point-buy cost table with validation
	point_buy_table = preload("res://data/point_buy_costs.tres") as Resource
	if not point_buy_table:
		Logger.error("AbilityScoreTab: Failed to load point_buy_costs.tres resource file!", "character_creation")
		return
	
	if not point_buy_table.has_method("get_cost"):
		Logger.error("AbilityScoreTab: point_buy_table resource missing get_cost() method! Type: %s" % point_buy_table.get_class(), "character_creation")
		return
	
	# Validate cost table works by testing a known value
	var test_cost: int = point_buy_table.get_cost(8)
	if test_cost == 999:
		Logger.error("AbilityScoreTab: point_buy_table.get_cost(8) returned 999 - cost table may be invalid!", "character_creation")
		return
	
	Logger.debug("AbilityScoreTab: Point-buy cost table loaded successfully (test: cost(8) = %d)" % test_cost, "character_creation")
	
	# Initialize all stats to 8 (cost 0 each = 0 points spent, 27 remaining)
	_initialize_stats_to_default()
	
	# Recalculate points based on current scores
	_recalculate_points()
	
	# Initialize UI state
	_populate_list()
	_update_confirm_button_state()
	
	# Connect signals
	if PlayerData:
		if not PlayerData.stats_changed.is_connected(_on_stats_changed):
			PlayerData.stats_changed.connect(_on_stats_changed)
			Logger.debug("AbilityScoreTab: Connected stats_changed signal", "character_creation")
		if not PlayerData.points_changed.is_connected(_on_points_changed):
			PlayerData.points_changed.connect(_on_points_changed)
			Logger.debug("AbilityScoreTab: Connected points_changed signal", "character_creation")
		if not PlayerData.racial_bonuses_updated.is_connected(_on_racial_bonuses_updated):
			PlayerData.racial_bonuses_updated.connect(_on_racial_bonuses_updated)
			Logger.debug("AbilityScoreTab: Connected racial_bonuses_updated signal", "character_creation")
	else:
		Logger.error("AbilityScoreTab: PlayerData singleton not found - signal connections failed!", "character_creation")
	
	# Signals are connected via scene file connections, no need to connect here
	Logger.info("AbilityScoreTab: Initialization complete - %d ability entries created" % all_entries.size(), "character_creation")

func _populate_list() -> void:
	"""Populate columns with ability score entries"""
	if not left_column or not right_column:
		push_error("AbilityScoreTab: LeftColumn or RightColumn node missing!")
		return
	
	# Clear existing entries
	for child in left_column.get_children():
		child.queue_free()
	for child in right_column.get_children():
		child.queue_free()
	all_entries.clear()
	
	# Wait for layout to update before adding children
	await get_tree().process_frame
	
	# Create entries for each ability and add to appropriate column
	for ability_key in ABILITY_ORDER:
		var entry := ability_entry_scene.instantiate()
		if not entry:
			Logger.error("AbilityScoreTab: Failed to instantiate ability_entry_scene!", "character_creation")
			continue
		
		# Determine which column to add to
		var target_column: VBoxContainer
		if ability_key in LEFT_COLUMN_ABILITIES:
			target_column = left_column
		elif ability_key in RIGHT_COLUMN_ABILITIES:
			target_column = right_column
		else:
			Logger.error("AbilityScoreTab: Unknown ability key: %s" % ability_key, "character_creation")
			continue
		
		target_column.add_child(entry)
		
		# Wait for node to be ready (methods/signals available after _ready() is called)
		await get_tree().process_frame
		
		# Verify it's an AbilityScoreEntry by checking for required methods (runtime check, no type annotation)
		if not entry.has_method("setup") or not entry.has_signal("value_changed"):
			Logger.error("AbilityScoreTab: Entry for %s is not an AbilityScoreEntry! Got type: %s" % [ability_key, entry.get_class()], "character_creation")
			continue
		
		all_entries.append(entry)
		
		# Get ability display name
		var ability_data: Dictionary = GameData.abilities.get(ability_key, {})
		var ability_name: String = ability_data.get("full", ability_key.capitalize())
		
		# Get current values
		var base: int = PlayerData.ability_scores.get(ability_key, PlayerData.get_min_score())
		var racial: int = PlayerData.get_racial_bonus(ability_key)
		
		# Setup the entry (now safe to call since node is ready)
		entry.setup(ability_key, ability_name, base, racial)
		
		# Connect signal (now safe since node is ready)
		if entry.value_changed.is_connected(_on_entry_value_changed):
			Logger.warning("AbilityScoreTab: value_changed signal already connected for %s" % ability_key, "character_creation")
		else:
			entry.value_changed.connect(_on_entry_value_changed)
			Logger.debug("AbilityScoreTab: Connected value_changed signal for %s" % ability_key, "character_creation")
		
		Logger.debug("AbilityScoreTab: Added ability entry: %s to %s column" % [ability_name, "left" if ability_key in LEFT_COLUMN_ABILITIES else "right"], "character_creation")
	
	# Wait for all entries to be added and processed
	await get_tree().process_frame
	
	# Force layout updates
	if left_column:
		left_column.update_minimum_size()
		left_column.queue_sort()
	if right_column:
		right_column.update_minimum_size()
		right_column.queue_sort()
	
	# Update unified scroll container
	await get_tree().process_frame
	if unified_scroll:
		unified_scroll.update_minimum_size()
		unified_scroll.queue_sort()
		unified_scroll.scroll_vertical = 0
	
	# Refresh all displays
	_refresh_all()
	
	Logger.info("AbilityScoreTab: Populated %d ability entries (left: %d, right: %d)" % [
		all_entries.size(),
		left_column.get_child_count(),
		right_column.get_child_count()
	], "character_creation")

func _on_entry_value_changed(ability_key: String, delta: int) -> void:
	"""Handle ability score change from entry"""
	var current_value: int = PlayerData.ability_scores.get(ability_key, 8)
	var desired_value: int = current_value + delta
	
	# Clamp to valid range
	desired_value = clampi(desired_value, point_buy_table.get_min_stat(), point_buy_table.get_max_stat())
	
	# Check if we can afford this change
	if can_afford(current_value, desired_value):
		apply_stat_change(ability_key, current_value, desired_value)
		Logger.log_user_action("change_ability" if delta > 0 else "decrease_ability", ability_key, "character_creation", {
			"old_value": current_value,
			"new_value": desired_value
		})
	else:
		# Cannot afford - revert and provide feedback
		Logger.warning("AbilityScoreTab: Cannot afford stat change %s: %d -> %d" % [ability_key, current_value, desired_value], "character_creation")
		# TODO: Add visual feedback (flash red, play sound) - keep existing feedback system
		_refresh_all()  # Refresh to revert any UI changes
	
	_refresh_all()
	_update_confirm_button_state()

func _refresh_all() -> void:
	"""Refresh all ability entries and preview display"""
	var refreshed_count: int = 0
	var skipped_count: int = 0
	
	for entry_node in all_entries:
		if not entry_node:
			skipped_count += 1
			continue
		
		# Verify it's an AbilityScoreEntry by checking for required methods (runtime check, no type annotation)
		if not entry_node.has_method("update_visuals"):
			Logger.warning("AbilityScoreTab: _refresh_all() - entry is not AbilityScoreEntry type: %s" % entry_node.get_class(), "character_creation")
			skipped_count += 1
			continue
		
		# Access properties directly using get() to avoid type annotation issues
		var ability_key = entry_node.get("ability_key")
		if ability_key == null or ability_key.is_empty():
			Logger.warning("AbilityScoreTab: _refresh_all() - entry has empty ability_key", "character_creation")
			skipped_count += 1
			continue
		
		var base: int = PlayerData.ability_scores.get(ability_key, PlayerData.get_min_score())
		var racial: int = PlayerData.get_racial_bonus(ability_key)
		
		# Set properties using set() to avoid type annotation issues
		entry_node.set("base_value", base)
		entry_node.set("racial_bonus", racial)
		entry_node.call("update_visuals")
		refreshed_count += 1
	
	if skipped_count > 0:
		Logger.warning("AbilityScoreTab: _refresh_all() skipped %d invalid entries" % skipped_count, "character_creation")
	
	Logger.debug("AbilityScoreTab: _refresh_all() updated %d entries" % refreshed_count, "character_creation")
	_update_preview()

func get_cost(stat_value: int) -> int:
	"""Get cost for a given stat value, returns 999 if out of bounds or invalid"""
	if not point_buy_table:
		Logger.error("AbilityScoreTab: get_cost() called but point_buy_table is null! Returning 999", "character_creation")
		return 999
	
	if not point_buy_table.has_method("get_cost"):
		Logger.error("AbilityScoreTab: get_cost() called but point_buy_table missing get_cost() method! Returning 999", "character_creation")
		return 999
	
	# Validate stat_value is in expected range before calling
	var min_stat: int = 6
	var max_stat: int = 26
	if point_buy_table.has_method("get_min_stat"):
		min_stat = point_buy_table.get_min_stat()
	if point_buy_table.has_method("get_max_stat"):
		max_stat = point_buy_table.get_max_stat()
	
	if stat_value < min_stat or stat_value > max_stat:
		Logger.warning("AbilityScoreTab: get_cost() called with out-of-bounds value %d (range: %d-%d)" % [stat_value, min_stat, max_stat], "character_creation")
	
	var cost: int = point_buy_table.get_cost(stat_value)
	
	# Log if 999 is returned to help debug
	if cost == 999:
		Logger.error("AbilityScoreTab: get_cost(%d) returned 999 - stat value may be out of bounds or cost table invalid!" % stat_value, "character_creation")
	
	Logger.debug("AbilityScoreTab: get_cost(%d) = %d" % [stat_value, cost], "character_creation")
	return cost

func _update_preview() -> void:
	"""Update the preview panel with points spent, remaining, and breakdown"""
	if not total_spent_label or not remaining_label or not spent_breakdown:
		Logger.warning("AbilityScoreTab: _update_preview() called but preview UI nodes are missing!", "character_creation")
		return
	
	var remaining_points: int = get_points_remaining()
	var total_spent: int = current_points_spent
	
	# Update total spent label
	total_spent_label.text = "Total Points Spent: %d" % total_spent
	
	# Update remaining points label
	remaining_label.text = "Points Remaining: %d / %d" % [remaining_points, POINT_BUY_TOTAL]
	
	# Color coding for remaining points - use theme colors only
	var theme_resource: Theme = get_theme()
	var gold_color: Color
	var red_color: Color
	if theme_resource:
		if theme_resource.has_color("positive", "Label"):
			gold_color = theme_resource.get_color("positive", "Label")
		else:
			# Fallback only if theme doesn't define positive color
			gold_color = Color(1, 0.843137, 0, 1)
		if theme_resource.has_color("negative", "Label"):
			red_color = theme_resource.get_color("negative", "Label")
		else:
			# Fallback only if theme doesn't define negative color
			red_color = Color(0.9, 0.3, 0.3, 1.0)
	else:
		# Only use hardcoded colors if theme is completely missing
		gold_color = Color(1, 0.843137, 0, 1)
		red_color = Color(0.9, 0.3, 0.3, 1.0)
	remaining_label.add_theme_color_override("font_color", gold_color if remaining_points >= 0 else red_color)
	
	# Update breakdown - clear existing labels
	for child in spent_breakdown.get_children():
		child.queue_free()
	
	# Create breakdown labels for each ability showing: StatName: final_value(+modifier)
	# Display final ability score (base + racial) with its D&D 5e modifier
	for ability_key in ABILITY_ORDER:
		# Get final ability score (base + racial bonus) - this is what gets displayed
		var final_score: int = PlayerData.get_final_ability_score(ability_key)
		
		# Calculate D&D 5e ability modifier: floor((score - 10) / 2.0)
		var modifier: int = floori((final_score - 10) / 2.0)
		
		# Format modifier string: +X for positive/zero, -X for negative
		# Use %+d which adds + for positive/zero, - for negative
		var mod_str: String = "%+d" % modifier
		# Fix edge case where %+d might produce "+-" (shouldn't happen, but defensive)
		mod_str = mod_str.replace("+-", "-")
		
		# Get ability short name from GameData (data-driven, no hardcoded strings)
		var ability_data: Dictionary = GameData.abilities.get(ability_key, {})
		var stat_name: String = ability_data.get("short", ability_key.substr(0, 3).to_upper())
		
		# Format: StatName: final_value(+modifier) or StatName: final_value(-modifier)
		# Examples: "Dex: 12(+2)", "Str: 17(+3)", "Con: 8(-1)"
		var label := Label.new()
		label.text = "%s: %d(%s)" % [stat_name, final_score, mod_str]
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		spent_breakdown.add_child(label)
	
	Logger.debug("AbilityScoreTab: _update_preview() - spent: %d, remaining: %d" % [total_spent, remaining_points], "character_creation")

func _update_confirm_button_state() -> void:
	"""Update confirm button state based on points remaining"""
	if not confirm_button:
		Logger.warning("AbilityScoreTab: _update_confirm_button_state() called but confirm_button is null!", "character_creation")
		return
	
	var points: int = get_points_remaining()
	var old_disabled: bool = confirm_button.disabled
	var old_text: String = confirm_button.text
	
	if points == 0:
		confirm_button.disabled = false
		confirm_button.text = "Confirm Ability Scores →"
	else:
		confirm_button.disabled = true
		if points > 0:
			confirm_button.text = "Spend %d More Points" % points
		else:
			confirm_button.text = "Points Over Budget"
	
	if old_disabled != confirm_button.disabled or old_text != confirm_button.text:
		Logger.debug("AbilityScoreTab: Confirm button state changed - disabled: %s, text: '%s' (points: %d)" % [
			confirm_button.disabled, confirm_button.text, points
		], "character_creation")

func _on_stats_changed() -> void:
	"""Handle ability score changes"""
	Logger.debug("AbilityScoreTab: _on_stats_changed() signal received", "character_creation")
	_refresh_all()
	_update_confirm_button_state()

func _on_points_changed() -> void:
	"""Handle points remaining changes"""
	Logger.debug("AbilityScoreTab: _on_points_changed() signal received - remaining: %d" % get_points_remaining(), "character_creation")
	_update_preview()
	_refresh_all()
	_update_confirm_button_state()

func _on_racial_bonuses_updated() -> void:
	"""Handle racial bonus updates"""
	Logger.debug("AbilityScoreTab: _on_racial_bonuses_updated() signal received", "character_creation")
	_refresh_all()

func _on_confirm_button_pressed() -> void:
	"""Handle confirm button press"""
	# Disable button immediately to prevent spam clicks
	if confirm_button:
		confirm_button.disabled = true
	
	var points: int = get_points_remaining()
	if points != 0:
		Logger.warning("AbilityScoreTab: Confirm pressed but %d points remaining!" % points, "character_creation")
		if confirm_button:
			confirm_button.disabled = false
		return
	
	Logger.info("AbilityScoreTab: Ability scores confirmed - emitting tab_completed signal", "character_creation")
	Logger.debug("AbilityScoreTab: tab_completed signal has %d connections" % tab_completed.get_connections().size(), "character_creation")
	
	# Explicitly emit the signal with logging
	if tab_completed.get_connections().is_empty():
		Logger.error("AbilityScoreTab: tab_completed signal has no connections! Tab advancement will fail.", "character_creation")
	else:
		for conn in tab_completed.get_connections():
			Logger.debug("AbilityScoreTab: tab_completed connected to: %s" % str(conn), "character_creation")
	
	tab_completed.emit()
	Logger.info("AbilityScoreTab: tab_completed signal emitted - awaiting tab transition", "character_creation")

func _on_back_button_pressed() -> void:
	"""Handle back button press (if needed)"""
	Logger.info("AbilityScoreTab: Back button pressed", "character_creation")
	# Could navigate back to previous tab if needed

func _initialize_stats_to_default() -> void:
	"""Initialize all stats to 8 (cost 0 each = 0 points spent, 27 remaining)"""
	var changed: bool = false
	
	for ability_key in ABILITY_ORDER:
		if not PlayerData.ability_scores.has(ability_key) or PlayerData.ability_scores[ability_key] != 8:
			PlayerData.ability_scores[ability_key] = 8
			changed = true
	
	if changed:
		Logger.info("AbilityScoreTab: Initialized all stats to 8", "character_creation")
		PlayerData.stats_changed.emit()

func get_points_remaining() -> int:
	"""Get remaining point-buy points"""
	return POINT_BUY_TOTAL - current_points_spent

func can_afford(stat_value: int, new_value: int) -> bool:
	"""Check if we can afford the stat change"""
	# Clamp to valid range
	var min_stat: int = 6
	var max_stat: int = 26
	if point_buy_table and point_buy_table.has_method("get_min_stat"):
		min_stat = point_buy_table.get_min_stat()
	if point_buy_table and point_buy_table.has_method("get_max_stat"):
		max_stat = point_buy_table.get_max_stat()
	var original_new_value: int = new_value
	new_value = clampi(new_value, min_stat, max_stat)
	
	if original_new_value != new_value:
		Logger.debug("AbilityScoreTab: can_afford() clamped value %d -> %d (range: %d-%d)" % [
			original_new_value, new_value, min_stat, max_stat
		], "character_creation")
	
	var current_cost: int = get_cost(stat_value)
	var new_cost: int = get_cost(new_value)
	var cost_difference: int = new_cost - current_cost
	var remaining: int = get_points_remaining()
	var can_afford_result: bool = cost_difference <= remaining
	
	if not can_afford_result:
		Logger.debug("AbilityScoreTab: can_afford(%d -> %d) = false (cost_diff: %d, remaining: %d)" % [
			stat_value, new_value, cost_difference, remaining
		], "character_creation")
	
	return can_afford_result

func apply_stat_change(ability_key: String, old_value: int, new_value: int) -> void:
	"""Apply stat change and update points spent"""
	# Clamp to valid range
	var min_stat: int = 6
	var max_stat: int = 26
	if point_buy_table and point_buy_table.has_method("get_min_stat"):
		min_stat = point_buy_table.get_min_stat()
	if point_buy_table and point_buy_table.has_method("get_max_stat"):
		max_stat = point_buy_table.get_max_stat()
	var original_new_value: int = new_value
	new_value = clampi(new_value, min_stat, max_stat)
	
	if original_new_value != new_value:
		Logger.warning("AbilityScoreTab: apply_stat_change() clamped %s value %d -> %d" % [
			ability_key, original_new_value, new_value
		], "character_creation")
	
	var old_cost: int = get_cost(old_value)
	var new_cost: int = get_cost(new_value)
	var cost_difference: int = new_cost - old_cost
	var old_points_spent: int = current_points_spent
	
	# Update stat
	PlayerData.ability_scores[ability_key] = new_value
	
	# Update points spent
	current_points_spent += cost_difference
	current_points_spent = clampi(current_points_spent, 0, POINT_BUY_TOTAL)
	
	if current_points_spent != old_points_spent + cost_difference:
		Logger.warning("AbilityScoreTab: apply_stat_change() clamped points_spent %d -> %d" % [
			old_points_spent + cost_difference, current_points_spent
		], "character_creation")
	
	Logger.debug("AbilityScoreTab: apply_stat_change(%s: %d -> %d, cost: %d -> %d, points: %d -> %d)" % [
		ability_key, old_value, new_value, old_cost, new_cost, old_points_spent, current_points_spent
	], "character_creation")
	
	# Emit signals
	PlayerData.stats_changed.emit()
	PlayerData.points_changed.emit()

func _recalculate_points() -> void:
	"""Recalculate points remaining based on current ability scores"""
	var old_points_spent: int = current_points_spent
	current_points_spent = 0
	
	# Calculate total points spent using cost table
	var breakdown: Dictionary = {}
	for ability_key in ABILITY_ORDER:
		var base: int = PlayerData.ability_scores.get(ability_key, 8)
		var cost: int = get_cost(base)
		current_points_spent += cost
		breakdown[ability_key] = {"base": base, "cost": cost}
	
	# Never allow points_spent > POINT_BUY_TOTAL
	var unclamped_points: int = current_points_spent
	current_points_spent = clampi(current_points_spent, 0, POINT_BUY_TOTAL)
	
	if unclamped_points != current_points_spent:
		Logger.warning("AbilityScoreTab: _recalculate_points() clamped points_spent %d -> %d (over budget!)" % [
			unclamped_points, current_points_spent
		], "character_creation")
	
	Logger.debug("AbilityScoreTab: Recalculated points - spent: %d (was %d), remaining: %d" % [
		current_points_spent, old_points_spent, get_points_remaining()
	], "character_creation")
	
	if old_points_spent != current_points_spent:
		Logger.info("AbilityScoreTab: Points recalculation changed total from %d to %d" % [
			old_points_spent, current_points_spent
		], "character_creation")
	
	PlayerData.points_changed.emit()

func _notification(what: int) -> void:
	"""Handle resize notifications to update layout."""
	if what == NOTIFICATION_RESIZED:
		if left_column:
			left_column.update_minimum_size()
			left_column.queue_sort()
		if right_column:
			right_column.update_minimum_size()
			right_column.queue_sort()
		if unified_scroll:
			unified_scroll.queue_sort()
		queue_redraw()
