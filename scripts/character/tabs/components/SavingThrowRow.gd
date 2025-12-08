# ╔═══════════════════════════════════════════════════════════
# ║ SavingThrowRow.gd
# ║ Desc: Row displaying a saving throw with proficiency checkbox
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name SavingThrowRow
extends HBoxContainer

@export var throw_name: String = ""
@export var throw_modifier: int = 0
@export var has_proficiency: bool = false

@onready var proficiency_check: CheckBox = %ProficiencyCheck
@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel

func _ready() -> void:
	update_display()

func update_display() -> void:
	"""Update the display with current values"""
	if name_label:
		name_label.text = throw_name
	
	if value_label:
		if throw_modifier >= 0:
			value_label.text = "+%d" % throw_modifier
		else:
			value_label.text = "%d" % throw_modifier
	
	if proficiency_check:
		proficiency_check.button_pressed = has_proficiency

func set_saving_throw(name: String, modifier: int, proficient: bool = false) -> void:
	"""Set the saving throw data and update display"""
	throw_name = name
	throw_modifier = modifier
	has_proficiency = proficient
	update_display()

