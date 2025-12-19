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


func push_metric_from_thread(metric: Dictionary) -> void:
	"""Push a metric from a thread into the ring buffer (DiagnosticDispatcher API)."""
	if monitor_instance:
		monitor_instance.push_metric_from_thread(metric)


func can_log() -> bool:
	"""Check if logging is allowed based on rate limiting (DiagnosticDispatcher API)."""
	if monitor_instance:
		return monitor_instance.can_log()
	return true  # Default to allowing if monitor not ready
