# ╔═══════════════════════════════════════════════════════════
# ║ PerformanceMonitor.gd
# ║ Desc: Toggleable performance overlay with Off/Simple/Detailed modes
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name PerformanceMonitor
extends CanvasLayer

enum Mode { OFF, SIMPLE, DETAILED }

@onready var perf_panel: PanelContainer = $PerfPanel
@onready var fps_label: Label = $PerfPanel/Content/FPSLabel
@onready var metrics_container: VBoxContainer = $PerfPanel/Content/MetricsContainer
@onready var graphs_container: HBoxContainer = $PerfPanel/Content/GraphsContainer
@onready var fps_graph: GraphControl = $PerfPanel/Content/GraphsContainer/FPSGraph
@onready var process_graph: GraphControl = $PerfPanel/Content/GraphsContainer/ProcessGraph

var current_mode: Mode = Mode.OFF : set = set_mode

# Detailed metric labels (created in _ready)
var process_label: Label
var physics_label: Label
var memory_label: Label
var object_label: Label
var node_label: Label

# FPS color thresholds (exportable for customization)
@export var fps_good_threshold: float = 55.0
@export var fps_warning_threshold: float = 30.0
@export var fps_good_color: Color = Color(0.2, 1.0, 0.2)
@export var fps_warning_color: Color = Color(1.0, 0.8, 0.2)
@export var fps_bad_color: Color = Color(1.0, 0.2, 0.2)

# Mode names for logging
var mode_names: Array[String] = ["OFF", "SIMPLE", "DETAILED"]

func _ready() -> void:
	"""Initialize performance monitor with labels, graphs, and settings."""
	MythosLogger.debug("PerformanceMonitor", "Overlay ready in singleton mode - available globally")
	MythosLogger.debug("PerformanceMonitor", "_ready() starting initialization")
	
	# Validate all @onready nodes exist
	if not perf_panel:
		MythosLogger.error("PerformanceMonitor", "perf_panel not found!")
		return
	if not fps_label:
		MythosLogger.error("PerformanceMonitor", "fps_label not found!")
		return
	if not metrics_container:
		MythosLogger.error("PerformanceMonitor", "metrics_container not found!")
		return
	if not graphs_container:
		MythosLogger.error("PerformanceMonitor", "graphs_container not found!")
		return
	if not fps_graph:
		MythosLogger.error("PerformanceMonitor", "fps_graph not found!")
		return
	if not process_graph:
		MythosLogger.error("PerformanceMonitor", "process_graph not found!")
		return
	
	MythosLogger.debug("PerformanceMonitor", "All @onready nodes validated successfully")
	
	# Create metric labels
	process_label = _create_metric_label("Process: -- ms")
	physics_label = _create_metric_label("Physics: -- ms")
	memory_label = _create_metric_label("Memory: --")
	object_label = _create_metric_label("Objects: --")
	node_label = _create_metric_label("Nodes: --")
	
	for label in [process_label, physics_label, memory_label, object_label, node_label]:
		metrics_container.add_child(label)
	
	# Apply smaller font
	var small_size: int = UIConstants.PERF_LABEL_FONT_SIZE
	for label in [fps_label, process_label, physics_label, memory_label, object_label, node_label]:
		label.add_theme_font_size_override("font_size", small_size)
	
	# Configure graphs
	fps_graph.max_value = 60.0
	fps_graph.line_color = Color(0.2, 1.0, 0.2)
	
	process_graph.max_value = 16.67  # 60 FPS budget
	process_graph.line_color = Color(1.0, 0.8, 0.2)
	
	# Create and apply custom stylebox for overlay
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(1, 0.843, 0, 0.6)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_right = 6
	stylebox.corner_radius_bottom_left = 6
	perf_panel.add_theme_stylebox_override("panel", stylebox)
	
	# Resize handling
	get_viewport().connect("size_changed", _on_viewport_resized)
	_on_viewport_resized()
	
	# Ensure CanvasLayer is visible and in tree
	visible = true
	MythosLogger.debug("PerformanceMonitor", "CanvasLayer visible: %s, in tree: %s" % [visible, is_inside_tree()])
	
	# Ensure panel has minimum size
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	MythosLogger.debug("PerformanceMonitor", "Viewport size: %s" % viewport_size)
	
	# Load saved mode or default to OFF
	_load_saved_mode()

func _verify_panel_visibility() -> void:
	"""Verify panel visibility state after deferred call."""
	if perf_panel:
		MythosLogger.debug("PerformanceMonitor", "Panel state - visible: %s, size: %s, position: %s" % [perf_panel.visible, perf_panel.size, perf_panel.position])
		MythosLogger.debug("PerformanceMonitor", "Panel global_position: %s, rect: %s" % [perf_panel.global_position, perf_panel.get_rect()])
	else:
		MythosLogger.error("PerformanceMonitor", "perf_panel is null in _verify_panel_visibility!")

func _create_metric_label(text: String) -> Label:
	"""Create a metric label with right alignment."""
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l

func _input(event: InputEvent) -> void:
	"""Handle input for toggling performance monitor."""
	if event is InputEventKey:
		if event.is_action_pressed("toggle_perf_monitor"):
			MythosLogger.debug("PerformanceMonitor", "F3 pressed via action - cycling mode")
			cycle_mode()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	"""Handle unhandled input as fallback for key detection."""
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3:
			MythosLogger.debug("PerformanceMonitor", "F3 detected via _unhandled_input - cycling mode")
			cycle_mode()
			get_viewport().set_input_as_handled()

func cycle_mode() -> void:
	"""Toggles performance monitor mode."""
	var old_mode: int = current_mode
	var new_mode: Mode = (current_mode + 1) % Mode.size()
	MythosLogger.debug("PerformanceMonitor", "Mode cycled: %s -> %s" % [mode_names[old_mode], mode_names[new_mode]])
	set_mode(new_mode)

func set_mode(new_mode: Mode) -> void:
	"""Set the performance monitor mode with logging."""
	current_mode = new_mode
	MythosLogger.debug("PerformanceMonitor", "set_mode() called: %s" % mode_names[current_mode])
	
	match current_mode:
		Mode.OFF:
			MythosLogger.debug("PerformanceMonitor", "Setting OFF mode - hiding panel")
			if perf_panel:
				perf_panel.visible = false
			set_process(false)
		Mode.SIMPLE:
			MythosLogger.debug("PerformanceMonitor", "Setting SIMPLE mode - showing FPS only")
			if perf_panel:
				perf_panel.visible = true
			if metrics_container:
				metrics_container.visible = false
			if graphs_container:
				graphs_container.visible = false
			set_process(true)
		Mode.DETAILED:
			MythosLogger.debug("PerformanceMonitor", "Setting DETAILED mode - showing all metrics and graphs")
			if perf_panel:
				perf_panel.visible = true
				MythosLogger.debug("PerformanceMonitor", "perf_panel.visible = %s" % perf_panel.visible)
			if metrics_container:
				metrics_container.visible = true
				MythosLogger.debug("PerformanceMonitor", "metrics_container.visible = %s" % metrics_container.visible)
			if graphs_container:
				graphs_container.visible = true
				MythosLogger.debug("PerformanceMonitor", "graphs_container.visible = %s" % graphs_container.visible)
			set_process(true)
	
	MythosLogger.debug("PerformanceMonitor", "Mode set complete - perf_panel exists: %s, visible: %s" % [perf_panel != null, perf_panel.visible if perf_panel else "N/A"])
	_save_mode()

func _process(_delta: float) -> void:
	"""Update performance metrics each frame."""
	var fps: float = Engine.get_frames_per_second()
	fps_label.text = "FPS: %.1f" % fps
	
	# Color-code FPS based on thresholds
	if fps >= fps_good_threshold:
		fps_label.modulate = fps_good_color
	elif fps >= fps_warning_threshold:
		fps_label.modulate = fps_warning_color
	else:
		fps_label.modulate = fps_bad_color
	
	if current_mode == Mode.DETAILED:
		_update_detailed_metrics()
		fps_graph.add_value(fps)
		var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		process_graph.add_value(process_ms)

func _update_detailed_metrics() -> void:
	"""Update all detailed metric labels."""
	var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var mem_bytes: int = Performance.get_monitor(Performance.MEMORY_STATIC)
	var obj_count: int = Performance.get_monitor(Performance.OBJECT_COUNT)
	var node_count: int = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	
	process_label.text = "Process: %.2f ms" % process_ms
	physics_label.text = "Physics: %.2f ms" % physics_ms
	memory_label.text = "Memory: %s" % _format_memory(mem_bytes)
	object_label.text = "Objects: %d" % obj_count
	node_label.text = "Nodes: %d" % node_count

func _format_memory(bytes: int) -> String:
	"""Format memory bytes into human-readable string (B/KB/MB/GB)."""
	var b: float = float(bytes)
	if b < 1024.0:
		return "%.0f B" % b
	elif b < 1048576.0:
		return "%.1f KB" % (b / 1024.0)
	elif b < 1073741824.0:
		return "%.1f MB" % (b / 1048576.0)
	else:
		return "%.2f GB" % (b / 1073741824.0)

func _on_viewport_resized() -> void:
	"""Handle viewport resize to update graph sizes."""
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	MythosLogger.debug("PerformanceMonitor", "Viewport resized to: %s" % vp_size)
	
	var graph_width: float = vp_size.x * UIConstants.PERF_GRAPH_WIDTH_RATIO
	if fps_graph:
		fps_graph.custom_minimum_size.x = graph_width
		fps_graph.custom_minimum_size.y = UIConstants.PERF_GRAPH_HEIGHT
	if process_graph:
		process_graph.custom_minimum_size.x = graph_width
		process_graph.custom_minimum_size.y = UIConstants.PERF_GRAPH_HEIGHT
	
	# Ensure panel has minimum width to be visible
	if perf_panel:
		# PanelContainer will size to content, but ensure it's not too narrow
		var min_width: float = max(300.0, vp_size.x * 0.15)  # At least 300px or 15% of viewport
		perf_panel.custom_minimum_size.x = min_width
		MythosLogger.debug("PerformanceMonitor", "Panel min width set to: %s" % min_width)

func _save_mode() -> void:
	"""Save current mode to user settings with error handling."""
	var cfg := ConfigFile.new()
	cfg.set_value("debug", "perf_monitor_mode", current_mode)
	var err: Error = cfg.save("user://settings.cfg")
	if err != OK:
		MythosLogger.warn("PerformanceMonitor", "Failed to save monitor mode: %d" % err)

func _load_saved_mode() -> void:
	"""Load saved mode from user settings with error handling."""
	var cfg := ConfigFile.new()
	var err: Error = cfg.load("user://settings.cfg")
	if err == OK:
		var saved: int = cfg.get_value("debug", "perf_monitor_mode", Mode.OFF)
		if saved >= 0 and saved < Mode.size():
			set_mode(saved)
		else:
			MythosLogger.warn("PerformanceMonitor", "Invalid saved mode: %d, using OFF" % saved)
			set_mode(Mode.OFF)
	else:
		set_mode(Mode.OFF)  # Default on first run or error
