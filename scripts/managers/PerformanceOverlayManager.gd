# ╔═══════════════════════════════════════════════════════════
# ║ PerformanceOverlayManager.gd
# ║ Desc: Singleton manager for toggleable HungryProton MonitorOverlay (F3 key)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

## Singleton manager for the performance overlay.
## Controls a manually-placed PerformanceOverlay scene instance.
## Handles F3 toggle, theme integration, and responsive positioning.
extends Node

@export var overlay_root: CanvasLayer  ## Drag the PerformanceOverlay CanvasLayer here in inspector

var margin_container: MarginContainer
var overlay: Control
var _theme_resource: Theme = preload("res://themes/bg3_theme.tres")


func _ready() -> void:
	"""Initialize overlay as hidden and apply initial setup."""
	# Auto-detect overlay if not manually assigned (like DebugMenuScaler pattern)
	if overlay_root == null:
		await get_tree().process_frame  # Wait for scene tree to be ready
		overlay_root = get_tree().root.get_node_or_null("PerformanceOverlay") as CanvasLayer
		if overlay_root == null:
			# Try searching in scene tree for any PerformanceOverlay
			overlay_root = _find_performance_overlay()
	
	if overlay_root == null:
		MythosLogger.warn("UI/PerformanceOverlay", "PerformanceOverlayManager: overlay_root not found. Add PerformanceOverlay.tscn to your main scene.")
		return
	
	# Get child nodes
	margin_container = overlay_root.get_node_or_null("MarginContainer")
	if margin_container == null:
		MythosLogger.error("UI/PerformanceOverlay", "PerformanceOverlayManager: MarginContainer not found in overlay_root")
		return
	
	overlay = margin_container.get_node_or_null("Panel/MonitorOverlay")
	if overlay == null:
		MythosLogger.error("UI/PerformanceOverlay", "PerformanceOverlayManager: MonitorOverlay not found in overlay_root")
		return
	
	# Ensure overlay starts hidden
	overlay_root.visible = false
	
	# Ensure input action exists (may already exist from project.godot)
	if not InputMap.has_action("toggle_perf_overlay"):
		InputMap.add_action("toggle_perf_overlay")
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = KEY_F3
		InputMap.action_add_event("toggle_perf_overlay", event)
	
	# Setup viewport resize handler
	_setup_resize_handler()
	
	MythosLogger.debug("UI/PerformanceOverlay", "PerformanceOverlayManager initialized (overlay_root: %s)" % overlay_root.get_path())


func _setup_resize_handler() -> void:
	"""Setup window resize handler."""
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	"""Handle viewport size change."""
	if overlay_root != null and overlay_root.visible:
		_apply_positioning_and_theme()
		MythosLogger.debug("UI/PerformanceOverlay", "Overlay repositioned on viewport resize")


func _setup_resize_handler() -> void:
	"""Setup window resize handler."""
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	"""Handle viewport size change."""
	if overlay_root != null and overlay_root.visible:
		_apply_positioning_and_theme()
		MythosLogger.debug("UI/PerformanceOverlay", "Overlay repositioned on viewport resize")


func _find_performance_overlay() -> CanvasLayer:
	"""Search scene tree for PerformanceOverlay CanvasLayer."""
	var root: Node = get_tree().root
	return _search_for_overlay(root)


func _search_for_overlay(node: Node) -> CanvasLayer:
	"""Recursively search for PerformanceOverlay CanvasLayer."""
	if node is CanvasLayer and node.name == "PerformanceOverlay":
		return node as CanvasLayer
	
	for child in node.get_children():
		var result: CanvasLayer = _search_for_overlay(child)
		if result != null:
			return result
	
	return null


func _input(event: InputEvent) -> void:
	"""Handle F3 toggle."""
	if event.is_action_pressed("toggle_perf_overlay"):
		_toggle_overlay()
		get_viewport().set_input_as_handled()


func _toggle_overlay() -> void:
	"""Toggle visibility and ensure proper positioning/theme when shown."""
	if overlay_root == null:
		return
	
	overlay_root.visible = !overlay_root.visible
	if overlay_root.visible:
		_apply_positioning_and_theme()


func _apply_positioning_and_theme() -> void:
	"""Apply responsive top-left positioning, theme, and sizing (mirrors DebugMenuScaler reliability)."""
	if not overlay or not margin_container:
		return
	
	# Force top-left anchor
	margin_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Apply larger readable font from theme
	var base_font_size: int = _theme_resource.get_font_size("font_size", "Label")
	if base_font_size <= 0:
		base_font_size = 14  # Fallback
	var scaled_font_size: int = int(base_font_size * 1.8)
	overlay.set("font_size", scaled_font_size)  # Addon supports this
	overlay.set("need_to_rebuild_ui", true)  # Trigger addon rebuild with new font
	
	# Wait TWO frames for layout/graphs to fully build (proven in DebugMenuScaler)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var content_size: Vector2 = overlay.get_combined_minimum_size()
	if content_size == Vector2.ZERO or content_size.y <= 0:
		# Safe fallback estimation
		var graph_height: float = 50.0
		if overlay.has("graph_height"):
			graph_height = overlay.get("graph_height")
		var estimated_height: float = (6.0 * graph_height) + (UIConstants.SPACING_MEDIUM * 2.0)
		content_size = Vector2(UIConstants.OVERLAY_MIN_WIDTH, estimated_height)
	
	# Clamp to screen (prevent clipping on any resolution)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var max_width: float = min(viewport_size.x * 0.4, 600.0)
	if content_size.x > max_width:
		content_size.x = max_width
	
	# Ensure minimum width from UIConstants
	if content_size.x < UIConstants.OVERLAY_MIN_WIDTH:
		content_size.x = UIConstants.OVERLAY_MIN_WIDTH
	
	# Apply margins + offsets using UIConstants
	var margin: int = UIConstants.OVERLAY_MARGIN_LARGE
	margin_container.offset_left = margin
	margin_container.offset_top = margin
	margin_container.offset_right = margin + content_size.x
	margin_container.offset_bottom = margin + content_size.y
	
	# Final screen bounds clamp (like DebugMenuScaler)
	# Calculate actual edges from offsets (PRESET_TOP_LEFT: offsets are from top-left)
	var left_edge: float = margin_container.offset_left
	var top_edge: float = margin_container.offset_top
	var right_edge: float = margin_container.offset_right
	var bottom_edge: float = margin_container.offset_bottom
	
	# Clamp to viewport bounds
	if right_edge > viewport_size.x:
		var excess: float = right_edge - viewport_size.x
		margin_container.offset_right = viewport_size.x - margin
		margin_container.offset_left = max(margin, left_edge - excess)
	if bottom_edge > viewport_size.y:
		var excess: float = bottom_edge - viewport_size.y
		margin_container.offset_bottom = viewport_size.y - margin
		margin_container.offset_top = max(margin, top_edge - excess)
	
	# Ensure minimum margins
	if margin_container.offset_left < margin:
		margin_container.offset_left = margin
	if margin_container.offset_top < margin:
		margin_container.offset_top = margin
	
	MythosLogger.debug("UI/PerformanceOverlay", "Overlay positioned: size=%s, offsets L=%d T=%d R=%d B=%d" % [content_size, margin_container.offset_left, margin_container.offset_top, margin_container.offset_right, margin_container.offset_bottom])
