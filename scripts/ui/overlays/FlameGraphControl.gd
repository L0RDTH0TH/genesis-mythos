# ╔═══════════════════════════════════════════════════════════
# ║ FlameGraphControl.gd
# ║ Desc: Custom control for rendering flame graphs from hierarchical call tree data
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name FlameGraphControl
extends Control

## Current call tree data from FlameGraphProfiler
var call_tree: Dictionary = {}

## Maximum depth to render (prevents excessive recursion)
const MAX_RENDER_DEPTH: int = 15

## Update throttling: Only update every N frames
var _update_frame_counter: int = 0
const UPDATE_INTERVAL_FRAMES: int = 60  ## Update every 1s at 60 FPS (fallback)

## Total time for scaling (from root node)
var _total_time_ms: float = 0.0

## Tooltip
@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipLabel
var _tooltip_node_key: String = ""
var _tooltip_pos: Vector2
var _tooltip_visible: bool = false

## Color thresholds for time-based coloring (from UIConstants or config)
const TIME_GOOD_MS: float = 1.0    ## Green threshold
const TIME_WARNING_MS: float = 5.0  ## Yellow threshold
const TIME_BAD_MS: float = 10.0     ## Red threshold

## Minimum bar width to render (prevents tiny unreadable bars)
const MIN_BAR_WIDTH: float = 2.0

## Current hover position for tooltip
var _hover_pos: Vector2 = Vector2(-1, -1)


func _ready() -> void:
	"""Initialize flame graph control with tooltip."""
	# Initialize tooltip panel if not in scene
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
	
	# Connect to profiler aggregation signal for immediate updates
	if FlameGraphProfiler and FlameGraphProfiler.has_signal("aggregation_complete"):
		FlameGraphProfiler.aggregation_complete.connect(_on_aggregation_complete)


func _process(_delta: float) -> void:
	"""Update call tree data periodically to avoid overhead."""
	_update_frame_counter += 1
	
	# Throttle updates: Only update every UPDATE_INTERVAL_FRAMES
	if _update_frame_counter >= UPDATE_INTERVAL_FRAMES:
		_update_frame_counter = 0
		update_from_profiler()


func update_from_profiler() -> void:
	"""Pull data from FlameGraphProfiler and update visualization."""
	if not FlameGraphProfiler:
		return
	
	# Get call tree from profiler
	call_tree = FlameGraphProfiler.get_call_tree()
	
	# Extract total time from root node for scaling
	if call_tree.has("total_time_ms"):
		_total_time_ms = call_tree.get("total_time_ms", 0.0)
	else:
		_total_time_ms = 0.0
	
	# Debug logging
	MythosLogger.debug("FlameGraphControl", "update_from_profiler() called - tree keys: %s, total_time_ms: %.2f" % [
		call_tree.keys() if not call_tree.is_empty() else "empty",
		_total_time_ms
	])
	
	# Trigger redraw
	queue_redraw()


func _on_aggregation_complete(_samples_processed: int) -> void:
	"""Called immediately when profiler finishes aggregating samples."""
	MythosLogger.debug("FlameGraphControl", "Aggregation complete - updating from profiler (samples: %d)" % _samples_processed)
	update_from_profiler()


func _gui_input(event: InputEvent) -> void:
	"""Handle mouse input for hover and tooltip."""
	if event is InputEventMouseMotion:
		_hover_pos = event.position
		_tooltip_node_key = _get_node_at_position(_hover_pos)
		if _tooltip_node_key != "":
			_tooltip_visible = true
			_update_tooltip()
			queue_redraw()  # Redraw to show hover highlight
		else:
			_tooltip_visible = false
			_update_tooltip()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_hover_pos = event.position
			_tooltip_node_key = _get_node_at_position(_hover_pos)
			if _tooltip_node_key != "":
				_tooltip_visible = true
				_update_tooltip()


func _get_node_at_position(pos: Vector2) -> String:
	"""Get the node key at the given position (for tooltip)."""
	if call_tree.is_empty() or _total_time_ms <= 0.0:
		return ""
	
	var root_y: float = UIConstants.SPACING_MEDIUM
	var result: Dictionary = _find_node_at_position_recursive(call_tree, 0.0, root_y, size.x, pos, _total_time_ms)
	if result.has("node_key"):
		return result.get("node_key", "")
	return ""


func _find_node_at_position_recursive(node: Dictionary, x: float, y: float, width: float, pos: Vector2, parent_total_time: float) -> Dictionary:
	"""Recursively find node at position."""
	if not node is Dictionary:
		return {}
	
	var node_time: float = node.get("total_time_ms", 0.0)
	if node_time <= 0.0 or width <= 0.0 or parent_total_time <= 0.0:
		return {}
	
	# Calculate this node's width based on time proportion relative to parent
	var node_width: float = (node_time / parent_total_time) * width
	
	# Check if position is within this node's bounds
	if pos.x >= x and pos.x < x + node_width and pos.y >= y and pos.y < y + UIConstants.WATERFALL_LANE_HEIGHT:
		# Found the node - return its key
		var source: String = node.get("source", "")
		var function: String = node.get("function", "")
		var line: int = node.get("line", 0)
		return {"node_key": "%s:%s:%d" % [source, function, line], "node": node}
	
	# Check children
	var children: Dictionary = node.get("children", {})
	var child_x: float = x
	for child_key in children.keys():
		var child: Dictionary = children[child_key]
		var child_time: float = child.get("total_time_ms", 0.0)
		var child_width: float = 0.0
		if node_time > 0.0:
			child_width = (child_time / node_time) * node_width
		
		var result: Dictionary = _find_node_at_position_recursive(child, child_x, y + UIConstants.WATERFALL_LANE_HEIGHT, child_width, pos, node_time)
		if not result.is_empty():
			return result
		
		child_x += child_width
	
	return {}


func _update_tooltip() -> void:
	"""Update tooltip text and position."""
	if not _tooltip_visible or not tooltip_panel or not tooltip_label:
		tooltip_panel.visible = false
		return
	
	if _tooltip_node_key == "":
		tooltip_panel.visible = false
		return
	
	# Find the node data
	var node: Dictionary = _find_node_by_key(call_tree, _tooltip_node_key)
	if node.is_empty():
		tooltip_panel.visible = false
		return
	
	# Format tooltip text
	var function_name: String = node.get("function", "unknown")
	var source: String = node.get("source", "unknown")
	var line: int = node.get("line", 0)
	var total_time: float = node.get("total_time_ms", 0.0)
	var self_time: float = node.get("self_time_ms", 0.0)
	var call_count: int = node.get("call_count", 0)
	
	var text: String = "Function: %s\n" % function_name
	text += "Source: %s:%d\n" % [source, line]
	text += "Total Time: %.2f ms\n" % total_time
	text += "Self Time: %.2f ms\n" % self_time
	text += "Call Count: %d" % call_count
	
	tooltip_label.text = text
	tooltip_panel.position = _clamp_tooltip_pos(_hover_pos)
	tooltip_panel.size = Vector2(250, 120)
	tooltip_panel.visible = true


func _find_node_by_key(node: Dictionary, key: String) -> Dictionary:
	"""Recursively find node by key."""
	if not node is Dictionary:
		return {}
	
	var source: String = node.get("source", "")
	var function: String = node.get("function", "")
	var line: int = node.get("line", 0)
	var node_key: String = "%s:%s:%d" % [source, function, line]
	
	if node_key == key:
		return node
	
	var children: Dictionary = node.get("children", {})
	for child_key in children.keys():
		var child: Dictionary = children[child_key]
		var result: Dictionary = _find_node_by_key(child, key)
		if not result.is_empty():
			return result
	
	return {}


func _clamp_tooltip_pos(pos: Vector2) -> Vector2:
	"""Clamp tooltip position to viewport bounds."""
	if not tooltip_panel:
		return pos
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var tooltip_size: Vector2 = tooltip_panel.size if tooltip_panel.size.x > 0 else Vector2(250, 120)
	
	var clamped_x: float = clamp(pos.x, 0.0, viewport_size.x - tooltip_size.x)
	var clamped_y: float = clamp(pos.y - tooltip_size.y, 0.0, viewport_size.y - tooltip_size.y)
	
	return Vector2(clamped_x, clamped_y)


func _draw() -> void:
	"""Draw the flame graph with nested rectangles and status feedback."""
	MythosLogger.debug("FlameGraphControl", "_draw() called - size: %s, call_tree empty: %s, total_time_ms: %.2f" % [
		size, call_tree.is_empty(), _total_time_ms
	])
	
	# Always draw background
	var bg_color: Color = Color(0.1, 0.08, 0.06, 0.9)
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	
	# If no data yet, show helpful status
	if call_tree.is_empty():
		_draw_status_message("Collecting samples...\nPress F3 to cycle modes")
		return
	
	if _total_time_ms <= 0.1:  # Very small threshold instead of 0.0
		_draw_status_message("Aggregating data...\nSamples collected but processing")
		return
	
	# Valid data - draw the actual flame graph
	# Draw grid lines
	_draw_grid()
	
	# Draw root node and all children recursively
	# Root node uses full width, children are proportional to parent
	var root_y: float = UIConstants.SPACING_MEDIUM
	_draw_func_node(call_tree, 0.0, root_y, size.x, 0, _total_time_ms)
	
	# Draw hover highlight if tooltip is visible
	if _tooltip_visible and _tooltip_node_key != "":
		_draw_hover_highlight()
	
	# Optional: overlay total time
	var info_text: String = "Total frame time: %.2f ms" % _total_time_ms
	draw_string(ThemeDB.fallback_font, Vector2(10, size.y - 10), info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8, 0.8))


func _draw_grid() -> void:
	"""Draw grid lines for reference."""
	var grid_color: Color = Color(1.0, 1.0, 1.0, 0.1)
	
	# Horizontal lines every lane height
	var lane_height: float = UIConstants.WATERFALL_LANE_HEIGHT
	var y: float = UIConstants.SPACING_MEDIUM
	var depth: int = 0
	
	while y < size.y and depth < MAX_RENDER_DEPTH:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		y += lane_height
		depth += 1
	
	# Vertical reference lines (every 25% of width)
	for i in range(1, 4):
		var x: float = (size.x / 4.0) * float(i)
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)


func _draw_func_node(node: Dictionary, x: float, y: float, width: float, depth: int, parent_total_time: float) -> void:
	"""Recursively draw a function node and its children.
	
	Args:
		node: Dictionary containing function call data
		x, y: Position of the node
		width: Width available for this node
		depth: Current recursion depth
		parent_total_time: Total time of parent node (for proportional sizing)
	"""
	if depth >= MAX_RENDER_DEPTH:
		return  # Prevent excessive recursion
	
	if not node is Dictionary:
		return
	
	var node_time: float = node.get("total_time_ms", 0.0)
	if node_time <= 0.0 or width <= MIN_BAR_WIDTH or parent_total_time <= 0.0:
		return  # Skip nodes with no time or too small to render
	
	# Calculate this node's width based on time proportion relative to parent
	var node_width: float = (node_time / parent_total_time) * width
	
	if node_width < MIN_BAR_WIDTH:
		return  # Skip if too narrow
	
	var lane_height: float = UIConstants.WATERFALL_LANE_HEIGHT
	
	# Get node color based on self_time (time spent in function itself)
	var self_time: float = node.get("self_time_ms", 0.0)
	var node_color: Color = _get_node_color(self_time, node_time)
	
	# Draw this node's bar
	var bar_rect: Rect2 = Rect2(Vector2(x, y), Vector2(node_width, lane_height))
	draw_rect(bar_rect, node_color)
	
	# Draw border (rune-like outline)
	var border_color: Color = Color(1.0, 0.843, 0.0, 0.3)  # Gold tint
	draw_rect(bar_rect, border_color, false, 1.0)
	
	# Draw function name label if bar is wide enough
	if node_width > UIConstants.LABEL_WIDTH_NARROW:
		var function_name: String = node.get("function", "unknown")
		var label_pos: Vector2 = Vector2(x + UIConstants.SPACING_SMALL, y + lane_height / 2 - 8)
		var label_color: Color = Color(1.0, 0.843, 0.0)  # Gold text
		draw_string(ThemeDB.fallback_font, label_pos, function_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label_color)
	
	# Draw children recursively
	var children: Dictionary = node.get("children", {})
	if children.is_empty():
		return
	
	var child_y: float = y + lane_height
	var child_x: float = x
	
	# Draw each child with proportional width
	for child_key in children.keys():
		var child: Dictionary = children[child_key]
		var child_time: float = child.get("total_time_ms", 0.0)
		
		# Calculate child width relative to parent node width
		# Child width = (child_time / parent_total_time) * parent_width
		# But we use node_time as parent_total_time for children
		var child_width: float = 0.0
		if node_time > 0.0:
			child_width = (child_time / node_time) * node_width
		else:
			child_width = node_width / children.size()  # Equal distribution if no time data
		
		# Only draw if child has time and is wide enough
		if child_time > 0.0 and child_width >= MIN_BAR_WIDTH:
			_draw_func_node(child, child_x, child_y, child_width, depth + 1, node_time)
		
		child_x += child_width


func _get_node_color(self_time_ms: float, total_time_ms: float) -> Color:
	"""Get color for a node based on self time (green → yellow → red gradient)."""
	# Use self_time for color intensity (time spent in function itself)
	var intensity: float = 0.0
	if total_time_ms > 0.0:
		intensity = clamp(self_time_ms / TIME_BAD_MS, 0.0, 1.0)
	
	# Green → Yellow → Red gradient
	var r: float = intensity
	var g: float = 1.0 - (intensity * 0.5)  # Green fades slower
	var b: float = 0.0
	
	# Apply alpha for depth effect
	var alpha: float = 0.85 - (intensity * 0.15)  # Slightly transparent for depth
	
	return Color(r, g, b, alpha)


func _draw_hover_highlight() -> void:
	"""Draw highlight for hovered node."""
	if _tooltip_node_key == "":
		return
	
	# Find and highlight the hovered node
	_draw_node_highlight(call_tree, 0.0, UIConstants.SPACING_MEDIUM, size.x, _tooltip_node_key, _total_time_ms)


func _draw_node_highlight(node: Dictionary, x: float, y: float, width: float, target_key: String, parent_total_time: float) -> bool:
	"""Recursively find and highlight target node. Returns true if found."""
	if not node is Dictionary:
		return false
	
	var node_time: float = node.get("total_time_ms", 0.0)
	if node_time <= 0.0 or width <= 0.0 or parent_total_time <= 0.0:
		return false
	
	var node_width: float = (node_time / parent_total_time) * width
	var source: String = node.get("source", "")
	var function: String = node.get("function", "")
	var line: int = node.get("line", 0)
	var node_key: String = "%s:%s:%d" % [source, function, line]
	
	var lane_height: float = UIConstants.WATERFALL_LANE_HEIGHT
	
	# Check if this is the target node
	if node_key == target_key:
		var highlight_rect: Rect2 = Rect2(Vector2(x, y), Vector2(node_width, lane_height))
		var highlight_color: Color = Color(1.0, 0.843, 0.0, 0.3)  # Semi-transparent gold glow
		draw_rect(highlight_rect, highlight_color)
		return true
	
	# Check children
	var children: Dictionary = node.get("children", {})
	var child_x: float = x
	
	for child_key in children.keys():
		var child: Dictionary = children[child_key]
		var child_time: float = child.get("total_time_ms", 0.0)
		var child_width: float = 0.0
		if node_time > 0.0:
			child_width = (child_time / node_time) * node_width
		
		if _draw_node_highlight(child, child_x, y + lane_height, child_width, target_key, node_time):
			return true
		
		child_x += child_width
	
	return false


func _draw_status_message(message: String) -> void:
	"""Draw centered multi-line status text."""
	var lines: PackedStringArray = message.split("\n")
	var font: Font = ThemeDB.fallback_font
	var line_height: int = font.get_height(18) + 4
	var total_height: int = lines.size() * line_height
	var start_y: float = (size.y - total_height) / 2.0
	
	for i in lines.size():
		var line: String = lines[i]
		var line_width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, -1, 18).x
		var pos: Vector2 = Vector2((size.x - line_width) / 2.0, start_y + i * line_height)
		draw_string(font, pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.9, 0.7, 0.9))


func _notification(what: int) -> void:
	"""Handle resize notifications."""
	if what == NOTIFICATION_RESIZED:
		if _tooltip_visible:
			_update_tooltip()
		queue_redraw()

