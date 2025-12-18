# ╔═══════════════════════════════════════════════════════════
# ║ MonitorManager.gd
# ║ Desc: Manages the runtime performance overlay, toggling and styling.
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

## Manages the runtime performance monitor overlay.
## Handles toggling via keybind (F3), theme integration, and responsive sizing.
class_name MonitorManager
extends CanvasLayer

@onready var margin_container: MarginContainer = $MarginContainer
@onready var overlay: VBoxContainer = $MarginContainer/MonitorOverlay

var _theme_resource: Theme


func _ready() -> void:
	# Set layer high to appear above game content
	layer = 128
	
	# Load theme
	_theme_resource = preload("res://themes/bg3_theme.tres")
	# Apply theme to child nodes (CanvasLayer doesn't have theme property)
	if margin_container:
		margin_container.theme = _theme_resource
	
	# Hide by default (player toggles with F3)
	visible = false
	
	# Apply theme and responsive sizing
	_apply_theme_and_sizing()
	
	# Connect to viewport resize
	var viewport: Viewport = get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)


func _input(event: InputEvent) -> void:
	"""Handle input for toggling the overlay."""
	if event.is_action_pressed("toggle_perf_overlay"):
		visible = !visible
		if visible:
			_apply_theme_and_sizing()


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
	
	# Set MarginContainer offsets using UIConstants (anchored to top-right)
	# offset_left = negative width to position from right edge
	# offset_top = spacing from top
	# offset_right = 0 (anchored to right edge)
	# offset_bottom = 0 (no bottom margin needed)
	var overlay_width: float = clamp(
		viewport_size.x * 0.2,
		UIConstants.OVERLAY_MIN_WIDTH,
		600.0
	)
	margin_container.offset_left = -overlay_width
	margin_container.offset_top = UIConstants.SPACING_LARGE
	margin_container.offset_right = 0.0
	margin_container.offset_bottom = 0.0
	
	# Set minimum width based on viewport size (20% of width, clamped)
	overlay.custom_minimum_size.x = overlay_width
	
	# Apply theme font and colors to MonitorOverlay addon properties
	# MonitorOverlay extends VBoxContainer and has export properties (font_size, graph_color, background_color)
	if _theme_resource and overlay.get_script() != null:
		# Apply theme font size if available
		var font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
		if font_size > 0:
			overlay.set("font_size", font_size)
		
		# Apply theme colors for fantasy aesthetic
		# Use gold color for graphs (BG3-inspired)
		var gold_color: Color = _theme_resource.get_color("font_color", "Label")
		if gold_color == Color.TRANSPARENT:
			# Fallback to BG3-inspired gold if theme doesn't have it
			gold_color = Color(1.0, 0.843, 0.0, 1.0)  # Gold
		
		overlay.set("graph_color", gold_color)
		overlay.set("background_color", Color(0.0, 0.0, 0.0, 0.6))  # Slightly more opaque for better readability


func toggle() -> void:
	"""Public method to toggle overlay visibility."""
	visible = !visible
	if visible:
		_apply_theme_and_sizing()


func set_overlay_visible(value: bool) -> void:
	"""Public method to set overlay visibility."""
	visible = value
	if visible:
		_apply_theme_and_sizing()
