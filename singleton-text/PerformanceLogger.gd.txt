# ╔═══════════════════════════════════════════════════════════
# ║ PerformanceLogger.gd
# ║ Desc: Lightweight performance logging system with CSV export (always-on by default)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Configuration file path
const CONFIG_PATH: String = "res://data/config/logging_config.json"

## Performance logging configuration
var config: Dictionary = {}

## Is performance logging currently enabled (default: true)
var is_logging_enabled: bool = true

## Current log file handle
var log_file: FileAccess = null

## Current log file path
var current_log_path: String = ""

## Timer for interval-based logging
var log_timer: float = 0.0

## Last logged timestamp (for interval control)
var last_log_time: float = 0.0

## Frame counter for CSV
var frame_counter: int = 0

## Notification label for on-screen status (optional)
var status_label: Label = null

## Signal emitted when logging state changes (for UI integration)
signal logging_state_changed(is_enabled: bool)


func _ready() -> void:
	"""Initialize performance logger from config."""
	_load_config()
	_ensure_log_directory()
	
	# Apply config setting (default: enabled = true)
	var perf_config: Dictionary = config.get("performance_logging", {})
	is_logging_enabled = perf_config.get("enabled", true)
	
	# Always start logging if enabled in config (no hotkey toggle)
	if is_logging_enabled:
		start_logging()
		MythosLogger.info_file_only("PerformanceLogger", "Performance logging active (always-on)")
	else:
		MythosLogger.debug_file_only("PerformanceLogger", "Performance logging disabled via config")
	
	MythosLogger.verbose_file_only("PerformanceLogger", "_ready() called")
	
	# Emit signal for initial state
	logging_state_changed.emit(is_logging_enabled)
	
	# DIAGNOSTIC TEST: Disable _process() entirely for testing
	set_process(false)
	MythosLogger.info("PerformanceLogger", "DIAGNOSTIC: _process() disabled for FPS testing")


func _process(_delta: float) -> void:
	"""Process per-frame logic: handle interval logging."""
	# DIAGNOSTIC TEST: Disabled entirely - return immediately
	return
	
	# If logging is enabled but file not open, start new log file
	if is_logging_enabled and log_file == null:
		_start_log_file()


func _exit_tree() -> void:
	"""Close log file on exit."""
	_close_log_file()


func _load_config() -> void:
	"""Load configuration from JSON file."""
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		MythosLogger.error("PerformanceLogger", "Failed to load config from: %s" % CONFIG_PATH)
		config = {}
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result: Error = json.parse(json_string)
	
	if parse_result != OK:
		MythosLogger.error("PerformanceLogger", "Failed to parse config JSON: %d" % parse_result)
		config = {}
		return
	
	config = json.data
	MythosLogger.debug_file_only("PerformanceLogger", "Config loaded successfully")


func _ensure_log_directory() -> void:
	"""Ensure perf_logs directory exists in user:// folder."""
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		MythosLogger.error("PerformanceLogger", "Failed to access user:// directory")
		return
	
	if not dir.dir_exists("perf_logs"):
		var err: Error = dir.make_dir("perf_logs")
		if err != OK:
			MythosLogger.error("PerformanceLogger", "Failed to create perf_logs directory: %d" % err)
		else:
			MythosLogger.debug_file_only("PerformanceLogger", "Created perf_logs directory")


func _start_log_file() -> void:
	"""Start a new log file with timestamped name."""
	if log_file != null:
		_close_log_file()
	
	var timestamp: String = Time.get_datetime_string_from_system(true, true).replace(":", "").replace("-", "").replace("T", "_").replace(".", "")
	current_log_path = "user://perf_logs/world_builder_perf_%s.csv" % timestamp
	
	log_file = FileAccess.open(current_log_path, FileAccess.WRITE)
	if log_file == null:
		MythosLogger.error("PerformanceLogger", "Failed to open log file: %s" % current_log_path)
		is_logging_enabled = false
		return
	
	# Write CSV header
	var header: PackedStringArray = PackedStringArray([
		"Timestamp", "Frame", "FrameTimeMs", "FPS", "DrawCalls", "Primitives",
		"SmallObjects", "LandmassNodes", "PhysicsMs", "ThreadMs", "MemoryMB",
		"Scene", "Notes"
	])
	log_file.store_csv_line(header)
	
	frame_counter = 0
	last_log_time = Time.get_ticks_msec() / 1000.0
	
	MythosLogger.info_file_only("PerformanceLogger", "Started logging to: %s" % current_log_path)
	
	# Show on-screen notification if possible
	_show_status_notification("Perf Logging: ON")


func _close_log_file() -> void:
	"""Close current log file."""
	if log_file != null:
		log_file.close()
		log_file = null
		MythosLogger.info_file_only("PerformanceLogger", "Closed log file: %s" % current_log_path)
		current_log_path = ""


func start_logging() -> void:
	"""Start performance logging (public method, called automatically if enabled in config)."""
	if is_logging_enabled and log_file == null:
		_start_log_file()
		MythosLogger.info_file_only("PerformanceLogger", "Performance logging started")


func stop_logging() -> void:
	"""Stop performance logging (public method, only used if explicitly disabled in config)."""
	if log_file != null:
		_close_log_file()
		MythosLogger.info_file_only("PerformanceLogger", "Performance logging stopped")


func log_current_frame(custom_data: Dictionary = {}) -> void:
	"""
	Log current frame performance metrics.
	
	Args:
		custom_data: Optional dictionary with custom metrics (e.g., {"small_objects": 20937, "landmass_nodes": 483, "scene": "WorldBuilder", "notes": "..."})
	"""
	if not is_logging_enabled or log_file == null:
		return
	
	# Check if we should log this frame (based on interval)
	var perf_config: Dictionary = config.get("performance_logging", {})
	var interval_seconds: float = perf_config.get("log_interval_seconds", 0.1)
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_log_time < interval_seconds:
		return  # Skip this frame
	
	last_log_time = current_time
	frame_counter += 1
	
	# Collect standard metrics from Performance singleton
	var fps: float = Engine.get_frames_per_second()
	var frame_time_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms: float = 0.0
	var memory_mb: float = 0.0
	var draw_calls: int = 0
	var primitives: int = 0
	
	# Get physics time if enabled
	if perf_config.get("include_physics_ms", true):
		physics_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	
	# Get memory if enabled
	if perf_config.get("include_memory", true):
		var memory_bytes: int = Performance.get_monitor(Performance.MEMORY_STATIC)
		memory_mb = float(memory_bytes) / 1048576.0  # Convert bytes to MB
	
	# Get rendering metrics if enabled (requires 2+ frames for RenderingServer to be ready)
	if perf_config.get("include_draw_calls", true) or perf_config.get("include_primitives", true):
		# Check if RenderingServer is ready (need to wait a couple frames)
		if Engine.get_process_frames() >= 3:
			if perf_config.get("include_draw_calls", true):
				draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			if perf_config.get("include_primitives", true):
				primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	
	# Get custom data (small_objects, landmass_nodes, scene, notes)
	var small_objects: int = custom_data.get("small_objects", 0)
	var landmass_nodes: int = custom_data.get("landmass_nodes", 0)
	var scene_name: String = custom_data.get("scene", "")
	var notes: String = custom_data.get("notes", "")
	
	# Thread time: Phase 2 - Use direct thread_time_ms (bypasses buffer consumption conflict)
	# Phase 1 fallback: Peek at breakdown buffer if direct time is 0.0
	var thread_ms: float = PerformanceMonitorSingleton.get_thread_time_ms()
	
	if thread_ms == 0.0:
		# Fallback: Peek at breakdown buffer (non-destructive read)
		var frame_id: int = Engine.get_process_frames()
		var thread_metric: Dictionary = PerformanceMonitorSingleton.peek_thread_for_frame(frame_id)
		if not thread_metric.is_empty():
			var breakdown: Dictionary = thread_metric.get("breakdown", {})
			thread_ms = breakdown.get("total_ms", 0.0)
			MythosLogger.debug_file_only("PerformanceLogger", "Using thread time from breakdown buffer (peek) - frame_id: %d, thread_ms: %.3f" % [frame_id, thread_ms])
		elif PerformanceMonitorSingleton.monitor_instance:
			# Final fallback: PerformanceMonitor's aggregated thread compute time
			thread_ms = PerformanceMonitorSingleton.monitor_instance.thread_compute_time_ms
			if thread_ms > 0.0:
				MythosLogger.debug_file_only("PerformanceLogger", "Using thread time from PerformanceMonitor fallback - thread_ms: %.3f" % thread_ms)
	
	# Format timestamp
	var timestamp: String = Time.get_datetime_string_from_system(false, true)
	
	# Write CSV row
	var row: PackedStringArray = PackedStringArray([
		timestamp,
		str(frame_counter),
		"%.3f" % frame_time_ms,
		"%.2f" % fps,
		str(draw_calls),
		str(primitives),
		str(small_objects),
		str(landmass_nodes),
		"%.3f" % physics_ms,
		"%.3f" % thread_ms,
		"%.2f" % memory_mb,
		scene_name,
		notes
	])
	log_file.store_csv_line(row)


func _show_status_notification(message: String) -> void:
	"""Show on-screen notification (optional - can be extended with UI)."""
	# For now, just log it to file. Future: could show temporary on-screen label
	MythosLogger.info_file_only("PerformanceLogger", message)

