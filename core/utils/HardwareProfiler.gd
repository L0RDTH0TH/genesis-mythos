# ╔═══════════════════════════════════════════════════════════
# ║ HardwareProfiler.gd
# ║ Desc: Detects system capabilities and determines quality presets for world generation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name HardwareProfiler

## Quality level enum
enum QualityLevel {
	LOW,      # Low-end hardware (integrated graphics, < 4 cores)
	MEDIUM,   # Mid-range hardware (dedicated GPU, 4-8 cores)
	HIGH      # High-end hardware (powerful GPU, 8+ cores)
}

## Detected quality level
var detected_quality: QualityLevel = QualityLevel.MEDIUM

## System information
var cpu_count: int = 1
var gpu_name: String = ""
var available_memory_mb: int = 0
var benchmark_time_ms: float = 0.0

## Configuration data loaded from JSON
var adaptation_config: Dictionary = {}

## Benchmark result (small map generation time in ms)
var benchmark_result_ms: float = 0.0


func _init() -> void:
	"""Initialize hardware profiler and load configuration."""
	_load_adaptation_config()
	_detect_system_info()
	_run_quick_benchmark()
	_determine_quality_level()


func _load_adaptation_config() -> void:
	"""Load hardware adaptation configuration from JSON."""
	const CONFIG_PATH: String = "res://data/config/hardware_adaptation.json"
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		MythosLogger.warn("System/HardwareProfiler", "Failed to load hardware adaptation config, using defaults")
		_use_default_config()
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.warn("System/HardwareProfiler", "Failed to parse hardware adaptation config: %s" % json.get_error_message())
		_use_default_config()
		return
	
	adaptation_config = json.data
	MythosLogger.info("System/HardwareProfiler", "Loaded hardware adaptation configuration")


func _use_default_config() -> void:
	"""Use default configuration if JSON fails to load."""
	adaptation_config = {
		"quality_levels": {
			"low": {
				"max_preview_resolution": 512,
				"max_octaves": 3,
				"erosion_iterations": 2,
				"erosion_enabled_default": false,
				"use_threading_threshold": 256,
				"preview_skip_post_processing": true,
				"max_map_size_preview": 1024
			},
			"medium": {
				"max_preview_resolution": 1024,
				"max_octaves": 4,
				"erosion_iterations": 3,
				"erosion_enabled_default": true,
				"use_threading_threshold": 512,
				"preview_skip_post_processing": false,
				"max_map_size_preview": 2048
			},
			"high": {
				"max_preview_resolution": 2048,
				"max_octaves": 6,
				"erosion_iterations": 5,
				"erosion_enabled_default": true,
				"use_threading_threshold": 1024,
				"preview_skip_post_processing": false,
				"max_map_size_preview": 4096
			}
		},
		"benchmark": {
			"test_map_size": 256,
			"timeout_ms": 5000,
			"low_threshold_ms": 2000,
			"medium_threshold_ms": 1000
		}
	}


func _detect_system_info() -> void:
	"""Detect basic system information."""
	cpu_count = OS.get_processor_count()
	
	# Try to get GPU name (platform-specific)
	if OS.get_name() == "Windows":
		# On Windows, we can't easily get GPU name without external tools
		gpu_name = "Unknown (Windows)"
	elif OS.get_name() == "Linux":
		# Try to read from /proc/driver/nvidia/version or similar
		gpu_name = "Unknown (Linux)"
	elif OS.get_name() == "macOS":
		gpu_name = "Unknown (macOS)"
	else:
		gpu_name = "Unknown"
	
	# Estimate available memory (rough approximation)
	# Godot doesn't provide direct memory info, so we use a heuristic
	available_memory_mb = _estimate_available_memory()
	
	MythosLogger.info("System/HardwareProfiler", "System info detected", {
		"cpu_count": cpu_count,
		"gpu_name": gpu_name,
		"estimated_memory_mb": available_memory_mb
	})


func _estimate_available_memory() -> int:
	"""Estimate available system memory (rough heuristic)."""
	# Use CPU count as a proxy for system capability
	# More cores generally correlate with more RAM
	var base_memory: int = 2048  # Base 2GB assumption
	var per_core_memory: int = 1024  # ~1GB per core (rough estimate)
	return base_memory + (cpu_count * per_core_memory)


func _run_quick_benchmark() -> void:
	"""Run a quick benchmark to determine generation performance."""
	var benchmark_config: Dictionary = adaptation_config.get("benchmark", {})
	var test_size: int = benchmark_config.get("test_map_size", 256)
	var timeout_ms: float = benchmark_config.get("timeout_ms", 5000.0)
	
	MythosLogger.verbose("System/HardwareProfiler", "Running quick benchmark", {"test_size": test_size})
	
	# Create a minimal test map generation
	var start_time: int = Time.get_ticks_msec()
	
	# Generate a small test heightmap using FastNoiseLite
	var test_noise: FastNoiseLite = FastNoiseLite.new()
	test_noise.seed = 12345
	test_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	test_noise.frequency = 0.01
	test_noise.fractal_octaves = 4
	test_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	# Sample noise at multiple points (simulating heightmap generation)
	var sample_count: int = test_size * test_size / 4  # Quarter resolution for speed
	for i in range(sample_count):
		var x: float = float(i % test_size)
		var y: float = float(i / test_size)
		var _noise_val: float = test_noise.get_noise_2d(x, y)
		
		# Check timeout
		var elapsed: float = Time.get_ticks_msec() - start_time
		if elapsed > timeout_ms:
			MythosLogger.warn("System/HardwareProfiler", "Benchmark timed out")
			benchmark_result_ms = timeout_ms
			return
	
	var end_time: int = Time.get_ticks_msec()
	benchmark_result_ms = float(end_time - start_time)
	
	MythosLogger.info("System/HardwareProfiler", "Benchmark complete", {
		"time_ms": benchmark_result_ms,
		"test_size": test_size
	})


func _determine_quality_level() -> void:
	"""Determine quality level based on system info and benchmark."""
	var benchmark_config: Dictionary = adaptation_config.get("benchmark", {})
	var low_threshold: float = benchmark_config.get("low_threshold_ms", 2000.0)
	var medium_threshold: float = benchmark_config.get("medium_threshold_ms", 1000.0)
	
	# Determine quality based on multiple factors
	var quality_score: float = 0.0
	
	# CPU count factor (0-1)
	var cpu_score: float = clampf(float(cpu_count) / 8.0, 0.0, 1.0)
	quality_score += cpu_score * 0.4
	
	# Benchmark time factor (0-1, lower is better)
	var benchmark_score: float = 1.0
	if benchmark_result_ms > 0.0:
		benchmark_score = clampf(medium_threshold / max(benchmark_result_ms, 1.0), 0.0, 1.0)
	quality_score += benchmark_score * 0.6
	
	# Determine quality level
	if quality_score < 0.4:
		detected_quality = QualityLevel.LOW
	elif quality_score < 0.7:
		detected_quality = QualityLevel.MEDIUM
	else:
		detected_quality = QualityLevel.HIGH
	
	var quality_name: String = ["LOW", "MEDIUM", "HIGH"][detected_quality]
	MythosLogger.info("System/HardwareProfiler", "Quality level determined", {
		"quality": quality_name,
		"score": quality_score,
		"cpu_count": cpu_count,
		"benchmark_ms": benchmark_result_ms
	})


func get_quality_preset() -> Dictionary:
	"""Get quality preset configuration for detected quality level."""
	var quality_name: String = ["low", "medium", "high"][detected_quality]
	var quality_levels: Dictionary = adaptation_config.get("quality_levels", {})
	var preset: Dictionary = quality_levels.get(quality_name, {})
	
	if preset.is_empty():
		MythosLogger.warn("System/HardwareProfiler", "Quality preset not found, using medium defaults")
		preset = quality_levels.get("medium", {})
	
	return preset


func get_adapted_generation_params(base_params: Dictionary) -> Dictionary:
	"""Adapt generation parameters based on detected hardware."""
	var preset: Dictionary = get_quality_preset()
	var adapted: Dictionary = base_params.duplicate(true)
	
	# Apply quality-based limits
	if preset.has("max_octaves"):
		adapted["noise_octaves"] = min(adapted.get("noise_octaves", 4), preset.get("max_octaves", 4))
	
	if preset.has("erosion_iterations"):
		adapted["erosion_iterations"] = min(adapted.get("erosion_iterations", 5), preset.get("erosion_iterations", 5))
	
	if preset.has("erosion_enabled_default"):
		adapted["erosion_enabled"] = preset.get("erosion_enabled_default", true) and adapted.get("erosion_enabled", true)
	
	# Limit preview resolution
	if preset.has("max_preview_resolution"):
		var max_preview: int = preset.get("max_preview_resolution", 1024)
		if adapted.has("width"):
			adapted["width"] = min(adapted.get("width", 1024), max_preview)
		if adapted.has("height"):
			adapted["height"] = min(adapted.get("height", 1024), max_preview)
	
	MythosLogger.debug("System/HardwareProfiler", "Adapted generation parameters", {
		"original_octaves": base_params.get("noise_octaves", 4),
		"adapted_octaves": adapted.get("noise_octaves", 4),
		"erosion_enabled": adapted.get("erosion_enabled", true)
	})
	
	return adapted


func should_use_threading(map_size: int) -> bool:
	"""Determine if threading should be used for given map size."""
	var preset: Dictionary = get_quality_preset()
	var threshold: int = preset.get("use_threading_threshold", 512)
	return map_size > threshold


func should_skip_post_processing_for_preview() -> bool:
	"""Determine if post-processing should be skipped for preview generation."""
	var preset: Dictionary = get_quality_preset()
	return preset.get("preview_skip_post_processing", false)


func get_max_map_size_for_preview() -> int:
	"""Get maximum map size for preview generation."""
	var preset: Dictionary = get_quality_preset()
	return preset.get("max_map_size_preview", 2048)
