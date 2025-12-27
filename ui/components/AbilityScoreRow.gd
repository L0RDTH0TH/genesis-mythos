# ╔═══════════════════════════════════════════════════════════
# ║ AbilityScoreRow.gd
# ║ Desc: Point-buy row with live racial bonus and modifier display
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name AbilityScoreRow
extends HBoxContainer

@export var ability_key: String = ""

signal value_changed(ability: String, new_base: int)

@onready var name_label: Label = %NameLabel
@onready var base_label: Label = %BaseLabel
@onready var bonus_label: Label = %BonusLabel
@onready var final_label: Label = %FinalLabel
@onready var mod_label: Label = %ModLabel
@onready var minus_btn: Button = %MinusButton
@onready var plus_btn: Button = %PlusButton

var base_value: int = 8
var racial_bonus: int = 0

func _ready() -> void:
	"""Initialize the ability score row"""
	_apply_ui_constants()
	if name_label:
		var ability_data: Dictionary = GameData.abilities.get(ability_key, {})
		name_label.text = ability_data.get("full", ability_key.capitalize())
	
	_refresh()
	minus_btn.pressed.connect(_on_minus_pressed)
	plus_btn.pressed.connect(_on_plus_pressed)
	
	if PlayerData:
		if not PlayerData.racial_bonuses_updated.is_connected(_on_racial_bonus_changed):
			PlayerData.racial_bonuses_updated.connect(_on_racial_bonus_changed)
		if not PlayerData.points_changed.is_connected(_on_points_changed):
			PlayerData.points_changed.connect(_on_points_changed)
		if not PlayerData.stats_changed.is_connected(_on_stats_changed):
			PlayerData.stats_changed.connect(_on_stats_changed)


func _apply_ui_constants() -> void:
	"""Apply UIConstants-based sizing for labels and buttons."""
	if name_label:
		name_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
	if base_label:
		base_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_NARROW, 0)
	if bonus_label:
		bonus_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_NARROW, 0)
	if final_label:
		final_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_COMPACT, 0)
	if mod_label:
		mod_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_COMPACT, 0)
	if minus_btn:
		minus_btn.custom_minimum_size = Vector2(UIConstants.ICON_SIZE_SMALL, UIConstants.ICON_SIZE_SMALL)
	if plus_btn:
		plus_btn.custom_minimum_size = Vector2(UIConstants.ICON_SIZE_SMALL, UIConstants.ICON_SIZE_SMALL)

func setup(initial_base: int, bonus: int) -> void:
	"""Setup the row with initial base value and racial bonus"""
	base_value = initial_base
	racial_bonus = bonus
	_refresh()

func _refresh() -> void:
	"""Refresh all display elements"""
	if base_label:
		base_label.text = str(base_value)
	
	var final: int = base_value + racial_bonus
	if final_label:
		final_label.text = str(final)
	
	if bonus_label:
		if racial_bonus != 0:
			bonus_label.text = "%+d" % racial_bonus
			bonus_label.visible = true
		else:
			bonus_label.text = ""
			bonus_label.visible = false
	
	var mod: int = floor((final - 10) / 2.0)
	if mod_label:
		mod_label.text = "%+d" % mod
		# GUI Performance Fix: Use modulate instead of theme override for color coding
		if mod >= 0:
			mod_label.modulate = Color.WHITE
		else:
			mod_label.modulate = Color(0.9, 0.4, 0.4, 1.0)  # Red tint for negative
	
	_update_button_states()

func _update_button_states() -> void:
	"""Update button enabled/disabled states based on current values and points"""
	if not PlayerData:
		return
	
	var current: int = PlayerData.ability_scores.get(ability_key, PlayerData.get_min_score())
	# TODO: Re-implement point-buy calculation logic here
	# var remaining: int = PlayerData.get_remaining_points()
	
	if minus_btn:
		# TODO: Re-implement point-buy calculation logic here
		# Cost calculation removed - only check range limits
		# var refund: int = PlayerData.get_cost_to_decrease(current)
		# minus_btn.disabled = (current <= PlayerData.get_min_score()) or (remaining < PlayerData.get_cost_to_increase(current - 1))
		minus_btn.disabled = (current <= PlayerData.get_min_score())
	
	if plus_btn:
		# TODO: Re-implement point-buy calculation logic here
		# Cost calculation removed - only check range limits
		# var cost: int = PlayerData.get_cost_to_increase(current)
		# plus_btn.disabled = (current >= PlayerData.get_max_score()) or (cost > remaining)
		plus_btn.disabled = (current >= PlayerData.get_max_score())

func _on_minus_pressed() -> void:
	"""Handle minus button press"""
	if PlayerData.decrease_ability_score(ability_key):
		base_value = PlayerData.ability_scores.get(ability_key, PlayerData.get_min_score())
		_refresh()
		value_changed.emit(ability_key, base_value)

func _on_plus_pressed() -> void:
	"""Handle plus button press"""
	if PlayerData.increase_ability_score(ability_key):
		base_value = PlayerData.ability_scores.get(ability_key, PlayerData.get_min_score())
		_refresh()
		value_changed.emit(ability_key, base_value)

func _on_racial_bonus_changed() -> void:
	"""Handle racial bonus updates"""
	racial_bonus = PlayerData.get_racial_bonus(ability_key)
	_refresh()

func _on_points_changed() -> void:
	"""Handle points remaining changes"""
	_update_button_states()

func _on_stats_changed() -> void:
	"""Handle ability score changes"""
	base_value = PlayerData.ability_scores.get(ability_key, PlayerData.get_min_score())
	_refresh()

