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
var file: FileAccess = null
var dev_path: String = ""
var dev_mirror_failed: bool = false  ## Track if dev mirror write has failed (suppress repeated warnings)

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
	_close_log_file()
	info("Logger", "Logging system shutting down")

func _load_config() -> void:
	"""Load configuration from JSON file."""
	var config_path: String = "res://data/config/logging_config.json"
	var config_file := FileAccess.open(config_path, FileAccess.READ)
	
	if not config_file:
		push_warning("Logger: Could not load config from %s, using defaults" % config_path)
		config = _get_default_config()
		_apply_config()
		return
	
	var content: String = config_file.get_as_text()
	config_file.close()
	
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
	if not config.get("log_to_file", true):
		_force_console_log("Logger", LogLevel.INFO, "File logging disabled by config")
		return

	var log_dir_path: String = config.get("log_dir", "user://logs/")
	var prefix: String = config.get("log_file_prefix", "mythos_log_")
	var timestamp_dict: Dictionary = Time.get_datetime_dict_from_system()
	var date_str: String = "%04d-%02d-%02d" % [int(timestamp_dict.year), int(timestamp_dict.month), int(timestamp_dict.day)]
	var filename: String = prefix + date_str + ".txt"
	var full_path: String = log_dir_path + filename if log_dir_path.ends_with("/") else log_dir_path + "/" + filename
	dev_path = "/home/darth/Documents/Mythos-gen/Final-Approach/" + filename
	dev_mirror_failed = false  ## Reset on new log file setup

	_force_console_log("Logger", LogLevel.DEBUG, "Setting up file logging - path: " + full_path + ", dev: " + dev_path)

	# Force create/ensure directories
	var dir_access: DirAccess = DirAccess.open("user://")
	if dir_access and not dir_access.dir_exists("logs"):
		var err: Error = dir_access.make_dir("logs")
		if err != OK:
			_force_console_log("Logger", LogLevel.ERROR, "Failed to create user://logs/ - err: " + str(err))
	
	# Create dev directory using absolute path
	var dev_dir: String = "/home/darth/Documents/Mythos-gen/Final-Approach"
	dir_access = DirAccess.open(dev_dir)
	if dir_access == null:
		# Try to create parent directory first
		var parent_dir: String = "/home/darth/Documents/Mythos-gen"
		var parent_access: DirAccess = DirAccess.open(parent_dir)
		if parent_access == null:
			# Create parent if it doesn't exist
			parent_access = DirAccess.open("/home/darth/Documents")
			if parent_access:
				var err: Error = parent_access.make_dir("Mythos-gen")
				if err != OK:
					_force_console_log("Logger", LogLevel.ERROR, "Failed to create dev parent dir - err: " + str(err))
				parent_access = DirAccess.open(parent_dir)
		if parent_access:
			var err: Error = parent_access.make_dir("Final-Approach")
			if err != OK:
				_force_console_log("Logger", LogLevel.ERROR, "Failed to create dev log dir - err: " + str(err))

	# Nuclear open: Always create/truncate first, then reopen for append
	var log_file: FileAccess = FileAccess.open(full_path, FileAccess.WRITE)
	if log_file == null:
		_force_console_log("Logger", LogLevel.ERROR, "Failed to create/truncate log file: " + full_path + " - err: " + str(FileAccess.get_open_error()))
		return
	log_file.close()

	log_file = FileAccess.open(full_path, FileAccess.READ_WRITE)
	if log_file == null:
		_force_console_log("Logger", LogLevel.ERROR, "Failed to reopen log file for append: " + full_path + " - err: " + str(FileAccess.get_open_error()))
		return
	log_file.seek_end()

	# Add header if file is empty
	if log_file.get_length() == 0:
		var header: String = "=== Log session started at " + Time.get_datetime_string_from_system() + " ===\n"
		log_file.store_string(header)
		log_file.flush()
	
	file = log_file

	_force_console_log("Logger", LogLevel.INFO, "File logging setup complete - ready to append")


func _close_log_file() -> void:
	"""Close the current log file."""
	var footer: String = "=== Log session ended at " + Time.get_datetime_string_from_system() + " ===\n"
	
	if file:
		file.seek_end()
		file.store_string(footer)
		file.flush()
		file.close()
		file = null
	
	# Also close dev mirror if open
	if config.get("dev_mode", true) and dev_path != "":
		var dev_file: FileAccess = FileAccess.open(dev_path, FileAccess.READ_WRITE)
		if dev_file == null:
			dev_file = FileAccess.open(dev_path, FileAccess.WRITE)
		if dev_file != null:
			dev_file.seek_end()
			dev_file.store_string(footer)
			dev_file.flush()
			dev_file.close()
	
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
	"""Main logging method - logs a message if the level allows. Thread-safe via DiagnosticDispatcher."""
	log_mutex.lock()
	
	# Check if we should log this (level filtering)
	if not _should_log(system, level):
		log_mutex.unlock()
		return
	
	# Check rate limiting via DiagnosticDispatcher (PerformanceMonitor)
	if not PerformanceMonitorSingleton.can_log():
		log_mutex.unlock()
		return
	
	var formatted: String = _format_message(system, level, message, data)
	
	# Wrap actual log operations in a Callable for DiagnosticDispatcher queue
	var log_callable: Callable = func():
		# Console output (thread-safe: push_error, push_warning, print work from threads)
		if log_to_console:
			_output_to_console(level, formatted)
		
		# File output (thread-safe: FileAccess operations work from threads)
		if log_to_file:
			_output_to_file(formatted)
		
		# Emit signal for UI integration (on main thread via queue)
		_emit_log_signal(level, system, message, data)
	
	log_mutex.unlock()
	
	# Queue diagnostic callable (handles main thread vs thread automatically)
	PerformanceMonitorSingleton.queue_diagnostic(log_callable)

func _output_to_console(level: LogLevel, message: String) -> void:
	"""Output message to console with appropriate formatting."""
	match level:
		LogLevel.ERROR:
			push_error(message)
		LogLevel.WARN:
			push_warning(message)
		LogLevel.INFO, LogLevel.DEBUG, LogLevel.VERBOSE:
			print(message)

func _emit_log_signal(level: LogLevel, system: String, message: String, data: Variant) -> void:
	"""Thread-safe signal emission wrapper (always uses call_deferred for safety)."""
	# Always use call_deferred to ensure signal emission happens on main thread
	# This is safe even if called from main thread (slight overhead, but ensures correctness)
	call_deferred("_do_emit_log_signal", level, system, message, data)

func _do_emit_log_signal(level: LogLevel, system: String, message: String, data: Variant) -> void:
	"""Actually emit the signal (called via call_deferred on main thread)."""
	emit_signal("log_entry_created", level, system, message, data)

func _force_console_log(system: String, level: LogLevel, message: String) -> void:
	"""Force log to console bypassing all checks - used for Logger internal messages."""
	var formatted: String = "[%s] [%s] [%s]: %s" % [_get_timestamp(), system, _log_level_to_string(level), message]
	_output_to_console(level, formatted)

func _output_to_file(message: String) -> void:
	"""Output message to log file."""
	var entry: String = message + "\n"
	
	# File output - nuclear append
	if config.get("log_to_file", true) and file != null:
		file.seek_end()
		file.store_string(entry)
		file.flush()
		if FileAccess.get_open_error() != OK:
			push_error("Log file write failed mid-session: " + str(FileAccess.get_open_error()))

	# Dev mirror - independent open/write/close each time to avoid locks
	if config.get("dev_mode", true) and not dev_mirror_failed:
		var dev_file: FileAccess = FileAccess.open(dev_path, FileAccess.READ_WRITE)
		if dev_file == null:
			dev_file = FileAccess.open(dev_path, FileAccess.WRITE)
		if dev_file != null:
			dev_file.seek_end()
			dev_file.store_string(entry)
			dev_file.flush()
			dev_file.close()
		else:
			# Only warn once, then silently skip subsequent attempts
			if not dev_mirror_failed:
				push_warning("Failed to write to dev mirror: " + dev_path + " - err: " + str(FileAccess.get_open_error()) + " (subsequent failures will be silent)")
				dev_mirror_failed = true

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
	if not current_log_file:
		return ""
	
	var filename: String = "%s%s.txt" % [log_file_prefix, current_log_date]
	return log_dir + filename if log_dir.ends_with("/") else log_dir + "/" + filename


func _log_level_to_string(level: LogLevel) -> String:
	"""Convert LogLevel enum to string."""
	match level:
		LogLevel.ERROR:
			return "ERROR"
		LogLevel.WARN:
			return "WARN"
		LogLevel.INFO:
			return "INFO"
		LogLevel.DEBUG:
			return "DEBUG"
		LogLevel.VERBOSE:
			return "VERBOSE"
		_:
			return "UNKNOWN"

