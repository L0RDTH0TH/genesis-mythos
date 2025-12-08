# ╔═══════════════════════════════════════════════════════════
# ║ SkillRow.gd
# ║ Desc: Row displaying a skill with proficiency checkbox
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name SkillRow
extends HBoxContainer

@export var skill_name: String = ""
@export var skill_modifier: int = 0
@export var has_proficiency: bool = false

@onready var proficiency_check: CheckBox = %ProficiencyCheck
@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel

func _ready() -> void:
	update_display()

func update_display() -> void:
	"""Update the display with current values"""
	if name_label:
		name_label.text = skill_name
	
	if value_label:
		if skill_modifier >= 0:
			value_label.text = "+%d" % skill_modifier
		else:
			value_label.text = "%d" % skill_modifier
	
	if proficiency_check:
		proficiency_check.button_pressed = has_proficiency

func set_skill(name: String, modifier: int, proficient: bool = false) -> void:
	"""Set the skill data and update display"""
	skill_name = name
	skill_modifier = modifier
	has_proficiency = proficient
	update_display()

