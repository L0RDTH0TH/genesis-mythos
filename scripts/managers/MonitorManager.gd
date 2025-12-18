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
@onready var overlay: MonitorOverlay = $MarginContainer/MonitorOverlay

var _theme_resource: Theme


func _ready() -> void:
	# Set layer high to appear above game content
	layer = 128
	
	# Load theme
	_theme_resource = preload("res://themes/bg3_theme.tres")
	theme = _theme_resource
	
	# Hide by default (player toggles with F3)
	visible = false
	
	# Apply theme and responsive sizing
	_apply_theme_and_sizing()
	
	# Connect to viewport resize
	if not get_viewport().resized.is_connected(_on_viewport_resized):
		get_viewport().resized.connect(_on_viewport_resized)


func _input(event: InputEvent) -> void:
	"""Handle input for toggling the overlay."""
	if event.is_action_pressed("toggle_perf_overlay"):
		visible = !visible
		if visible:
			_apply_theme_and_sizing()


func _notification(what: int) -> void:
	"""Handle notifications for viewport resize."""
	if what == NOTIFICATION_RESIZED:
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
	
	# Apply theme font if available
	if _theme_resource:
		var default_font: Font = _theme_resource.get_default_font()
		if default_font:
			# Override font size from theme if available
			var font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
			if font_size > 0:
				overlay.font_size = font_size
			
			# Apply font to graphs (they use get_theme_default_font internally)
			# The overlay will propagate this via its _create_graph_for method
	
	# Apply theme colors for fantasy aesthetic
	if _theme_resource:
		# Use gold color for graphs (BG3-inspired)
		var gold_color: Color = _theme_resource.get_color("font_color", "Label")
		if gold_color == Color.TRANSPARENT:
			# Fallback to BG3-inspired gold if theme doesn't have it
			gold_color = Color(1.0, 0.843, 0.0, 1.0)  # Gold
		overlay.graph_color = gold_color
		
		# Use semi-transparent dark background for readability
		overlay.background_color = Color(0.0, 0.0, 0.0, 0.6)  # Slightly more opaque for better readability


func toggle() -> void:
	"""Public method to toggle overlay visibility."""
	visible = !visible
	if visible:
		_apply_theme_and_sizing()


func set_visible(value: bool) -> void:
	"""Public method to set overlay visibility."""
	visible = value
	if visible:
		_apply_theme_and_sizing()
