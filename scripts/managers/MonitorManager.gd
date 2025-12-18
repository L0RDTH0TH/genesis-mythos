# ╔═══════════════════════════════════════════════════════════
# ║ MonitorManager.gd
# ║ Desc: Manages toggling and responsiveness of performance overlay.
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

## Manages the runtime performance monitor overlay.
## Handles toggling via keybind (F3), theme integration, and responsive sizing.
class_name MonitorManager
extends CanvasLayer

@onready var margin_container: MarginContainer = $MarginContainer
@onready var panel: Panel = $MarginContainer/Panel
@onready var overlay: VBoxContainer = $MarginContainer/Panel/MonitorOverlay

var _theme_resource: Theme
var _sizing_in_progress: bool = false


func _ready() -> void:
	"""Initialize the overlay manager."""
	# Set layer high to appear above game content
	layer = 128
	
	# Load theme
	_theme_resource = preload("res://themes/bg3_theme.tres")
	# Apply theme to child nodes (CanvasLayer doesn't have theme property)
	if margin_container:
		margin_container.theme = _theme_resource
	if panel:
		panel.theme = _theme_resource
	
	# Hide by default (player toggles with F3)
	visible = false
	
	# Connect to viewport resize
	var viewport: Viewport = get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)
	
	# Apply theme and responsive sizing (deferred to ensure layout is ready)
	call_deferred("_apply_theme_and_sizing")


func _input(event: InputEvent) -> void:
	"""Handle input for toggling the overlay."""
	if event.is_action_pressed("toggle_perf_overlay"):
		toggle_overlay()


func _notification(what: int) -> void:
	"""Handle notifications for viewport resize."""
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# Defer to avoid async issues in notification handler
		if visible:
			call_deferred("_apply_theme_and_sizing")


func _on_viewport_resized() -> void:
	"""Update overlay sizing when viewport resizes."""
	if visible:
		call_deferred("_apply_theme_and_sizing")


func _apply_theme_and_sizing() -> void:
	"""Apply theme overrides and responsive sizing to the overlay.
	
	This function schedules an async sizing operation that waits for layout
	to update before calculating sizes. Follows the pattern from DebugMenuScaler.gd.
	"""
	if _sizing_in_progress:
		return
	
	# Start async coroutine (will handle its own await calls)
	_apply_theme_and_sizing_async()


func _apply_theme_and_sizing_async() -> void:
	"""Internal async function that applies theme and calculates responsive sizing.
	
	Follows the proven pattern from DebugMenuScaler.gd:
	- Waits for layout to update before calculating sizes
	- Measures actual content size using get_combined_minimum_size()
	- Properly calculates offsets for PRESET_TOP_RIGHT anchors
	- Ensures overlay is fully visible with proper margins from UIConstants
	"""
	if not overlay or not margin_container:
		return
	
	_sizing_in_progress = true
	
	# Ensure anchor is set to top-right (should already be set in .tscn, but ensure consistency)
	margin_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	
	# Apply theme font and colors first (before measuring, as it affects content size)
	if _theme_resource and overlay.get_script() != null:
		# Apply theme font size with larger multiplier for readability
		var base_font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
		if base_font_size <= 0:
			base_font_size = 14  # Fallback
		var font_size: int = int(base_font_size * 1.5)  # 1.5x for readability
		# Setting via set() will trigger the export property setter, which sets need_to_rebuild_ui=true
		overlay.set("font_size", font_size)
		
		# Apply theme colors for fantasy aesthetic
		var gold_color: Color = _theme_resource.get_color("font_color", "Label")
		if gold_color == Color.TRANSPARENT:
			# Fallback to BG3-inspired gold if theme doesn't have it
			gold_color = Color(1.0, 0.843, 0.0, 1.0)  # Gold
		
		overlay.set("graph_color", gold_color)
		overlay.set("background_color", Color(0.0, 0.0, 0.0, 0.6))  # Slightly more opaque for better readability
	
	# Apply theme to labels for consistent styling
	_apply_theme_to_labels()
	
	# Wait for layout to update to get actual content size
	# The overlay needs time to rebuild its UI (DebugGraph nodes) after font_size change
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame to ensure size is calculated
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	
	# Get the actual content size of the overlay
	var content_size: Vector2 = overlay.get_combined_minimum_size()
	if content_size == Vector2.ZERO or content_size.y <= 0:
		# Fallback: estimate size based on enabled monitors
		# Get graph_height from overlay property (default 50 if not set)
		var graph_height: float = 50.0
		if overlay.has("graph_height"):
			graph_height = overlay.get("graph_height")
		# Estimate: 6 enabled monitors * graph_height + padding
		var estimated_height: float = (6.0 * graph_height) + (UIConstants.SPACING_MEDIUM * 2.0)
		content_size = Vector2(UIConstants.OVERLAY_MIN_WIDTH, estimated_height)
	
	# Ensure minimum width from UIConstants
	if content_size.x < UIConstants.OVERLAY_MIN_WIDTH:
		content_size.x = UIConstants.OVERLAY_MIN_WIDTH
	
	# Clamp maximum width to 25% of viewport or 800px (whichever is smaller)
	var max_width: float = min(viewport_size.x * 0.25, 800.0)
	if content_size.x > max_width:
		content_size.x = max_width
	
	# Apply margins from UIConstants
	var safe_margin: int = UIConstants.OVERLAY_MARGIN_LARGE
	
	# For PRESET_TOP_RIGHT anchors:
	# - offset_left: negative value extends left from right edge (defines width)
	# - offset_right: negative value creates margin from right edge
	# - offset_top: positive value creates margin from top edge
	# - offset_bottom: positive value sets bottom edge from top (defines height = margin + content_height)
	margin_container.offset_left = -content_size.x
	margin_container.offset_top = safe_margin
	margin_container.offset_right = -safe_margin
	margin_container.offset_bottom = safe_margin + content_size.y
	
	# Final bounds check to ensure it's fully visible on screen
	var right_edge: float = viewport_size.x + margin_container.offset_right
	var left_edge: float = right_edge - content_size.x
	var top_edge: float = margin_container.offset_top
	var bottom_edge: float = top_edge + content_size.y
	
	# Clamp if needed to ensure it fits on screen (shouldn't be needed, but safety check)
	if right_edge > viewport_size.x:
		margin_container.offset_right = -safe_margin
		margin_container.offset_left = -content_size.x
	if left_edge < safe_margin:
		margin_container.offset_right = -safe_margin
		margin_container.offset_left = -(viewport_size.x - safe_margin * 2)
	if top_edge < safe_margin:
		margin_container.offset_top = safe_margin
		margin_container.offset_bottom = safe_margin + content_size.y
	if bottom_edge > viewport_size.y - safe_margin:
		margin_container.offset_top = viewport_size.y - content_size.y - safe_margin
		margin_container.offset_bottom = margin_container.offset_top + content_size.y
	
	_sizing_in_progress = false


func _apply_theme_to_labels() -> void:
	"""Recursively apply theme to all Label nodes for better readability."""
	if not _theme_resource or not overlay:
		return
	
	# Recurse through all children and apply theme to Labels
	_apply_theme_to_node_recursive(overlay)


func _apply_theme_to_node_recursive(node: Node) -> void:
	"""Recursively apply theme overrides to Label nodes."""
	if node is Label:
		var label: Label = node as Label
		# Apply larger font size for readability
		var base_font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
		if base_font_size <= 0:
			base_font_size = 14
		label.theme_override_font_sizes.font_size = int(base_font_size * 1.5)
		
		# Apply theme font color (gold/earthy)
		var font_color: Color = _theme_resource.get_color("font_color", "Label")
		if font_color != Color.TRANSPARENT:
			label.theme_override_colors.font_color = font_color
	
	# Recurse to children
	for child in node.get_children():
		_apply_theme_to_node_recursive(child)


func toggle_overlay() -> void:
	"""Toggles visibility of the performance overlay."""
	visible = !visible
	if visible:
		# When becoming visible, ensure sizing happens after layout is ready
		call_deferred("_apply_theme_and_sizing")


func toggle() -> void:
	"""Public method to toggle overlay visibility."""
	toggle_overlay()


func set_overlay_visible(value: bool) -> void:
	"""Public method to set overlay visibility."""
	visible = value
	if visible:
		# When becoming visible, ensure sizing happens after layout is ready
		call_deferred("_apply_theme_and_sizing")
