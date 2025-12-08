# ╔═══════════════════════════════════════════════════════════
# ║ StatRow.gd
# ║ Desc: Reusable row for displaying a stat name, value/modifier, and progress bar
# ║ Author: Grok + Cursor + Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name StatRow
extends HBoxContainer

@export var stat_name: String = ""
@export var stat_value: int = 10

@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel
@onready var progress_bar: ProgressBar = %ProgressBar

func _ready() -> void:
	update_display()

func update_display() -> void:
	"""Update the display with current stat values"""
	if name_label:
		name_label.text = stat_name
	
	if stat_value > 0:
		var modifier: int = floor((stat_value - 10) / 2.0)
		if value_label:
			value_label.text = "%d (%+d)" % [stat_value, modifier]
		if progress_bar:
			progress_bar.value = stat_value
	else:
		if value_label:
			value_label.text = "—"
		if progress_bar:
			progress_bar.value = 0

func set_stat(name: String, value: int) -> void:
	"""Set the stat name and value, then update display"""
	stat_name = name
	stat_value = value
	update_display()

