# ╔═══════════════════════════════════════════════════════════
# ║ GraphControl.gd
# ║ Desc: Reusable control for drawing simple line graphs with history data
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name GraphControl
extends Control

@export var max_value: float = 0.0  ## 0 = auto-scale
@export var line_color: Color = Color(0.2, 1.0, 0.2)
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.4)
@export var grid_color: Color = Color(1.0, 1.0, 1.0, 0.15)
@export var smoothing_enabled: bool = false  ## Enable moving average smoothing
@export var smoothing_samples: int = 3  ## Number of samples for smoothing

var history: PackedFloat32Array = PackedFloat32Array()
var history_index: int = 0
var history_full: bool = false

var min_label: Label
var max_label: Label
var stats_label: Label  # Min/Avg/Max stats display

const GRID_LINES: int = 4

func _ready() -> void:
	"""Initialize graph control with min/max labels."""
	# Create min/max labels
	min_label = Label.new()
	min_label.name = "MinLabel"
	min_label.add_theme_font_size_override("font_size", 10)
	add_child(min_label)
	
	max_label = Label.new()
	max_label.name = "MaxLabel"
	max_label.add_theme_font_size_override("font_size", 10)
	add_child(max_label)
	
	# Create stats label (Min/Avg/Max)
	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(stats_label)
	
	# Update positions after size is set
	call_deferred("_update_label_positions")

func _update_label_positions() -> void:
	"""Update label positions based on current size."""
	if min_label and max_label:
		min_label.position = Vector2(2, size.y - 12)
		max_label.position = Vector2(2, 2)
	if stats_label:
		stats_label.position = Vector2(size.x / 2 - 50, size.y - 12)
		stats_label.size = Vector2(100, 12)

func _notification(what: int) -> void:
	"""Handle notifications including resize."""
	if what == NOTIFICATION_RESIZED:
		_update_label_positions()
		if stats_label:
			stats_label.position = Vector2(size.x / 2 - 50, size.y - 12)

func add_value(value: float) -> void:
	"""Add a new value to the history with optional smoothing."""
	var final_value: float = value
	
	# Apply smoothing if enabled
	if smoothing_enabled and history.size() > 0:
		var avg: float = value
		var count: int = min(smoothing_samples, history.size())
		for i in range(1, count + 1):
			var idx: int = (history_index - i + UIConstants.PERF_HISTORY_SIZE) % UIConstants.PERF_HISTORY_SIZE if history_full else (history.size() - i)
			if idx >= 0 and idx < history.size():
				avg += history[idx]
		avg /= (count + 1)
		final_value = avg
	
	# Circular buffer: add or overwrite
	if history.size() < UIConstants.PERF_HISTORY_SIZE:
		history.append(final_value)
	else:
		if not history_full:
			history_full = true
		history[history_index] = final_value
		history_index = (history_index + 1) % UIConstants.PERF_HISTORY_SIZE
	
	queue_redraw()

func _draw() -> void:
	"""Draw the graph with background, grid, line, and labels."""
	if history.is_empty():
		return
	
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	
	# Determine max for scaling
	var max_val: float = max_value if max_value > 0.0 else _get_auto_max()
	if max_val <= 0.0:
		max_val = 1.0
	
	var min_val: float = _get_auto_min()
	
	# Grid lines
	for i in range(1, GRID_LINES):
		var y: float = (float(i) / GRID_LINES) * size.y
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
	
	# Build points from circular buffer
	var points: PackedVector2Array = PackedVector2Array()
	var count: int = history.size() if not history_full else UIConstants.PERF_HISTORY_SIZE
	
	for i in range(count):
		var idx: int = (history_index + i) % count if history_full else i
		if idx >= 0 and idx < history.size():
			var x: float = (float(i) / max(count - 1, 1)) * size.x
			var y: float = size.y * (1.0 - ((history[idx] - min_val) / max(max_val - min_val, 0.001)))
			points.append(Vector2(x, y))
	
	# Draw filled area under curve (semi-transparent)
	if points.size() > 1:
		var filled_points: PackedVector2Array = points.duplicate()
		# Add bottom corners to close the polygon
		filled_points.append(Vector2(points[points.size() - 1].x, size.y))
		filled_points.append(Vector2(points[0].x, size.y))
		# Draw filled polygon with 25% opacity
		var fill_color: Color = line_color
		fill_color.a = 0.25
		draw_colored_polygon(filled_points, fill_color)
	
	# Draw line graph
	if points.size() > 1:
		draw_polyline(points, line_color, 2.0)
	
	# Current value dot
	if points.size() > 0:
		draw_circle(points[points.size() - 1], 4.0, line_color)
	
	# Update min/max labels
	if min_label and max_label:
		max_label.text = "%.1f" % max_val
		min_label.text = "%.1f" % min_val
		
		# Update label positions (handle resize)
		min_label.position = Vector2(2, size.y - 12)
		max_label.position = Vector2(2, 2)
	
	# Update stats label (Min/Avg/Max)
	if stats_label:
		var min_stat: float = get_min()
		var avg_stat: float = get_average()
		var max_stat: float = get_max()
		stats_label.text = "Min: %.1f | Avg: %.1f | Max: %.1f" % [min_stat, avg_stat, max_stat]
		stats_label.position = Vector2(size.x / 2 - 50, size.y - 12)

func _get_auto_max() -> float:
	"""Calculate maximum value from history with 10% padding."""
	if history.is_empty():
		return 1.0
	var m: float = history[0]
	var count: int = history.size() if not history_full else UIConstants.PERF_HISTORY_SIZE
	for i in range(count):
		var idx: int = (history_index + i) % count if history_full else i
		if idx >= 0 and idx < history.size() and history[idx] > m:
			m = history[idx]
	return max(m * 1.1, 1.0)

func _get_auto_min() -> float:
	"""Calculate minimum value from history with 10% padding."""
	if history.is_empty():
		return 0.0
	var m: float = history[0]
	var count: int = history.size() if not history_full else UIConstants.PERF_HISTORY_SIZE
	for i in range(count):
		var idx: int = (history_index + i) % count if history_full else i
		if idx >= 0 and idx < history.size() and history[idx] < m:
			m = history[idx]
	return max(m * 0.9, 0.0)

func get_min() -> float:
	"""Get minimum value from current history."""
	if history.is_empty():
		return 0.0
	var m: float = history[0]
	var count: int = history.size() if not history_full else UIConstants.PERF_HISTORY_SIZE
	for i in range(count):
		var idx: int = (history_index + i) % count if history_full else i
		if idx >= 0 and idx < history.size() and history[idx] < m:
			m = history[idx]
	return m

func get_max() -> float:
	"""Get maximum value from current history."""
	if history.is_empty():
		return 0.0
	var m: float = history[0]
	var count: int = history.size() if not history_full else UIConstants.PERF_HISTORY_SIZE
	for i in range(count):
		var idx: int = (history_index + i) % count if history_full else i
		if idx >= 0 and idx < history.size() and history[idx] > m:
			m = history[idx]
	return m

func get_average() -> float:
	"""Get average value from current history."""
	if history.is_empty():
		return 0.0
	var sum: float = 0.0
	var count: int = history.size() if not history_full else UIConstants.PERF_HISTORY_SIZE
	for i in range(count):
		var idx: int = (history_index + i) % count if history_full else i
		if idx >= 0 and idx < history.size():
			sum += history[idx]
	return sum / count
