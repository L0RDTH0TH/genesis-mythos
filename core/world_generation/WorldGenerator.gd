# ╔═══════════════════════════════════════════════════════════
# ║ WorldGenerator.gd
# ║ Desc: Threaded world generation manager with signals and progress tracking
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node
class_name WorldGenerator

## Generation thread
var generation_thread: Thread

## Signal emitted when generation completes with result data
signal generation_complete(data: Dictionary)

## Signal emitted during generation with phase name and progress (0.0-1.0)
signal progress_update(phase: String, percent: float)

## Current generation config loaded from JSON
var current_config: Dictionary = {}

## Internal MapGenerator instance
var map_generator: MapGenerator

## Current WorldMapData being generated
var current_world_data: WorldMapData

## Thread-safe metrics queue (Array of Dicts {phase: String, time_ms: float})
var thread_metrics_queue: Array[Dictionary] = []
var metrics_mutex: Mutex = Mutex.new()

## Config file path
const CONFIG_PATH: String = "res://data/world_gen_config.json"


func _ready() -> void:
	"""Initialize WorldGenerator."""
	MythosLogger.debug("WorldGenerator", "WorldGenerator initialized")
	map_generator = MapGenerator.new()
	# Connect progress callback
	map_generator.progress_callback = _on_map_generator_progress


func start_generation() -> void:
	"""Start threaded world generation from config JSON."""
	MythosLogger.debug("WorldGenerator", "start_generation() called")
	
	# Load config
	if not _load_config():
		MythosLogger.error("WorldGenerator", "Failed to load config, aborting generation")
		return
	
	# Create WorldMapData from config
	current_world_data = WorldMapData.new()
	current_world_data.seed = current_config.get("seed", 0)
	current_world_data.world_width = current_config.get("map_size", 1024)
	current_world_data.world_height = current_config.get("map_size", 1024)
	current_world_data.erosion_enabled = current_config.get("erosion_enabled", true)
	current_world_data.erosion_iterations = current_config.get("erosion_iterations", 5)
	current_world_data.rivers_enabled = current_config.get("rivers_enabled", true)
	current_world_data.river_count = current_config.get("river_count", 10)
	current_world_data.noise_type = current_config.get("noise_type", FastNoiseLite.TYPE_PERLIN)
	current_world_data.noise_frequency = current_config.get("noise_frequency", 0.0005)
	current_world_data.noise_octaves = current_config.get("noise_octaves", 4)
	current_world_data.noise_persistence = current_config.get("noise_persistence", 0.5)
	current_world_data.noise_lacunarity = current_config.get("noise_lacunarity", 2.0)
	current_world_data.sea_level = current_config.get("sea_level", 0.4)
	current_world_data.landmass_type = current_config.get("landmass_type", "Continents")
	
	# Start thread
	if generation_thread != null and generation_thread.is_alive():
		MythosLogger.warn("WorldGenerator", "Thread already running, waiting for completion")
		generation_thread.wait_to_finish()
	
	generation_thread = Thread.new()
	generation_thread.start(_threaded_generate)
	
	MythosLogger.info("WorldGenerator", "Generation thread started")


func _load_config() -> bool:
	"""Load config from JSON file, create defaults if missing."""
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		MythosLogger.warn("WorldGenerator", "Config file not found, creating defaults: %s" % CONFIG_PATH)
		_create_default_config()
		file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file == null:
			MythosLogger.error("WorldGenerator", "Failed to create default config")
			return false
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		MythosLogger.error("WorldGenerator", "Failed to parse config JSON: %d" % error)
		return false
	
	current_config = json.data as Dictionary
	MythosLogger.debug("WorldGenerator", "Config loaded: %s" % current_config)
	return true


func _create_default_config() -> void:
	"""Create default config file if missing."""
	var defaults: Dictionary = {
		"seed": 0,
		"map_size": 1024,
		"biome_count": 8,
		"erosion_enabled": true,
		"erosion_iterations": 5,
		"rivers_enabled": true,
		"river_count": 10,
		"noise_type": FastNoiseLite.TYPE_PERLIN,
		"noise_frequency": 0.0005,
		"noise_octaves": 4,
		"noise_persistence": 0.5,
		"noise_lacunarity": 2.0,
		"sea_level": 0.4,
		"landmass_type": "Continents"
	}
	
	var json_string: String = JSON.stringify(defaults, "\t")
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		MythosLogger.info("WorldGenerator", "Default config created: %s" % CONFIG_PATH)
	else:
		MythosLogger.error("WorldGenerator", "Failed to write default config: %s" % CONFIG_PATH)


func _threaded_generate() -> void:
	"""Thread function that runs generation logic."""
	MythosLogger.debug("WorldGenerator", "_threaded_generate() started in thread")
	
	var total_start: int = Time.get_ticks_msec()
	var phase_start: int
	
	# Phase 1: Configure noise
	var current_phase: String = "Configuring Noise"
	phase_start = Time.get_ticks_msec()
	call_deferred("_emit_progress", current_phase, 0.0)
	map_generator._configure_noise(current_world_data)
	var config_time: float = Time.get_ticks_msec() - phase_start
	_record_metric("configure_noise", config_time)
	# Instrumentation for flamegraph
	if FlameGraphProfiler:
		FlameGraphProfiler.push_flame_data_instrumented("configure_noise", config_time, {
			"seed": current_world_data.seed if current_world_data else 0,
			"noise_type": current_world_data.noise_type if current_world_data else 0
		})
	call_deferred("_emit_progress", current_phase, 1.0)
	
	# Phase 2: Generate heightmap
	current_phase = "Generating Heightmap"
	phase_start = Time.get_ticks_msec()
	call_deferred("_emit_progress", current_phase, 0.0)
	map_generator._generate_heightmap(current_world_data)
	var heightmap_time: float = Time.get_ticks_msec() - phase_start
	_record_metric("generate_heightmap", heightmap_time)
	# Instrumentation for flamegraph
	if FlameGraphProfiler:
		FlameGraphProfiler.push_flame_data_instrumented("generate_heightmap", heightmap_time, {
			"seed": current_world_data.seed if current_world_data else 0,
			"size": "%dx%d" % [current_world_data.world_width if current_world_data else 0, current_world_data.world_height if current_world_data else 0]
		})
	call_deferred("_emit_progress", current_phase, 1.0)
	
	# Phase 3: Post-processing
	current_phase = "Post-Processing"
	phase_start = Time.get_ticks_msec()
	call_deferred("_emit_progress", current_phase, 0.0)
	map_generator._apply_post_processing_pipeline(current_world_data)
	var postproc_time: float = Time.get_ticks_msec() - phase_start
	_record_metric("post_processing", postproc_time)
	# Instrumentation for flamegraph
	if FlameGraphProfiler:
		FlameGraphProfiler.push_flame_data_instrumented("post_processing_pipeline", postproc_time, {
			"seed": current_world_data.seed if current_world_data else 0,
			"erosion_enabled": current_world_data.erosion_enabled if current_world_data else false,
			"rivers_enabled": current_world_data.rivers_enabled if current_world_data else false
		})
	call_deferred("_emit_progress", current_phase, 1.0)
	
	var total_time: float = Time.get_ticks_msec() - total_start
	_record_metric("total_generation", total_time)
	# Instrumentation for flamegraph - top-level generation
	if FlameGraphProfiler:
		FlameGraphProfiler.push_flame_data_instrumented("world_generation", total_time, {
			"seed": current_world_data.seed if current_world_data else 0,
			"map_size": current_world_data.world_width if current_world_data else 0,
			"config_ms": config_time,
			"heightmap_ms": heightmap_time,
			"postproc_ms": postproc_time
		})
	MythosLogger.info("WorldGenerator", "Thread generation complete", {
		"total_time_ms": total_time,
		"config_ms": config_time,
		"heightmap_ms": heightmap_time,
		"postproc_ms": postproc_time
	})
	# Note: time values are now in milliseconds (not microseconds) for consistency with instrumentation
	
	# Aggregate phase metrics into breakdown and push to breakdown buffer (for waterfall view and CSV logging)
	# Use call_deferred to push on main thread with correct frame_id
	var breakdown: Dictionary = {
		"total_ms": total_time,
		"configure_noise_ms": config_time,
		"generate_heightmap_ms": heightmap_time,
		"post_processing_ms": postproc_time
	}
	call_deferred("_push_thread_breakdown_main_thread", breakdown)
	
	# Emit completion signal with data
	var result_data: Dictionary = {
		"world_map_data": current_world_data,
		"total_time_ms": total_time,
		"config_time_ms": config_time,
		"heightmap_time_ms": heightmap_time,
		"postproc_time_ms": postproc_time
	}
	call_deferred("_emit_complete", result_data)
	# Mark thread as complete (cleanup will happen in _emit_complete on main thread)


func _record_metric(phase: String, time_ms: float) -> void:
	"""Record thread metric via DiagnosticDispatcher (thread-safe)."""
	# Push metric to DiagnosticDispatcher ring buffer (thread-safe)
	PerformanceMonitorSingleton.push_metric_from_thread({
		"phase": phase,
		"time_ms": time_ms,
		"timestamp": Time.get_ticks_msec()
	})
	
	# Also keep local queue for backward compatibility with get_thread_metrics()
	metrics_mutex.lock()
	thread_metrics_queue.append({"phase": phase, "time_ms": time_ms})
	# Keep queue size reasonable (last 100 entries)
	if thread_metrics_queue.size() > 100:
		thread_metrics_queue.pop_front()
	metrics_mutex.unlock()


func get_thread_metrics() -> Array[Dictionary]:
	"""Get and clear thread metrics queue (thread-safe, called from main thread)."""
	metrics_mutex.lock()
	var metrics: Array[Dictionary] = thread_metrics_queue.duplicate()
	thread_metrics_queue.clear()
	metrics_mutex.unlock()
	return metrics


func is_generating() -> bool:
	"""Check if generation thread is currently running."""
	return generation_thread != null and generation_thread.is_alive()


func _emit_progress(phase: String, percent: float) -> void:
	"""Emit progress signal (callable from thread via call_deferred)."""
	progress_update.emit(phase, percent)


func _push_thread_breakdown_main_thread(breakdown: Dictionary) -> void:
	"""Push thread breakdown to PerformanceMonitorSingleton on main thread (callable from thread via call_deferred)."""
	var frame_id: int = Engine.get_process_frames()
	var total_ms: float = breakdown.get("total_ms", 0.0)
	
	# Phase 2: Set thread_time_ms directly (bypasses buffer, available for PerformanceLogger)
	PerformanceMonitorSingleton.set_thread_time_ms(total_ms)
	
	# Phase 1: Also push to breakdown buffer (for waterfall view)
	PerformanceMonitorSingleton.push_thread_breakdown(breakdown, frame_id)
	
	MythosLogger.info("WorldGenerator", "Pushed thread breakdown (both buffer and direct time)", {
		"frame_id": frame_id,
		"total_ms": total_ms,
		"configure_noise_ms": breakdown.get("configure_noise_ms", 0.0),
		"generate_heightmap_ms": breakdown.get("generate_heightmap_ms", 0.0),
		"post_processing_ms": breakdown.get("post_processing_ms", 0.0)
	})


func _emit_complete(data: Dictionary) -> void:
	"""Emit completion signal (callable from thread via call_deferred)."""
	# CRITICAL FIX: Duplicate Image from thread to main thread
	# Images created in threads must be duplicated before use on main thread
	if data.has("world_map_data") and data["world_map_data"] != null:
		var world_map_data = data["world_map_data"]
		if world_map_data.heightmap_image != null:
			world_map_data.heightmap_image = world_map_data.heightmap_image.duplicate()
			MythosLogger.debug("WorldGenerator", "Heightmap duplicated from thread to main thread")
	
	generation_complete.emit(data)
	# Clean up thread reference after completion (on main thread)
	if generation_thread != null:
		if generation_thread.is_alive():
			generation_thread.wait_to_finish()
		generation_thread = null


func _on_map_generator_progress(progress: float) -> void:
	"""Handle progress callback from MapGenerator."""
	# MapGenerator progress is generic, we'll use current phase context
	# This is a fallback if phase-specific progress isn't available
	pass


func _exit_tree() -> void:
	"""Clean up thread on exit."""
	if generation_thread != null and generation_thread.is_alive():
		MythosLogger.warn("WorldGenerator", "Waiting for thread to finish on exit")
		generation_thread.wait_to_finish()
		generation_thread = null

func _notification(what: int) -> void:
	"""Handle notification for proper thread cleanup."""
	if what == NOTIFICATION_PREDELETE:
		# Ensure thread is properly cleaned up before node is destroyed
		if generation_thread != null and generation_thread.is_alive():
			generation_thread.wait_to_finish()
			generation_thread = null
