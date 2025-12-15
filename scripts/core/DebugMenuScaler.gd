# ╔═══════════════════════════════════════════════════════════
# ║ DebugMenuScaler.gd
# ║ Desc: Scales the Debug Menu overlay for better readability
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

@export var scale_factor: float = 1.5  # Adjust as needed (1.5-2.0 recommended for readability)

var debug_menu: CanvasLayer = null

func _ready() -> void:
	await get_tree().process_frame  # Wait one frame for DebugMenu to fully initialize
	# Access DebugMenu singleton directly (it's a CanvasLayer autoload)
	debug_menu = get_tree().root.get_node_or_null("DebugMenu")
	if debug_menu:
		debug_menu.scale = Vector2(scale_factor, scale_factor)
		# Ensure DebugMenu is on top layer and visible when toggled
		debug_menu.layer = 128  # High layer to ensure it's on top
		print("Debug Menu scaled by factor: ", scale_factor, " and positioned on layer ", debug_menu.layer)
	else:
		push_warning("DebugMenu CanvasLayer not found – ensure addon is enabled and running")

func _input(event: InputEvent) -> void:
	"""Fallback input handler to ensure F3 toggle works even if DebugMenu doesn't receive input."""
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		if debug_menu:
			# Access the style property directly to cycle through states
			# Style enum: HIDDEN=0, VISIBLE_COMPACT=1, VISIBLE_DETAILED=2, MAX=3
			var current_style: int = debug_menu.get("style")
			var next_style: int = wrapi(current_style + 1, 0, 3)
			debug_menu.set("style", next_style)
