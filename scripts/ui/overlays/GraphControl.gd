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
			y = clamp(y, 0.0, size.y)  # Clamp to graph bounds
			points.append(Vector2(x, y))
	
	# Draw filled area under curve (semi-transparent)
	# Need at least 2 points to form a polygon with bottom corners
	if points.size() >= 2:
		var filled_points: PackedVector2Array = PackedVector2Array()
		const MIN_POINT_DISTANCE: float = 0.1  # Minimum distance between points
		const EPSILON: float = 0.001
		
		# Remove duplicate and too-close consecutive points to avoid invalid geometry
		var last_point: Vector2 = Vector2(-1.0, -1.0)
		for i in range(points.size()):
			var pt: Vector2 = points[i]
			pt.y = clamp(pt.y, 0.0, size.y)  # Clamp y-coordinate
			pt.x = clamp(pt.x, 0.0, size.x)  # Clamp x-coordinate
			
			# Skip if this point is too close to the last one
			if i == 0:
				filled_points.append(pt)
				last_point = pt
			else:
				var distance: float = pt.distance_to(last_point)
				if distance >= MIN_POINT_DISTANCE:
					filled_points.append(pt)
					last_point = pt
		
		# Need at least 2 unique points to form a polygon with bottom corners
		if filled_points.size() >= 2:
			# Add bottom corners to close the polygon
			var last_x: float = filled_points[filled_points.size() - 1].x
			var first_x: float = filled_points[0].x
			var bottom_y: float = size.y
			
			# Ensure bottom corners are different from existing points
			var last_pt: Vector2 = filled_points[filled_points.size() - 1]
			var first_pt: Vector2 = filled_points[0]
			
			# Only add bottom corners if they're different from the curve endpoints
			if abs(last_pt.y - bottom_y) > EPSILON or abs(last_pt.x - last_x) > EPSILON:
				filled_points.append(Vector2(last_x, bottom_y))
			if abs(first_pt.y - bottom_y) > EPSILON or abs(first_pt.x - first_x) > EPSILON:
				filled_points.append(Vector2(first_x, bottom_y))
			
			# Validate polygon has at least 3 points (required for triangulation)
			if filled_points.size() >= 3:
				# Check for degenerate polygons (all points on same line)
				var all_same_y: bool = true
				var all_same_x: bool = true
				var first_y: float = filled_points[0].y
				var first_x_check: float = filled_points[0].x
				
				for pt in filled_points:
					if abs(pt.y - first_y) > EPSILON:
						all_same_y = false
					if abs(pt.x - first_x_check) > EPSILON:
						all_same_x = false
					if not all_same_y and not all_same_x:
						break
				
				# Only draw if polygon is not degenerate (not all on same line)
				if not all_same_y and not all_same_x:
					# Additional validation: ensure polygon has non-zero area
					# Calculate signed area (Shoelace formula)
					var area: float = 0.0
					for i in range(filled_points.size()):
						var j: int = (i + 1) % filled_points.size()
						area += filled_points[i].x * filled_points[j].y
						area -= filled_points[j].x * filled_points[i].y
					area = abs(area) / 2.0
					
					# Only draw if polygon has meaningful area
					if area > EPSILON:
						var fill_color: Color = line_color
						fill_color.a = 0.25
						draw_colored_polygon(filled_points, fill_color)
	
	# Draw line graph
	if points.size() > 1:
		draw_polyline(points, line_color, 2.0)
	
	# Current value dot (clamp position to graph bounds)
	if points.size() > 0:
		var dot_pos: Vector2 = points[points.size() - 1]
		dot_pos.y = clamp(dot_pos.y, 0.0, size.y)
		draw_circle(dot_pos, 4.0, line_color)
	
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
