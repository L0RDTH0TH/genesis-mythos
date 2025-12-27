# ╔═══════════════════════════════════════════════════════════
# ║ PerformanceInvestigator.gd
# ║ Desc: Temporary script to investigate performance bottlenecks for caching opportunities
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Track JSON file loads
var json_loads: Dictionary = {}  # path -> count
var json_parse_times: Dictionary = {}  # path -> total_time

## Track resource loads
var resource_loads: Dictionary = {}  # path -> count
var resource_load_times: Dictionary = {}  # path -> total_time

## Track function call frequencies
var function_calls: Dictionary = {}  # function_name -> count

## Track terrain operations
var terrain_operations: Dictionary = {}  # operation -> count

## Track UI updates
var ui_updates: int = 0
var ui_update_times: Array[float] = []

## Track Azgaar operations
var azgaar_js_executions: int = 0
var azgaar_js_times: Array[float] = []

var start_time: float = 0.0

func _ready() -> void:
	start_time = Time.get_ticks_msec() / 1000.0
	MythosLogger.info("PerformanceInvestigator", "Performance investigation started")

func track_json_load(path: String, parse_time: float) -> void:
	if not json_loads.has(path):
		json_loads[path] = 0
		json_parse_times[path] = 0.0
	json_loads[path] += 1
	json_parse_times[path] += parse_time

func track_resource_load(path: String, load_time: float) -> void:
	if not resource_loads.has(path):
		resource_loads[path] = 0
		resource_load_times[path] = 0.0
	resource_loads[path] += 1
	resource_load_times[path] += load_time

func track_function_call(function_name: String) -> void:
	if not function_calls.has(function_name):
		function_calls[function_name] = 0
	function_calls[function_name] += 1

func track_terrain_operation(operation: String) -> void:
	if not terrain_operations.has(operation):
		terrain_operations[operation] = 0
	terrain_operations[operation] += 1

func track_ui_update(update_time: float) -> void:
	ui_updates += 1
	ui_update_times.append(update_time)

func track_azgaar_js(time: float) -> void:
	azgaar_js_executions += 1
	azgaar_js_times.append(time)

func print_report() -> void:
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - start_time
	MythosLogger.info("PerformanceInvestigator", "=== PERFORMANCE REPORT (%.2fs elapsed) ===" % elapsed)
	
	MythosLogger.info("PerformanceInvestigator", "--- JSON Loads ---")
	for path in json_loads.keys():
		var count: int = json_loads[path]
		var total_time: float = json_parse_times[path]
		var avg_time: float = total_time / count if count > 0 else 0.0
		MythosLogger.info("PerformanceInvestigator", "  %s: %d loads, %.3fms total, %.3fms avg" % [path, count, total_time * 1000, avg_time * 1000])
	
	MythosLogger.info("PerformanceInvestigator", "--- Resource Loads ---")
	for path in resource_loads.keys():
		var count: int = resource_loads[path]
		var total_time: float = resource_load_times[path]
		var avg_time: float = total_time / count if count > 0 else 0.0
		MythosLogger.info("PerformanceInvestigator", "  %s: %d loads, %.3fms total, %.3fms avg" % [path, count, total_time * 1000, avg_time * 1000])
	
	MythosLogger.info("PerformanceInvestigator", "--- Function Calls (Top 20) ---")
	var sorted_calls: Array = []
	for func_name in function_calls.keys():
		sorted_calls.append({"name": func_name, "count": function_calls[func_name]})
	sorted_calls.sort_custom(func(a, b): return a.count > b.count)
	for i in range(min(20, sorted_calls.size())):
		var item = sorted_calls[i]
		MythosLogger.info("PerformanceInvestigator", "  %s: %d calls" % [item.name, item.count])
	
	MythosLogger.info("PerformanceInvestigator", "--- Terrain Operations ---")
	for op in terrain_operations.keys():
		MythosLogger.info("PerformanceInvestigator", "  %s: %d operations" % [op, terrain_operations[op]])
	
	MythosLogger.info("PerformanceInvestigator", "--- UI Updates ---")
	if ui_updates > 0:
		var total_ui_time: float = 0.0
		for t in ui_update_times:
			total_ui_time += t
		var avg_ui_time: float = total_ui_time / ui_updates if ui_updates > 0 else 0.0
		MythosLogger.info("PerformanceInvestigator", "  Total: %d updates, %.3fms total, %.3fms avg" % [ui_updates, total_ui_time * 1000, avg_ui_time * 1000])
	
	MythosLogger.info("PerformanceInvestigator", "--- Azgaar JS Executions ---")
	if azgaar_js_executions > 0:
		var total_js_time: float = 0.0
		for t in azgaar_js_times:
			total_js_time += t
		var avg_js_time: float = total_js_time / azgaar_js_executions if azgaar_js_executions > 0 else 0.0
		MythosLogger.info("PerformanceInvestigator", "  Total: %d executions, %.3fms total, %.3fms avg" % [azgaar_js_executions, total_js_time * 1000, avg_js_time * 1000])
	
	MythosLogger.info("PerformanceInvestigator", "=== END REPORT ===")

func _exit_tree() -> void:
	print_report()

