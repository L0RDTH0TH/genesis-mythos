# ╔═══════════════════════════════════════════════════════════
# ║ WaterfallControl.gd
# ║ Desc: Custom Control for rendering timeline waterfall performance view
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WaterfallControl
extends Control

# Parallel PackedArrays for primaries (memory-efficient, ~1.2KB for 120 frames)
var history_frame_time: PackedFloat32Array = PackedFloat32Array()
var history_process: PackedFloat32Array = PackedFloat32Array()
var history_physics: PackedFloat32Array = PackedFloat32Array()
var history_refresh: PackedFloat32Array = PackedFloat32Array()
var history_thread: PackedFloat32Array = PackedFloat32Array()
var history_other_process: PackedFloat32Array = PackedFloat32Array()
var history_idle: PackedFloat32Array = PackedFloat32Array()
var history_draw_calls: PackedInt32Array = PackedInt32Array()
var history_primitives: PackedInt32Array = PackedInt32Array()

# Sparse sub-metrics (only when available, Array[Dictionary] indexed by history_index)
var history_sub: Array[Dictionary] = []

# Frame metadata for sync
var history_frame_ids: PackedInt32Array = PackedInt32Array()
var history_timestamps_usec: PackedInt64Array = PackedInt64Array()

const HISTORY_SIZE: int = UIConstants.PERF_HISTORY_SIZE
const VISIBLE_FRAMES: int = 60  # Last 60 frames for wider bars
const LANE_COUNT: int = 8

var history_index: int = 0
var history_full: bool = false
var _max_primitives_seen: float = 1.0
var _last_rendered_index: int = -1

## GUI Performance Fix: Dirty flag for redraw optimization
var _needs_redraw: bool = true

# Tooltip
@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipLabel
var _tooltip_frame_idx: int = -1
var _tooltip_pos: Vector2
var _tooltip_visible: bool = false

# Lane colors (base colors, intensity applied in rendering)
var _lane_colors: Array[Color] = [
	Color(0.5, 0.5, 0.5),  # Frame Time - Gray
	Color(1.0, 0.8, 0.2),  # Main Process - Yellow/Orange
	Color(0.2, 0.8, 1.0),  # Physics Process - Cyan
	Color(1.0, 0.3, 0.3),  # Map Refresh - Red
	Color(0.3, 0.5, 1.0),  # Thread Compute - Blue
	Color(0.2, 1.0, 0.2),  # Other Process - Green
	Color(0.7, 0.7, 0.7),  # Idle/GPU Wait - Light Gray
	Color(0.8, 0.2, 0.8),  # Draw Calls - Purple
]

func _ready() -> void:
	"""Initialize waterfall control with history arrays and tooltip."""
	# Resize all arrays to HISTORY_SIZE
	history_frame_time.resize(HISTORY_SIZE)
	history_process.resize(HISTORY_SIZE)
	history_physics.resize(HISTORY_SIZE)
	history_refresh.resize(HISTORY_SIZE)
	history_thread.resize(HISTORY_SIZE)
	history_other_process.resize(HISTORY_SIZE)
	history_idle.resize(HISTORY_SIZE)
	history_draw_calls.resize(HISTORY_SIZE)
	history_primitives.resize(HISTORY_SIZE)
	history_frame_ids.resize(HISTORY_SIZE)
	history_timestamps_usec.resize(HISTORY_SIZE)
	history_sub.resize(HISTORY_SIZE)
	
	# Initialize tooltip panel if not in scene (should be in scene, but handle gracefully)
	if not tooltip_panel:
		var existing_panel: Node = get_node_or_null("TooltipPanel")
		if existing_panel and existing_panel is Panel:
			tooltip_panel = existing_panel as Panel
			var existing_label: Node = tooltip_panel.get_node_or_null("TooltipLabel")
			if existing_label and existing_label is Label:
				tooltip_label = existing_label as Label
		else:
			tooltip_panel = Panel.new()
			tooltip_panel.name = "TooltipPanel"
			tooltip_panel.visible = false
			tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(tooltip_panel)
			
			tooltip_label = Label.new()
			tooltip_label.name = "TooltipLabel"
			tooltip_panel.add_child(tooltip_label)
	elif not tooltip_label:
		tooltip_label = tooltip_panel.get_node_or_null("TooltipLabel") as Label
		if not tooltip_label:
			tooltip_label = Label.new()
			tooltip_label.name = "TooltipLabel"
			tooltip_panel.add_child(tooltip_label)
	
	# Apply theme
	theme = preload("res://themes/bg3_theme.tres")
	
	# Set anchors and size flags
	anchors_preset = Control.PRESET_FULL_RECT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Enable mouse input for hover/click
	mouse_filter = Control.MOUSE_FILTER_PASS

func _get_write_index() -> int:
	"""Get the current write index for circular buffer."""
	return history_index

func _organize_sub_metrics(sub_metrics: Array[Dictionary]) -> Dictionary:
	"""Organize sub-metrics into a structured dictionary."""
	var organized: Dictionary = {}
	for metric: Dictionary in sub_metrics:
		var category: String = metric.get("category", "unknown")
		if not organized.has(category):
			organized[category] = {}
		var breakdown: Dictionary = metric.get("breakdown", {})
		for key: String in breakdown.keys():
			organized[category][key] = breakdown[key]
	return organized

func add_frame_metrics(primary: Dictionary, sub_metrics: Array[Dictionary] = []) -> void:
	"""Add frame metrics to history with conditional redraw."""
	var write_idx: int = _get_write_index()
	
	# Primaries to packed arrays
	history_frame_time[write_idx] = primary.get("frame_delta_ms", 0.0)
	history_process[write_idx] = primary.get("process_ms", 0.0)
	history_physics[write_idx] = primary.get("physics_ms", 0.0)
	history_refresh[write_idx] = primary.get("refresh_ms", 0.0)
	history_thread[write_idx] = primary.get("thread_ms", 0.0)
	history_other_process[write_idx] = primary.get("other_process_ms", 0.0)
	history_idle[write_idx] = primary.get("idle_ms", 0.0)
	history_draw_calls[write_idx] = primary.get("draw_calls", 0)
	history_primitives[write_idx] = primary.get("primitives", 0)
	_max_primitives_seen = max(_max_primitives_seen, float(primary.get("primitives", 0)))
	
	# Sparse sub only if present
	if sub_metrics.size() > 0:
		history_sub[write_idx] = _organize_sub_metrics(sub_metrics)
	else:
		history_sub[write_idx] = {}
	
	# Metadata
	history_frame_ids[write_idx] = primary.get("frame_id", -1)
	history_timestamps_usec[write_idx] = primary.get("timestamp_usec", 0)
	
	# Conditional redraw
	if history_index != _last_rendered_index:
		_last_rendered_index = history_index
		_needs_redraw = true  # GUI Performance Fix: Mark as needing redraw
		queue_redraw()
	
	# Circular advance
	history_index = (history_index + 1) % HISTORY_SIZE
	if not history_full and history_index == 0:
		history_full = true

func _get_lane_value(lane_idx: int, frame_idx: int) -> float:
	"""Get the value for a specific lane and frame."""
	match lane_idx:
		0: return history_frame_time[frame_idx]
		1: return history_process[frame_idx]
		2: return history_physics[frame_idx]
		3: return history_refresh[frame_idx]
		4: return history_thread[frame_idx]
		5: return history_other_process[frame_idx]
		6: return history_idle[frame_idx]
		7: return float(history_draw_calls[frame_idx])
		_: return 0.0

func _get_lane_rect(lane_idx: int) -> Rect2:
	"""Get the rectangle for a specific lane."""
	var lane_height: float = UIConstants.WATERFALL_LANE_HEIGHT
	var label_width: float = UIConstants.LABEL_WIDTH_NARROW
	var y: float = float(lane_idx) * lane_height
	return Rect2(Vector2(label_width, y), Vector2(size.x - label_width, lane_height))

func _get_bar_rect(lane_idx: int, frame_idx: int, value: float) -> Rect2:
	"""Get the rectangle for a bar in a lane."""
	var lane_rect: Rect2 = _get_lane_rect(lane_idx)
	var frame_width: float = max((size.x - UIConstants.LABEL_WIDTH_NARROW) / float(VISIBLE_FRAMES), float(UIConstants.WATERFALL_FRAME_WIDTH_MIN))
	var x: float = lane_rect.position.x + float(frame_idx) * frame_width
	
	# Scale value based on lane type
	var scaled_height: float = 0.0
	if lane_idx < 7:  # Time lanes (0-6)
		var scale: float = lane_rect.size.y / UIConstants.WATERFALL_TARGET_FRAME_MS
		scaled_height = min(value * scale, lane_rect.size.y)
	elif lane_idx == 7:  # Draw calls lane
		var scale: float = lane_rect.size.y / float(UIConstants.WATERFALL_DRAW_CALLS_MAX)
		scaled_height = min(value * scale, lane_rect.size.y)
	
	var y: float = lane_rect.position.y + lane_rect.size.y - scaled_height
	return Rect2(Vector2(x, y), Vector2(frame_width, scaled_height))

func _get_lane_color(lane_idx: int, value: float = 0.0) -> Color:
	"""Get the color for a lane with intensity applied."""
	var base_color: Color = _lane_colors[lane_idx]
	
	# Apply intensity gradient for time lanes (0-6)
	if lane_idx < 7:
		var intensity: float = clamp(value / UIConstants.WATERFALL_TARGET_FRAME_MS, 0.0, 1.0)
		# Green → Yellow → Red gradient
		var r: float = intensity
		var g: float = 1.0 - intensity
		var b: float = 0.0
		return Color(r, g, b, 0.8)
	
	return Color(base_color.r, base_color.g, base_color.b, 0.8)

func _get_primitives_normalized(frame_idx: int) -> float:
	"""Get normalized primitives value (0.0 to 1.0)."""
	if _max_primitives_seen <= 0.0:
		return 0.0
	return clamp(float(history_primitives[frame_idx]) / _max_primitives_seen, 0.0, 1.0)

func _get_frame_idx_from_pos(pos: Vector2) -> int:
	"""Get frame index from mouse position."""
	var label_width: float = UIConstants.LABEL_WIDTH_NARROW
	var frame_width: float = max((size.x - label_width) / float(VISIBLE_FRAMES), float(UIConstants.WATERFALL_FRAME_WIDTH_MIN))
	var x_offset: float = pos.x - label_width
	if x_offset < 0.0:
		return -1
	var frame_idx: int = int(x_offset / frame_width)
	return clamp(frame_idx, 0, VISIBLE_FRAMES - 1)

func _get_frame_data(frame_idx: int) -> Dictionary:
	"""Get all data for a specific frame."""
	if frame_idx < 0 or frame_idx >= VISIBLE_FRAMES:
		return {}
	
	var history_frame_idx: int = (history_index - 1 - frame_idx + HISTORY_SIZE) % HISTORY_SIZE
	if not history_full and history_frame_idx >= history_index:
		return {}
	
	return {
		"frame_id": history_frame_ids[history_frame_idx],
		"frame_time": history_frame_time[history_frame_idx],
		"process": history_process[history_frame_idx],
		"physics": history_physics[history_frame_idx],
		"refresh": history_refresh[history_frame_idx],
		"thread": history_thread[history_frame_idx],
		"other_process": history_other_process[history_frame_idx],
		"idle": history_idle[history_frame_idx],
		"draw_calls": history_draw_calls[history_frame_idx],
		"primitives": history_primitives[history_frame_idx],
		"timestamp": history_timestamps_usec[history_frame_idx],
		"sub_metrics": history_sub[history_frame_idx] if history_frame_idx < history_sub.size() else {}
	}

func _format_tooltip(data: Dictionary) -> String:
	"""Format tooltip text from frame data."""
	if data.is_empty():
		return ""
	
	var text: String = "Frame #%d\n" % data.get("frame_id", -1)
	text += "Frame Time: %.2f ms\n" % data.get("frame_time", 0.0)
	text += "Process: %.2f ms\n" % data.get("process", 0.0)
	text += "Physics: %.2f ms\n" % data.get("physics", 0.0)
	text += "Refresh: %.2f ms\n" % data.get("refresh", 0.0)
	text += "Thread: %.2f ms\n" % data.get("thread", 0.0)
	text += "Other: %.2f ms\n" % data.get("other_process", 0.0)
	text += "Idle: %.2f ms\n" % data.get("idle", 0.0)
	text += "Draw Calls: %d\n" % data.get("draw_calls", 0)
	text += "Primitives: %d" % data.get("primitives", 0)
	
	return text

func _clamp_tooltip_pos(pos: Vector2) -> Vector2:
	"""Clamp tooltip position to viewport bounds."""
	if not tooltip_panel:
		return pos
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var tooltip_size: Vector2 = tooltip_panel.size if tooltip_panel.size.x > 0 else Vector2(200, 150)
	
	var clamped_x: float = clamp(pos.x, 0.0, viewport_size.x - tooltip_size.x)
	var clamped_y: float = clamp(pos.y - tooltip_size.y, 0.0, viewport_size.y - tooltip_size.y)
	
	return Vector2(clamped_x, clamped_y)

func _update_tooltip() -> void:
	"""Update tooltip text and position."""
	if not _tooltip_visible or not tooltip_panel or not tooltip_label:
		return
	
	var data: Dictionary = _get_frame_data(_tooltip_frame_idx)
	if data.is_empty():
		tooltip_panel.visible = false
		return
	
	tooltip_label.text = _format_tooltip(data)
	tooltip_panel.position = _clamp_tooltip_pos(_tooltip_pos)
	tooltip_panel.size = Vector2(200, 150)  # Set size if not set
	tooltip_panel.visible = true

func _gui_input(event: InputEvent) -> void:
	"""Handle mouse input for hover and click."""
	if event is InputEventMouseMotion:
		var frame_idx: int = _get_frame_idx_from_pos(event.position)
		if frame_idx != _tooltip_frame_idx and frame_idx >= 0:
			_tooltip_frame_idx = frame_idx
			_tooltip_pos = event.position
			_tooltip_visible = true
			_update_tooltip()
			_needs_redraw = true  # GUI Performance Fix: Mark as needing redraw
			queue_redraw()  # Redraw to show hover highlight
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var frame_idx: int = _get_frame_idx_from_pos(event.position)
			if frame_idx >= 0:
				# Pin tooltip to bottom-right
				var viewport_size: Vector2 = get_viewport().get_visible_rect().size
				_tooltip_pos = Vector2(viewport_size.x - 220, viewport_size.y - 160)
				_update_tooltip()

func _notification(what: int) -> void:
	"""Handle resize notifications."""
	if what == NOTIFICATION_RESIZED:
		# Recompute tooltip position if visible
		if _tooltip_visible:
			_update_tooltip()
		_needs_redraw = true  # GUI Performance Fix: Mark as needing redraw
		queue_redraw()

func _draw() -> void:
	"""Draw the waterfall view with all lanes and bars."""
	# GUI Performance Fix: Only draw if visible and needs redraw
	if not visible:
		return
	if not _needs_redraw:
		return
	
	# Background (theme-based parchment)
	var bg_color: Color = Color(0.1, 0.08, 0.06, 0.9)  # Parchment-like
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	
	# Draw grid
	_draw_grid()
	
	# Draw lanes and bars
	for lane_idx in range(LANE_COUNT):
		var lane_rect: Rect2 = _get_lane_rect(lane_idx)
		
		# Draw lane background (subtle parchment gradient)
		var lane_bg: Color = Color(0.12, 0.10, 0.08, 0.5)
		draw_rect(lane_rect, lane_bg)
		
		# Draw lane separator (rune-like line)
		if lane_idx > 0:
			var separator_y: float = lane_rect.position.y
			draw_line(Vector2(0, separator_y), Vector2(size.x, separator_y), Color(1.0, 0.843, 0.0, 0.3), 1.0)
		
		# Draw lane label
		var label_text: String = _get_lane_name(lane_idx)
		var label_pos: Vector2 = Vector2(2, lane_rect.position.y + lane_rect.size.y / 2 - 8)
		draw_string(ThemeDB.fallback_font, label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.843, 0.0))
		
		# Draw bars for visible frames
		for i in range(VISIBLE_FRAMES):
			var history_frame_idx: int = (history_index - 1 - i + HISTORY_SIZE) % HISTORY_SIZE
			if not history_full and history_frame_idx >= history_index:
				continue
			
			var value: float = _get_lane_value(lane_idx, history_frame_idx)
			if value <= 0.0:
				continue
			
			var bar_rect: Rect2 = _get_bar_rect(lane_idx, i, value)
			if bar_rect.size.x > 0 and bar_rect.size.y > 0:
				var bar_color: Color = _get_lane_color(lane_idx, value)
				draw_rect(bar_rect, bar_color)
			
			# Draw primitives overlay line for lane 7
			if lane_idx == 7:
				var primitives_norm: float = _get_primitives_normalized(history_frame_idx)
				var line_y: float = lane_rect.position.y + (1.0 - primitives_norm) * lane_rect.size.y
				var line_x_start: float = lane_rect.position.x + float(i) * bar_rect.size.x
				var line_x_end: float = line_x_start + bar_rect.size.x
				draw_line(Vector2(line_x_start, line_y), Vector2(line_x_end, line_y), Color(1.0, 0.0, 1.0), 2.0)
		
		# Draw hover highlight if tooltip is visible
		if _tooltip_visible and _tooltip_frame_idx >= 0:
			var hover_frame_idx: int = _tooltip_frame_idx
			var frame_width: float = max((size.x - UIConstants.LABEL_WIDTH_NARROW) / float(VISIBLE_FRAMES), float(UIConstants.WATERFALL_FRAME_WIDTH_MIN))
			var hover_x: float = lane_rect.position.x + float(hover_frame_idx) * frame_width
			var hover_rect: Rect2 = Rect2(Vector2(hover_x, lane_rect.position.y), Vector2(frame_width, lane_rect.size.y))
			draw_rect(hover_rect, Color(1.0, 0.843, 0.0, 0.2))  # Semi-transparent glow
	
	# GUI Performance Fix: Mark as drawn
	_needs_redraw = false

func _draw_grid() -> void:
	"""Draw grid lines (vertical every 30 frames, reference lines for time lanes)."""
	# Vertical grid lines every 30 frames
	var label_width: float = UIConstants.LABEL_WIDTH_NARROW
	var frame_width: float = max((size.x - label_width) / float(VISIBLE_FRAMES), float(UIConstants.WATERFALL_FRAME_WIDTH_MIN))
	
	for i in range(0, VISIBLE_FRAMES, 30):
		var x: float = label_width + float(i) * frame_width
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1.0, 1.0, 1.0, 0.1), 1.0)
	
	# Reference lines for time lanes (16.67ms green, 33.33ms orange)
	for lane_idx in range(7):  # Time lanes only
		var lane_rect: Rect2 = _get_lane_rect(lane_idx)
		
		# 16.67ms line (green, dashed effect)
		var target_y: float = lane_rect.position.y + lane_rect.size.y - (16.67 * lane_rect.size.y / UIConstants.WATERFALL_TARGET_FRAME_MS)
		for x in range(int(lane_rect.position.x), int(lane_rect.position.x + lane_rect.size.x), 4):
			draw_line(Vector2(x, target_y), Vector2(x + 2, target_y), Color(0.2, 1.0, 0.2, 0.5), 1.0)
		
		# 33.33ms line (orange, dashed effect)
		var warning_y: float = lane_rect.position.y + lane_rect.size.y - (33.33 * lane_rect.size.y / UIConstants.WATERFALL_TARGET_FRAME_MS)
		for x in range(int(lane_rect.position.x), int(lane_rect.position.x + lane_rect.size.x), 4):
			draw_line(Vector2(x, warning_y), Vector2(x + 2, warning_y), Color(1.0, 0.6, 0.0, 0.5), 1.0)

func _get_lane_name(lane_idx: int) -> String:
	"""Get the display name for a lane."""
	match lane_idx:
		0: return "Frame Time"
		1: return "Main Process"
		2: return "Physics Process"
		3: return "Map Refresh"
		4: return "Thread Compute"
		5: return "Other Process"
		6: return "Idle/GPU Wait"
		7: return "Draw Calls"
		_: return "Unknown"

func export_frame_snapshot(frame_idx: int) -> void:
	"""Export a frame snapshot to CSV."""
	var data: Dictionary = _get_frame_data(frame_idx)
	if data.is_empty():
		return
	
	# Ensure export directory exists
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("perf_exports"):
		dir.make_dir("perf_exports")
	
	var timestamp: int = Time.get_unix_time_from_system()
	var file_path: String = "user://perf_exports/waterfall_frame_%d_%d.csv" % [timestamp, frame_idx]
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		MythosLogger.error("WaterfallControl", "Failed to open file for export: %s" % file_path)
		return
	
	# Write CSV header
	var header: PackedStringArray = PackedStringArray([
		"timestamp_usec", "frame_id", "frame_time_ms", "process_ms", "physics_ms",
		"refresh_ms", "thread_ms", "other_process_ms", "idle_ms", "draw_calls", "primitives"
	])
	file.store_csv_line(header)
	
	# Write values
	var values: PackedStringArray = PackedStringArray([
		str(data.get("timestamp", 0)),
		str(data.get("frame_id", -1)),
		str(data.get("frame_time", 0.0)),
		str(data.get("process", 0.0)),
		str(data.get("physics", 0.0)),
		str(data.get("refresh", 0.0)),
		str(data.get("thread", 0.0)),
		str(data.get("other_process", 0.0)),
		str(data.get("idle", 0.0)),
		str(data.get("draw_calls", 0)),
		str(data.get("primitives", 0))
	])
	file.store_csv_line(values)
	
	file.close()
	MythosLogger.info("WaterfallControl", "Frame snapshot exported to: %s" % file_path)
