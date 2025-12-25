# ╔═══════════════════════════════════════════════════════════
# ║ PerfIsolationTest.gd
# ║ Desc: Minimal performance test scene to isolate bottlenecks
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

var _frame_time_log: Array = []
var _frame_count: int = 0

func _ready() -> void:
	"""Initialize minimal test scene."""
	set_process(true)
	print("PERF TEST: Minimal scene loaded - should be 60 FPS")

func _process(_delta: float) -> void:
	"""Measure frame time."""
	_frame_count += 1
	var frame_start: int = Time.get_ticks_usec()
	
	# Wait for frame to complete
	call_deferred("_measure_frame_time", frame_start)

func _measure_frame_time(frame_start: int) -> void:
	"""Measure frame time after rendering."""
	var frame_end: int = Time.get_ticks_usec()
	var elapsed_ms: float = (frame_end - frame_start) / 1000.0
	_frame_time_log.append(elapsed_ms)
	
	if _frame_time_log.size() >= 60:
		var total: float = 0.0
		for time in _frame_time_log:
			total += time
		var avg: float = total / 60.0
		var fps: float = 1000.0 / avg if avg > 0.0 else 0.0
		
		# Capture rendering info
		var draw_calls_2d: int = Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME)
		var draw_calls_total: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var objects_drawn: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		
		print("PERF TEST - AVG FRAME TIME: %.2f ms -> FPS: %.1f | Draw Calls 2D: %d | Total Draw Calls: %d | Objects: %d" % [
			avg, fps, draw_calls_2d, draw_calls_total, objects_drawn
		])
		_frame_time_log.clear()

