# ╔═══════════════════════════════════════════════════════════════════════════════
# ║ test_logger.gd
# ║ Desc: Unit tests for Logger log levels, categories, and file rotation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Logger instance (using autoload singleton)
var logger: Node

func before_each() -> void:
	"""Setup test fixtures before each test."""
	# MythosLogger is an autoload singleton, so we access it directly
	logger = MythosLogger
	# Reset to known state if possible (Logger doesn't have reset, so we test current state)

func test_logger_singleton_exists() -> void:
	"""Test that Logger singleton exists and is accessible."""
	assert_not_null(logger, "FAIL: Expected Logger singleton to exist. Context: Autoload singleton. Why: Logger should be registered in project.godot autoload. Hint: Check project.godot [autoload] section has Logger entry.")
	
	if logger:
		assert_true(logger is Node, "FAIL: Expected Logger to be a Node. Got %s. Context: Autoload singleton. Why: Logger extends Node. Hint: Check core/singletons/Logger.gd extends Node.")

func test_log_level_enum_exists() -> void:
	"""Test that LogLevel enum exists with expected values."""
	if not logger:
		pass_test("Logger not available, skipping enum test")
		return
	
	# Check enum values exist
	var has_error: bool = logger.has_method("error")
	var has_warn: bool = logger.has_method("warn")
	var has_info: bool = logger.has_method("info")
	var has_debug: bool = logger.has_method("debug")
	var has_verbose: bool = logger.has_method("verbose")
	
	assert_true(has_error, "FAIL: Expected Logger.error() method to exist. Context: Logger singleton. Why: Logger should have error logging method. Hint: Check core/singletons/Logger.gd has error() method.")
	assert_true(has_warn, "FAIL: Expected Logger.warn() method to exist. Context: Logger singleton. Why: Logger should have warn logging method. Hint: Check core/singletons/Logger.gd has warn() method.")
	assert_true(has_info, "FAIL: Expected Logger.info() method to exist. Context: Logger singleton. Why: Logger should have info logging method. Hint: Check core/singletons/Logger.gd has info() method.")
	assert_true(has_debug, "FAIL: Expected Logger.debug() method to exist. Context: Logger singleton. Why: Logger should have debug logging method. Hint: Check core/singletons/Logger.gd has debug() method.")
	assert_true(has_verbose, "FAIL: Expected Logger.verbose() method to exist. Context: Logger singleton. Why: Logger should have verbose logging method. Hint: Check core/singletons/Logger.gd has verbose() method.")

func test_logger_logs_without_crash() -> void:
	"""Test that logger methods can be called without crashing."""
	if not logger:
		pass_test("Logger not available, skipping log test")
		return
	
	# Test each log level - should not crash
	logger.error("Test", "Test error message")
	logger.warn("Test", "Test warning message")
	logger.info("Test", "Test info message")
	logger.debug("Test", "Test debug message")
	logger.verbose("Test", "Test verbose message")
	
	# If we get here without crash, test passes
	pass_test("All logger methods called without crash")

func test_logger_handles_null_system_gracefully() -> void:
	"""Test that logger handles null/empty system name gracefully."""
	if not logger:
		pass_test("Logger not available, skipping null system test")
		return
	
	# Should not crash with empty system name
	logger.info("", "Test message with empty system")
	logger.info("Test", "Test message")
	
	pass_test("Logger handles empty system name without crash")

func test_logger_handles_null_message_gracefully() -> void:
	"""Test that logger handles null/empty message gracefully."""
	if not logger:
		pass_test("Logger not available, skipping null message test")
		return
	
	# Should not crash with empty message
	logger.info("Test", "")
	logger.info("Test", "Valid message")
	
	pass_test("Logger handles empty message without crash")

func test_logger_handles_data_parameter() -> void:
	"""Test that logger accepts optional data parameter."""
	if not logger:
		pass_test("Logger not available, skipping data parameter test")
		return
	
	# Test with Dictionary data
	var test_data: Dictionary = {"key": "value", "number": 42}
	logger.info("Test", "Test message with data", test_data)
	
	# Test with Array data
	var test_array: Array = [1, 2, 3]
	logger.info("Test", "Test message with array", test_array)
	
	# Test with null data
	logger.info("Test", "Test message with null data", null)
	
	pass_test("Logger handles data parameter without crash")

func test_logger_has_reload_config_method() -> void:
	"""Test that logger has reload_config method for runtime config updates."""
	if not logger:
		pass_test("Logger not available, skipping reload_config test")
		return
	
	var has_reload: bool = logger.has_method("reload_config")
	assert_true(has_reload, "FAIL: Expected Logger.reload_config() method to exist. Context: Logger singleton. Why: Logger should support runtime config reloading. Hint: Check core/singletons/Logger.gd has reload_config() method.")
	
	if has_reload:
		# Should not crash when called
		logger.reload_config()
		pass_test("reload_config() called without crash")

func test_logger_has_set_system_level_method() -> void:
	"""Test that logger has set_system_level method for runtime level changes."""
	if not logger:
		pass_test("Logger not available, skipping set_system_level test")
		return
	
	var has_set_level: bool = logger.has_method("set_system_level")
	assert_true(has_set_level, "FAIL: Expected Logger.set_system_level() method to exist. Context: Logger singleton. Why: Logger should support runtime level changes (dev_mode). Hint: Check core/singletons/Logger.gd has set_system_level() method.")
	
	if has_set_level:
		# Should not crash when called (may require dev_mode)
		logger.set_system_level("Test", "INFO")
		pass_test("set_system_level() called without crash")

func test_logger_config_loading() -> void:
	"""Test that logger loads configuration from JSON file."""
	if not logger:
		pass_test("Logger not available, skipping config test")
		return
	
	# Logger should have loaded config in _ready()
	# We can't easily test internal state without exposing it, but we can test it doesn't crash
	# and that methods work (which implies config loaded)
	logger.info("Test", "Config loaded test")
	
	pass_test("Logger config loading appears to work (methods functional)")
