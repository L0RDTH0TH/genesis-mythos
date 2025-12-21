# ╔═══════════════════════════════════════════════════════════
# ║ FlameGraphProfiler.gd
# ║ Desc: Singleton for flame graph profiling data collection
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Configuration file path
const CONFIG_PATH: String = "res://data/config/flame_graph_config.json"

## Configuration dictionary loaded from JSON
var config: Dictionary = {}

## Is flame graph profiling currently enabled
var is_profiling_enabled: bool = false

## Sampling timer for interval-based stack collection
var sampling_timer: Timer = null

## Ring buffer for stack trace samples
var stack_samples: Array[Dictionary] = []
const MAX_SAMPLES: int = 1000  ## Maximum samples in buffer

## Hierarchical call tree (aggregated from samples)
var call_tree: Dictionary = {}

## Mutex for thread-safe operations
var _buffer_mutex: Mutex = Mutex.new()

## Auto-export timer
var auto_export_timer: Timer = null


func _ready() -> void:
	"""Initialize the flame graph profiler on ready."""
	_load_config()
	_apply_config()
	
	if is_profiling_enabled:
		# Setup timers directly since config says enabled
		var sampling_mode: String = config.get("sampling_mode", "sampling")
		if sampling_mode == "sampling":
			_setup_sampling_timer()
		_setup_auto_export_timer()
		MythosLogger.info("FlameGraphProfiler", "Flame graph profiling initialized and enabled")
	else:
		MythosLogger.debug("FlameGraphProfiler", "Flame graph profiling initialized (disabled)")


func _exit_tree() -> void:
	"""Cleanup on exit."""
	stop_profiling()
	MythosLogger.info("FlameGraphProfiler", "Flame graph profiler shutting down")


func _load_config() -> void:
	"""Load configuration from JSON file."""
	var config_file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	
	if not config_file:
		MythosLogger.warn("FlameGraphProfiler", "Could not load config from %s, using defaults" % CONFIG_PATH)
		config = _get_default_config()
		return
	
	var content: String = config_file.get_as_text()
	config_file.close()
	
	var json := JSON.new()
	var parse_result: Error = json.parse(content)
	
	if parse_result != OK:
		MythosLogger.warn("FlameGraphProfiler", "Failed to parse config JSON, using defaults")
		config = _get_default_config()
		return
	
	var parsed: Variant = json.data
	if parsed is Dictionary:
		config = parsed as Dictionary
	else:
		MythosLogger.warn("FlameGraphProfiler", "Invalid config format, using defaults")
		config = _get_default_config()


func _get_default_config() -> Dictionary:
	"""Return default configuration dictionary."""
	return {
		"enabled": false,
		"sampling_mode": "sampling",
		"sampling_interval_ms": 10.0,
		"max_stack_depth": 20,
		"export_format": "json",
		"export_directory": "user://flame_graphs/",
		"auto_export_interval_seconds": 60.0,
		"systems": {
			"world_generation": true,
			"rendering": true,
			"entity_sim": false
		}
	}


func _apply_config() -> void:
	"""Apply loaded configuration to internal variables."""
	is_profiling_enabled = config.get("enabled", false)


func start_profiling() -> void:
	"""Start flame graph profiling."""
	if is_profiling_enabled:
		MythosLogger.warn("FlameGraphProfiler", "Profiling already started")
		return
	
	is_profiling_enabled = true
	
	# Setup sampling timer if using sampling mode
	var sampling_mode: String = config.get("sampling_mode", "sampling")
	if sampling_mode == "sampling":
		_setup_sampling_timer()
	
	# Setup auto-export timer
	_setup_auto_export_timer()
	
	MythosLogger.info("FlameGraphProfiler", "Flame graph profiling started")


func stop_profiling() -> void:
	"""Stop flame graph profiling."""
	if not is_profiling_enabled:
		return
	
	is_profiling_enabled = false
	
	# Stop timers
	if sampling_timer:
		sampling_timer.stop()
		sampling_timer.queue_free()
		sampling_timer = null
	
	if auto_export_timer:
		auto_export_timer.stop()
		auto_export_timer.queue_free()
		auto_export_timer = null
	
	MythosLogger.info("FlameGraphProfiler", "Flame graph profiling stopped")


func _setup_sampling_timer() -> void:
	"""Setup timer for interval-based stack sampling."""
	if sampling_timer:
		return
	
	var interval_ms: float = config.get("sampling_interval_ms", 10.0)
	sampling_timer = Timer.new()
	sampling_timer.name = "SamplingTimer"
	sampling_timer.wait_time = interval_ms / 1000.0  # Convert ms to seconds
	sampling_timer.timeout.connect(_collect_stack_sample)
	add_child(sampling_timer)
	sampling_timer.start()
	
	MythosLogger.debug("FlameGraphProfiler", "Sampling timer setup with interval: %.2f ms" % interval_ms)


func _setup_auto_export_timer() -> void:
	"""Setup timer for automatic data export."""
	if auto_export_timer:
		return
	
	var interval_seconds: float = config.get("auto_export_interval_seconds", 60.0)
	auto_export_timer = Timer.new()
	auto_export_timer.name = "AutoExportTimer"
	auto_export_timer.wait_time = interval_seconds
	auto_export_timer.timeout.connect(_auto_export_data)
	add_child(auto_export_timer)
	auto_export_timer.start()
	
	MythosLogger.debug("FlameGraphProfiler", "Auto-export timer setup with interval: %.2f seconds" % interval_seconds)


func _collect_stack_sample() -> void:
	"""Collect a stack trace sample (called by sampling timer)."""
	if not is_profiling_enabled:
		return
	
	# Check rate limiting via PerformanceMonitorSingleton
	if PerformanceMonitorSingleton and not PerformanceMonitorSingleton.can_log():
		return
	
	# Get stack trace (get_stack() returns Array[Dictionary] with source, function, line)
	var raw_stack: Array = get_stack()
	var max_depth: int = config.get("max_stack_depth", 20)
	
	# Limit stack depth (keep deepest frames, remove top-level ones)
	var stack: Array = []
	if raw_stack.size() > max_depth:
		# Keep the deepest frames (most recent calls)
		var start_idx: int = raw_stack.size() - max_depth
		stack = raw_stack.slice(start_idx)
	else:
		stack = raw_stack.duplicate()
	
	# Format stack frames for better readability
	var formatted_stack: Array[Dictionary] = []
	for frame in stack:
		if frame is Dictionary:
			var formatted_frame: Dictionary = {
				"function": frame.get("function", "unknown"),
				"source": frame.get("source", "unknown"),
				"line": frame.get("line", 0)
			}
			formatted_stack.append(formatted_frame)
	
	# Create sample dictionary
	var sample: Dictionary = {
		"frame_id": Engine.get_process_frames(),
		"timestamp_usec": Time.get_ticks_usec(),
		"stack": formatted_stack,
		"stack_depth": formatted_stack.size()
	}
	
	# Push to buffer (thread-safe)
	_buffer_mutex.lock()
	stack_samples.append(sample)
	if stack_samples.size() > MAX_SAMPLES:
		stack_samples.pop_front()
	_buffer_mutex.unlock()


func _auto_export_data() -> void:
	"""Automatically export data (called by auto-export timer)."""
	if not is_profiling_enabled:
		return
	
	export_to_json()


func push_flame_data(stack_trace: Array, time_ms: float, frame_id: int = -1) -> void:
	"""
	Push flame graph data with stack trace and timing.
	
	Args:
		stack_trace: Array of stack frame dictionaries from get_stack()
		time_ms: Time spent in milliseconds
		frame_id: Frame ID for synchronization (defaults to current frame)
	"""
	if not is_profiling_enabled:
		return
	
	if frame_id == -1:
		frame_id = Engine.get_process_frames()
	
	var max_depth: int = config.get("max_stack_depth", 20)
	
	# Format and limit stack trace
	var formatted_stack: Array[Dictionary] = []
	var stack_size: int = stack_trace.size()
	var start_idx: int = 0
	if stack_size > max_depth:
		start_idx = stack_size - max_depth
	
	for i in range(start_idx, stack_size):
		var frame = stack_trace[i]
		if frame is Dictionary:
			var formatted_frame: Dictionary = {
				"function": frame.get("function", "unknown"),
				"source": frame.get("source", "unknown"),
				"line": frame.get("line", 0)
			}
			formatted_stack.append(formatted_frame)
	
	var sample: Dictionary = {
		"frame_id": frame_id,
		"timestamp_usec": Time.get_ticks_usec(),
		"time_ms": time_ms,
		"stack": formatted_stack,
		"stack_depth": formatted_stack.size()
	}
	
	# Push to buffer (thread-safe)
	_buffer_mutex.lock()
	stack_samples.append(sample)
	if stack_samples.size() > MAX_SAMPLES:
		stack_samples.pop_front()
	_buffer_mutex.unlock()


func export_to_json() -> String:
	"""
	Export collected flame graph data to JSON file.
	
	Returns:
		Path to exported file, or empty string on failure
	"""
	var export_dir: String = config.get("export_directory", "user://flame_graphs/")
	
	# Ensure directory exists
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		MythosLogger.error("FlameGraphProfiler", "Failed to access user:// directory")
		return ""
	
	# Create export directory if needed
	var dir_path: String = export_dir.trim_prefix("user://")
	if not dir.dir_exists(dir_path):
		var err: Error = dir.make_dir(dir_path)
		if err != OK:
			MythosLogger.error("FlameGraphProfiler", "Failed to create export directory: %s" % dir_path)
			return ""
	
	# Generate timestamped filename
	var timestamp: String = Time.get_datetime_string_from_system(true, true).replace(":", "").replace("-", "").replace("T", "_").replace(".", "")
	var filename: String = "flame_graph_%s.json" % timestamp
	var full_path: String = export_dir + filename if export_dir.ends_with("/") else export_dir + "/" + filename
	
	# Get samples (thread-safe copy)
	_buffer_mutex.lock()
	var samples_to_export: Array[Dictionary] = stack_samples.duplicate()
	_buffer_mutex.unlock()
	
	# Aggregate samples into hierarchical call tree
	_aggregate_samples_to_tree(samples_to_export)
	
	# Create export data structure with hierarchical tree
	var export_data: Dictionary = {
		"metadata": {
			"export_timestamp": Time.get_datetime_string_from_system(),
			"sample_count": samples_to_export.size(),
			"profiler": "GenesisMythos_FlameGraphProfiler",
			"version": "1.0.0",
			"config": config
		},
		"call_tree": call_tree,
		"samples": samples_to_export  # Keep raw samples for reference
	}
	
	# Write JSON file
	var file := FileAccess.open(full_path, FileAccess.WRITE)
	if not file:
		MythosLogger.error("FlameGraphProfiler", "Failed to open file for export: %s" % full_path)
		return ""
	
	var json_string: String = JSON.stringify(export_data, "\t")
	file.store_string(json_string)
	file.close()
	
	MythosLogger.info("FlameGraphProfiler", "Exported %d samples and call tree to: %s" % [samples_to_export.size(), full_path])
	return full_path


func get_sample_count() -> int:
	"""Get current number of samples in buffer."""
	_buffer_mutex.lock()
	var count: int = stack_samples.size()
	_buffer_mutex.unlock()
	return count


func clear_samples() -> void:
	"""Clear all collected samples."""
	_buffer_mutex.lock()
	stack_samples.clear()
	call_tree.clear()
	_buffer_mutex.unlock()
	MythosLogger.debug("FlameGraphProfiler", "Cleared all samples and call tree")


func _aggregate_samples_to_tree(samples: Array[Dictionary]) -> void:
	"""
	Aggregate stack trace samples into hierarchical call tree.
	
	Builds a tree structure where each node represents a function call,
	with parent-child relationships based on call stack depth.
	"""
	call_tree.clear()
	
	if samples.is_empty():
		return
	
	# Initialize root node
	call_tree = {
		"function": "<root>",
		"source": "",
		"line": 0,
		"total_time_ms": 0.0,
		"self_time_ms": 0.0,
		"call_count": 0,
		"frame_ids": [],
		"children": {}
	}
	
	# Process each sample
	for sample in samples:
		var stack: Array = sample.get("stack", [])
		var frame_id: int = sample.get("frame_id", -1)
		var time_ms: float = sample.get("time_ms", 0.0)
		
		# If no time_ms provided, use sampling interval as estimate
		if time_ms <= 0.0:
			time_ms = config.get("sampling_interval_ms", 10.0)
		
		# Update root statistics
		call_tree["total_time_ms"] += time_ms
		call_tree["call_count"] += 1
		if not call_tree["frame_ids"].has(frame_id):
			call_tree["frame_ids"].append(frame_id)
		
		# Build tree from root to leaf (stack[0] is deepest, stack[-1] is shallowest)
		var current_node: Dictionary = call_tree
		
		for i in range(stack.size()):
			var frame: Dictionary = stack[i]
			if not frame is Dictionary:
				continue
			
			var function_name: String = frame.get("function", "unknown")
			var source: String = frame.get("source", "unknown")
			var line: int = frame.get("line", 0)
			
			# Create unique key for this function
			var node_key: String = "%s:%s:%d" % [source, function_name, line]
			
			# Get or create child node
			var children: Dictionary = current_node.get("children", {})
			
			if not children.has(node_key):
				# Create new node
				children[node_key] = {
					"function": function_name,
					"source": source,
					"line": line,
					"total_time_ms": 0.0,
					"self_time_ms": 0.0,
					"call_count": 0,
					"frame_ids": [],
					"children": {}
				}
			
			var node: Dictionary = children[node_key]
			
			# Update node statistics
			node["total_time_ms"] += time_ms
			node["call_count"] += 1
			if not node["frame_ids"].has(frame_id):
				node["frame_ids"].append(frame_id)
			
			# Update current_node's children reference
			current_node["children"] = children
			
			# Move to child node for next iteration
			current_node = node
		
		# Add time to leaf node's self_time (time spent in the function itself)
		if current_node.has("function") and current_node["function"] != "<root>":
			current_node["self_time_ms"] += time_ms
	
	# Calculate self_time for all nodes (total_time - sum of children's total_time)
	_calculate_self_times(call_tree)
	
	MythosLogger.debug("FlameGraphProfiler", "Aggregated %d samples into call tree" % samples.size())


func _calculate_self_times(node: Dictionary) -> void:
	"""Recursively calculate self_time for all nodes (total_time - children's total_time)."""
	if not node.has("children"):
		return
	
	var children: Dictionary = node.get("children", {})
	var children_total: float = 0.0
	
	# First, recursively calculate self_times for all children
	for child_key in children.keys():
		var child: Dictionary = children[child_key]
		_calculate_self_times(child)
		children_total += child.get("total_time_ms", 0.0)
	
	# Then calculate self_time for this node
	var total_time: float = node.get("total_time_ms", 0.0)
	var self_time: float = max(0.0, total_time - children_total)
	node["self_time_ms"] = self_time


func get_call_tree() -> Dictionary:
	"""Get the current aggregated call tree."""
	_buffer_mutex.lock()
	var tree: Dictionary = call_tree.duplicate(true)  # Deep copy
	_buffer_mutex.unlock()
	return tree

