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
