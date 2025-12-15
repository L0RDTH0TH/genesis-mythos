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
		# Ensure DebugMenu is on the HIGHEST possible layer (255 is max) to be above ALL other UI
		debug_menu.layer = 255
		# Also ensure the DebugMenu Control node itself is on top
		var debug_control: Control = debug_menu.get_node_or_null("DebugMenu")
		if debug_control:
			debug_control.z_index = 1000  # Very high z-index to ensure it's on top
			debug_control.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input to game
			print("Debug Menu scaled by factor: ", scale_factor, " and positioned on layer ", debug_menu.layer, " with z_index ", debug_control.z_index)
		else:
			print("Debug Menu scaled by factor: ", scale_factor, " and positioned on layer ", debug_menu.layer, " (DebugMenu Control node not found)")
	else:
		push_warning("DebugMenu CanvasLayer not found – ensure addon is enabled and running")

func _input(event: InputEvent) -> void:
	"""Fallback input handler to ensure F3 toggle works even if DebugMenu doesn't receive input."""
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		print("=== F3 PRESSED ===")
		if debug_menu:
			print("DebugMenu CanvasLayer found")
			print("  - Layer: ", debug_menu.layer)
			print("  - Scale: ", debug_menu.scale)
			print("  - Visible: ", debug_menu.visible)
			
			# Access the style property directly to cycle through states
			# Style enum: HIDDEN=0, VISIBLE_COMPACT=1, VISIBLE_DETAILED=2, MAX=3
			var current_style: int = debug_menu.get("style")
			var style_names = ["HIDDEN", "VISIBLE_COMPACT", "VISIBLE_DETAILED"]
			print("  - Current style: ", style_names[current_style], " (", current_style, ")")
			
			var next_style: int = wrapi(current_style + 1, 0, 3)
			debug_menu.set("style", next_style)
			
			var new_style: int = debug_menu.get("style")
			print("  - New style: ", style_names[new_style], " (", new_style, ")")
			print("  - Visible after change: ", debug_menu.visible)
			
			# Check the DebugMenu Control node
			var debug_control: Control = debug_menu.get_node_or_null("DebugMenu")
			if debug_control:
				print("  - DebugMenu Control node found")
				print("    - Visible: ", debug_control.visible)
				print("    - Z-index: ", debug_control.z_index)
				print("    - Position: ", debug_control.position)
				print("    - Size: ", debug_control.size)
				print("    - Global position: ", debug_control.global_position)
				print("    - Modulate: ", debug_control.modulate)
			else:
				print("  - DebugMenu Control node NOT FOUND!")
				print("  - Available children: ", debug_menu.get_children())
		else:
			print("DebugMenu CanvasLayer NOT FOUND!")
			# Try to find it again
			debug_menu = get_tree().root.get_node_or_null("DebugMenu")
			if debug_menu:
				print("  - Found on retry!")
			else:
				print("  - Root children: ", get_tree().root.get_children())
		print("==================")
