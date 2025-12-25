# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUIPerfTest.gd
# ║ Desc: Performance test helper for WorldBuilderUI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## Test mode: "theme_null", "shadow_off", "webview_remove", "hsplit_replace", "all"
@export var test_mode: String = "none"

var _frame_time_log: Array = []
var _test_frame_count: int = 0

func _ready() -> void:
	"""Apply test modifications based on test_mode."""
	match test_mode:
		"theme_null":
			theme = null
			print("PERF TEST: Theme set to null")
		"shadow_off":
			_remove_label_shadows()
			print("PERF TEST: Label shadows removed")
		"webview_remove":
			_remove_webview()
			print("PERF TEST: WebView removed")
		"hsplit_replace":
			_replace_hsplit()
			print("PERF TEST: HSplitContainer replaced with HBoxContainer")
		"all":
			theme = null
			_remove_webview()
			print("PERF TEST: All optimizations applied")
	
	# Enable frame timing
	set_process(true)

func _remove_label_shadows() -> void:
	"""Remove shadow offsets from all Labels in the scene."""
	var labels: Array[Label] = []
	_collect_labels(self, labels)
	
	for label in labels:
		label.remove_theme_constant_override("shadow_offset_x")
		label.remove_theme_constant_override("shadow_offset_y")
		label.remove_theme_color_override("font_shadow_color")
	
	print("PERF TEST: Removed shadows from %d labels" % labels.size())

func _collect_labels(node: Node, labels: Array) -> void:
	"""Recursively collect all Label nodes."""
	if node is Label:
		labels.append(node)
	
	for child in node.get_children():
		_collect_labels(child, labels)

func _remove_webview() -> void:
	"""Remove or hide the AzgaarWebView node."""
	var webview = get_node_or_null("MainVBox/MainHSplit/CenterPanel/CenterContent/WebViewMargin/AzgaarWebView")
	if webview:
		webview.visible = false
		webview.queue_free()
		print("PERF TEST: WebView removed")
	
	var webview_margin = get_node_or_null("MainVBox/MainHSplit/CenterPanel/CenterContent/WebViewMargin")
	if webview_margin:
		webview_margin.visible = false

func _replace_hsplit() -> void:
	"""Replace HSplitContainer with HBoxContainer."""
	var hsplit = get_node_or_null("MainVBox/MainHSplit")
	if not hsplit or not hsplit is HSplitContainer:
		return
	
	var parent = hsplit.get_parent()
	var children = []
	for child in hsplit.get_children():
		children.append(child)
		hsplit.remove_child(child)
	
	var hbox = HBoxContainer.new()
	hbox.name = "MainHBox"
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	for child in children:
		hbox.add_child(child)
	
	parent.add_child(hbox)
	hsplit.queue_free()
	print("PERF TEST: HSplitContainer replaced with HBoxContainer")

func _process(_delta: float) -> void:
	"""Measure frame time."""
	_test_frame_count += 1
	var frame_start: int = Time.get_ticks_usec()
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
		
		print("PERF TEST [%s] - AVG FRAME TIME: %.2f ms -> FPS: %.1f | Draw Calls 2D: %d | Total: %d | Objects: %d" % [
			test_mode, avg, fps, draw_calls_2d, draw_calls_total, objects_drawn
		])
		_frame_time_log.clear()

