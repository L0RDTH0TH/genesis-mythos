# ╔═══════════════════════════════════════════════════════════
# ║ StatsTab.gd
# ║ Desc: Displays character stats in classic D&D 5e layout
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

const StatRowScene: PackedScene = preload("res://scenes/character/tabs/components/StatRow.tscn")
const SavingThrowRowScene: PackedScene = preload("res://scenes/character/tabs/components/SavingThrowRow.tscn")
const SkillRowScene: PackedScene = preload("res://scenes/character/tabs/components/SkillRow.tscn")

const ABILITY_ORDER := ["STR", "DEX", "CON", "INT", "WIS", "CHA"]
const ABILITY_FULL_NAMES := {
	"STR": "Strength",
	"DEX": "Dexterity",
	"CON": "Constitution",
	"INT": "Intelligence",
	"WIS": "Wisdom",
	"CHA": "Charisma"
}

const SAVING_THROW_ABILITIES := ["STR", "DEX", "CON", "INT", "WIS", "CHA"]

const SKILL_NAMES := {
	"acrobatics": "Acrobatics",
	"animal_handling": "Animal Handling",
	"arcana": "Arcana",
	"athletics": "Athletics",
	"deception": "Deception",
	"history": "History",
	"insight": "Insight",
	"intimidation": "Intimidation",
	"investigation": "Investigation",
	"medicine": "Medicine",
	"nature": "Nature",
	"perception": "Perception",
	"performance": "Performance",
	"persuasion": "Persuasion",
	"religion": "Religion",
	"sleight_of_hand": "Sleight of Hand",
	"stealth": "Stealth",
	"survival": "Survival"
}

@onready var name_label: Label = %NameLabel
@onready var details_label: Label = %DetailsLabel
@onready var portrait_texture: TextureRect = %PortraitTexture
@onready var ability_grid: GridContainer = %AbilityGrid
@onready var saving_throws_vbox: VBoxContainer = %SavingThrowsVBox
@onready var skills_vbox: VBoxContainer = %SkillsVBox
@onready var proficiencies_vbox: VBoxContainer = %ProficienciesVBox
@onready var hp_label: Label = %HPLabel
@onready var ac_label: Label = %ACLabel
@onready var speed_label: Label = %SpeedLabel
@onready var initiative_label: Label = %InitiativeLabel
@onready var prof_bonus_label: Label = %ProfBonusLabel
@onready var passive_perception_label: Label = %PassivePerceptionLabel
@onready var resistances_label: Label = %ResistancesLabel
@onready var vulnerabilities_label: Label = %VulnerabilitiesLabel
@onready var immunities_label: Label = %ImmunitiesLabel
@onready var senses_label: Label = %SensesLabel

func _ready() -> void:
	"""Initialize the stats display"""
	update_display()

func update_display() -> void:
	"""Update all stat displays from PlayerData"""
	_update_character_header()
	_update_ability_scores()
	_update_saving_throws()
	_update_skills()
	_update_proficiencies()
	_update_core_stats()
	_update_special_properties()

func _update_character_header() -> void:
	"""Update character name and details"""
	if name_label:
		name_label.text = PlayerData.character_name if PlayerData.character_name != "" else "Unnamed Character"
	
	if details_label:
		var race_name: String = _get_race_display_name()
		var character_class_name: String = _get_class_display_name()
		var level: int = _get_character_level()
		details_label.text = "%s / %s / Level %d" % [race_name, character_class_name, level]
	
	# Portrait would be loaded from appearance_data if available
	if portrait_texture and PlayerData.appearance_data.has("portrait"):
		var portrait_path: String = PlayerData.appearance_data.get("portrait", "")
		if portrait_path != "":
			var texture: Texture2D = load(portrait_path)
			if texture:
				portrait_texture.texture = texture

func _update_ability_scores() -> void:
	"""Populate the 3x2 ability score grid"""
	# Clear existing rows
	for child in ability_grid.get_children():
		child.queue_free()
	
	# Create ability rows
	for ability_short in ABILITY_ORDER:
		var ability_full: String = ABILITY_FULL_NAMES[ability_short]
		var ability_key: String = ability_short.to_lower()
		
		# Get ability score from PlayerData
		var score: int = 10  # Default
		if PlayerData.ability_scores.has(ability_key):
			score = PlayerData.ability_scores[ability_key]
		
		var row := StatRowScene.instantiate()
		if row and row.has_method("set_stat"):
			row.set_stat(ability_full, score)
			ability_grid.add_child(row)

func _update_saving_throws() -> void:
	"""Populate saving throws column"""
	# Clear existing rows
	for child in saving_throws_vbox.get_children():
		if child.name != "SavingTitle":
			child.queue_free()
	
	var proficiency_bonus: int = _get_proficiency_bonus()
	
	for ability_short in SAVING_THROW_ABILITIES:
		var ability_full: String = ABILITY_FULL_NAMES[ability_short]
		var ability_key: String = ability_short.to_lower()
		
		# Get ability score and calculate modifier
		var score: int = 10
		if PlayerData.ability_scores.has(ability_key):
			score = PlayerData.ability_scores[ability_key]
		var modifier: int = floor((score - 10) / 2.0)
		
		# Check if proficient (simplified - would check class/features)
		var is_proficient: bool = _has_saving_throw_proficiency(ability_short)
		if is_proficient:
			modifier += proficiency_bonus
		
		var row := SavingThrowRowScene.instantiate()
		if row and row.has_method("set_saving_throw"):
			row.set_saving_throw(ability_full, modifier, is_proficient)
			saving_throws_vbox.add_child(row)

func _update_skills() -> void:
	"""Populate skills column"""
	# Clear existing rows
	for child in skills_vbox.get_children():
		if child.name != "SkillsTitle":
			child.queue_free()
	
	var proficiency_bonus: int = _get_proficiency_bonus()
	var dex_modifier: int = _get_ability_modifier("dexterity")
	var wis_modifier: int = _get_ability_modifier("wisdom")
	
	# Simplified skill list - would normally come from data files
	var skills_to_display: Array[String] = [
		"acrobatics", "animal_handling", "arcana", "athletics",
		"deception", "history", "insight", "intimidation",
		"investigation", "medicine", "nature", "perception",
		"performance", "persuasion", "religion", "sleight_of_hand",
		"stealth", "survival"
	]
	
	for skill_key in skills_to_display:
		var skill_name: String = SKILL_NAMES.get(skill_key, skill_key.capitalize())
		
		# Determine which ability the skill uses
		var ability_modifier: int = 0
		match skill_key:
			"acrobatics", "sleight_of_hand", "stealth":
				ability_modifier = dex_modifier
			"animal_handling", "insight", "medicine", "perception", "survival":
				ability_modifier = wis_modifier
			_:
				ability_modifier = _get_ability_modifier_for_skill(skill_key)
		
		# Check if proficient
		var is_proficient: bool = _has_skill_proficiency(skill_key)
		var total_modifier: int = ability_modifier
		if is_proficient:
			total_modifier += proficiency_bonus
		
		var row := SkillRowScene.instantiate()
		if row and row.has_method("set_skill"):
			row.set_skill(skill_name, total_modifier, is_proficient)
			skills_vbox.add_child(row)

func _update_proficiencies() -> void:
	"""Populate proficiencies column"""
	# Clear existing items
	for child in proficiencies_vbox.get_children():
		if child.name != "ProfTitle":
			child.queue_free()
	
	var proficiencies: Array[String] = _get_all_proficiencies()
	
	if proficiencies.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "None"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		proficiencies_vbox.add_child(empty_label)
	else:
		for prof in proficiencies:
			var label: Label = Label.new()
			label.text = "• %s" % prof
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			proficiencies_vbox.add_child(label)

func _update_core_stats() -> void:
	"""Update core stats labels"""
	if hp_label:
		var hp_current: int = _get_hp_current()
		var hp_max: int = _get_hp_max()
		hp_label.text = "Hit Points: %d / %d" % [hp_current, hp_max]
	
	if ac_label:
		var ac: int = _get_armor_class()
		ac_label.text = "Armor Class: %d" % ac
	
	if speed_label:
		var speed: String = _get_speed()
		speed_label.text = "Speed: %s" % speed
	
	if initiative_label:
		var initiative: int = _get_initiative()
		if initiative >= 0:
			initiative_label.text = "Initiative: +%d" % initiative
		else:
			initiative_label.text = "Initiative: %d" % initiative
	
	if prof_bonus_label:
		var prof_bonus: int = _get_proficiency_bonus()
		prof_bonus_label.text = "Proficiency Bonus: +%d" % prof_bonus
	
	if passive_perception_label:
		var passive_perception: int = _get_passive_perception()
		passive_perception_label.text = "Passive Wisdom (Perception): %d" % passive_perception

func _update_special_properties() -> void:
	"""Update resistances, vulnerabilities, immunities, senses"""
	if resistances_label:
		var resistances: Array[String] = _get_resistances()
		if resistances.is_empty():
			resistances_label.text = "Resistances: none"
		else:
			resistances_label.text = "Resistances: %s" % ", ".join(resistances)
	
	if vulnerabilities_label:
		var vulnerabilities: Array[String] = _get_vulnerabilities()
		if vulnerabilities.is_empty():
			vulnerabilities_label.text = "Damage Vulnerabilities: none"
		else:
			vulnerabilities_label.text = "Damage Vulnerabilities: %s" % ", ".join(vulnerabilities)
	
	if immunities_label:
		var immunities: Array[String] = _get_immunities()
		if immunities.is_empty():
			immunities_label.text = "Condition Immunities: none"
		else:
			immunities_label.text = "Condition Immunities: %s" % ", ".join(immunities)
	
	if senses_label:
		var senses: Array[String] = _get_senses()
		if senses.is_empty():
			senses_label.text = "Senses: Normal"
		else:
			senses_label.text = "Senses: %s" % ", ".join(senses)

# Helper functions to get computed values

func _get_race_display_name() -> String:
	"""Get formatted race name"""
	if PlayerData.subrace_id != "":
		# Try to get subrace name from race_data
		if PlayerData.race_data.has("subraces"):
			var subraces: Array = PlayerData.race_data.get("subraces", [])
			for subrace in subraces:
				if subrace.get("id", "") == PlayerData.subrace_id:
					return subrace.get("name", PlayerData.race_id.capitalize())
	
	# Fallback to race name or ID
	if PlayerData.race_data.has("name"):
		return PlayerData.race_data.get("name", "")
	return PlayerData.race_id.capitalize() if PlayerData.race_id != "" else "No Race"

func _get_class_display_name() -> String:
	"""Get formatted class name"""
	if PlayerData.class_data.has("name"):
		return PlayerData.class_data.get("name", "")
	return PlayerData.class_id.capitalize() if PlayerData.class_id != "" else "No Class"

func _get_character_level() -> int:
	"""Get character level (default to 1)"""
	return 1  # Would normally come from PlayerData or character resource

func _get_proficiency_bonus() -> int:
	"""Calculate proficiency bonus based on level"""
	var level: int = _get_character_level()
	return ceil(level / 4.0) + 1  # 5e formula: +2 at levels 1-4, +3 at 5-8, etc.

func _get_ability_modifier(ability_key: String) -> int:
	"""Get ability modifier for given ability"""
	var score: int = 10
	if PlayerData.ability_scores.has(ability_key):
		score = PlayerData.ability_scores[ability_key]
	return floor((score - 10) / 2.0)

func _get_ability_modifier_for_skill(skill_key: String) -> int:
	"""Get ability modifier for a skill based on its ability"""
	# Simplified mapping - would normally come from data files
	var ability_skill_map := {
		"strength": ["athletics"],
		"dexterity": ["acrobatics", "sleight_of_hand", "stealth"],
		"constitution": [],
		"intelligence": ["arcana", "history", "investigation", "nature", "religion"],
		"wisdom": ["animal_handling", "insight", "medicine", "perception", "survival"],
		"charisma": ["deception", "intimidation", "performance", "persuasion"]
	}
	
	for ability in ability_skill_map.keys():
		if skill_key in ability_skill_map[ability]:
			return _get_ability_modifier(ability)
	
	return 0

func _has_saving_throw_proficiency(ability_short: String) -> bool:
	"""Check if character has proficiency in this saving throw"""
	# Simplified - would check class saving throw proficiencies from data
	return false

func _has_skill_proficiency(skill_key: String) -> bool:
	"""Check if character has proficiency in this skill"""
	# Simplified - would check class/background/race skill proficiencies from data
	return false

func _get_all_proficiencies() -> Array[String]:
	"""Get all weapon/armor/language proficiencies"""
	var proficiencies: Array[String] = []
	
	# Get from class
	if PlayerData.class_data.has("proficiencies"):
		var class_profs: Array = PlayerData.class_data.get("proficiencies", [])
		if class_profs is Array:
			proficiencies.append_array(class_profs)
	
	# Get from race (would parse features)
	# Get from background (would parse features)
	
	return proficiencies

func _get_hp_current() -> int:
	"""Get current hit points"""
	return 0  # Would come from PlayerData

func _get_hp_max() -> int:
	"""Get maximum hit points"""
	return 0  # Would be calculated from class hit die, constitution, level

func _get_armor_class() -> int:
	"""Get armor class"""
	return 10  # Default 10 + dex modifier, modified by armor

func _get_speed() -> String:
	"""Get movement speed"""
	if PlayerData.race_data.has("speed"):
		return PlayerData.race_data.get("speed", "30 ft")
	return "30 ft"

func _get_initiative() -> int:
	"""Get initiative modifier"""
	return _get_ability_modifier("dexterity")

func _get_passive_perception() -> int:
	"""Get passive perception score"""
	var wis_modifier: int = _get_ability_modifier("wisdom")
	var base: int = 10 + wis_modifier
	
	# Add proficiency bonus if perception is proficient
	if _has_skill_proficiency("perception"):
		base += _get_proficiency_bonus()
	
	return base

func _get_resistances() -> Array[String]:
	"""Get damage resistances"""
	var resistances: Array[String] = []
	# Would parse from race/class features
	return resistances

func _get_vulnerabilities() -> Array[String]:
	"""Get damage vulnerabilities"""
	var vulnerabilities: Array[String] = []
	# Would parse from race/class features
	return vulnerabilities

func _get_immunities() -> Array[String]:
	"""Get condition immunities"""
	var immunities: Array[String] = []
	# Would parse from race/class features
	return immunities

func _get_senses() -> Array[String]:
	"""Get special senses"""
	var senses: Array[String] = []
	
	# Check race features for darkvision, etc.
	if PlayerData.race_data.has("features"):
		var features: Array = PlayerData.race_data.get("features", [])
		if features is Array:
			for feature in features:
				if feature is String:
					var feature_lower: String = feature.to_lower()
					if "darkvision" in feature_lower:
						senses.append(feature)
	
	return senses

