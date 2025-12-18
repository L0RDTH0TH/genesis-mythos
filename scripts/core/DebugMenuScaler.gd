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
	
	# Also listen to window notifications
	set_process(true)


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
	
	# Ensure anchor is set to top-right
	debug_control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	
	# Wait for layout to update to get actual content size
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame to ensure size is calculated
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	
	# Get the natural size of the content (before scaling)
	var content_size: Vector2 = debug_control.get_combined_minimum_size()
	if content_size == Vector2.ZERO:
		# Fallback: estimate size based on typical debug menu content
		content_size = Vector2(UIConstants.LABEL_WIDTH_WIDE * 2, UIConstants.LIST_HEIGHT_STANDARD * 2)
	
	# Calculate scaled size
	var scaled_size: Vector2 = content_size * debug_control.scale
	
	# Apply margins from UIConstants
	var safe_margin: int = UIConstants.SPACING_MEDIUM
	
	# For PRESET_TOP_RIGHT:
	# - offset_left: negative value extends left from right edge (defines width)
	# - offset_right: negative value creates margin from right edge
	# - offset_top: positive value creates margin from top edge
	# - offset_bottom: positive value sets bottom edge from top (defines height)
	
	# Calculate safe position ensuring it fits on screen
	var max_width: float = viewport_size.x - (safe_margin * 2)
	var max_height: float = viewport_size.y - (safe_margin * 2)
	
	# Adjust scale if content is too large
	if scaled_size.x > max_width:
		debug_control.scale = Vector2(max_width / content_size.x, debug_control.scale.y)
		scaled_size = content_size * debug_control.scale
	if scaled_size.y > max_height:
		debug_control.scale = Vector2(debug_control.scale.x, max_height / content_size.y)
		scaled_size = content_size * debug_control.scale
	
	# Set offsets with safe margins
	debug_control.offset_left = -scaled_size.x
	debug_control.offset_top = safe_margin
	debug_control.offset_right = -safe_margin
	debug_control.offset_bottom = safe_margin + scaled_size.y
	
	# Verify it's fully visible (final check)
	var right_edge: float = viewport_size.x + debug_control.offset_right
	var left_edge: float = right_edge - scaled_size.x
	var top_edge: float = debug_control.offset_top
	var bottom_edge: float = top_edge + scaled_size.y
	
	# Final clamp if still needed (shouldn't be, but safety check)
	if right_edge > viewport_size.x:
		debug_control.offset_right = -safe_margin
		debug_control.offset_left = -scaled_size.x
	if left_edge < safe_margin:
		debug_control.offset_right = -safe_margin
		debug_control.offset_left = -(viewport_size.x - safe_margin * 2)
	if top_edge < safe_margin:
		debug_control.offset_top = safe_margin
		debug_control.offset_bottom = safe_margin + scaled_size.y
	if bottom_edge > viewport_size.y - safe_margin:
		debug_control.offset_top = viewport_size.y - scaled_size.y - safe_margin
		debug_control.offset_bottom = debug_control.offset_top + scaled_size.y


func _notification(what: int) -> void:
	"""Handle window resize notifications."""
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# Defer to next frame to avoid async issues in notification handler
		call_deferred("_apply_responsive_positioning")
		MythosLogger.debug("UI/DebugMenu", "Debug menu repositioned via notification")


