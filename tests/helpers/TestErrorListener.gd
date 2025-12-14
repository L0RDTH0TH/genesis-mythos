# ╔═══════════════════════════════════════════════════════════
# ║ TestErrorListener.gd
# ║ Desc: Global error listener for tests - captures errors, warnings, and script errors
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name TestErrorListener

## Captured errors
var errors: Array[String] = []

## Captured warnings
var warnings: Array[String] = []

## Script errors (parse errors, load failures)
var script_errors: Array[String] = []

## Resource load failures
var resource_load_failures: Array[String] = []

## Signal tracking - tracks signals that should have fired
var expected_signals: Dictionary = {}  # signal_name -> bool (fired)
var signal_timeouts: Dictionary = {}  # signal_name -> timeout_time

## Thread tracking
var active_threads: Array[Thread] = []

## Singleton instance
static var instance = null

func _init() -> void:
	"""Initialize error listener."""
	if instance == null:
		instance = self
		_connect_error_signals()

func _connect_error_signals() -> void:
	"""Connect to Godot's error reporting system."""
	# Note: Godot 4 doesn't have a direct script_error signal
	# We'll use push_error/push_warning hooks via a custom approach
	pass

func capture_error(error_text: String) -> void:
	"""Capture an error message."""
	if not errors.has(error_text):
		errors.append(error_text)

func capture_warning(warning_text: String) -> void:
	"""Capture a warning message."""
	if not warnings.has(warning_text):
		warnings.append(warning_text)

func capture_script_error(script_path: String, error_text: String) -> void:
	"""Capture a script parse/load error."""
	var error_msg: String = "%s: %s" % [script_path, error_text]
	if not script_errors.has(error_msg):
		script_errors.append(error_msg)

func capture_resource_load_failure(resource_path: String) -> void:
	"""Capture a resource load failure."""
	if not resource_load_failures.has(resource_path):
		resource_load_failures.append(resource_path)

func expect_signal(source: Object, signal_name: String, timeout_seconds: float = 5.0) -> void:
	"""Expect a signal to fire within timeout."""
	var full_signal_name: String = "%s::%s" % [str(source.get_script().get_path() if source.get_script() else "unknown"), signal_name]
	expected_signals[full_signal_name] = false
	signal_timeouts[full_signal_name] = Time.get_ticks_msec() + (timeout_seconds * 1000.0)
	
	# Connect to signal
	if source.has_signal(signal_name):
		var callable: Callable = Callable(self, "_on_expected_signal").bind(full_signal_name)
		source.connect(signal_name, callable)

func _on_expected_signal(signal_name: String) -> void:
	"""Called when an expected signal fires."""
	expected_signals[signal_name] = true

func check_expected_signals() -> Array[String]:
	"""Check if all expected signals fired, return list of missing signals."""
	var missing: Array[String] = []
	var current_time: int = Time.get_ticks_msec()
	
	for signal_name: String in expected_signals.keys():
		if not expected_signals[signal_name]:
			var timeout_time: int = signal_timeouts.get(signal_name, 0)
			if current_time > timeout_time:
				missing.append(signal_name)
	
	return missing

func track_thread(thread: Thread) -> void:
	"""Track an active thread."""
	if not active_threads.has(thread):
		active_threads.append(thread)

func check_threads_complete() -> Array[Thread]:
	"""Check if all tracked threads are complete, return list of active threads."""
	var active: Array[Thread] = []
	for thread: Thread in active_threads:
		if thread.is_alive():
			active.append(thread)
		else:
			active_threads.erase(thread)
	return active

func clear() -> void:
	"""Clear all captured errors and tracking."""
	errors.clear()
	warnings.clear()
	script_errors.clear()
	resource_load_failures.clear()
	expected_signals.clear()
	signal_timeouts.clear()
	active_threads.clear()

func has_errors() -> bool:
	"""Check if any errors were captured."""
	return errors.size() > 0 or script_errors.size() > 0 or resource_load_failures.size() > 0

func get_all_errors() -> String:
	"""Get all errors as a formatted string."""
	var all_errors: Array[String] = []
	
	if errors.size() > 0:
		all_errors.append("Errors: %s" % str(errors))
	if script_errors.size() > 0:
		all_errors.append("Script Errors: %s" % str(script_errors))
	if resource_load_failures.size() > 0:
		all_errors.append("Resource Load Failures: %s" % str(resource_load_failures))
	
	var missing_signals: Array[String] = check_expected_signals()
	if missing_signals.size() > 0:
		all_errors.append("Missing Signals: %s" % str(missing_signals))
	
	var active_threads_list: Array[Thread] = check_threads_complete()
	if active_threads_list.size() > 0:
		all_errors.append("Active Threads: %d" % active_threads_list.size())
	
	return "\n".join(all_errors)

static func get_instance():
	"""Get or create singleton instance."""
	if instance == null:
		var script = load("res://tests/helpers/TestErrorListener.gd")
		instance = script.new()
	return instance
