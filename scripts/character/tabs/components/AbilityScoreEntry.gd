# ╔═══════════════════════════════════════════════════════════
# ║ AbilityScoreEntry.gd
# ║ Desc: Tall vertical ability score card – exact BG3 aesthetic
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name AbilityScoreEntry
extends PanelContainer

signal value_changed(ability_key: String, delta: int)

@onready var label_name: Label = %AbilityNameLabel
@onready var label_base: Label = %BaseLabel
@onready var label_bonus: Label = %BonusLabel
@onready var label_total: Label = %TotalLabel
@onready var btn_minus: Button = %ButtonMinus
@onready var btn_plus: Button = %ButtonPlus

var ability_key: String = ""
var ability_name: String = ""
var base_value: int = 8
var racial_bonus: int = 0
var is_selected: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	
	if btn_plus:
		btn_plus.pressed.connect(_on_plus_pressed)
	else:
		Logger.error("AbilityScoreEntry: btn_plus node missing!", "character_creation")
	
	if btn_minus:
		btn_minus.pressed.connect(_on_minus_pressed)
	else:
		Logger.error("AbilityScoreEntry: btn_minus node missing!", "character_creation")
	
	# Connect to PlayerData signals to update button states when points change
	if PlayerData:
		if not PlayerData.points_changed.is_connected(_on_points_changed):
			PlayerData.points_changed.connect(_on_points_changed)
		if not PlayerData.stats_changed.is_connected(_on_stats_changed):
			PlayerData.stats_changed.connect(_on_stats_changed)
	else:
		Logger.error("AbilityScoreEntry: PlayerData singleton not found!", "character_creation")
	
	_update_style()
	update_visuals()
	Logger.debug("AbilityScoreEntry: _ready() complete for ability: %s" % ability_key, "character_creation")

func setup(key: String, name_text: String, initial_base: int = 8, racial: int = 0) -> void:
	ability_key = key
	ability_name = name_text
	base_value = initial_base
	racial_bonus = racial
	Logger.debug("AbilityScoreEntry: setup() called - %s (base: %d, racial: %d)" % [name_text, initial_base, racial], "character_creation")
	update_visuals()

func update_visuals() -> void:
	if not is_inside_tree():
		call_deferred("update_visuals")
		return
	
	# Refresh values from PlayerData
	if PlayerData:
		base_value = PlayerData.ability_scores.get(ability_key, 8)
		racial_bonus = PlayerData.get_racial_bonus(ability_key)
	else:
		Logger.warning("AbilityScoreEntry: update_visuals() called but PlayerData is null for %s!" % ability_key, "character_creation")
	
	if label_name:
		label_name.text = ability_name
	else:
		Logger.warning("AbilityScoreEntry: label_name missing for %s!" % ability_key, "character_creation")
	
	var total: int = base_value + racial_bonus
	
	if label_base:
		label_base.text = "Base: %d" % base_value
	else:
		Logger.warning("AbilityScoreEntry: label_base missing for %s!" % ability_key, "character_creation")
	
	# Calculate D&D 5e modifier: floor((score - 10) / 2)
	var total_modifier: int = floori((total - 10) / 2.0)
	
	# Update modifier label with proper color coding - use theme colors
	if label_bonus:
		label_bonus.visible = true
		var theme_resource: Theme = get_theme()
		if total_modifier > 0:
			label_bonus.text = "Bonus: +%d" % total_modifier
			if theme_resource and theme_resource.has_color("positive", "Label"):
				label_bonus.modulate = theme_resource.get_color("positive", "Label")
			else:
				label_bonus.modulate = Color(0.8, 1.0, 0.6)  # fallback: light green/gold
		elif total_modifier < 0:
			label_bonus.text = "Bonus: %d" % total_modifier
			if theme_resource and theme_resource.has_color("negative", "Label"):
				label_bonus.modulate = theme_resource.get_color("negative", "Label")
			else:
				label_bonus.modulate = Color(1.0, 0.4, 0.4)  # fallback: red
		else:
			label_bonus.text = "Bonus: +0"
			if theme_resource and theme_resource.has_color("font_color", "Label"):
				label_bonus.modulate = theme_resource.get_color("font_color", "Label")
			else:
				label_bonus.modulate = Color(0.7, 0.7, 0.7)  # fallback: gray
	
	if label_total:
		label_total.text = str(total)
	
	# Add tooltip with full breakdown
	tooltip_text = "Base: %d\nRacial: %+d\nTotal: %d → Modifier: %+d" % [
		base_value, racial_bonus, total, total_modifier
	]
	
	# Update style based on value (but don't override hover/selected states)
	if not is_selected:
		var style_name: String = "race_button_normal"
		if total >= 14:
			style_name = "race_button_selected"
		elif total > 8:
			style_name = "race_button_hover"
		
		var theme_resource := load("res://themes/bg3_theme.tres") as Theme
		if theme_resource:
			var stylebox := theme_resource.get_stylebox(style_name, "PanelContainer")
			if stylebox:
				add_theme_stylebox_override("panel", stylebox)
	
	_update_button_states()
	Logger.debug("AbilityScoreEntry: update_visuals() complete - %s (base: %d, racial: %d, total: %d)" % [
		ability_key, base_value, racial_bonus, total
	], "character_creation")

func _update_button_states() -> void:
	"""Update button states enforcing strict data-driven range and point-buy affordability"""
	if not PlayerData:
		Logger.warning("AbilityScoreEntry: _update_button_states() called but PlayerData is null for %s!" % ability_key, "character_creation")
		return
	
	# Get parent node that has can_afford method (AbilityScoreTab)
	var parent_tab: Node = null
	var node: Node = get_parent()
	while node:
		if node.has_method("can_afford"):
			parent_tab = node
			break
		node = node.get_parent()
	
	if not parent_tab:
		Logger.warning("AbilityScoreEntry: _update_button_states() - parent tab with can_afford() not found for %s!" % ability_key, "character_creation")
	
	var current: int = PlayerData.ability_scores.get(ability_key, 8)
	var min_score: int = 6  # Point-buy range: 6-26
	var max_score: int = 26
	
	var old_minus_disabled: bool = btn_minus.disabled if btn_minus else true
	var old_plus_disabled: bool = btn_plus.disabled if btn_plus else true
	
	# Enforce strict limits: cannot go below min_score or above max_score (before racial bonuses)
	if btn_minus:
		var can_decrease: bool = (current > min_score)
		# Decrease always refunds points, so it's always affordable if within range
		btn_minus.disabled = not can_decrease
	else:
		Logger.warning("AbilityScoreEntry: btn_minus missing for %s!" % ability_key, "character_creation")
	
	if btn_plus:
		var can_increase: bool = (current < max_score)
		# Check if we can afford the increase
		if can_increase and parent_tab:
			var can_afford_increase: bool = parent_tab.can_afford(current, current + 1)
			btn_plus.disabled = not (can_increase and can_afford_increase)
		else:
			btn_plus.disabled = not can_increase
	else:
		Logger.warning("AbilityScoreEntry: btn_plus missing for %s!" % ability_key, "character_creation")
	
	if btn_minus and btn_plus and (old_minus_disabled != btn_minus.disabled or old_plus_disabled != btn_plus.disabled):
		Logger.debug("AbilityScoreEntry: Button states changed for %s - minus: %s -> %s, plus: %s -> %s" % [
			ability_key,
			old_minus_disabled, btn_minus.disabled,
			old_plus_disabled, btn_plus.disabled
		], "character_creation")

func _on_points_changed() -> void:
	"""Handle points remaining changes - update button states"""
	_update_button_states()

func _on_stats_changed() -> void:
	"""Handle ability score changes - update button states"""
	_update_button_states()

func _on_plus_pressed() -> void:
	Logger.debug("AbilityScoreEntry: Plus button pressed for %s" % ability_key, "character_creation")
	value_changed.emit(ability_key, 1)

func _on_minus_pressed() -> void:
	Logger.debug("AbilityScoreEntry: Minus button pressed for %s" % ability_key, "character_creation")
	value_changed.emit(ability_key, -1)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			set_selected(true)

func _on_mouse_entered() -> void:
	if not is_selected:
		_update_style("hover")

func _on_mouse_exited() -> void:
	_update_style()

func set_selected(value: bool) -> void:
	is_selected = value
	_update_style()

func _update_style(state: String = "normal") -> void:
	if is_selected:
		state = "selected"
	
	var theme_resource := load("res://themes/bg3_theme.tres") as Theme
	if not theme_resource:
		return
	
	var style_name: String = "race_button_" + state
	var stylebox := theme_resource.get_stylebox(style_name, "PanelContainer")
	if stylebox:
		add_theme_stylebox_override("panel", stylebox)
