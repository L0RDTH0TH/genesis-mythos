# ╔═══════════════════════════════════════════════════════════
# ║ LoadingOverlay.gd
# ║ Desc: Global singleton for managing loading overlay across scenes
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Reference to the instantiated overlay instance
var overlay_instance: LoadingOverlayUI = null


func show_loading(text: String = "Loading...", progress: float = 0.0) -> void:
	"""Show global loading overlay with text and progress."""
	# Instantiate overlay if needed
	if not overlay_instance:
		var overlay_scene: PackedScene = preload("res://scenes/ui/LoadingOverlay.tscn")
		overlay_instance = overlay_scene.instantiate()
		
		# Add to scene tree root (persists across scene changes)
		var root: Window = get_tree().root
		root.add_child(overlay_instance)
		
		MythosLogger.debug("LoadingOverlay", "Overlay instance created and added to root")
	
	# Show overlay
	overlay_instance.show_loading(text, progress)


func update_progress(text: String, progress: float) -> void:
	"""Update global loading progress."""
	if overlay_instance:
		overlay_instance.update_progress(text, progress)
	else:
		MythosLogger.warn("LoadingOverlay", "Cannot update progress - overlay not instantiated")


func hide_loading() -> void:
	"""Hide global loading overlay."""
	if overlay_instance:
		overlay_instance.hide_loading()
		# Don't queue_free here - keep instance for reuse
		MythosLogger.debug("LoadingOverlay", "Loading overlay hidden")
	else:
		MythosLogger.warn("LoadingOverlay", "Cannot hide - overlay not instantiated")

