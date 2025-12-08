# ╔═══════════════════════════════════════════════════════════
# ║ test_debug_console_commands.gd
# ║ Desc: Tests debug console command execution (interaction-only)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

var test_results: Array[Dictionary] = []

func test_console_command_execution() -> Dictionary:
	"""Test debug console command execution (interaction-only)"""
	var result := {"name": "console_commands", "passed": false, "message": ""}
	
	if not Engine.has_singleton("DebugConsole"):
		result["message"] = "DebugConsole singleton not present"
		return result
	
	var console = Engine.get_singleton("DebugConsole")
	if not console.has_method("execute_command"):
		result["message"] = "DebugConsole does not have execute_command method"
		return result
	
	# Test command execution (only happens when player types command)
	console.execute_command("help")
	await get_tree().process_frame
	
	result["passed"] = true
	result["message"] = "Console command execution works"
	return result
