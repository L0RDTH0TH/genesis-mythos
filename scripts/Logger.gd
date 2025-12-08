# ╔═══════════════════════════════════════════════════════════
# ║ Logger.gd
# ║ Desc: Centralized logging system with configurable levels and outputs
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════

extends Node

enum LOG_LEVEL {
	DEBUG,
	INFO,
	WARNING,
	ERROR
}

signal log_event(level: LOG_LEVEL, message: String, module: String)

var log_config: Dictionary = {}
var log_file_path: String = ""
var file_handle: FileAccess = null
var performance_timers: Dictionary = {}
var structured_data_enabled: bool = true

func _ready() -> void:
	add_to_group("autoload")
	_load_config()
	_setup_file_logging()

func _exit_tree() -> void:
	_close_file()

func _load_config() -> void:
	var config_path: String = "res://data/config/logging_config.json"
	var file := FileAccess.open(config_path, FileAccess.READ)
	
	if not file:
		# Default config if file doesn't exist
		log_config = _get_default_config()
		push_warning("Logger: Could not load config from %s, using defaults" % config_path)
		return
	
	var content: String = file.get_as_text()
	file.close()
	
	var parsed: Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		log_config = parsed as Dictionary
	else:
		log_config = _get_default_config()
		push_warning("Logger: Invalid config format, using defaults")

func _get_default_config() -> Dictionary:
	return {
		"levels_enabled": {
			"DEBUG": true,
			"INFO": true,
			"WARNING": true,
			"ERROR": true
		},
		"outputs": ["console", "file"],
		"modules": {
			"combat": "DEBUG",
			"dialogue": "INFO",
			"inventory": "INFO",
			"quest": "INFO",
			"character_creation": "DEBUG"
		},
		"file_logging": {
			"enabled": true,
			"daily_rotation": true,
			"max_file_size_mb": 10
		}
	}

func _setup_file_logging() -> void:
	if not log_config.get("file_logging", {}).get("enabled", false):
		return
	
	var outputs: Array = log_config.get("outputs", [])
	if "file" not in outputs:
		return
	
	# Create logs directory
	var logs_dir: String = "user://logs"
	if not DirAccess.dir_exists_absolute(logs_dir):
		DirAccess.make_dir_recursive_absolute(logs_dir)
	
	# Generate log file path with timestamp for one file per run
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	var timestamp_str: String = "%04d%02d%02d_%02d%02d%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	log_file_path = logs_dir + "/game_log_%s.txt" % timestamp_str
	
	# Open file for writing (new file each run)
	file_handle = FileAccess.open(log_file_path, FileAccess.WRITE)
	if not file_handle:
		push_error("Logger: Failed to open log file: %s" % log_file_path)
		return
	
	# Write initial entry
	var init_msg: String = "=== Log session started at %s ===\n" % _get_timestamp()
	file_handle.store_string(init_msg)
	file_handle.flush()

func _close_file() -> void:
	if file_handle:
		var close_msg: String = "=== Log session ended at %s ===\n" % _get_timestamp()
		file_handle.store_string(close_msg)
		file_handle.flush()
		file_handle.close()
		file_handle = null

func _get_timestamp() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

func _should_log(level: LOG_LEVEL, module: String) -> bool:
	var level_name: String = LOG_LEVEL.keys()[level]
	
	# Check if level is enabled globally
	var levels_enabled: Dictionary = log_config.get("levels_enabled", {})
	if not levels_enabled.get(level_name, true):
		return false
	
	# Check module-specific level
	if module != "":
		var modules: Dictionary = log_config.get("modules", {})
		if modules.has(module):
			var module_level_str: String = modules[module]
			var module_level: LOG_LEVEL = _parse_level_string(module_level_str)
			if level < module_level:
				return false
	
	return true

func _parse_level_string(level_str: String) -> LOG_LEVEL:
	match level_str.to_upper():
		"DEBUG":
			return LOG_LEVEL.DEBUG
		"INFO":
			return LOG_LEVEL.INFO
		"WARNING":
			return LOG_LEVEL.WARNING
		"ERROR":
			return LOG_LEVEL.ERROR
		_:
			return LOG_LEVEL.DEBUG

func _format_message(level: LOG_LEVEL, message: String, module: String) -> String:
	var level_name: String = LOG_LEVEL.keys()[level]
	var timestamp: String = _get_timestamp()
	var module_str: String = "[%s]" % module if module != "" else ""
	return "[%s] %s %s: %s" % [timestamp, level_name, module_str, message]

func log_message(level: LOG_LEVEL, message: String, module: String = "") -> void:
	"""Main logging method. Routes messages to configured outputs."""
	if not _should_log(level, module):
		return
	
	var formatted: String = _format_message(level, message, module)
	var outputs: Array = log_config.get("outputs", ["console"])
	
	# Console output
	if "console" in outputs:
		match level:
			LOG_LEVEL.DEBUG:
				print(formatted)
			LOG_LEVEL.INFO:
				print(formatted)
			LOG_LEVEL.WARNING:
				push_warning(formatted)
			LOG_LEVEL.ERROR:
				push_error(formatted)
	
	# File output
	if "file" in outputs and file_handle and file_handle.is_open():
		file_handle.store_string(formatted + "\n")
		file_handle.flush()
	
	# UI output (emit signal for LogUI to connect)
	if "ui" in outputs:
		emit_signal("log_event", level, message, module)

func debug(message: String, module: String = "") -> void:
	"""Convenience method for DEBUG level."""
	log_message(LOG_LEVEL.DEBUG, message, module)

func info(message: String, module: String = "") -> void:
	"""Convenience method for INFO level."""
	log_message(LOG_LEVEL.INFO, message, module)

func warning(message: String, module: String = "") -> void:
	"""Convenience method for WARNING level."""
	log_message(LOG_LEVEL.WARNING, message, module)

func error(message: String, module: String = "") -> void:
	"""Convenience method for ERROR level."""
	log_message(LOG_LEVEL.ERROR, message, module)

func log_combat(character: String, action: String, target: String = "", damage: int = 0) -> void:
	"""Specialized method for combat log entries."""
	var message: String
	if damage > 0:
		message = "%s hits %s for %d damage" % [character, target, damage]
	else:
		message = "%s %s" % [character, action]
	log_message(LOG_LEVEL.INFO, message, "combat")

func log_quest(quest_name: String, event: String) -> void:
	"""Specialized method for quest log entries."""
	var message: String = "%s: %s" % [quest_name, event]
	log_message(LOG_LEVEL.INFO, message, "quest")

func capture_error_with_stack(error_message: String, module: String = "") -> void:
	"""Capture error with stack trace for crash reports."""
	var stack_array: Array = get_stack()
	var stack_trace: String = ""
	for frame in stack_array:
		if frame is Dictionary:
			stack_trace += "  at %s:%d in %s()\n" % [
				frame.get("source", ""),
				frame.get("line", 0),
				frame.get("function", "")
			]
	var full_message: String = "%s\nStack trace:\n%s" % [error_message, stack_trace]
	log_message(LOG_LEVEL.ERROR, full_message, module)
	
	# Optionally save crash report
	var crash_dir: String = "user://logs"
	if not DirAccess.dir_exists_absolute(crash_dir):
		DirAccess.make_dir_recursive_absolute(crash_dir)
	
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	var crash_file: String = crash_dir + "/crash_%04d%02d%02d_%02d%02d%02d.txt" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	var crash_file_handle := FileAccess.open(crash_file, FileAccess.WRITE)
	if crash_file_handle:
		crash_file_handle.store_string(full_message)
		crash_file_handle.close()

func start_timer(timer_id: String, module: String = "") -> void:
	"""Start a performance timer. Returns immediately."""
	if not structured_data_enabled:
		return
	performance_timers[timer_id] = {
		"start_time": Time.get_ticks_msec(),
		"module": module
	}

func end_timer(timer_id: String, log_result: bool = true) -> float:
	"""End a performance timer and optionally log the result. Returns elapsed time in milliseconds."""
	if not structured_data_enabled or not performance_timers.has(timer_id):
		return -1.0
	
	var timer_data: Dictionary = performance_timers[timer_id]
	var start_time: int = timer_data.get("start_time", 0)
	var elapsed: float = Time.get_ticks_msec() - start_time
	var module: String = timer_data.get("module", "")
	
	performance_timers.erase(timer_id)
	
	if log_result:
		log_message(LOG_LEVEL.DEBUG, "Timer '%s' completed in %.2f ms" % [timer_id, elapsed], module)
	
	return elapsed

func log_performance(operation: String, duration_ms: float, module: String = "", details: Dictionary = {}) -> void:
	"""Log a performance metric with optional structured details."""
	var message: String = "Performance: %s took %.2f ms" % [operation, duration_ms]
	if not details.is_empty():
		var detail_parts: Array = []
		for key in details.keys():
			detail_parts.append("%s=%s" % [key, str(details[key])])
		message += " | " + ", ".join(detail_parts)
	log_message(LOG_LEVEL.DEBUG, message, module)

func log_structured(level: LOG_LEVEL, event: String, module: String = "", data: Dictionary = {}) -> void:
	"""Log a structured event with key-value data."""
	if not structured_data_enabled:
		# Fallback to simple message
		log_message(level, event, module)
		return
	
	var message: String = "Event: %s" % event
	if not data.is_empty():
		var data_parts: Array = []
		for key in data.keys():
			var value = data[key]
			# Format value appropriately
			if value is Dictionary or value is Array:
				value = JSON.stringify(value)
			data_parts.append("%s=%s" % [key, str(value)])
		message += " | " + ", ".join(data_parts)
	
	log_message(level, message, module)

func log_user_action(action: String, target: String = "", module: String = "", details: Dictionary = {}) -> void:
	"""Log a user action (selection, click, etc.) with context."""
	var data: Dictionary = {"action": action}
	if target != "":
		data["target"] = target
	if not details.is_empty():
		for key in details.keys():
			data[key] = details[key]
	log_structured(LOG_LEVEL.INFO, "UserAction", module, data)

func log_state_transition(from_state: String, to_state: String, module: String = "", context: Dictionary = {}) -> void:
	"""Log a state transition with optional context."""
	var data: Dictionary = {"from": from_state, "to": to_state}
	if not context.is_empty():
		for key in context.keys():
			data[key] = context[key]
	log_structured(LOG_LEVEL.DEBUG, "StateTransition", module, data)

func log_validation(field: String, passed: bool, message: String = "", module: String = "", details: Dictionary = {}) -> void:
	"""Log a validation result."""
	var level: LOG_LEVEL = LOG_LEVEL.DEBUG if passed else LOG_LEVEL.WARNING
	var data: Dictionary = {"field": field, "passed": passed}
	if message != "":
		data["message"] = message
	if not details.is_empty():
		for key in details.keys():
			data[key] = details[key]
	log_structured(level, "Validation", module, data)

