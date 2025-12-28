# ╔═══════════════════════════════════════════════════════════
# ║ PerformanceMonitorSingleton.gd
# ║ Desc: Global autoload singleton for managing the Performance Monitor overlay
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Preloaded Performance Monitor scene
var monitor_scene: PackedScene = preload("res://scenes/ui/overlays/PerformanceMonitor.tscn")

## Instance of the Performance Monitor overlay
var monitor_instance: PerformanceMonitor = null


func _ready() -> void:
	"""Instantiate and add the Performance Monitor overlay to the scene tree."""
	MythosLogger.debug("PerformanceMonitorSingleton", "_ready() called - instantiating global overlay")
	
	# DIAGNOSTIC TEST: Prevent instantiation entirely
	MythosLogger.info("PerformanceMonitorSingleton", "DIAGNOSTIC: PerformanceMonitor instantiation disabled for FPS testing")
	return
	
	# Instantiate the Performance Monitor scene
	monitor_instance = monitor_scene.instantiate() as PerformanceMonitor
	if monitor_instance == null:
		MythosLogger.error("PerformanceMonitorSingleton", "Failed to instantiate PerformanceMonitor scene")
		return
	
	# Add to scene tree
	add_child(monitor_instance, true)
	MythosLogger.debug("PerformanceMonitorSingleton", "Global Performance Monitor overlay instantiated and added to scene tree")
	MythosLogger.info("PerformanceMonitorSingleton", "Performance Monitor available globally in all scenes")


func set_refresh_time(time_ms: float) -> void:
	"""Set refresh time for the performance monitor (called from MapRenderer)."""
	if monitor_instance:
		monitor_instance.set_refresh_time(time_ms)


func queue_diagnostic(callable: Callable) -> void:
	"""Queue a diagnostic callable for execution on main thread (DiagnosticDispatcher API)."""
	if monitor_instance:
		monitor_instance.queue_diagnostic(callable)
	else:
		# Fallback: If monitor not instantiated, execute directly on main thread
		# This ensures logging still works when PerformanceMonitor is disabled for testing
		callable.call()


func push_metric_from_thread(metric: Dictionary) -> void:
	"""Push a metric from a thread into the ring buffer (DiagnosticDispatcher API)."""
	if monitor_instance:
		monitor_instance.push_metric_from_thread(metric)


func can_log() -> bool:
	"""Check if logging is allowed based on rate limiting (DiagnosticDispatcher API)."""
	if monitor_instance:
		return monitor_instance.can_log()
	return true  # Default to allowing if monitor not ready


## Waterfall View Instrumentation Hooks (Frame-Tagged for Sync)

var _refresh_breakdown_buffer: Array[Dictionary] = []
var _thread_breakdown_buffer: Array[Dictionary] = []
var _other_process_buffer: Array[Dictionary] = []
var _buffer_mutex: Mutex = Mutex.new()

## Direct thread time storage (Phase 2: Separate from breakdown buffer)
## Updated by WorldGenerator after generation completes, read by PerformanceLogger
var thread_time_ms: float = 0.0
var _thread_time_mutex: Mutex = Mutex.new()

func push_refresh_breakdown(breakdown: Dictionary, frame_id: int = -1) -> void:
	"""Push refresh breakdown with frame_id for waterfall view sync."""
	if frame_id == -1:
		frame_id = Engine.get_process_frames()
	_buffer_mutex.lock()
	_refresh_breakdown_buffer.append({
		"frame_id": frame_id,
		"breakdown": breakdown,
		"timestamp_usec": Time.get_ticks_usec()
	})
	if _refresh_breakdown_buffer.size() > UIConstants.WATERFALL_BUFFER_MAX:
		_refresh_breakdown_buffer.pop_front()
	_buffer_mutex.unlock()

func push_thread_breakdown(breakdown: Dictionary, frame_id: int = -1) -> void:
	"""Push thread breakdown with frame_id for waterfall view sync."""
	if frame_id == -1:
		frame_id = Engine.get_process_frames()
	_buffer_mutex.lock()
	_thread_breakdown_buffer.append({
		"frame_id": frame_id,
		"breakdown": breakdown,
		"timestamp_usec": Time.get_ticks_usec()
	})
	var buffer_size: int = _thread_breakdown_buffer.size()
	if buffer_size > UIConstants.WATERFALL_BUFFER_MAX:
		_thread_breakdown_buffer.pop_front()
	_buffer_mutex.unlock()
	
	var total_ms: float = breakdown.get("total_ms", 0.0)
	MythosLogger.info("PerformanceMonitorSingleton", "Pushed thread breakdown to buffer", {
		"frame_id": frame_id,
		"buffer_size": buffer_size,
		"total_ms": total_ms
	})


func set_thread_time_ms(time_ms: float) -> void:
	"""Set thread compute time directly (Phase 2: Separate from breakdown buffer)."""
	_thread_time_mutex.lock()
	var old_value: float = thread_time_ms
	thread_time_ms = time_ms
	_thread_time_mutex.unlock()
	MythosLogger.info("PerformanceMonitorSingleton", "Set thread_time_ms", {
		"old_value": old_value,
		"new_value": time_ms
	})


func get_thread_time_ms() -> float:
	"""Get current thread compute time (Phase 2: Direct access, no buffer consumption)."""
	_thread_time_mutex.lock()
	var result: float = thread_time_ms
	_thread_time_mutex.unlock()
	return result

func push_other_process_timing(timing_ms: float, frame_id: int = -1) -> void:
	"""Push explicit other process timing with frame_id."""
	if frame_id == -1:
		frame_id = Engine.get_process_frames()
	_buffer_mutex.lock()
	_other_process_buffer.append({
		"frame_id": frame_id,
		"time_ms": timing_ms,
		"timestamp_usec": Time.get_ticks_usec()
	})
	if _other_process_buffer.size() > UIConstants.WATERFALL_BUFFER_MAX:
		_other_process_buffer.pop_front()
	_buffer_mutex.unlock()

func get_refresh_breakdown_buffer() -> Array[Dictionary]:
	"""Get refresh breakdown buffer (for PerformanceMonitor matching)."""
	_buffer_mutex.lock()
	var buffer: Array[Dictionary] = _refresh_breakdown_buffer.duplicate()
	_buffer_mutex.unlock()
	return buffer

func get_thread_breakdown_buffer() -> Array[Dictionary]:
	"""Get thread breakdown buffer (for PerformanceMonitor matching)."""
	_buffer_mutex.lock()
	var buffer: Array[Dictionary] = _thread_breakdown_buffer.duplicate()
	_buffer_mutex.unlock()
	return buffer

func get_other_process_buffer() -> Array[Dictionary]:
	"""Get other process buffer (for PerformanceMonitor matching)."""
	_buffer_mutex.lock()
	var buffer: Array[Dictionary] = _other_process_buffer.duplicate()
	_buffer_mutex.unlock()
	return buffer

func consume_refresh_for_frame(frame_id: int) -> Dictionary:
	"""Consume and return refresh breakdown for a specific frame."""
	_buffer_mutex.lock()
	for i in range(_refresh_breakdown_buffer.size() - 1, -1, -1):
		var metric: Dictionary = _refresh_breakdown_buffer[i]
		if metric.get("frame_id", -1) == frame_id or metric.get("frame_id", -1) == frame_id - 1:
			var result: Dictionary = metric.duplicate()
			_refresh_breakdown_buffer.remove_at(i)
			_buffer_mutex.unlock()
			return result
	_buffer_mutex.unlock()
	return {}

func peek_thread_for_frame(frame_id: int) -> Dictionary:
	"""Peek at thread breakdown for a specific frame without removing it (non-destructive read)."""
	_buffer_mutex.lock()
	for i in range(_thread_breakdown_buffer.size() - 1, -1, -1):
		var metric: Dictionary = _thread_breakdown_buffer[i]
		if metric.get("frame_id", -1) == frame_id or metric.get("frame_id", -1) == frame_id - 1:
			var result: Dictionary = metric.duplicate()
			_buffer_mutex.unlock()
			MythosLogger.debug("PerformanceMonitorSingleton", "Peeked thread breakdown", {
				"frame_id": frame_id,
				"buffer_size": _thread_breakdown_buffer.size()
			})
			return result
	_buffer_mutex.unlock()
	return {}


func consume_thread_for_frame(frame_id: int) -> Dictionary:
	"""Consume and return thread breakdown for a specific frame (removes from buffer)."""
	_buffer_mutex.lock()
	var buffer_size_before: int = _thread_breakdown_buffer.size()
	for i in range(_thread_breakdown_buffer.size() - 1, -1, -1):
		var metric: Dictionary = _thread_breakdown_buffer[i]
		if metric.get("frame_id", -1) == frame_id or metric.get("frame_id", -1) == frame_id - 1:
			var result: Dictionary = metric.duplicate()
			var breakdown: Dictionary = result.get("breakdown", {})
			var total_ms: float = breakdown.get("total_ms", 0.0)
			_thread_breakdown_buffer.remove_at(i)
			_buffer_mutex.unlock()
			MythosLogger.info("PerformanceMonitorSingleton", "Consumed thread breakdown", {
				"frame_id": frame_id,
				"buffer_size_before": buffer_size_before,
				"buffer_size_after": _thread_breakdown_buffer.size(),
				"total_ms": total_ms
			})
			return result
	_buffer_mutex.unlock()
	return {}

func consume_other_process_for_frame(frame_id: int) -> Dictionary:
	"""Consume and return other process timing for a specific frame."""
	_buffer_mutex.lock()
	for i in range(_other_process_buffer.size() - 1, -1, -1):
		var metric: Dictionary = _other_process_buffer[i]
		if metric.get("frame_id", -1) == frame_id or metric.get("frame_id", -1) == frame_id - 1:
			var result: Dictionary = metric.duplicate()
			_other_process_buffer.remove_at(i)
			_buffer_mutex.unlock()
			return result
	_buffer_mutex.unlock()
	return {}
