# ╔═══════════════════════════════════════════════════════════
# ║ SkillsSelection.gd
# ║ Desc: Skill proficiency selection component for Ability Scores tab
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name SkillsSelection
extends VBoxContainer

signal skills_confirmed

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var remaining_label: Label = %RemainingLabel
@onready var skills_scroll: ScrollContainer = %SkillsScroll
@onready var skills_vbox: VBoxContainer = %SkillsVBox

var skill_rows: Array[Control] = []
var available_proficiency_slots: int = 0
var selected_proficiencies: Array[String] = []

func _ready() -> void:
	"""Initialize the skills selection component"""
	_update_available_slots()
	_populate_skills()
	_update_remaining_display()
	
	if PlayerData:
		PlayerData.stats_changed.connect(_on_stats_changed)

func _update_available_slots() -> void:
	"""Calculate available skill proficiency slots from class and background"""
	available_proficiency_slots = 0
	
	# Get class skill proficiencies count
	if PlayerData.class_data.has("skill_proficiencies_choose"):
		available_proficiency_slots += PlayerData.class_data.get("skill_proficiencies_choose", 0)
	
	# Get background skill proficiencies count
	if PlayerData.background_data.has("skill_proficiencies_choose"):
		available_proficiency_slots += PlayerData.background_data.get("skill_proficiencies_choose", 0)
	
	# Default to 2 if not specified (most classes give 2)
	if available_proficiency_slots == 0:
		available_proficiency_slots = 2

func _populate_skills() -> void:
	"""Populate the skills list from GameData.skills"""
	# Clear existing rows
	for child in skills_vbox.get_children():
		child.queue_free()
	skill_rows.clear()
	
	if not GameData.skills:
		push_error("GameData.skills is empty! Check data/skills.json")
		return
	
	# Sort skills by display name
	var sorted_skills: Array[String] = []
	for skill_key in GameData.skills.keys():
		sorted_skills.append(skill_key)
	
	sorted_skills.sort_custom(func(a, b): 
		var name_a: String = GameData.skills[a].get("display_name", a)
		var name_b: String = GameData.skills[b].get("display_name", b)
		return name_a < name_b
	)
	
	# Create skill rows
	for skill_key in sorted_skills:
		var skill_data: Dictionary = GameData.skills[skill_key]
		var skill_name: String = skill_data.get("display_name", skill_key.capitalize())
		var ability_key: String = skill_data.get("ability", "strength")
		
		# Check if already proficient from class/background
		var is_auto_proficient: bool = _is_auto_proficient(skill_key)
		
		# Create skill row
		var row: HBoxContainer = _create_skill_row(skill_key, skill_name, ability_key, is_auto_proficient)
		skills_vbox.add_child(row)
		skill_rows.append(row)

func _create_skill_row(skill_key: String, skill_name: String, ability_key: String, is_auto_proficient: bool) -> HBoxContainer:
	"""Create a single skill row with checkbox"""
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	
	# Checkbox
	var checkbox: CheckBox = CheckBox.new()
	checkbox.text = skill_name
	checkbox.disabled = is_auto_proficient
	checkbox.button_pressed = is_auto_proficient or skill_key in selected_proficiencies
	
	if is_auto_proficient:
		checkbox.tooltip_text = "Already proficient from class or background"
	else:
		checkbox.tooltip_text = "Select to gain proficiency in %s" % skill_name
	
	checkbox.toggled.connect(func(pressed): _on_skill_toggled(skill_key, pressed))
	row.add_child(checkbox)
	
	# Ability modifier display
	var ability_data: Dictionary = GameData.abilities.get(ability_key, {})
	var ability_short: String = ability_data.get("short", ability_key.substr(0, 3).to_upper())
	var modifier: int = PlayerData.get_ability_modifier(ability_key)
	
	var mod_label: Label = Label.new()
	mod_label.text = "(%s %+d)" % [ability_short, modifier]
	mod_label.custom_minimum_size = Vector2(100, 0)
	mod_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Color modifier based on theme
	var theme: Theme = get_theme()
	if theme:
		var pos_color: Color = Color.WHITE
		var neg_color: Color = Color(0.9, 0.4, 0.4, 1.0)
		if theme.has_color("positive_modifier", "Label"):
			pos_color = theme.get_color("positive_modifier", "Label")
		if theme.has_color("negative_modifier", "Label"):
			neg_color = theme.get_color("negative_modifier", "Label")
		mod_label.add_theme_color_override("font_color", pos_color if modifier >= 0 else neg_color)
	
	row.add_child(mod_label)
	
	return row

func _is_auto_proficient(skill_key: String) -> bool:
	"""Check if skill is automatically proficient from class or background"""
	# Check class skills
	if PlayerData.class_data.has("skill_proficiencies"):
		var class_profs: Array = PlayerData.class_data.get("skill_proficiencies", [])
		if skill_key in class_profs:
			return true
	
	# Check background skills
	if PlayerData.background_data.has("skill_proficiencies"):
		var bg_profs: Array = PlayerData.background_data.get("skill_proficiencies", [])
		if skill_key in bg_profs:
			return true
	
	return false

func _on_skill_toggled(skill_key: String, pressed: bool) -> void:
	"""Handle skill proficiency toggle"""
	if pressed:
		if skill_key not in selected_proficiencies:
			selected_proficiencies.append(skill_key)
	else:
		selected_proficiencies.erase(skill_key)
	
	PlayerData.selected_skill_proficiencies = selected_proficiencies.duplicate()
	_update_remaining_display()
	
	# Emit signal to update parent (for confirm button state)
	skills_confirmed.emit()

func _update_remaining_display() -> void:
	"""Update the remaining proficiency slots display"""
	if not remaining_label:
		return
	
	var used: int = selected_proficiencies.size()
	var remaining: int = available_proficiency_slots - used
	
	remaining_label.text = "Proficiency Slots Remaining: %d / %d" % [remaining, available_proficiency_slots]
	
	# Color coding
	var theme: Theme = get_theme()
	if theme:
		var pos_color: Color = Color.WHITE
		var neg_color: Color = Color(0.9, 0.3, 0.3, 1.0)
		if theme.has_color("positive", "Label"):
			pos_color = theme.get_color("positive", "Label")
		if theme.has_color("negative", "Label"):
			neg_color = theme.get_color("negative", "Label")
		remaining_label.add_theme_color_override("font_color", pos_color if remaining >= 0 else neg_color)

func _on_stats_changed() -> void:
	"""Handle ability score changes (refresh modifiers)"""
	_populate_skills()
	_update_remaining_display()

func is_valid() -> bool:
	"""Check if skill selection is valid (all slots used or none selected)"""
	var used: int = selected_proficiencies.size()
	return used == available_proficiency_slots

