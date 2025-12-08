# ╔═══════════════════════════════════════════════════════════
# ║ PointsSummaryPanel.gd
# ║ Desc: Blue center panel showing detailed point spend
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name PointsSummaryPanel
extends PanelContainer

@onready var remaining_label: Label = $MarginContainer/VBoxContainer/RemainingLabel
@onready var breakdown_container: VBoxContainer = $MarginContainer/VBoxContainer/SpentBreakdown

func refresh(points_remaining: int, spent_dict: Dictionary) -> void:
	remaining_label.text = "Points Remaining: %d" % points_remaining
	remaining_label.modulate = Color(1, 0.84, 0) if points_remaining == 0 else Color(0.8, 1, 0.8)
	
	# Clear previous lines
	for child in breakdown_container.get_children():
		child.queue_free()
	
	# TODO: Re-implement point-buy calculation logic here
	# Cost calculation removed - breakdown display disabled
	# Add one clean line per spent ability (exactly like BG3)
	# for ability: String in ["strength","dexterity","constitution","intelligence","wisdom","charisma"]:
	# 	var spent: int = spent_dict.get(ability, 0)
	# 	if spent > 0:
	# 		var cost: int = _calculate_total_cost(spent)
	# 		var label := Label.new()
	# 		var abbr: String = ability.left(3).to_upper()
	# 		label.text = "%s  +%d  (%d pts)" % [abbr, spent, cost]
	# 		label.add_theme_font_size_override("font_size", 28)
	# 		label.add_theme_color_override("font_color", Color(0.85, 1, 0.85))
	# 		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# 		breakdown_container.add_child(label)

func _calculate_total_cost(score_increase: int) -> int:
	"""Calculate total cost to increase score by score_increase points above minimum"""
	# TODO: Re-implement point-buy calculation logic here
	# All cost calculation logic has been removed
	# if not GameData.point_buy_data.has("cost_table"):
	# 	return 0
	# 
	# var cost_table: Dictionary = GameData.point_buy_data.get("cost_table", {})
	# var min_score: int = PlayerData.get_min_score()
	# var total_cost: int = 0
	# 
	# # Sum costs from min_score+1 to min_score+score_increase
	# for i in range(1, score_increase + 1):
	# 	var score: int = min_score + i
	# 	if cost_table.has(str(score)):
	# 		total_cost += cost_table.get(str(score), 0)
	# 
	# return total_cost
	return 0

