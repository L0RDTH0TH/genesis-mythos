# ╔═══════════════════════════════════════════════════════════
# ║ Logger.gd
# ║ Desc: Detailed, verbose, and configurable logging system with per-system levels
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Log levels enum - lower numbers are more critical
enum LogLevel {
	ERROR = 0,    ## Critical errors that prevent functionality
	WARN = 1,     ## Warnings about potential issues
	INFO = 2,     ## High-level informational messages
	DEBUG = 3,    ## Debug information for development
	VERBOSE = 4   ## Very detailed step-by-step logging
}

## Configuration dictionary loaded from JSON
var config: Dictionary = {}

## Per-system log levels (system_name -> LogLevel)
var system_levels: Dictionary = {}

## Global default log level
var global_default_level: LogLevel = LogLevel.INFO

## Development mode flag - allows runtime overrides
var dev_mode: bool = false

## Output flags
var log_to_console: bool = true
var log_to_file: bool = true

## File logging
var log_dir: String = "user://logs/"
var log_file_prefix: String = "mythos_log_"
var current_log_file: FileAccess = null
var current_log_date: String = ""

## Timestamp format
var timestamp_format: String = "%Y-%m-%d %H:%M:%S"

## Thread safety mutex (for future multi-threading support)
var log_mutex: Mutex = Mutex.new()

## Signal emitted when a log entry is created (for UI integration)
signal log_entry_created(level: LogLevel, system: String, message: String, data: Variant)

func _ready() -> void:
	"""Initialize the logger on ready."""
	_load_config()
	_setup_file_logging()
	info("Logger", "Logging system initialized")

func _exit_tree() -> void:
	"""Cleanup on exit."""
	# Write shutdown message before closing file
	if current_log_file and current_log_file.is_open():
		var shutdown_msg: String = _format_message("Logger", LogLevel.INFO, "Logging system shutting down", null)
		current_log_file.store_string(shutdown_msg + "\n")
		current_log_file.flush()
	_close_log_file()

func _load_config() -> void:
	"""Load configuration from JSON file."""
	var config_path: String = "res://config/logging_config.json"
	var file := FileAccess.open(config_path, FileAccess.READ)
	
	if not file:
		push_warning("Logger: Could not load config from %s, using defaults" % config_path)
		config = _get_default_config()
		_apply_config()
		return
	
	var content: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result: Error = json.parse(content)
	
	if parse_result != OK:
		push_warning("Logger: Failed to parse config JSON, using defaults")
		config = _get_default_config()
		_apply_config()
		return
	
	var parsed: Variant = json.data
	if parsed is Dictionary:
		config = parsed as Dictionary
		_apply_config()
	else:
		push_warning("Logger: Invalid config format, using defaults")
		config = _get_default_config()
		_apply_config()

func _get_default_config() -> Dictionary:
	"""Return default configuration dictionary."""
	return {
		"global_default_level": "INFO",
		"systems": {
			"Combat": "INFO",
			"UI": "INFO",
			"AI": "INFO",
			"Inventory": "INFO",
			"Networking": "WARN"
		},
		"dev_mode": true,
		"log_to_console": true,
		"log_to_file": true,
		"log_dir": "user://logs/",
		"log_file_prefix": "mythos_log_",
		"timestamp_format": "%Y-%m-%d %H:%M:%S"
	}

func _apply_config() -> void:
	"""Apply loaded configuration to internal variables."""
	# Global default level
	var global_level_str: String = config.get("global_default_level", "INFO")
	global_default_level = _parse_level_string(global_level_str)
	
	# System-specific levels
	system_levels.clear()
	var systems_dict: Dictionary = config.get("systems", {})
	for system_name in systems_dict.keys():
		var level_str: String = systems_dict[system_name]
		system_levels[system_name] = _parse_level_string(level_str)
	
	# Development mode
	dev_mode = config.get("dev_mode", false)
	
	# Output flags
	log_to_console = config.get("log_to_console", true)
	log_to_file = config.get("log_to_file", true)
	
	# File logging settings
	log_dir = config.get("log_dir", "user://logs/")
	log_file_prefix = config.get("log_file_prefix", "mythos_log_")
	timestamp_format = config.get("timestamp_format", "%Y-%m-%d %H:%M:%S")

func _parse_level_string(level_str: String) -> LogLevel:
	"""Parse a level string to LogLevel enum."""
	match level_str.to_upper():
		"ERROR":
			return LogLevel.ERROR
		"WARN", "WARNING":
			return LogLevel.WARN
		"INFO":
			return LogLevel.INFO
		"DEBUG":
			return LogLevel.DEBUG
		"VERBOSE":
			return LogLevel.VERBOSE
		_:
			return LogLevel.INFO

func _setup_file_logging() -> void:
	"""Setup file logging directory and initial file."""
	if not log_to_file:
		return
	
	# Determine if we're using an absolute path or user:// path
	var is_absolute_path: bool = log_dir.begins_with("/")
	var log_dir_path: String = log_dir.trim_suffix("/")
	
	if is_absolute_path:
		# Use absolute path directly
		var dir := DirAccess.open("/")
		if not dir:
			push_error("Logger: Failed to open root directory")
			return
		
		if not dir.dir_exists(log_dir_path):
			var err: Error = dir.make_dir_recursive(log_dir_path)
			if err != OK:
				push_error("Logger: Failed to create log directory: %s" % log_dir_path)
				return
	else:
		# Use user:// path (Godot's user data directory)
		var dir := DirAccess.open("user://")
		if not dir:
			push_error("Logger: Failed to open user:// directory")
			return
		
		if log_dir_path.begins_with("user://"):
			log_dir_path = log_dir_path.replace("user://", "")
		
		if not dir.dir_exists(log_dir_path):
			var err: Error = dir.make_dir_recursive(log_dir_path)
			if err != OK:
				push_error("Logger: Failed to create log directory: %s" % log_dir_path)
				return
	
	# Open or create today's log file
	_open_log_file()

func _open_log_file() -> void:
	"""Open or create the log file for today."""
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	var date_str: String = "%04d-%02d-%02d" % [int(datetime.year), int(datetime.month), int(datetime.day)]
	
	# If we already have today's file open, don't reopen
	if current_log_file and current_log_date == date_str:
		return
	
	# Close previous file if open
	_close_log_file()
	
	# Build file path
	var filename: String = "%s%s.txt" % [log_file_prefix, date_str]
	var file_path: String = log_dir + filename if log_dir.ends_with("/") else log_dir + "/" + filename
	
	# FileAccess.open() works with both absolute paths and user:// paths
	current_log_file = FileAccess.open(file_path, FileAccess.WRITE)
	if not current_log_file:
		push_error("Logger: Failed to open log file: %s" % file_path)
		return
	
	current_log_date = date_str
	
	# Write header
	var header: String = "=== Log session started at %s ===\n" % _get_timestamp()
	current_log_file.store_string(header)
	current_log_file.flush()

func _close_log_file() -> void:
	"""Close the current log file."""
	if current_log_file:
		var footer: String = "=== Log session ended at %s ===\n" % _get_timestamp()
		current_log_file.store_string(footer)
		current_log_file.flush()
		current_log_file.close()
		current_log_file = null
		current_log_date = ""

func _get_timestamp() -> String:
	"""Get formatted timestamp string."""
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	# Format timestamp according to configured format
	var formatted: String = timestamp_format
	formatted = formatted.replace("%Y", "%04d" % int(datetime.year))
	formatted = formatted.replace("%m", "%02d" % int(datetime.month))
	formatted = formatted.replace("%d", "%02d" % int(datetime.day))
	formatted = formatted.replace("%H", "%02d" % int(datetime.hour))
	formatted = formatted.replace("%M", "%02d" % int(datetime.minute))
	formatted = formatted.replace("%S", "%02d" % int(datetime.second))
	return formatted

func _should_log(system: String, level: LogLevel) -> bool:
	"""Check if a log entry should be logged based on system and level."""
	# Get the configured level for this system (or global default)
	var system_level: LogLevel = system_levels.get(system, global_default_level)
	
	# Log if the message level is <= configured level (lower = more critical)
	return level <= system_level

func _format_message(system: String, level: LogLevel, message: String, data: Variant = null) -> String:
	"""Format a log message with timestamp, system, level, and optional data."""
	var timestamp: String = _get_timestamp()
	var level_name: String = LogLevel.keys()[level]
	
	var formatted: String = "[%s] [%s] [%s]: %s" % [timestamp, system, level_name, message]
	
	if data != null:
		var data_str: String = ""
		if data is Dictionary or data is Array:
			data_str = JSON.stringify(data)
		else:
			data_str = str(data)
		formatted += " [%s]" % data_str
	
	return formatted

func log_entry(system: String, level: LogLevel, message: String, data: Variant = null) -> void:
	"""Main logging method - logs a message if the level allows."""
	log_mutex.lock()
	
	# Check if we should log this
	if not _should_log(system, level):
		log_mutex.unlock()
		return
	
	var formatted: String = _format_message(system, level, message, data)
	
	# Console output
	if log_to_console:
		_output_to_console(level, formatted)
	
	# File output
	if log_to_file:
		_output_to_file(formatted)
	
	# Emit signal for UI integration
	emit_signal("log_entry_created", level, system, message, data)
	
	log_mutex.unlock()

func _output_to_console(level: LogLevel, message: String) -> void:
	"""Output message to console with appropriate formatting."""
	match level:
		LogLevel.ERROR:
			push_error(message)
		LogLevel.WARN:
			push_warning(message)
		LogLevel.INFO, LogLevel.DEBUG, LogLevel.VERBOSE:
			print(message)

func _output_to_file(message: String) -> void:
	"""Output message to log file."""
	# Ensure we have a file open (check if date changed)
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	var date_str: String = "%04d-%02d-%02d" % [int(datetime.year), int(datetime.month), int(datetime.day)]
	
	if current_log_date != date_str:
		_open_log_file()
	
	if current_log_file and current_log_file.is_open():
		current_log_file.store_string(message + "\n")
		current_log_file.flush()

## Convenience methods for each log level

func error(system: String, message: String, data: Variant = null) -> void:
	"""Log an ERROR level message."""
	log_entry(system, LogLevel.ERROR, message, data)

func warn(system: String, message: String, data: Variant = null) -> void:
	"""Log a WARN level message."""
	log_entry(system, LogLevel.WARN, message, data)

func info(system: String, message: String, data: Variant = null) -> void:
	"""Log an INFO level message."""
	log_entry(system, LogLevel.INFO, message, data)

func debug(system: String, message: String, data: Variant = null) -> void:
	"""Log a DEBUG level message."""
	log_entry(system, LogLevel.DEBUG, message, data)

func verbose(system: String, message: String, data: Variant = null) -> void:
	"""Log a VERBOSE level message."""
	log_entry(system, LogLevel.VERBOSE, message, data)

## Development mode runtime overrides

func set_system_level(system: String, level: String) -> void:
	"""Set the log level for a system at runtime (dev_mode only)."""
	if not dev_mode:
		push_warning("Logger: Runtime level changes require dev_mode=true")
		return
	
	var parsed_level: LogLevel = _parse_level_string(level)
	system_levels[system] = parsed_level
	info("Logger", "System '%s' log level set to %s" % [system, level])

func get_system_level(system: String) -> LogLevel:
	"""Get the current log level for a system."""
	return system_levels.get(system, global_default_level)

func reload_config() -> void:
	"""Reload configuration from JSON file."""
	_load_config()
	info("Logger", "Configuration reloaded")

func get_log_file_path() -> String:
	"""Get the path to the current log file (for external access)."""
	if not current_log_file or current_log_date.is_empty():
		return ""
	
	var filename: String = "%s%s.txt" % [log_file_prefix, current_log_date]
	return log_dir + filename if log_dir.ends_with("/") else log_dir + "/" + filename
