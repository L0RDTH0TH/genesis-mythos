# ╔═══════════════════════════════════════════════════════════
# ║ PointBuyCostTable.gd
# ║ Desc: Resource class for D&D 5e point-buy cost table (6-26 range)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends Resource
class_name PointBuyCostTable

@export var cost_table: Dictionary = {
	6: 0, 7: 0,
	8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 6, 15: 7,
	16: 15, 17: 18, 18: 22, 19: 26,
	20: 31, 21: 37, 22: 43, 23: 50, 24: 58, 25: 67, 26: 77
}

func get_cost(stat_value: int) -> int:
	"""Get cost for a given stat value, returns 999 if out of bounds"""
	if cost_table.is_empty():
		Logger.error("PointBuyCostTable: get_cost() called but cost_table is empty!", "character_creation")
		return 999
	
	# Try integer key first (preferred)
	if cost_table.has(stat_value):
		var cost: int = cost_table[stat_value]
		return cost
	
	# Try string key (fallback for .tres files that store keys as strings)
	var stat_key_str: String = str(stat_value)
	if cost_table.has(stat_key_str):
		var cost_value = cost_table[stat_key_str]
		# Convert to int (handles both int and string values from .tres)
		var cost: int = int(cost_value)
		return cost
	
	# Stat value is out of bounds - log for debugging
	Logger.warning("PointBuyCostTable: get_cost() called with out-of-bounds value %d (valid range: %d-%d). Cost table keys: %s" % [
		stat_value, get_min_stat(), get_max_stat(), str(cost_table.keys())
	], "character_creation")
	return 999

func get_min_stat() -> int:
	"""Get minimum stat value"""
	return 6

func get_max_stat() -> int:
	"""Get maximum stat value"""
	return 26

