# ╔═══════════════════════════════════════════════════════════
# ║ PerformanceOverlayController.gd
# ║ Desc: Controls visibility of the MonitorOverlay (F3 toggle)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

@onready var overlay: Control = $PerformanceOverlay

var overlay_visible: bool = false

func _ready() -> void:
	"""Initialize overlay visibility state."""
	if overlay:
		overlay.visible = overlay_visible
	else:
		MythosLogger.warn("PerformanceOverlay", "PerformanceOverlay node not found")

func _input(event: InputEvent) -> void:
	"""Handle input for toggling overlay visibility."""
	if event.is_action_pressed("ui_debug_toggle"):
		overlay_visible = !overlay_visible
		if overlay:
			overlay.visible = overlay_visible
			MythosLogger.debug("PerformanceOverlay", "Toggled overlay visibility: %s" % overlay_visible)
