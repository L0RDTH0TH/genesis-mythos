# ╔═══════════════════════════════════════════════════════════
# ║ DebugMenuScaler.gd
# ║ Desc: Scales the Debug Menu overlay for better readability
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

@export var scale_factor: float = 1.5  # Adjust as needed (1.5-2.0 recommended for readability)

func _ready() -> void:
	await get_tree().process_frame  # Wait one frame for DebugMenu to fully initialize
	# Access DebugMenu singleton directly (it's a CanvasLayer autoload)
	var debug_canvas: CanvasLayer = get_tree().root.get_node_or_null("DebugMenu")
	if debug_canvas:
		debug_canvas.scale = Vector2(scale_factor, scale_factor)
		print("Debug Menu scaled by factor: ", scale_factor)
	else:
		push_warning("DebugMenu CanvasLayer not found – ensure addon is enabled and running")
