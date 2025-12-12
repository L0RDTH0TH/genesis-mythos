# ╔═══════════════════════════════════════════════════════════
# ║ Eryndor.gd
# ║ Desc: Core singleton for Eryndor 4.0 Final - main game controller
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	Logger.info("Eryndor", "Authentic engine initialized – the truth awakens.")
	
	# Test all log levels (only if Logger system is set to VERBOSE or DEBUG)
	Logger.verbose("Eryndor", "VERBOSE: Detailed step-by-step logging test")
	Logger.debug("Eryndor", "DEBUG: Key decision point test")
	Logger.info("Eryndor", "INFO: High-level event test")
	Logger.warn("Eryndor", "WARN: Potential issue test")
	Logger.error("Eryndor", "ERROR: Critical error test (this is just a test)")
	
	# Test with data
	Logger.info("Eryndor", "Test with data", {"key": "value", "number": 42})
