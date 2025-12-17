# ╔═══════════════════════════════════════════════════════════
# ║ DebugMenuScaler.gd
# ║ Desc: Scales and positions the Debug Menu overlay for readability and full visibility
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

@export var scale_factor: float = 1.5  # Adjust for readability (1.5-2.0 recommended)

var debug_canvas: CanvasLayer = null
var debug_control: Control = null

func _ready() -> void:
	"""Initialize debug menu positioning and scaling."""
	await get_tree().process_frame  # Wait for DebugMenu to initialize
	_setup_debug_menu()
	_setup_resize_handler()
	MythosLogger.info("UI/DebugMenu", "Debug menu scaler initialized")


func _setup_resize_handler() -> void:
	"""Setup window resize handler."""
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	"""Handle viewport size change."""
	_apply_responsive_positioning()
	MythosLogger.debug("UI/DebugMenu", "Debug menu repositioned on viewport resize")


func _setup_debug_menu() -> void:
	"""Setup debug menu with responsive positioning."""
	debug_canvas = get_tree().root.get_node_or_null("DebugMenu")
	if debug_canvas == null:
		MythosLogger.warn("UI/DebugMenu", "DebugMenu CanvasLayer not found – ensure addon is enabled")
		return
	
	debug_control = debug_canvas.get_node_or_null("DebugMenu")
	if debug_control == null:
		MythosLogger.warn("UI/DebugMenu", "DebugMenu Control node not found in CanvasLayer")
		return
	
	# Apply responsive positioning using anchors and UIConstants
	_apply_responsive_positioning()
	
	# Scale the content for readability
	debug_control.scale = Vector2(scale_factor, scale_factor)
	
	MythosLogger.debug("UI/DebugMenu", "Debug menu scaled by %.1fx and positioned responsively" % scale_factor)


func _apply_responsive_positioning() -> void:
	"""Apply responsive positioning using anchors and UIConstants."""
	if debug_control == null:
		return
	
	# Set anchor to top-right
	debug_control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	
	# Apply margins from UIConstants
	var margin_right: int = -UIConstants.SPACING_MEDIUM  # Negative = margin from right edge
	var margin_top: int = UIConstants.SPACING_MEDIUM
	
	# Get the natural size of the content (before scaling)
	await get_tree().process_frame  # Wait for layout to update
	var content_size: Vector2 = debug_control.get_combined_minimum_size()
	if content_size == Vector2.ZERO:
		# Fallback if size not available yet
		content_size = Vector2(300, 400)
	
	# Apply margins to position in top-right with safe spacing
	# For PRESET_TOP_RIGHT (anchor at top-right corner):
	# - offset_left: negative value = extends left from right edge
	# - offset_right: usually 0 or negative for margin
	# - offset_top: positive = down from top edge
	# - offset_bottom: positive = down from top edge
	debug_control.offset_left = -content_size.x + margin_right
	debug_control.offset_top = margin_top
	debug_control.offset_right = margin_right
	debug_control.offset_bottom = margin_top + content_size.y
	
	# Clamp to ensure it stays on screen
	_clamp_to_viewport()


func _clamp_to_viewport() -> void:
	"""Clamp debug menu position to ensure it stays fully visible."""
	if debug_control == null:
		return
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	await get_tree().process_frame  # Wait for size to update
	var rect_size: Vector2 = debug_control.get_combined_minimum_size() * debug_control.scale
	if rect_size == Vector2.ZERO:
		rect_size = Vector2(300, 400) * debug_control.scale
	
	# Calculate actual position based on anchors and offsets
	var right_edge: float = viewport_size.x + debug_control.offset_right
	var left_edge: float = right_edge - rect_size.x
	var top_edge: float = debug_control.offset_top
	var bottom_edge: float = top_edge + rect_size.y
	
	# Ensure it doesn't go off the right edge
	if right_edge > viewport_size.x:
		var overflow: float = right_edge - viewport_size.x
		debug_control.offset_right -= overflow
	
	# Ensure it doesn't go off the left edge (if viewport is very small)
	if left_edge < 0:
		debug_control.offset_right = viewport_size.x - rect_size.x - UIConstants.SPACING_MEDIUM
	
	# Ensure it doesn't go off the top
	if top_edge < 0:
		debug_control.offset_top = UIConstants.SPACING_MEDIUM
		debug_control.offset_bottom = debug_control.offset_top + rect_size.y
	
	# Ensure it doesn't go off the bottom (if viewport is very small)
	if bottom_edge > viewport_size.y:
		debug_control.offset_top = viewport_size.y - rect_size.y - UIConstants.SPACING_MEDIUM
		debug_control.offset_bottom = debug_control.offset_top + rect_size.y


