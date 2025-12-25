# ╔═══════════════════════════════════════════════════════════
# ║ PerformanceMonitor.gd
# ║ Desc: Toggleable performance overlay with Off/Simple/Detailed modes
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name PerformanceMonitor
extends CanvasLayer

enum Mode { OFF, SIMPLE, DETAILED, FLAME }

@onready var perf_panel: PanelContainer = $PerfPanel
@onready var fps_label: Label = $PerfPanel/Content/FPSLabel
@onready var metrics_container: VBoxContainer = $PerfPanel/Content/MetricsContainer
@onready var graphs_container: HBoxContainer = $PerfPanel/Content/GraphsContainer
@onready var fps_graph: GraphControl = $PerfPanel/Content/GraphsContainer/FPSGraph
@onready var process_graph: GraphControl = $PerfPanel/Content/GraphsContainer/ProcessGraph
@onready var refresh_graph: GraphControl = $PerfPanel/Content/GraphsContainer/RefreshGraph
@onready var bottom_graph_bar: PanelContainer = $BottomGraphBar
# Old bottom graphs removed - replaced by waterfall_control
@onready var bottom_fps_graph: GraphControl = get_node_or_null("BottomGraphBar/MarginContainer/BottomGraphsContainer/BottomFPSGraph")
@onready var bottom_process_graph: GraphControl = get_node_or_null("BottomGraphBar/MarginContainer/BottomGraphsContainer/BottomProcessGraph")
@onready var bottom_refresh_graph: GraphControl = get_node_or_null("BottomGraphBar/MarginContainer/BottomGraphsContainer/BottomRefreshGraph")
@onready var bottom_thread_graph: GraphControl = get_node_or_null("BottomGraphBar/MarginContainer/BottomGraphsContainer/BottomThreadGraph")
@onready var waterfall_control: Control = $BottomGraphBar/MarginContainer/BottomGraphsContainer/WaterfallControl
@onready var flame_graph_control: Control = $BottomGraphBar/MarginContainer/BottomGraphsContainer/FlameGraphControl

var current_mode: Mode = Mode.OFF : set = set_mode

# Custom timing for MapRenderer.refresh()
var refresh_time_ms: float = 0.0

# Thread compute time tracking
var thread_compute_time_ms: float = 0.0

# System status tracking
var system_status: String = "Idle"

# Frame counter for safe RenderingServer initialization (needs 2+ frames)
var _frame_count: int = 0

# Category system for metric filtering
var current_category: int = 0  # 0=All, 1=Time, 2=Memory, 3=Rendering, 4=Objects
const CATEGORIES: Array[String] = ["All", "Time", "Memory", "Rendering", "Objects"]

# Detailed metric labels (created in _ready)
# Time category
var process_label: Label
var physics_label: Label
var refresh_label: Label
var system_status_label: Label
# Memory category
var memory_label: Label
var vram_label: Label
var texture_mem_label: Label
# Rendering category
var draw_calls_label: Label
var primitives_label: Label
var objects_drawn_label: Label
# Objects category
var object_label: Label
var node_label: Label

# FPS color thresholds (exportable for customization)
@export var fps_good_threshold: float = 55.0
@export var fps_warning_threshold: float = 30.0
@export var fps_good_color: Color = Color(0.2, 1.0, 0.2)
@export var fps_warning_color: Color = Color(1.0, 0.8, 0.2)
@export var fps_bad_color: Color = Color(1.0, 0.2, 0.2)

# Mode names for logging
var mode_names: Array[String] = ["OFF", "SIMPLE", "DETAILED", "FLAME"]

# Flame graph status label
var flame_status_label: Label = null

# DiagnosticDispatcher infrastructure (thread-safe, high-priority diagnostics)
var _diagnostic_queue: Array[Callable] = []
var _metric_ring_buffer: Array[Dictionary] = []  # For thread-pushed metrics {phase: String, time_ms: float, timestamp: int}
var _buffer_mutex: Mutex = Mutex.new()
var _log_timestamps: Array[int] = []
const MAX_LOGS_PER_SECOND: int = 15

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
	if not refresh_graph:
		MythosLogger.error("PerformanceMonitor", "refresh_graph not found!")
		return
	if not bottom_graph_bar:
		MythosLogger.error("PerformanceMonitor", "bottom_graph_bar not found!")
		return
	
	# Old bottom graphs are optional (replaced by waterfall view)
	# No need to check or log - they're intentionally removed
	
	if not waterfall_control:
		MythosLogger.error("PerformanceMonitor", "waterfall_control not found!")
		return
	
	MythosLogger.debug("PerformanceMonitor", "All @onready nodes validated successfully")
	
	# Create metric labels (organized by category)
	# Time category
	process_label = _create_metric_label("Process: -- ms")
	physics_label = _create_metric_label("Physics: -- ms")
	refresh_label = _create_metric_label("Refresh: -- ms")
	system_status_label = _create_metric_label("Status: Idle")
	# Memory category
	memory_label = _create_metric_label("Memory: --")
	vram_label = _create_metric_label("VRAM: --")
	texture_mem_label = _create_metric_label("Texture Mem: --")
	# Rendering category
	draw_calls_label = _create_metric_label("Draw Calls: --")
	primitives_label = _create_metric_label("Primitives: --")
	objects_drawn_label = _create_metric_label("Objects Drawn: --")
	# Objects category
	object_label = _create_metric_label("Objects: --")
	node_label = _create_metric_label("Nodes: --")
	
	# Flame status label
	flame_status_label = _create_metric_label("Flame: OFF")
	flame_status_label.modulate = Color(0.3, 0.7, 1.0)  # Blue tint for flame mode
	flame_status_label.visible = false  # Hidden by default
	
	# Add all labels to container
	var all_labels: Array[Label] = [
		process_label, physics_label, refresh_label, system_status_label,  # Time
		memory_label, vram_label, texture_mem_label,  # Memory
		draw_calls_label, primitives_label, objects_drawn_label,  # Rendering
		object_label, node_label,  # Objects
		flame_status_label  # Flame status
	]
	
	for label in all_labels:
		metrics_container.add_child(label)
	
	# Apply smaller font and attempt monospaced font for alignment
	var small_size: int = UIConstants.PERF_LABEL_FONT_SIZE
	var all_font_labels: Array[Label] = []
	all_font_labels.append(fps_label)
	all_font_labels.append_array(all_labels)
	
	# Try to load monospaced font if available (optional enhancement)
	var mono_font_paths: Array[String] = [
		"res://assets/fonts/roboto_mono.ttf",
		"res://assets/fonts/courier_new.ttf",
		"res://assets/fonts/monospace.ttf"
	]
	var mono_font: Font = null
	for path in mono_font_paths:
		if ResourceLoader.exists(path):
			mono_font = load(path) as Font
			if mono_font:
				MythosLogger.debug("PerformanceMonitor", "Loaded monospaced font: %s" % path)
				break
	
	for label in all_font_labels:
		label.add_theme_font_size_override("font_size", small_size)
		if mono_font:
			label.add_theme_font_override("font", mono_font)
	
	# Configure graphs
	fps_graph.max_value = 60.0
	fps_graph.line_color = Color(0.2, 1.0, 0.2)
	
	process_graph.max_value = 16.67  # 60 FPS budget
	process_graph.line_color = Color(1.0, 0.8, 0.2)
	
	refresh_graph.max_value = 16.67  # 60 FPS budget (same as process)
	refresh_graph.line_color = Color(1.0, 0.3, 0.3)  # Red for refresh bottleneck
	
	# Configure bottom graphs with headroom for spikes (optional - replaced by waterfall)
	if bottom_fps_graph:
		bottom_fps_graph.max_value = 120.0  # Give headroom above 60 FPS
		bottom_fps_graph.line_color = Color(0.2, 1.0, 0.2)
	
	if bottom_process_graph:
		bottom_process_graph.max_value = 33.33  # Headroom for 30 FPS budget
		bottom_process_graph.line_color = Color(1.0, 1.0, 0.2)
	
	if bottom_refresh_graph:
		bottom_refresh_graph.max_value = 33.33  # Headroom for refresh spikes
		bottom_refresh_graph.line_color = Color(1.0, 0.3, 0.3)  # Red for refresh bottleneck
	
	if bottom_thread_graph:
		bottom_thread_graph.max_value = 33.33  # Headroom for thread compute time
		bottom_thread_graph.line_color = Color(0.3, 0.7, 1.0)  # Blue for thread compute time
	
	# Apply theme stylebox for overlay (moved from programmatic creation to theme)
	var theme_stylebox: StyleBox = perf_panel.get_theme_stylebox("perf_overlay", "PanelContainer")
	if theme_stylebox:
		perf_panel.add_theme_stylebox_override("panel", theme_stylebox)
		MythosLogger.debug("PerformanceMonitor", "Applied perf_overlay stylebox from theme")
	else:
		# Fallback: create programmatically if theme stylebox not found
		MythosLogger.warn("PerformanceMonitor", "perf_overlay stylebox not found in theme, using fallback")
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
	
	# Apply initial layout (PerfPanel always top-right)
	_apply_panel_positioning()
	
	# Setup bottom graph bar positioning (will set visibility based on mode)
	_update_bottom_graph_bar()
	
	# Connect to viewport resize
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().connect("size_changed", _on_viewport_resized)
	
	# Ensure CanvasLayer is visible and in tree
	visible = true
	MythosLogger.debug("PerformanceMonitor", "CanvasLayer visible: %s, in tree: %s" % [visible, is_inside_tree()])
	
	# Ensure panel has minimum size
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	MythosLogger.debug("PerformanceMonitor", "Viewport size: %s" % viewport_size)
	
	# Load saved mode or default to OFF
	_load_saved_mode()
	
	# Set process priority to -1000 for high-priority diagnostic processing
	set_process_priority(-1000)

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
	"""Handle input for toggling performance monitor and category filtering."""
	if event is InputEventKey:
		if event.is_action_pressed("toggle_perf_monitor"):
			MythosLogger.debug("PerformanceMonitor", "F3 pressed via action - cycling mode")
			cycle_mode()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("perf_toggle_category"):
			current_category = (current_category + 1) % CATEGORIES.size()
			_apply_category_filter(CATEGORIES[current_category])
			_save_category()
			MythosLogger.debug("PerformanceMonitor", "Category changed to: %s" % CATEGORIES[current_category])
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("perf_export_data"):
			export_snapshot()
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
			if bottom_graph_bar:
				bottom_graph_bar.visible = false
			# Stop flame profiling if it was running
			if FlameGraphProfiler and FlameGraphProfiler.is_profiling_enabled:
				FlameGraphProfiler.stop_profiling()
			_update_flame_status_label(false)
			set_process(false)  # GUI Performance Fix: Disable _process when OFF
		Mode.SIMPLE:
			MythosLogger.debug("PerformanceMonitor", "Setting SIMPLE mode - showing FPS only")
			if perf_panel:
				perf_panel.visible = true
			if metrics_container:
				metrics_container.visible = false
			if graphs_container:
				graphs_container.visible = false
			if bottom_graph_bar:
				bottom_graph_bar.visible = false
			# Stop flame profiling if it was running
			if FlameGraphProfiler and FlameGraphProfiler.is_profiling_enabled:
				FlameGraphProfiler.stop_profiling()
			_update_flame_status_label(false)
			set_process(true and visible)  # GUI Performance Fix: Only enable if visible
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
			if bottom_graph_bar:
				bottom_graph_bar.visible = true
			_update_bottom_graph_bar()  # Show bottom graph bar
			# Show waterfall, hide flame graph
			if waterfall_control:
				waterfall_control.visible = true
			if flame_graph_control:
				flame_graph_control.visible = false
			# Stop flame profiling if it was running
			if FlameGraphProfiler and FlameGraphProfiler.is_profiling_enabled:
				FlameGraphProfiler.stop_profiling()
			_update_flame_status_label(false)
			set_process(true and visible)  # GUI Performance Fix: Only enable if visible
		Mode.FLAME:
			MythosLogger.debug("PerformanceMonitor", "Setting FLAME mode - showing all metrics, graphs, and flame profiling")
			if perf_panel:
				perf_panel.visible = true
			if metrics_container:
				metrics_container.visible = true
			if graphs_container:
				graphs_container.visible = true
			if bottom_graph_bar:
				bottom_graph_bar.visible = true
			_update_bottom_graph_bar()
			# Show flame graph, hide waterfall
			if waterfall_control:
				waterfall_control.visible = false
			if flame_graph_control:
				flame_graph_control.visible = true
			# Start flame profiling
			if FlameGraphProfiler:
				FlameGraphProfiler.start_profiling()
			_update_flame_status_label(true)
			set_process(true and visible)  # GUI Performance Fix: Only enable if visible
	
	MythosLogger.debug("PerformanceMonitor", "Mode set complete - perf_panel exists: %s, visible: %s" % [perf_panel != null, perf_panel.visible if perf_panel else "N/A"])
	_save_mode()

func _process(_delta: float) -> void:
	"""Update performance metrics each frame. DiagnosticDispatcher: drains queue first, then metrics, then existing logic."""
	# GUI Performance Fix: Only process if overlay is visible and mode is not OFF
	if not visible or current_mode == Mode.OFF:
		return
	
	_frame_count += 1
	
	# FIRST: Drain diagnostic queue completely (thread-safe log/UI updates)
	for i in range(_diagnostic_queue.size()):
		var callable: Callable = _diagnostic_queue[i]
		callable.call()
	_diagnostic_queue.clear()
	
	# SECOND: Drain metric ring buffer (thread-safe metric collection)
	_buffer_mutex.lock()
	var metrics_to_process: Array[Dictionary] = _metric_ring_buffer.duplicate()
	_metric_ring_buffer.clear()
	_buffer_mutex.unlock()
	
	# Feed drained metrics into graphs (live updates)
	for metric: Dictionary in metrics_to_process:
		var time_ms: float = metric.get("time_ms", 0.0)
		
		# Update thread graph with metric time (perfectly live)
		if bottom_thread_graph:
			bottom_thread_graph.add_value(time_ms)
	
	# Rest of existing _process logic (FPS, graphs, etc.)
	var fps: float = Engine.get_frames_per_second()
	fps_label.text = "FPS: %.1f" % fps
	
	# Color-code FPS based on thresholds
	if fps >= fps_good_threshold:
		fps_label.modulate = fps_good_color
	elif fps >= fps_warning_threshold:
		fps_label.modulate = fps_warning_color
	else:
		fps_label.modulate = fps_bad_color
	
	if current_mode == Mode.DETAILED or current_mode == Mode.FLAME:
		# RenderingServer data requires at least 2 frames
		if _frame_count >= 3:
			_update_detailed_metrics()
		# Update small graphs in top-right panel
		fps_graph.add_value(fps)
		var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		process_graph.add_value(process_ms)
		refresh_graph.add_value(refresh_time_ms)
		
		# Update waterfall view (only in DETAILED mode, not FLAME)
		if current_mode == Mode.DETAILED and waterfall_control and _frame_count >= 3:
			var frame_id: int = Engine.get_process_frames()
			var frame_time_start: int = Time.get_ticks_usec()
			var frame_delta_ms: float = _delta * 1000.0
			
			var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			var refresh_ms: float = _match_refresh_to_frame(frame_id)
			var thread_ms: float = _match_thread_to_frame(frame_id)
			
			var cpu_total_ms: float = process_ms + physics_ms + refresh_ms + thread_ms
			var other_process_ms: float = max(0.0, process_ms - refresh_ms - thread_ms)
			var idle_ms: float = max(0.0, frame_delta_ms - cpu_total_ms)
			
			var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			
			var primary: Dictionary = {
				"frame_id": frame_id,
				"frame_delta_ms": frame_delta_ms,
				"process_ms": process_ms,
				"physics_ms": physics_ms,
				"refresh_ms": refresh_ms,
				"thread_ms": thread_ms,
				"other_process_ms": other_process_ms,
				"idle_ms": idle_ms,
				"draw_calls": draw_calls,
				"primitives": primitives,
				"timestamp_usec": frame_time_start
			}
			
			var sub_breakdowns: Array[Dictionary] = _sub_breakdowns_for_frame(frame_id)
			# Cast to WaterfallControl to access add_frame_metrics method
			if waterfall_control.has_method("add_frame_metrics"):
				waterfall_control.add_frame_metrics(primary, sub_breakdowns)
		
		# Update refresh label with color coding
		if refresh_label:
			refresh_label.text = "Refresh: %.2f ms" % refresh_time_ms
			if refresh_time_ms > UIConstants.PERF_REFRESH_THRESHOLD:
				refresh_label.modulate = fps_bad_color  # Red if >10ms
			else:
				refresh_label.modulate = Color.WHITE  # Normal color if <=10ms
		
		# Update system status and thread metrics
		_update_thread_metrics()

func _update_detailed_metrics() -> void:
	"""Update all detailed metric labels."""
	# Time category metrics
	var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	if process_label:
		process_label.text = "Process: %.2f ms" % process_ms
	if physics_label:
		physics_label.text = "Physics: %.2f ms" % physics_ms
	
	# Memory category metrics
	var mem_bytes: int = Performance.get_monitor(Performance.MEMORY_STATIC)
	if memory_label:
		memory_label.text = "Memory: %s" % _format_memory(mem_bytes)
	
	# RenderingServer metrics (requires 2+ frames, checked in _process)
	var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var objects_drawn: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var vram_bytes: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)
	var texture_bytes: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
	
	if draw_calls_label:
		draw_calls_label.text = "Draw Calls: %d" % draw_calls
	if primitives_label:
		primitives_label.text = "Primitives: %d" % primitives
	if objects_drawn_label:
		objects_drawn_label.text = "Objects Drawn: %d" % objects_drawn
	if vram_label:
		vram_label.text = "VRAM: %s" % _format_memory(vram_bytes)
	if texture_mem_label:
		texture_mem_label.text = "Texture Mem: %s" % _format_memory(texture_bytes)
	
	# Objects category metrics
	var obj_count: int = Performance.get_monitor(Performance.OBJECT_COUNT)
	var node_count: int = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	if object_label:
		object_label.text = "Objects: %d" % obj_count
	if node_label:
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

func _apply_panel_positioning() -> void:
	"""Apply panel positioning - always top-right (unchanged from original)."""
	if not perf_panel:
		return
	
	var margin: int = UIConstants.SPACING_MEDIUM
	
	# Always use top-right positioning
	perf_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	perf_panel.anchor_left = 1.0
	perf_panel.anchor_top = 0.0
	perf_panel.anchor_right = 1.0
	perf_panel.anchor_bottom = 0.0
	perf_panel.offset_left = -UIConstants.OVERLAY_MIN_WIDTH - margin
	perf_panel.offset_top = UIConstants.SPACING_SMALL
	perf_panel.offset_right = -UIConstants.SPACING_SMALL
	perf_panel.offset_bottom = UIConstants.SPACING_SMALL
	perf_panel.custom_minimum_size = Vector2(UIConstants.OVERLAY_MIN_WIDTH, 0)
	
	MythosLogger.debug("PerformanceMonitor", "PerfPanel positioned at top-right")

func _update_bottom_graph_bar() -> void:
	"""Update bottom graph bar positioning and visibility."""
	if not bottom_graph_bar:
		return
	
	var margin: int = UIConstants.SPACING_MEDIUM
	
	# Position at bottom with full width
	bottom_graph_bar.anchor_left = 0.0
	bottom_graph_bar.anchor_top = 1.0
	bottom_graph_bar.anchor_right = 1.0
	bottom_graph_bar.anchor_bottom = 1.0
	bottom_graph_bar.offset_left = margin
	bottom_graph_bar.offset_top = -UIConstants.BOTTOM_GRAPH_BAR_HEIGHT - UIConstants.BOTTOM_GRAPH_BAR_MARGIN
	bottom_graph_bar.offset_right = -margin
	bottom_graph_bar.offset_bottom = -UIConstants.BOTTOM_GRAPH_BAR_MARGIN
	bottom_graph_bar.custom_minimum_size = Vector2(0, UIConstants.BOTTOM_GRAPH_BAR_HEIGHT)
	
	# Update waterfall control height
	if waterfall_control:
		waterfall_control.custom_minimum_size = Vector2(0, UIConstants.BOTTOM_GRAPH_BAR_HEIGHT)
	
	# Set visibility based on mode
	bottom_graph_bar.visible = (current_mode == Mode.DETAILED or current_mode == Mode.FLAME)
	
	MythosLogger.debug("PerformanceMonitor", "Bottom graph bar updated (visible: %s, height: %d)" % [bottom_graph_bar.visible, UIConstants.BOTTOM_GRAPH_BAR_HEIGHT])

func _on_viewport_resized() -> void:
	"""Handle viewport resize to update panel layout and graph sizes."""
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	MythosLogger.debug("PerformanceMonitor", "Viewport resized to: %s" % vp_size)
	
	# Reapply PerfPanel positioning (always top-right)
	_apply_panel_positioning()
	
	# Update bottom graph bar positioning
	_update_bottom_graph_bar()
	
	# Update graph sizes for top-right panel
	var graph_width: float = vp_size.x * UIConstants.PERF_GRAPH_WIDTH_RATIO
	if fps_graph:
		fps_graph.custom_minimum_size.x = graph_width
		fps_graph.custom_minimum_size.y = UIConstants.PERF_GRAPH_HEIGHT
	if process_graph:
		process_graph.custom_minimum_size.x = graph_width
		process_graph.custom_minimum_size.y = UIConstants.PERF_GRAPH_HEIGHT
	if refresh_graph:
		refresh_graph.custom_minimum_size.x = graph_width
		refresh_graph.custom_minimum_size.y = UIConstants.PERF_GRAPH_HEIGHT

func _save_mode() -> void:
	"""Save current mode to user settings with error handling."""
	var cfg := ConfigFile.new()
	var err: Error = cfg.load("user://settings.cfg")
	if err != OK:
		cfg = ConfigFile.new()  # Create new if load failed
	cfg.set_value("debug", "perf_monitor_mode", current_mode)
	err = cfg.save("user://settings.cfg")
	if err != OK:
		MythosLogger.warn("PerformanceMonitor", "Failed to save monitor mode: %d" % err)

func _save_category() -> void:
	"""Save current category to user settings with error handling."""
	var cfg := ConfigFile.new()
	var err: Error = cfg.load("user://settings.cfg")
	if err != OK:
		cfg = ConfigFile.new()  # Create new if load failed
	cfg.set_value("debug", "perf_monitor_category", current_category)
	err = cfg.save("user://settings.cfg")
	if err != OK:
		MythosLogger.warn("PerformanceMonitor", "Failed to save monitor category: %d" % err)

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
		
		# Load saved category if available
		var saved_category: int = cfg.get_value("debug", "perf_monitor_category", 0)
		if saved_category >= 0 and saved_category < CATEGORIES.size():
			current_category = saved_category
			_apply_category_filter(CATEGORIES[current_category])
	else:
		set_mode(Mode.OFF)  # Default on first run or error

func _apply_category_filter(category: String) -> void:
	"""Show/hide metrics based on selected category."""
	# Time category
	var time_labels: Array[Label] = [process_label, physics_label, refresh_label, system_status_label]
	# Memory category
	var memory_labels: Array[Label] = [memory_label, vram_label, texture_mem_label]
	# Rendering category
	var rendering_labels: Array[Label] = [draw_calls_label, primitives_label, objects_drawn_label]
	# Objects category
	var objects_labels: Array[Label] = [object_label, node_label]
	
	match category:
		"All":
			for label in time_labels + memory_labels + rendering_labels + objects_labels:
				if label:
					label.visible = true
		"Time":
			for label in time_labels:
				if label:
					label.visible = true
			for label in memory_labels + rendering_labels + objects_labels:
				if label:
					label.visible = false
		"Memory":
			for label in memory_labels:
				if label:
					label.visible = true
			for label in time_labels + rendering_labels + objects_labels:
				if label:
					label.visible = false
		"Rendering":
			for label in rendering_labels:
				if label:
					label.visible = true
			for label in time_labels + memory_labels + objects_labels:
				if label:
					label.visible = false
		"Objects":
			for label in objects_labels:
				if label:
					label.visible = true
			for label in time_labels + memory_labels + rendering_labels:
				if label:
					label.visible = false

func export_snapshot() -> void:
	"""Export current performance metrics to CSV file."""
	# Ensure export directory exists
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("perf_exports"):
		dir.make_dir("perf_exports")
	
	var timestamp: int = Time.get_unix_time_from_system()
	var file_path: String = "user://perf_exports/snapshot_%d.csv" % timestamp
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		MythosLogger.error("PerformanceMonitor", "Failed to open file for export: %s" % file_path)
		return
	
	# Collect current metrics
	var data: Dictionary = {
		"timestamp": timestamp,
		"fps": Engine.get_frames_per_second(),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	}
	
	# Add RenderingServer metrics if available
	if _frame_count >= 3:
		data["draw_calls"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		data["primitives"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		data["objects_drawn"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		data["vram_bytes"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)
		data["texture_mem_bytes"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
	else:
		data["draw_calls"] = 0
		data["primitives"] = 0
		data["objects_drawn"] = 0
		data["vram_bytes"] = 0
		data["texture_mem_bytes"] = 0
	
	# Write CSV header
	var keys: PackedStringArray = PackedStringArray(data.keys())
	file.store_csv_line(keys)
	
	# Write CSV values
	var values: PackedStringArray = PackedStringArray()
	for key in keys:
		values.append(str(data[key]))
	file.store_csv_line(values)
	
	file.close()
	MythosLogger.info("PerformanceMonitor", "Snapshot exported to: %s" % file_path)


func set_refresh_time(time_ms: float) -> void:
	"""Set refresh time for MapRenderer timing (called via PerformanceMonitorSingleton)."""
	refresh_time_ms = time_ms


func _update_thread_metrics() -> void:
	"""Update thread metrics from WorldGenerator if available."""
	# Try to find WorldGenerator in scene tree (using method check to avoid type issues)
	var world_gen = _find_world_generator()
	if world_gen and world_gen.has_method("is_generating"):
		# Check if generating
		if world_gen.is_generating():
			system_status = "World Gen Active"
			# Get thread metrics
			var metrics: Array[Dictionary] = world_gen.get_thread_metrics()
			if metrics.size() > 0:
				# Sum up recent compute time (last metric's time)
				thread_compute_time_ms = 0.0
				for metric: Dictionary in metrics:
					thread_compute_time_ms += metric.get("time_ms", 0.0)
				# Average over metrics count
				if metrics.size() > 0:
					thread_compute_time_ms /= metrics.size()
		else:
			system_status = "Idle"
			thread_compute_time_ms = 0.0
	else:
		system_status = "Idle"
		thread_compute_time_ms = 0.0
	
	# Update status label
	if system_status_label:
		system_status_label.text = "Status: %s" % system_status
		if system_status == "World Gen Active":
			system_status_label.modulate = Color(0.3, 0.7, 1.0)  # Blue tint when active
		else:
			system_status_label.modulate = Color.WHITE


func _find_world_generator():
	"""Find WorldGenerator instance in scene tree."""
	# Search from root using method check (avoids type resolution issues)
	var root: Node = get_tree().root
	return _find_world_generator_recursive(root)


func _find_world_generator_recursive(node: Node):
	"""Recursively search for WorldGenerator node by checking for is_generating method."""
	if node.has_method("is_generating") and node.has_method("get_thread_metrics"):
		return node
	
	for child: Node in node.get_children():
		var result = _find_world_generator_recursive(child)
		if result:
			return result
	
	return null


## Waterfall View Frame Matching Methods

func _match_refresh_to_frame(frame_id: int) -> float:
	"""Match refresh breakdown to frame_id from PerformanceMonitorSingleton buffer."""
	var metric: Dictionary = PerformanceMonitorSingleton.consume_refresh_for_frame(frame_id)
	if metric.is_empty():
		return refresh_time_ms  # Fallback to current refresh_time_ms
	
	var breakdown: Dictionary = metric.get("breakdown", {})
	return breakdown.get("total_ms", refresh_time_ms)

func _match_thread_to_frame(frame_id: int) -> float:
	"""Match thread breakdown to frame_id from PerformanceMonitorSingleton buffer."""
	var metric: Dictionary = PerformanceMonitorSingleton.consume_thread_for_frame(frame_id)
	if metric.is_empty():
		return thread_compute_time_ms  # Fallback to current thread_compute_time_ms
	
	var breakdown: Dictionary = metric.get("breakdown", {})
	return breakdown.get("total_ms", thread_compute_time_ms)

func _sub_breakdowns_for_frame(frame_id: int) -> Array[Dictionary]:
	"""Get sub-breakdowns for a frame (refresh and thread sub-metrics)."""
	var sub_breakdowns: Array[Dictionary] = []
	
	# Get refresh sub-metrics
	var refresh_metric: Dictionary = PerformanceMonitorSingleton.consume_refresh_for_frame(frame_id)
	if not refresh_metric.is_empty():
		var breakdown: Dictionary = refresh_metric.get("breakdown", {})
		if breakdown.has("culling_ms") or breakdown.has("mesh_gen_ms") or breakdown.has("texture_update_ms"):
			sub_breakdowns.append({
				"category": "refresh",
				"breakdown": breakdown
			})
	
	# Get thread sub-metrics
	var thread_metric: Dictionary = PerformanceMonitorSingleton.consume_thread_for_frame(frame_id)
	if not thread_metric.is_empty():
		var breakdown: Dictionary = thread_metric.get("breakdown", {})
		# Check for per-thread metrics (e.g., thread_0, thread_1)
		var has_thread_sub: bool = false
		for key: String in breakdown.keys():
			if key.begins_with("thread_"):
				has_thread_sub = true
				break
		if has_thread_sub:
			sub_breakdowns.append({
				"category": "thread",
				"breakdown": breakdown
			})
	
	return sub_breakdowns


## DiagnosticDispatcher public API

func queue_diagnostic(callable: Callable) -> void:
	"""Queue a diagnostic callable for execution on main thread. Thread-safe."""
	# Check if we're on main thread by trying to access Engine (main thread only)
	# If we can access Engine safely, execute immediately; otherwise queue
	var is_main: bool = false
	if is_inside_tree():
		# We have scene tree access, so we're on main thread
		is_main = true
	else:
		# Try to access Engine (safe on main thread)
		var main_loop = Engine.get_main_loop()
		is_main = (main_loop != null)
	
	if is_main:
		callable.call()
	else:
		_diagnostic_queue.append(callable)


func push_metric_from_thread(metric: Dictionary) -> void:
	"""Push a metric from a thread into the ring buffer. Thread-safe."""
	_buffer_mutex.lock()
	_metric_ring_buffer.append(metric)
	# Keep ring buffer size reasonable (last 1000 entries)
	if _metric_ring_buffer.size() > 1000:
		_metric_ring_buffer.pop_front()
	_buffer_mutex.unlock()


func can_log() -> bool:
	"""Check if logging is allowed based on rate limiting (MAX_LOGS_PER_SECOND). Public API for Logger."""
	var now: int = Time.get_ticks_msec()
	
	# Remove timestamps older than 1 second
	var one_second_ago: int = now - 1000
	var i: int = 0
	while i < _log_timestamps.size():
		if _log_timestamps[i] < one_second_ago:
			_log_timestamps.remove_at(i)
		else:
			i += 1
	
	# Check if we're under the limit
	if _log_timestamps.size() < MAX_LOGS_PER_SECOND:
		_log_timestamps.append(now)
		return true
	
	return false


func _update_flame_status_label(is_flame_mode: bool) -> void:
	"""Update flame status label visibility and text."""
	if not flame_status_label:
		return
	
	if is_flame_mode:
		flame_status_label.text = "Flame: ON"
		flame_status_label.visible = true
	else:
		flame_status_label.text = "Flame: OFF"
		flame_status_label.visible = false


