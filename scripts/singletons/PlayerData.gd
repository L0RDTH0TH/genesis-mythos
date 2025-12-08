# ╔═══════════════════════════════════════════════════════════
# ║ PlayerData.gd
# ║ Desc: Autoload singleton to store player character creation data
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════
"""
PlayerData Singleton

Central state storage for character creation. This singleton tracks all
character creation choices (race, class, background, ability scores, etc.)
and provides methods to calculate final scores, modifiers, and bonuses.

The singleton emits signals when data changes, allowing UI components to
update in real-time.

Signals:
- stats_changed: Emitted when ability scores change
- points_changed: Emitted when point-buy points change
- racial_bonuses_updated: Emitted when race/subrace selection changes
"""
extends Node

# ============================================================
# RACE SELECTION DATA
# ============================================================

# Unique identifier for selected race (e.g., "dwarf", "elf")
# Must match an "id" field in GameData.races
var race_id: String = ""

# Unique identifier for selected subrace (e.g., "hill_dwarf", "high_elf")
# Empty string if no subrace is selected or race has no subraces
# Must match an "id" field in the race's subraces array
var subrace_id: String = ""

# Complete race data dictionary from GameData.races
# Contains all race information: name, description, features, bonuses, subraces
var race_data: Dictionary = {}

# ============================================================
# CLASS SELECTION DATA
# ============================================================

# Unique identifier for selected class (e.g., "fighter", "wizard")
# Must match an "id" field in GameData.classes
var class_id: String = ""

# Unique identifier for selected subclass (e.g., "champion", "evocation")
# Empty string if no subclass is selected or class has no subclasses
var subclass_id: String = ""

# Complete class data dictionary from GameData.classes
# Contains all class information: name, hit_die, proficiencies, features, subclasses
var class_data: Dictionary = {}

# ============================================================
# BACKGROUND SELECTION DATA
# ============================================================

# Unique identifier for selected background (e.g., "acolyte", "criminal")
# Must match an "id" field in GameData.backgrounds
var background_id: String = ""

# Complete background data dictionary from GameData.backgrounds
# Contains all background information: name, description, skill_proficiencies, feature
var background_data: Dictionary = {}

# ============================================================
# ABILITY SCORES
# ============================================================

# Base ability scores (before racial bonuses)
# Keys: "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"
# Values: Integer scores (typically 6-25 range, data-driven from point_buy.json)
# Default to 8 (standard starting value) - will be clamped to min_score on reset
var ability_scores: Dictionary = {
	"strength": 8,
	"dexterity": 8,
	"constitution": 8,
	"intelligence": 8,
	"wisdom": 8,
	"charisma": 8
}

# ============================================================
# POINT-BUY SYSTEM
# ============================================================

# Remaining point-buy points available for ability score increases
# Starts at starting_points (from point_buy.json, typically 27)
# Decreases when increasing scores, increases when decreasing scores
var points_remaining: int = 0

# ============================================================
# SKILL PROFICIENCIES
# ============================================================

# Array of skill IDs that the player has selected beyond class/background proficiencies
# Each string should match a key in GameData.skills
var selected_skill_proficiencies: Array[String] = []

# ============================================================
# APPEARANCE DATA
# ============================================================

# Dictionary storing all appearance customization data
# Structure depends on appearance system implementation
# May contain: head_preset, hair_style, skin_color, hair_color, etc.
var appearance_data: Dictionary = {}

# Character gender selection
# Valid values: "male" or "female"
# Used to load appropriate character models and assets
var gender: String = "male"

# ============================================================
# CHARACTER IDENTITY
# ============================================================

# Character's chosen name (display name)
# Can be any string, validated by NameConfirmTab
var character_name: String = ""

# Unique identifier for selected voice
# Must match an "id" field in GameData.voices
var voice_id: String = ""

# ============================================================
# SIGNALS
# ============================================================

# Emitted whenever ability scores change (increase/decrease)
# Connected components should recalculate derived values (modifiers, etc.)
signal stats_changed

# Emitted whenever point-buy points change (spent/refunded)
# Connected UI should update point display
signal points_changed

# Emitted when race or subrace selection changes
# Connected components should update racial bonuses and recalculate final scores
signal racial_bonuses_updated

func reset() -> void:
	"""Reset all player data to default values"""
	race_id = ""
	subrace_id = ""
	race_data.clear()
	class_id = ""
	subclass_id = ""
	class_data.clear()
	background_id = ""
	background_data.clear()
	# Clamp all scores to valid range (data-driven min-max) on reset
	var min_score: int = get_min_score()
	ability_scores = {
		"strength": min_score,
		"dexterity": min_score,
		"constitution": min_score,
		"intelligence": min_score,
		"wisdom": min_score,
		"charisma": min_score
	}
	points_remaining = get_starting_points()
	appearance_data.clear()
	gender = "male"
	character_name = ""
	voice_id = ""
	stats_changed.emit()
	points_changed.emit()

func get_starting_points() -> int:
	"""Get starting point-buy points from GameData"""
	if GameData.point_buy_data.has("starting_points"):
		return GameData.point_buy_data.get("starting_points", 27)
	return 27

func get_min_score() -> int:
	"""Get minimum ability score from GameData"""
	if GameData.point_buy_data.has("min_base_score"):
		return GameData.point_buy_data.get("min_base_score", 6)
	# Fallback for old JSON format
	if GameData.point_buy_data.has("min_score"):
		return GameData.point_buy_data.get("min_score", 6)
	return 6

func get_max_score() -> int:
	"""Get maximum ability score from GameData"""
	if GameData.point_buy_data.has("max_base_score"):
		return GameData.point_buy_data.get("max_base_score", 25)
	# Fallback for old JSON format
	if GameData.point_buy_data.has("max_score"):
		return GameData.point_buy_data.get("max_score", 25)
	return 25

func get_remaining_points() -> int:
	"""Get remaining point-buy points"""
	return points_remaining

func get_cost_to_increase(_current_score: int) -> int:
	"""Get cost to increase ability score from current value (marginal cost)"""
	# TODO: Re-implement point-buy calculation logic here
	# All cost calculation logic has been removed
	return 0

func get_cost_to_decrease(_current_score: int) -> int:
	"""Get points refunded when decreasing ability score (marginal cost that was paid)"""
	# TODO: Re-implement point-buy calculation logic here
	# All cost calculation logic has been removed
	return 0

func increase_ability_score(ability_key: String) -> bool:
	"""Increase an ability score if points allow"""
	var current: int = ability_scores.get(ability_key, get_min_score())
	# Enforce strict data-driven range before racial bonuses
	if current >= get_max_score():
		return false
	
	# TODO: Re-implement point-buy calculation logic here
	# Cost calculation and point deduction removed
	# var cost: int = get_cost_to_increase(current)
	# if cost > points_remaining:
	# 	return false
	
	ability_scores[ability_key] = current + 1
	# points_remaining -= cost  # Point deduction removed
	stats_changed.emit()
	points_changed.emit()
	return true

func decrease_ability_score(ability_key: String) -> bool:
	"""Decrease an ability score and refund points"""
	var current: int = ability_scores.get(ability_key, get_min_score())
	# Enforce strict data-driven range before racial bonuses
	if current <= get_min_score():
		return false
	
	# TODO: Re-implement point-buy calculation logic here
	# Cost calculation and point refund removed
	# var refund: int = get_cost_to_decrease(current)
	ability_scores[ability_key] = current - 1
	# points_remaining += refund  # Point refund removed
	stats_changed.emit()
	points_changed.emit()
	return true

func get_racial_bonus(ability_key: String) -> int:
	"""
	Get the total racial bonus for a specific ability.
	
	Calculates bonus from both race and subrace (if selected).
	Racial bonuses are additive (race bonus + subrace bonus).
	
	Parameters:
		ability_key (String): Ability key ("strength", "dexterity", etc.)
	
	Returns:
		int: Total racial bonus for the ability (can be negative, zero, or positive)
	
	Example:
		If race gives +2 CON and subrace gives +1 CON, returns 3 for "constitution"
	"""
	var bonus: int = 0
	
	# Check race bonuses
	if race_data.has("ability_bonuses"):
		var race_bonuses: Dictionary = race_data.get("ability_bonuses", {})
		bonus += race_bonuses.get(ability_key, 0)
	
	# Check subrace bonuses (if subrace is selected)
	if subrace_id != "" and race_data.has("subraces"):
		var subraces: Array = race_data.get("subraces", [])
		for subrace in subraces:
			if subrace.has("id") and subrace.get("id") == subrace_id:
				if subrace.has("ability_bonuses"):
					var subrace_bonuses: Dictionary = subrace.get("ability_bonuses", {})
					bonus += subrace_bonuses.get(ability_key, 0)
				break
	
	return bonus

func get_final_ability_score(ability_key: String) -> int:
	"""
	Get the final ability score (base score + racial bonus).
	
	This is the score used for all game calculations (modifiers, saves, etc.).
	
	Parameters:
		ability_key (String): Ability key ("strength", "dexterity", etc.)
	
	Returns:
		int: Final ability score (base + racial bonus)
	
	Example:
		If base STR is 15 and racial bonus is +2, returns 17
	"""
	var base: int = ability_scores.get(ability_key, get_min_score())
	return base + get_racial_bonus(ability_key)

func get_ability_modifier(ability_key: String) -> int:
	"""
	Calculate the ability modifier for a given ability.
	
	Formula: floor((score - 10) / 2.0)
	This is the standard D&D 5e ability modifier calculation.
	
	Parameters:
		ability_key (String): Ability key ("strength", "dexterity", etc.)
	
	Returns:
		int: Ability modifier (can be negative, zero, or positive)
	
	Examples:
		Score 8 → modifier -1
		Score 10 → modifier 0
		Score 12 → modifier +1
		Score 15 → modifier +2
		Score 18 → modifier +4
	"""
	var score: int = get_final_ability_score(ability_key)
	return floor((score - 10) / 2.0)

