# ╔═══════════════════════════════════════════════════════════
# ║ DebugMenuScaler.gd
# ║ Desc: Scales and positions the Debug Menu overlay for readability and full visibility
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

@export var scale_factor: float = 1.5  # Adjust for readability (1.5-2.0 recommended)
@export var x_offset_pixels: int = -20  # Negative = move left from right edge; adjust if needed for no clipping

func _ready() -> void:
	await get_tree().process_frame  # Wait for DebugMenu to initialize
	var debug_canvas: CanvasLayer = get_tree().root.get_node_or_null("DebugMenu")
	if debug_canvas:
		# Apply offset to CanvasLayer (moves entire overlay)
		debug_canvas.offset = Vector2(x_offset_pixels, 20)  # 20px top margin; x_offset pulls it away from right edge
		# Scale the Control node child (scales the content)
		var debug_control: Control = debug_canvas.get_node_or_null("DebugMenu")
		if debug_control:
			debug_control.scale = Vector2(scale_factor, scale_factor)
			print("Debug Menu scaled by ", scale_factor, "x and offset to ", debug_canvas.offset)
		else:
			push_warning("DebugMenu Control node not found in CanvasLayer")
	else:
		push_warning("DebugMenu CanvasLayer not found – ensure addon is enabled")
