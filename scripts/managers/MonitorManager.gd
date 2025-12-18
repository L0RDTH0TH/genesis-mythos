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


func _ready() -> void:
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
	
	# Apply theme and responsive sizing
	_apply_theme_and_sizing()
	_apply_theme_to_labels()
	
	# Connect to viewport resize
	var viewport: Viewport = get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)


func _input(event: InputEvent) -> void:
	"""Handle input for toggling the overlay."""
	if event.is_action_pressed("toggle_perf_overlay"):
		toggle_overlay()


func _notification(what: int) -> void:
	"""Handle notifications for viewport resize."""
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_on_viewport_resized()


func _on_viewport_resized() -> void:
	"""Update overlay sizing when viewport resizes."""
	_apply_theme_and_sizing()


func _apply_theme_and_sizing() -> void:
	"""Apply theme overrides and responsive sizing to the overlay."""
	if not overlay or not margin_container:
		return
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	
	# Calculate dynamic width (25% of viewport, clamped)
	var overlay_width: float = clamp(
		viewport_size.x * 0.25,
		UIConstants.OVERLAY_MIN_WIDTH,
		800.0
	)
	
	# Set MarginContainer offsets using UIConstants (anchored to top-right)
	# offset_left = negative width to position from right edge
	# offset_top = margin from top
	# offset_right = negative margin from right edge (positive inset)
	# offset_bottom = 0 (no bottom margin needed)
	margin_container.offset_left = -overlay_width
	margin_container.offset_top = UIConstants.OVERLAY_MARGIN_LARGE
	margin_container.offset_right = -UIConstants.OVERLAY_MARGIN_LARGE
	margin_container.offset_bottom = 0.0
	
	# Set minimum width based on viewport size
	overlay.custom_minimum_size.x = overlay_width
	
	# Apply theme font and colors to MonitorOverlay addon properties
	# MonitorOverlay extends VBoxContainer and has export properties (font_size, graph_color, background_color)
	if _theme_resource and overlay.get_script() != null:
		# Apply theme font size with larger multiplier for readability
		var base_font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
		if base_font_size <= 0:
			base_font_size = 14  # Fallback
		var font_size: int = int(base_font_size * 1.5)  # 1.5x for readability
		overlay.set("font_size", font_size)
		
		# Apply theme colors for fantasy aesthetic
		# Use gold color for graphs (BG3-inspired)
		var gold_color: Color = _theme_resource.get_color("font_color", "Label")
		if gold_color == Color.TRANSPARENT:
			# Fallback to BG3-inspired gold if theme doesn't have it
			gold_color = Color(1.0, 0.843, 0.0, 1.0)  # Gold
		
		overlay.set("graph_color", gold_color)
		overlay.set("background_color", Color(0.0, 0.0, 0.0, 0.6))  # Slightly more opaque for better readability


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
	"""Toggles visibility."""
	visible = !visible
	if visible:
		_apply_theme_and_sizing()
		_apply_theme_to_labels()


func toggle() -> void:
	"""Public method to toggle overlay visibility."""
	toggle_overlay()


func set_overlay_visible(value: bool) -> void:
	"""Public method to set overlay visibility."""
	visible = value
	if visible:
		_apply_theme_and_sizing()
		_apply_theme_to_labels()
