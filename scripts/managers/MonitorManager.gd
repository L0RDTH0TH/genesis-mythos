# ╔═══════════════════════════════════════════════════════════
# ║ MonitorManager.gd
# ║ Desc: Manages toggling and responsiveness of performance overlay.
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

## Manages the runtime performance monitor overlay.
## Handles toggling via keybind (F3), theme integration, and responsive sizing.
## Positioned at top-left with proper margins using built-in anchors.
class_name MonitorManager
extends CanvasLayer

@onready var margin_container: MarginContainer = $MarginContainer
@onready var panel: Panel = $MarginContainer/Panel
@onready var overlay: VBoxContainer = $MarginContainer/Panel/MonitorOverlay

var _theme_resource: Theme


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
	
	# Apply theme and readability settings
	call_deferred("_apply_theme_and_readability")


func _input(event: InputEvent) -> void:
	"""Handle input for toggling the overlay."""
	if event.is_action_pressed("toggle_perf_overlay"):
		toggle_overlay()


func _notification(what: int) -> void:
	"""Handle notifications for viewport resize."""
	if what == NOTIFICATION_RESIZED:
		if visible:
			call_deferred("_apply_theme_and_readability")


func _on_viewport_resized() -> void:
	"""Update overlay when viewport resizes."""
	if visible:
		call_deferred("_apply_theme_and_readability")


func _apply_theme_and_readability() -> void:
	# This function needs to be async but can't be called directly with await from call_deferred
	# So we start an async coroutine
	_apply_theme_and_readability_async()


func _apply_theme_and_readability_async() -> void:
	"""Apply theme overrides and readability settings to the overlay.
	
	For top-left positioning, we use built-in anchors with simple margin offsets.
	The container sizes based on content, which is simpler than top-right positioning.
	"""
	if not overlay or not margin_container:
		return
	
	# Ensure anchor is set to top-left (PRESET_TOP_LEFT = 1)
	margin_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Apply theme font and colors first (before measuring, as it affects content size)
	if _theme_resource and overlay.get_script() != null:
		# Apply larger font size for better readability (1.8x multiplier)
		var base_font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
		if base_font_size <= 0:
			base_font_size = 14  # Fallback
		var font_size: int = int(base_font_size * 1.8)  # 1.8x for readability
		# Setting via set() will trigger the export property setter, which sets need_to_rebuild_ui=true
		overlay.set("font_size", font_size)
		
		# Apply theme colors for fantasy aesthetic
		var gold_color: Color = _theme_resource.get_color("font_color", "Label")
		if gold_color == Color.TRANSPARENT:
			# Fallback to BG3-inspired gold if theme doesn't have it
			gold_color = Color(1.0, 0.843, 0.0, 1.0)  # Gold
		
		overlay.set("graph_color", gold_color)
		overlay.set("background_color", Color(0.0, 0.0, 0.0, 0.6))  # Slightly more opaque for better readability
		
		# Trigger UI rebuild if the addon supports it
		if overlay.has("need_to_rebuild_ui"):
			overlay.set("need_to_rebuild_ui", true)
	
	# Apply theme to labels for consistent styling
	_apply_theme_to_labels()
	
	# Wait one frame for layout to update after font/theme changes
	await get_tree().process_frame
	
	# Get content size after layout update
	var content_size: Vector2 = overlay.get_combined_minimum_size()
	if content_size == Vector2.ZERO or content_size.y <= 0:
		# Fallback: estimate size based on enabled monitors
		var graph_height: float = 50.0
		if overlay.has("graph_height"):
			graph_height = overlay.get("graph_height")
		var estimated_height: float = (6.0 * graph_height) + (UIConstants.SPACING_MEDIUM * 2.0)
		content_size = Vector2(UIConstants.OVERLAY_MIN_WIDTH, estimated_height)
	
	# Ensure minimum width from UIConstants
	if content_size.x < UIConstants.OVERLAY_MIN_WIDTH:
		content_size.x = UIConstants.OVERLAY_MIN_WIDTH
	
	# Clamp max width to 40% of viewport or 600px (whichever is smaller)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var max_width: float = min(viewport_size.x * 0.4, 600.0)
	if content_size.x > max_width:
		content_size.x = max_width
	
	# Set margins using UIConstants (position from top-left corner)
	var margin: int = UIConstants.OVERLAY_MARGIN_LARGE
	
	# For PRESET_TOP_LEFT:
	# - offset_left: margin from left edge
	# - offset_top: margin from top edge
	# - offset_right: width (offset_left + content_width)
	# - offset_bottom: height (offset_top + content_height)
	margin_container.offset_left = margin
	margin_container.offset_top = margin
	margin_container.offset_right = margin + content_size.x
	margin_container.offset_bottom = margin + content_size.y


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
		# Apply larger font size for readability (1.8x multiplier to match overlay font)
		var base_font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
		if base_font_size <= 0:
			base_font_size = 14
		label.theme_override_font_sizes.font_size = int(base_font_size * 1.8)
		
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
		# When becoming visible, ensure theme and readability are applied
		call_deferred("_apply_theme_and_readability")


func toggle() -> void:
	"""Public method to toggle overlay visibility."""
	toggle_overlay()


func set_overlay_visible(value: bool) -> void:
	"""Public method to set overlay visibility."""
	visible = value
	if visible:
		# When becoming visible, ensure theme and readability are applied
		call_deferred("_apply_theme_and_readability")
